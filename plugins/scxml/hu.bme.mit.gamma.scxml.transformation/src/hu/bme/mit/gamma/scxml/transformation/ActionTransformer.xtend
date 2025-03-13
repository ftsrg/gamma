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
import ac.soton.scxml.ScxmlRaiseType
import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent
import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import java.util.logging.Level
import org.eclipse.emf.ecore.EObject

import static ac.soton.scxml.ScxmlModelDerivedFeatures.*
import ac.soton.scxml.ScxmlSendType

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
			val expression = expressionLanguageParser.parse(expr, traceability.variables)
			val gammaAssign = actionUtil.createAssignment(variable as VariableDeclaration, expression)
			return gammaAssign
		}

		// TODO Assignment by child content if expr is not present
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

		val eventName = tokens.last

		// If a port is specified, the event will be an out event on an interface
		// realized in provided mode by the port receiving the event.
		// In the case of default interfaces and ports, realization mode is also provided,
		// but the trigger events are internal.
		val gammaEvent = if (isDefault) {
				getOrTransformInternalEvent(gammaInterface, eventName)
			} else {
				getOrTransformOutEvent(gammaInterface, eventName)
			}

		// Event parameters are currently not supported.
		// TODO Support payload
		val gammaRaise = createRaiseEventAction(gammaPort, gammaEvent, newArrayList)
		return gammaRaise
	}

	// TODO <send> actions
	// TODO Is traceability entry needed?
	def dispatch Action transformAction(ScxmlSendType scxmlSend) {
		logger.log(Level.INFO, "Transforming <send> element (" + scxmlSend + ")")

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

		val eventName = tokens.last
		val gammaEvent = getOrTransformOutEvent(gammaInterface, eventName)

		// Event parameters are currently not supported.
		// TODO Support payload
		val gammaRaise = createRaiseEventAction(gammaPort, gammaEvent, newArrayList)
		return gammaRaise
	}

	def dispatch Action transformAction(ScxmlIfType scxmlIf) {
		logger.log(Level.INFO, "Transforming <if> element (" + scxmlIf + ")")

		val gammaIf = createIfStatement
		val cond = scxmlIf.cond
		if (!cond.nullOrEmpty) {
			val condExpression = expressionLanguageParser.parse(cond, traceability.variables)

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

		// TODO invoked statechart type transformation should be ready at this point,
		// or be done lazily by the get call. Anyway, ActionTransformer is
		// not responsible for invoking contained statechart type transformation.
		val invokedTypeURI = scxmlInvoke.type

		// TODO get invoked type traceability
		// TODO check component type
		val invokedTypeTraceability = traceability.compositeTraceability.getTraceability(invokedTypeURI)
		val gammaSubcomponentType = invokedTypeTraceability.adapter as AsynchronousComponent

		val gammaSubcomponent = gammaSubcomponentType.instantiateAsynchronousComponent
		gammaSubcomponent.name = scxmlInvoke.id

		val missionPhaseAnnotation = createMissionPhaseStateAnnotation
		missionPhaseAnnotation.component = gammaSubcomponent

		// TODO Side effect: find state to put the phase annotation onto 
		// return missionPhaseAnnotation
		// TODO State, transition
		// Put transformed invoke to stable target state
		// val rootState = ecoreUtil.getContainerOfType(scxmlInvoke, ScxmlScxmlType);
		// val gammaRootState = traceability.getTraceability(rootState)
		// TODO Assignment by child content if expr is not present
		val gammaEmptyAction = createEmptyStatement
		return gammaEmptyAction
	}

	def Action transformBlock(Iterable<? extends EObject> actions) {
		if (actions.empty) {
			return createBlock
		}

		val gammaActions = actions.map[it.transformAction].toList
		val gammaBlock = actionUtil.wrap(gammaActions)

		return gammaBlock
	}

}
