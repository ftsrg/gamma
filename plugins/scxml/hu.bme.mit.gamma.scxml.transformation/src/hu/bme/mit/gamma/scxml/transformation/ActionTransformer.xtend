/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlAssignType
import ac.soton.scxml.ScxmlIfType
import ac.soton.scxml.ScxmlInvokeType
import ac.soton.scxml.ScxmlOnentryType
import ac.soton.scxml.ScxmlOnexitType
import ac.soton.scxml.ScxmlParamType
import ac.soton.scxml.ScxmlRaiseType
import ac.soton.scxml.ScxmlSendType
import ac.soton.scxml.ScxmlStateType
import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.statechart.phase.History
import java.util.function.Function
import java.util.logging.Level
import org.eclipse.emf.ecore.EObject

import static ac.soton.scxml.ScxmlModelDerivedFeatures.*

class ActionTransformer extends AtomicElementTransformer {

	protected final extension PortTransformer portTransformer
	protected final extension InterfaceTransformer interfaceTransformer
	protected final extension EventTransformer eventTransformer
	protected final extension ScxmlGammaExpressionTransformer expressionTransformer

	new(StatechartTraceability traceability) {
		super(traceability)

		this.portTransformer = new PortTransformer(traceability)
		this.interfaceTransformer = new InterfaceTransformer(traceability)
		this.eventTransformer = new EventTransformer(traceability)
		this.expressionTransformer = new ScxmlGammaExpressionTransformer(traceability)
	}

	def Action transformOnentry(ScxmlOnentryType scxmlOnentry) {
		logger.log(Level.INFO, "Transforming <onentry> element (" + scxmlOnentry + ")")

		val scxmlActions = getOnentryActions(scxmlOnentry)
		if (!scxmlActions.nullOrEmpty) {
			val gammaEntryAction = scxmlActions.transformBlock;
			return gammaEntryAction
		}
		return null
	}

	def Action transformOnexit(ScxmlOnexitType scxmlOnexit) {
		logger.log(Level.INFO, "Transforming <onexit> element (" + scxmlOnexit + ")")

		val scxmlActions = getOnexitActions(scxmlOnexit)
		if (!scxmlActions.nullOrEmpty) {
			val gammaExitAction = scxmlActions.transformBlock;
			return gammaExitAction
		}
		return null
	}

	def dispatch Action transformAction(ScxmlAssignType scxmlAssign) {
		logger.log(Level.INFO, "Transforming <assign> element (" + scxmlAssign + ")")

		val varLoc = scxmlAssign.location
		val variable = traceability.getVariable(varLoc)

		val expr = scxmlAssign.expr
		if (expr !== null) {
			val expression = expressionLanguageParser.preprocessAndParse(
				expr,
				expressionLanguageLinker.getLinker(traceability)
			)
			val gammaAssign = createAssignment(variable as VariableDeclaration, expression)
			return gammaAssign
		}

		// TODO Assignment by <assign> element's child content if expr is not present.
		val gammaAssign = createEmptyStatement

		return gammaAssign
	}

	def dispatch Action transformAction(ScxmlRaiseType scxmlRaise) {
		logger.log(Level.INFO, "Transforming <raise> element (" + scxmlRaise + ")")

		val eventString = scxmlRaise.event
		val tokens = eventString.split("\\.")
		if (tokens.size < 1 || tokens.size > 3) {
			throw new IllegalArgumentException(
				"Event descriptor " + eventString + " does not contain exactly 1, 2 or 3 dot separated tokens."
			)
		}

		var gammaInterface = null as Interface
		var gammaPort = null as Port
		var isDefault = false

		if (tokens.size == 1) {
			isDefault = true
			gammaInterface = getOrCreateDefaultInterface()
			gammaPort = getOrCreateDefaultPort()
		} else {
			val interfaceName = tokens.get(tokens.size - 2)
			gammaInterface = getOrTransformInterfaceByName(interfaceName)

			if (tokens.size >= 3) {
				val portName = tokens.head
				gammaPort = getOrTransformPortByName(gammaInterface, portName, RealizationMode.PROVIDED)
			} else {
				isDefault = true
				gammaPort = getOrTransformDefaultInterfacePort(gammaInterface)
			}
		}

		val eventName = tokens.lastOrNull

		// If a port is specified, the event will be an out event on an interface
		// realized in provided mode by the port receiving the event.
		// In the case of default interfaces and ports, realization mode is also provided,
		// but the trigger events are internal.
		val gammaEvent = if (isDefault) {
				getOrTransformInternalEvent(gammaInterface, eventName)
			} else {
				getOrTransformOutEvent(gammaInterface, eventName)
			}

		val gammaRaise = createRaiseEventAction(gammaPort, gammaEvent, newArrayList)
		return gammaRaise
	}

	// TODO <send> actions
	// TODO Is traceability entry needed?
	def dispatch Action transformAction(ScxmlSendType scxmlSend) {
		logger.info("Transforming <send> element (" + scxmlSend + ")")

		// TODO Check nulls / empty substrings
		val eventString = scxmlSend.event
		val targetInterfacePortString = scxmlSend.targetexpr
		val eventTargetString = targetInterfacePortString + "." + eventString

		val tokens = eventTargetString.split("\\.")
		if (tokens.size < 2 || tokens.size > 3) {
			throw new IllegalArgumentException(
				"Event descriptor " + eventString + " does not contain exactly 2 or 3 dot separated tokens."
			)
		}

		var gammaInterface = null as Interface
		var gammaPort = null as Port

		val interfaceName = tokens.get(tokens.size - 2)
		gammaInterface = getOrTransformInterfaceByName(interfaceName)

		if (tokens.size >= 3) {
			val portName = tokens.head
			gammaPort = getOrTransformPortByName(gammaInterface, portName, RealizationMode.PROVIDED)
		} else {
			gammaPort = getOrTransformDefaultInterfacePort(gammaInterface)
		}

		val eventName = tokens.lastOrNull
		val gammaEvent = getOrTransformOutEvent(gammaInterface, eventName)

		// Event <param> elements
		// TODO Refactor, extract param and argument transformer method
		// TODO Named parameter support
		// In the Gamma event, the order of the parameters and arguments matters, they are not named.
		// Currently, every event parameter of the same event has to be specified, in exact order.
		val gammaArgumentNames = newArrayList
		val gammaArgumentExpressions = newArrayList
		val arguments = scxmlSend.getContentsOfType(ScxmlParamType)
		for (argument : arguments) {
			val argName = argument.name
			val argExpr = argument.expr

			if (argExpr !== null) {
				val argExpression = expressionLanguageParser.preprocessAndParse(
					argExpr,
					expressionLanguageLinker.getLinker(traceability)
				)
				gammaArgumentNames += argName
				gammaArgumentExpressions += argExpression

				val argType = expressionTypeDeterminator.getType(argExpression)

				// TODO Traceability; event+param -> event+param
				// existsParameter(event, param)
				// getOrCreateParameter(event, param): creates if not exists, then returns
				if (!gammaEvent.parameterDeclarations.exists[it.name == argName]) {
					val gammaEventParameterDeclaration = argType.createParameterDeclaration(argName)
					gammaEvent.parameterDeclarations += gammaEventParameterDeclaration
					
					// TODO Refactor into getOrCreate event parameter method
					if (!traceability.containsEventParameter(argName)) {
						traceability.putEventParameter(argName, gammaEventParameterDeclaration)
					}
				}
			}
		}
		
		// TODO Reorder event arguments according to parameter names in event
		// TODO Mix named and indexed parameter passing
		// TODO Name -> Find argument by name
			// No name -> get index of element in parent's children list
			// Parametric(parameterized)Element-ekre meg lehet csinálni
		val orderedGammaArguments = newArrayList
		for (eventParameter : gammaEvent.parameterDeclarations) {
			val index = gammaArgumentNames.indexOf(eventParameter.name)
			/*if (index < 0) {
				val index = ecoreUtil.getIndex(0)
			}*/
			val argumentExpression = gammaArgumentExpressions.get(index)
			orderedGammaArguments += argumentExpression
		} 

		val gammaRaise = createRaiseEventAction(gammaPort, gammaEvent, orderedGammaArguments)
		return gammaRaise
	}

	def dispatch Action transformAction(ScxmlIfType scxmlIf) {
		logger.log(Level.INFO, "Transforming <if> element (" + scxmlIf + ")")

		val gammaIf = createIfStatement
		val cond = scxmlIf.cond
		if (!cond.nullOrEmpty) {
			val condExpression = expressionLanguageParser.preprocessAndParse(
				cond,
				expressionLanguageLinker.getLinker(traceability)
			)

			val thenStatements = getIfThenActions(scxmlIf);
			val gammaThenStatements = thenStatements.transformBlock

			val gammaConditional = createBranch
			gammaConditional.guard = condExpression
			gammaConditional.action = gammaThenStatements
			gammaIf.conditionals += gammaConditional
		}
		return gammaIf
	}

	// TODO check return type (Action vs other)
	// TODO use global section of traceability object to store component types, interfaces etc.
	def dispatch Action transformAction(ScxmlInvokeType scxmlInvoke) {
		logger.log(Level.INFO, "Transforming <invoke> element (" + scxmlInvoke + ")")

		// TODO invoked statechart type transformation should already be done at this point,
		// or be done lazily by the get call. Either way, ActionTransformer is
		// not responsible for invoking contained statechart type transformation.
		val invokedTypeSourceURI = scxmlInvoke.src

		// TODO get invoked type traceability
		// TODO check component type
		val invokedTypeTraceability = traceability.compositeTraceability.getTraceability(invokedTypeSourceURI)
		val gammaSubcomponentType = invokedTypeTraceability.statechart /*adapter as AsynchronousComponent*/

		val gammaSubcomponent = gammaSubcomponentType.instantiateComponent
		gammaSubcomponent.name = scxmlInvoke.id

		val missionPhaseStateAnnotation = createMissionPhaseStateAnnotation

		val invokeParameters = scxmlInvoke.param

		// TODO Pass <invoke> arguments by subcomponent parameter names
		val arguments = invokeParameters.filter[it.name == "_argument"]
		/* arguments.forEach [ it |
		 *	val gammaArgument = it.expr.transformArgument
		 *	gammaSubcomponent.arguments += gammaArgument
		 * ] */
		val parameters = gammaSubcomponentType.parameterDeclarations
		for (parameter : parameters) {
			val argument = arguments.findFirst[it.name == parameter.name]
			val gammaArgument = argument.expr.transformArgument
			gammaSubcomponent.arguments += gammaArgument
		}

		missionPhaseStateAnnotation.component = gammaSubcomponent

		val portBindings = invokeParameters.filter[it.name == "_port_binding"]
		portBindings.forEach [ it |
			val gammaPortBinding = transformPortBinding(gammaSubcomponent, it.expr)
			missionPhaseStateAnnotation.portBindings += gammaPortBinding
		]

		val variableBindings = invokeParameters.filter[it.name == "_variable_binding"]
		variableBindings.forEach [ it |
			val gammaVariableBinding = transformVariableBinding(gammaSubcomponent, it.expr)
			missionPhaseStateAnnotation.variableBindings += gammaVariableBinding
		]

		val history = invokeParameters.findFirst[it.name == "_history"]
		if (history !== null) {
			val gammaHistory = switch history.expr {
				case "shallow": History.SHALLOW_HISTORY
				case "deep": History.DEEP_HISTORY
				case "no",
				default: History.NO_HISTORY
			}
			missionPhaseStateAnnotation.history = gammaHistory
		}

		// TODO State, transition
		// Put transformed invoke to stable target state
		// TODO Assignment by child content if expr is not present
		val parentState = scxmlInvoke.getContainerOfType(ScxmlStateType)
		val gammaState = traceability.getState(parentState)
		gammaState.annotations += missionPhaseStateAnnotation

		val gammaEmptyAction = createEmptyStatement
		return gammaEmptyAction
	}

	def Action transformBlock(Iterable<? extends EObject> actions) {
		if (actions.empty) {
			return createBlock
		}

		val gammaActions = actions.map[it.transformAction].toList
		val gammaBlock = gammaActions.wrap

		return gammaBlock
	}

	// TODO Connect statechart arguments with statechart parameters by name
	private def Expression transformArgument(String argumentSpec) {
		val argumentString = argumentSpec.trim
		val tokens = argumentString.split("\\.|\\s*\\=\\s*")
		if (tokens.size != 2) {
			throw new IllegalArgumentException(
				"Argument descriptor " + argumentString + " does not contain exactly 2 dot separated tokens."
			)
		}
		// TODO Trim tokens
		// TODO Use parameter name to determine the order of statechart arguments
		val targetParameterName = tokens.get(0)
		val scxmlArgumentExpression = tokens.get(1)

		// TODO Expression parsing
		val gammaArgumentExpression = expressionLanguageParser.preprocessAndParse(
			scxmlArgumentExpression,
			expressionLanguageLinker.getLinker(traceability)
		)

		return gammaArgumentExpression
	}

	// TODO Reuse code - port/variable bindings
	// TODO? Pattern, Matcher, regexes etc.
	private def transformPortBinding(ComponentInstance instance, String portBindingSpec) {
		val bindingString = portBindingSpec.trim
		val tokens = bindingString.split("\\.|\\s*\\-\\s*")
		if (tokens.size != 3) {
			throw new IllegalArgumentException(
				"Binding descriptor " + bindingString + " does not contain exactly 3 dot separated tokens."
			)
		}
		// TODO Trim tokens
		val sourcePortName = tokens.get(0)
		val targetInstanceName = tokens.get(1)
		val targetPortName = tokens.get(2)

		// TODO Throw exception if port does not exist or ambiguous
		val gammaSourcePort = traceability.getPort(sourcePortName)
		val gammaInstancePortReference = createInstancePortReference(instance, targetInstanceName, targetPortName)

		val gammaPortBinding = createPortBinding(gammaSourcePort, gammaInstancePortReference)
		return gammaPortBinding
	}

	private def createInstancePortReference(ComponentInstance instance, String instanceName, String scxmlPortName) {
		// val instance = traceability.compositeTraceability.getComponentInstance(instanceName)
		// TODO Make it more performant to get statechart traceability
		// by instance invokeId or source URI.
		val statechartTraceability = traceability.compositeTraceability.getTraceabilityById(instanceName)
		val port = statechartTraceability.getPort(scxmlPortName)

		val instancePortReference = createInstancePortReference(instance, port)
		return instancePortReference
	}

	private def transformVariableBinding(ComponentInstance instance, String variableBindingSpec) {
		val bindingString = variableBindingSpec.trim
		val tokens = bindingString.split("\\.|\\s*\\-\\s*")
		if (tokens.size != 3) {
			throw new IllegalArgumentException(
				"Binding descriptor " + bindingString + " does not contain exactly 3 dot separated tokens."
			)
		}

		val sourceVariableName = tokens.get(0)
		val targetInstanceName = tokens.get(1)
		val targetVariableName = tokens.get(2)

		// TODO Throw exception if port does not exist or ambiguous
		val gammaSourceVariable = traceability.getVariable(sourceVariableName)
		val gammaInstanceVariableReference = createInstanceVariableReference(instance, targetInstanceName,
			targetVariableName)

		val gammaVariableBinding = createVariableBinding
		gammaVariableBinding.instanceVariableReference = gammaInstanceVariableReference
		gammaVariableBinding.statechartVariable = gammaSourceVariable
		return gammaVariableBinding
	}

	private def createInstanceVariableReference(ComponentInstance instance, String instanceName,
		String scxmlVariableName) {
		// val instance = traceability.compositeTraceability.getComponentInstance(instanceName)
		// TODO Make it more performant to get statechart traceability
		// by instance invokeId or source URI.
		val statechartTraceability = traceability.compositeTraceability.getTraceabilityById(instanceName)
		val variable = statechartTraceability.getVariable(scxmlVariableName)

		val instanceVariableReference = createInstanceVariableReference
		instanceVariableReference.instance = instance
		instanceVariableReference.variable = variable
		return instanceVariableReference
	}

}
