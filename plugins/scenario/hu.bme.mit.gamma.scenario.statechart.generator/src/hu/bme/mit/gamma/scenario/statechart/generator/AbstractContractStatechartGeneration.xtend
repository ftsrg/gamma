/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.statechart.generator

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.InfinityExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.scenario.model.Delay
import hu.bme.mit.gamma.scenario.model.DeterministicOccurrence
import hu.bme.mit.gamma.scenario.model.DeterministicOccurrenceSet
import hu.bme.mit.gamma.scenario.model.Interaction
import hu.bme.mit.gamma.scenario.model.InteractionDirection
import hu.bme.mit.gamma.scenario.model.NegatedDeterministicOccurrence
import hu.bme.mit.gamma.scenario.model.ScenarioAssignmentStatement
import hu.bme.mit.gamma.scenario.model.ScenarioCheckExpression
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import hu.bme.mit.gamma.scenario.model.ScenarioModelFactory
import hu.bme.mit.gamma.scenario.statechart.util.ScenarioStatechartUtil
import hu.bme.mit.gamma.statechart.contract.ContractModelFactory
import hu.bme.mit.gamma.statechart.contract.NotDefinedEventMode
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.interface_.Trigger
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.OnCycleTrigger
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import java.util.Arrays
import java.util.List
import java.util.Map
import org.eclipse.emf.ecore.EObject

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

abstract class AbstractContractStatechartGeneration {

	protected val extension StatechartModelFactory statechartfactory = StatechartModelFactory.eINSTANCE
	protected val extension ScenarioModelFactory scenariofactory = ScenarioModelFactory.eINSTANCE
	protected val extension ExpressionModelFactory expressionfactory = ExpressionModelFactory.eINSTANCE
	protected val extension InterfaceModelFactory interfacefactory = InterfaceModelFactory.eINSTANCE
	protected val extension ActionModelFactory actionfactory = ActionModelFactory.eINSTANCE
	protected val extension ContractModelFactory contractfactory = ContractModelFactory.eINSTANCE
	protected val extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected val extension ExpressionEvaluator exprEval = ExpressionEvaluator.INSTANCE
	protected val extension ExpressionUtil exprUtil = ExpressionUtil.INSTANCE
	protected val extension ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE
	protected val StatechartUtil statechartUtil = StatechartUtil.INSTANCE

	protected val JavaUtil javaUtil = JavaUtil.INSTANCE

	protected var Component component = null
	protected var ScenarioDeclaration scenario = null
	protected var StatechartDefinition statechart = null
	protected val Map<String, VariableDeclaration> variableMap = <String, VariableDeclaration>newHashMap
	protected var exsistingChoices = 0
	protected var exsistingMerges = 0
	protected var stateCount = 0
	protected var timeoutCount = 0
	protected var Region firstRegion = null
	protected var StateNode previousState = null
	protected var State hotViolation = null
	protected var State coldViolation = null
	protected var State firstState
	protected val Map<StateNode, StateNode> replacedStateWithValue = <StateNode, StateNode>newHashMap
	protected val Map<Delay, TimeoutDeclaration> delaysToTimeouts = <Delay, TimeoutDeclaration>newHashMap
	
	def abstract StatechartDefinition execute()

	new(ScenarioDeclaration scenario, Component component) {
		this.component = component
		this.scenario = scenario
	}

	def VariableDeclaration getOrCreate(Map<String, VariableDeclaration> map, String string) {
		val result = map.get(string)
		if (result !== null) {
			return result
		} else {
			val newVariable = createIntegerVariable(string)
			variableMap.put(string, newVariable)
			statechart.variableDeclarations += newVariable
			return newVariable
		}
	}

	def protected addPorts(Component component) {
		for (port : component.allPorts) {
			val portCopy = createPort
			val interfaceRealization = createInterfaceRealization
			interfaceRealization.realizationMode = port.interfaceRealization.realizationMode
			interfaceRealization.interface = port.interfaceRealization.interface
			portCopy.interfaceRealization = interfaceRealization
			portCopy.name = port.name
			statechart.ports += portCopy
			val portReverse = createPort
			portReverse.name = scenarioStatechartUtil.getTurnedOutPortName(port)
			val interfaceRealizationReverse = createInterfaceRealization
			interfaceRealizationReverse.interface = port.interfaceRealization.interface
			interfaceRealizationReverse.realizationMode =
					port.interfaceRealization.realizationMode.opposite
			portReverse.interfaceRealization = interfaceRealizationReverse
			statechart.ports += portReverse
		}
	}

	protected def addScenarioContractAnnotation(NotDefinedEventMode mode) {
		val annotation = createScenarioContractAnnotation
		annotation.monitoredComponent = component
		annotation.scenarioType = mode
		statechart.annotations += annotation
	}

///////// Create Set and Check Variables
	protected def AssignmentStatement incrementVar(VariableDeclaration variable) {
		return statechartUtil.createIncrementation(variable)
	}

	def protected VariableDeclaration createIntegerVariable(String name) {
		return exprUtil.createVariableDeclaration(createIntegerTypeDefinition,
				name, exprUtil.toIntegerLiteral(0))
	}

	protected def setIntVariable(VariableDeclaration variable, int value) {
		return statechartUtil.createAssignment(variable,
				exprUtil.toIntegerLiteral(value))
	}
	
	// TODO check if there are util methods in StatechartUtil for this
	def protected Expression getVariableLessEqualParamExpression(
				VariableDeclaration variable, int maxValue) {
		var maxCheck = createLessEqualExpression
		maxCheck.leftOperand = exprUtil.createReferenceExpression(variable)
		maxCheck.rightOperand = exprUtil.toIntegerLiteral(maxValue)
		return maxCheck
	}

	// TODO check if there are util methods in StatechartUtil for this
	def protected Expression getVariableGreaterEqualParamExpression(
				VariableDeclaration variable, int minValue) {
		var minCheck = createGreaterEqualExpression
		minCheck.leftOperand = exprUtil.createReferenceExpression(variable)
		minCheck.rightOperand = exprUtil.toIntegerLiteral(minValue)
		return minCheck
	}

	def protected Expression getVariableInIntervalExpression(VariableDeclaration variable,
			int minValue, int maxValue) {
		var and = createAndExpression
		and.operands += getVariableGreaterEqualParamExpression(variable, minValue)
		and.operands += getVariableLessEqualParamExpression(variable, maxValue)
		return and
	}

//////// Create Binary and negate triggers
	def protected void negateBinaryTree(BinaryTrigger binaryTrigger) {
		val right = binaryTrigger.rightOperand
		val left = binaryTrigger.leftOperand
		if (right instanceof EventTrigger) {
			binaryTrigger.rightOperand = negateTrigger(right)
		}
		if (left instanceof EventTrigger) {
			binaryTrigger.leftOperand = negateTrigger(left)
		}
		if (left instanceof BinaryTrigger) {
			negateBinaryTree(left)
		}
		if (right instanceof BinaryTrigger) {
			negateBinaryTree(right)
		}
	}

	def protected Trigger negateTrigger(Trigger trigger) {
		if (trigger instanceof UnaryTrigger) {
			if (trigger.type == UnaryType.NOT) {
				return trigger.operand
			}
		}
		var negated = createUnaryTrigger
		negated.type = UnaryType.NOT
		negated.operand = trigger
		return negated
	}

	def protected BinaryTrigger getBinaryTriggerFromTriggers(List<Trigger> triggers, BinaryType type) {
		val binaryTrigger = createBinaryTrigger
		binaryTrigger.type = type
		var runningbin = binaryTrigger
		var signalCount = 0
		for (trigger : triggers) {
			signalCount++
			if (runningbin.leftOperand === null) {
				runningbin.leftOperand = trigger
			} else if (signalCount == triggers.size) {
				runningbin.rightOperand = trigger
			} else {
				var newbin = createBinaryTrigger
				runningbin.rightOperand = newbin
				newbin.type = type
				runningbin = newbin
				runningbin.leftOperand = trigger
			}
		}
		return binaryTrigger
	}
	
	def protected Trigger getBinaryTriggerFromTriggersIfPossible(
			List<Trigger> triggers, BinaryType type) {
		if (triggers.size > 1) {
			return getBinaryTriggerFromTriggers(triggers.filterNull.toList, type)
		} else if (triggers.size == 1) {
			return triggers.head
		}
	}

	def protected BinaryTrigger getAllEvents(BinaryType type) {
		var bin = createBinaryTrigger
		bin.type = type
		var ports = statechart.ports.filter[!it.inputEvents.empty]
		var size = ports.size
		var runningbin = bin
		var signalCount = 0
		for (i : 0 ..< size) {
			signalCount++
			var ref = createAnyPortEventReference
			ref.port = ports.get(i)
			var trigger = createEventTrigger
			trigger.eventReference = ref
			if (runningbin.leftOperand === null)
				runningbin.leftOperand = trigger
			else if (signalCount == size) {
				runningbin.rightOperand = trigger
			} else {
				var newbin = createBinaryTrigger
				runningbin.rightOperand = newbin
				newbin.type = type
				runningbin = newbin
				runningbin.leftOperand = trigger
			}
		}
		return bin
	}
	
	protected def List<Trigger> createOtherTriggers(DeterministicOccurrenceSet set, boolean combineEvents, boolean onlySend) {
		val triggers = <Trigger>newArrayList
		val portsAndEvents = <Port,List<Event>>newHashMap
		val allPorts = 
		if(onlySend) {
			statechart.allPorts.filter[!it.inputEvents.empty].filter[it.isTurnedOut]
		} else {
			statechart.allPorts.filter[!it.inputEvents.empty]
		}
		for (modalInteraction : set.deterministicOccurrences) {
			var Interaction signal = null
			if (modalInteraction instanceof Interaction) {
				signal = modalInteraction
			} else if (modalInteraction instanceof NegatedDeterministicOccurrence) {
				val innerModalInteraction = modalInteraction.deterministicOccurrence
				if (innerModalInteraction instanceof Interaction) {
					signal = innerModalInteraction
				}
			}
			if (signal !== null) {
				val portName = signal.getDirection == InteractionDirection.SEND ?
						scenarioStatechartUtil.getTurnedOutPortName(signal.getPort) :
						signal.getPort.name
				val port = getPort(portName)
				val event = getEvent(signal.getEvent.name, port)
				if(portsAndEvents.containsKey(port)) {
					portsAndEvents.get(port).add(event)
				} else {
					portsAndEvents.put(port, <Event>newArrayList(Arrays.asList(event)))
				}
			}
		}
		for (port : allPorts) {
			if (!portsAndEvents.containsKey(port) && combineEvents) {
				val anyPortEvent = createAnyPortEventReference
				anyPortEvent.port = port
				val trigger = createEventTrigger
				trigger.eventReference = anyPortEvent
				triggers += trigger
			} else {
				val concrateEvents = 
					if(portsAndEvents.containsKey(port)) {
						port.inputEvents.filter[!(portsAndEvents.get(port).contains(it))]
					} else {
						port.inputEvents
					}
				for (concrateEvent : concrateEvents) {
					val trigger = createEventTrigger
					val portEventReference = createPortEventReference
					portEventReference.event = concrateEvent
					portEventReference.port = port
					trigger.eventReference = portEventReference
					triggers += trigger
				}
			}
		}
		return triggers
	}
	
	

	protected def List<Trigger> createOtherNegatedTriggers(DeterministicOccurrenceSet set, boolean combineEvents) {
		return createOtherTriggers(set,combineEvents, false).map[it.negateTrigger]
	}
	
	protected def List<Trigger> createOtherNegatedTriggers(DeterministicOccurrenceSet set, boolean combineEvents, boolean onlySend) {
		return createOtherTriggers(set,combineEvents, onlySend).map[it.negateTrigger]
	}

	def protected Trigger getBinaryTrigger(List<DeterministicOccurrence> interactions,
			BinaryType type, boolean reversed) {
		val triggers = newArrayList
		for (interaction : interactions) {
			triggers += getEventTrigger(interaction, reversed)
		}
		return getBinaryTriggerFromTriggersIfPossible(triggers.filterNull.toList, type)
	}

	// /////////////// Event triggers based on Interactions	
	def protected dispatch Trigger getEventTrigger(Interaction signal, boolean reversed) {
		val trigger = createEventTrigger
		val eventref = createPortEventReference
		val port = reversed ?
				getPort(scenarioStatechartUtil.getTurnedOutPortName(signal.getPort)) :
				getPort(signal.getPort.name)
		if (port.isInternal) {
			return null
		}
		eventref.event = getEvent(signal.getEvent.name, port)
		eventref.port = port
		trigger.eventReference = eventref
		return trigger
	}
	
	def protected Trigger createTimeoutTrigger(TimeoutDeclaration decl) {
		val trigger = createEventTrigger
		val timeoutEventReference = createTimeoutEventReference
		timeoutEventReference.timeout = decl
		trigger.eventReference = timeoutEventReference
		return trigger
	}

	def protected dispatch Trigger getEventTrigger(Delay delay, boolean reversed) {
		return createTimeoutTrigger(delaysToTimeouts.get(delay))
	}

	def protected dispatch Trigger getEventTrigger(
			NegatedDeterministicOccurrence negatedInteraction, boolean reversed) {
		val trigger = createEventTrigger
		if (negatedInteraction.deterministicOccurrence instanceof Interaction) {
			var signal = negatedInteraction.deterministicOccurrence as Interaction
			var Port port = signal.getDirection.equals(InteractionDirection.SEND) ?
					getPort(scenarioStatechartUtil.getTurnedOutPortName(signal.getPort)) :
					getPort(signal.getPort.name)
			if (port.isInternal) {
				return null
			}
			val Event event = getEvent(signal.getEvent.name, port)
			val eventRef = createPortEventReference
			eventRef.event = event
			eventRef.port = port
			trigger.eventReference = eventRef
			val unary = createUnaryTrigger
			unary.operand = trigger
			unary.type = UnaryType.NOT
			return unary
		}
		return trigger
	}

////////// RaiseEventActions based on Interactions
	def protected dispatch Action getRaiseEventAction(Interaction signal, boolean reversed) {
		var action = createRaiseEventAction
		var port = getPort(getNameOfNewPort(signal.getPort, reversed))
		val event = getEvent(signal.getEvent.name, port)
		action.event = event
		action.port = port
		if (signal.arguments.empty) {
			for (argument : event.parameterDeclarations) {
				val reference = createEventParameterReferenceExpression
				reference.port = getPort(port.turnedOutPortName)
				reference.event = getEvent(signal.getEvent.name, reference.port)
				reference.parameter = argument
				action.arguments += reference
			}
		} else {
			action.arguments += signal.arguments.clone
		}
		
		return action
	}

	def protected dispatch Action getRaiseEventAction(Delay delay, boolean reversed) {
		return null
	}

	def protected dispatch Action getRaiseEventAction(
			NegatedDeterministicOccurrence negatedInteraction, boolean reversed) {
		return null
	}

	def protected Port getPort(String name) {
		for (port : statechart.ports) {
			if (port.name == name) {
				return port
			}
		}
		return null
	}

	def protected Event getEvent(String name, Port port) {
		for (event : port.allEventDeclarations) {
			if (event.event.name == name) {
				return event.event
			}
		}
		return null
	}

	def protected createNewState(String name) {
		var state = createState
		state.name = name
		return state
	}

	def protected createNewState() {
		return createNewState(scenarioStatechartUtil.stateName + String.valueOf(stateCount++))
	}

	def protected ChoiceState createNewChoiceState() {
		exsistingChoices++
		var choice = createChoiceState
		var name = String.valueOf(scenarioStatechartUtil.choiceName + exsistingChoices++)
		choice.name = name
		return choice
	}

	def protected handleArguments(List<DeterministicOccurrence> set, Transition transition) {
		var signals = set.filter(Interaction).filter[!it.arguments.empty]
		if (signals.empty) {
			val firstInteraction = set.get(0)
			if (set.size == 1 && firstInteraction instanceof NegatedDeterministicOccurrence) {
				val interaction = firstInteraction as NegatedDeterministicOccurrence
				val innerInteraction = interaction.deterministicOccurrence
				if (innerInteraction instanceof Interaction) {
					if (!innerInteraction.arguments.empty) {
						signals = newArrayList(innerInteraction)
					}
				}
			}
		}
		if (signals.empty) {
			return
		}
		val guard1 = createAndExpression
		for (signal : signals) {
			val tmp = signal
			var i = 0
			var String portName = tmp.getPort.name
			if (tmp.getDirection.equals(InteractionDirection.SEND)) {
				if (!scenarioStatechartUtil.isTurnedOut(tmp.getPort)) {
					portName = scenarioStatechartUtil.getTurnedOutPortName(tmp.getPort)
				}
			}
			val port = getPort(portName)
			val event = getEvent(tmp.getEvent.name, port)
			for (paramDec : event.parameterDeclarations) {
				val paramRef = createEventParameterReferenceExpression
				paramRef.parameter = paramDec
				paramRef.port = port
				paramRef.event = event
				guard1.operands += createEqualityExpression(paramRef, tmp.arguments.get(i).clone)
				i++
			}
		}
		var Expression expr = null
		if (guard1.operands.size == 1) {
			expr = guard1.operands.get(0)
		} else {
			expr = guard1
		}
		val guard = transition.guard
		if (guard === null) {
			transition.guard = expr
		} else {
			val and = createAndExpression
			and.operands += expr
			and.operands += guard
			transition.guard = and
		}
	}

	def protected retargetAllEventParamRefs(EObject container, boolean reversed) {
		val eventParamRefs = ecoreUtil.getAllContentsOfType(container, EventParameterReferenceExpression)
		for (eventParamRef : eventParamRefs) {
			eventParamRef.port = getPort(getNameOfNewPort(eventParamRef.port, reversed))
			eventParamRef.event = getEvent(eventParamRef.event.name, eventParamRef.port)
		}
	}

	def protected addAssignmentsToTransition(Iterable<ScenarioAssignmentStatement> assignments,
			Transition transition) {
		for (assignment : assignments) {
 			transition.effects += statechartUtil.createAssignment(
 				assignment.lhs.clone, assignment.rhs.clone)
		}
	}

	def protected addChecksToTransition(Iterable<ScenarioCheckExpression> checks, Transition transition) {
		if (checks.size == 0) {
			return
		}
		var Expression newGuard = null
		if (checks.size > 1) {
			val andExpression = createAndExpression
			andExpression.operands += checks.map[it.expression.clone]
			newGuard = andExpression
		} else if (checks.size == 1) {
			newGuard = checks.head.expression.clone
		}
		if (transition.guard === null) {
			transition.guard = newGuard
		} else {
			val and = createAndExpression
			and.operands += newGuard
			and.operands += transition.guard
			transition.guard = and
		}
	}

	def protected setupForwardTransition(DeterministicOccurrenceSet set,
			boolean reversed, boolean isNegated, Transition forwardTransition) {
		retargetAllEventParamRefs(set, reversed)
		var Trigger trigger = null
		val checks = set.deterministicOccurrences.filter(ScenarioCheckExpression)
		val assignments = set.deterministicOccurrences.filter(ScenarioAssignmentStatement)
		val nonCheckOrAssignmentInteractitons = set.deterministicOccurrences.filter [
			!(it instanceof ScenarioCheckExpression) && ! (it instanceof ScenarioAssignmentStatement)
		].toList
		if (nonCheckOrAssignmentInteractitons.size > 1) {
			trigger = getBinaryTrigger(nonCheckOrAssignmentInteractitons, BinaryType.AND, reversed)
		} else if (nonCheckOrAssignmentInteractitons.size == 1) {
			trigger = getEventTrigger(nonCheckOrAssignmentInteractitons.head, reversed)
		} 
		if (trigger === null) {
			trigger = createOnCycleTrigger
		}
		if (isNegated) {
			forwardTransition.setOrExtendTrigger(negateTrigger(trigger), BinaryType.AND)
		} else {
			forwardTransition.setOrExtendTrigger(trigger, BinaryType.AND)
			//Uncomment these lines to allow effects on the reversed ports
//			for (modalInteraction : nonCheckOrAssignmentInteractitons) {
//				val effect = getRaiseEventAction(modalInteraction, !reversed)
//				if (effect !== null) {
//					forwardTransition.effects += effect
//				}
//			}
		}
		addChecksToTransition(checks, forwardTransition)
		addAssignmentsToTransition(assignments, forwardTransition)
	}

	def protected handleDelays(DeterministicOccurrenceSet set, Transition forwardTransition, Transition violationTransition) {
		val delays = set.deterministicOccurrences.filter(Delay)
		if (!delays.empty) {
			val delay = delays.head
			val timeoutDeclaration = createTimeoutDeclaration
			val timeSpecification = createTimeSpecification(delay.minimum)
			setTimeoutDeclarationForState(previousState, timeoutDeclaration, timeSpecification)
			delaysToTimeouts.put(delay, timeoutDeclaration)
			if (!(delay.maximum instanceof InfinityExpression)) {
				val timeoutDeclarationMax = createTimeoutDeclaration
				val timeSpecificationMax = createTimeSpecification(delay.maximum)
				setTimeoutDeclarationForState(previousState, timeoutDeclarationMax, timeSpecificationMax)
				
				val timeoutTrigger = createTimeoutTrigger(timeoutDeclarationMax)
				
				val negatedTimeoutTrigger = createUnaryTrigger
				negatedTimeoutTrigger.type = UnaryType.NOT
				negatedTimeoutTrigger.operand = timeoutTrigger.clone

				setOrExtendTrigger(violationTransition, timeoutTrigger, BinaryType.OR)

				setOrExtendTrigger(forwardTransition, negatedTimeoutTrigger, BinaryType.AND)
			}
		}
	}
	
	def protected setOrExtendTrigger(Transition transition, Trigger newTrigger, BinaryType logicalRelation) {
		if(transition.trigger !== null && !(transition.trigger instanceof OnCycleTrigger)) {
			val binaryAND = createBinaryTrigger
			binaryAND.type = logicalRelation
			binaryAND.leftOperand = newTrigger
			binaryAND.rightOperand = transition.trigger
			transition.trigger = binaryAND				
		} else {
			transition.trigger = newTrigger
		}
	}

	def protected createTimeoutDeclaration() {
		val timeoutDeclaration = statechartfactory.createTimeoutDeclaration
		timeoutDeclaration.name = getDelayName(timeoutCount++)
		statechart.timeoutDeclarations += timeoutDeclaration
		return timeoutDeclaration
	}

	def protected createTimeSpecification(Expression expression) {
		val timeSpecification = createTimeSpecification
		timeSpecification.unit = TimeUnit.MILLISECOND
		timeSpecification.value = expression.clone
		return timeSpecification
	}

	def protected void setTimeoutDeclarationForState(StateNode state,
			TimeoutDeclaration timeoutDeclaration, TimeSpecification timeSpecification) {
		val action = createSetTimeoutAction
		action.timeoutDeclaration = timeoutDeclaration
		action.time = timeSpecification
		if (state instanceof State) {
			state.entryActions += action
		}
	}
	
	def protected void removeZeroDelays() {
		val timeoutDeclarationsToBeRemoved = newArrayList
		for (timeout : statechart.timeoutDeclarations) {
			val value = timeout.timeoutValue
			if (value === null || (value.value.evaluable && value.value.evaluate == 0)) {
				timeoutDeclarationsToBeRemoved += timeout
			}
		}
		val eventRefs = ecoreUtil.getAllContentsOfType(statechart, TimeoutEventReference)
			.filter[timeoutDeclarationsToBeRemoved.contains(it.timeout)]
		val triggers = eventRefs.map[it.eContainer].filter(EventTrigger)	
		for (trigger : triggers) {
			val container = trigger.eContainer
			if (container instanceof Transition) {
				ecoreUtil.replace(createOnCycleTrigger, trigger)
			} else if (container instanceof UnaryTrigger) {
				ecoreUtil.replace(createOnCycleTrigger, trigger)
			} else if (container instanceof BinaryTrigger) {
				val otherSide = container.rightOperand == trigger ? container.leftOperand : container.rightOperand
				ecoreUtil.replace(otherSide, container)
			}
		}
		
		statechart.timeoutDeclarations -= timeoutDeclarationsToBeRemoved
		
		for (state : firstRegion.states) {
			state.entryActions -= state.entryActions
				.filter(SetTimeoutAction)
				.filter[it.time.value.evaluable && it.time.value.evaluate == 0]
				.toList
		}
	}
}
