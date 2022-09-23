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

import hu.bme.mit.gamma.expression.model.InfinityExpression
import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment
import hu.bme.mit.gamma.scenario.model.Delay
import hu.bme.mit.gamma.scenario.model.InteractionDirection
import hu.bme.mit.gamma.scenario.model.InteractionFragment
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet
import hu.bme.mit.gamma.scenario.model.ModalityType
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction
import hu.bme.mit.gamma.scenario.model.OptionalCombinedFragment
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import hu.bme.mit.gamma.scenario.model.Signal
import hu.bme.mit.gamma.statechart.contract.NotDefinedEventMode
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.interface_.Trigger
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.OnCycleTrigger
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import java.math.BigInteger
import java.util.List

import static extension hu.bme.mit.gamma.scenario.model.derivedfeatures.ScenarioModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class MonitorStatechartGenerator extends AbstractContractStatechartGeneration {

	protected boolean skipNextInteraction = false
	protected State componentViolation = null
	protected State environmentViolation = null
	protected final List<Pair<StateNode, StateNode>> copyOutgoingTransitionsForOptional = newLinkedList

	protected final boolean restartOnColdViolation

	protected final boolean useColdViolationForEnvironmentViolation = true
	protected final boolean useHotViolationForComponentViolation = false

	new(ScenarioDeclaration scenario, Component component, boolean restartOnColdViolation) {
		super(scenario, component)
		this.restartOnColdViolation = restartOnColdViolation
	}

	override execute() {
		if (component.isSynchronousStatechart) {
			statechart = createSynchronousStatechartDefinition
		} else {
			statechart = createAsynchronousStatechartDefinition
		}
		intializeStatechart()
		for (modalInteraction : scenario.chart.fragment.interactions) {
			if (!skipNextInteraction) {
				process(modalInteraction)
			} else {
				skipNextInteraction = false;
			}
		}
		firstRegion.stateNodes.get(firstRegion.stateNodes.size - 1).name = scenarioStatechartUtil.accepting
		fixReplacedStates
		copyTransitionsForOptional
		addScenarioContractAnnotation(NotDefinedEventMode.PERMISSIVE)
		resetVariablesOnViolation()
		resolveEqualPriorities()
		removeZeroDelays()
		val oldPorts = component.allPorts.filter[!it.inputEvents.empty]
		for (port : statechart.allPorts) {
			val oldPort = oldPorts.findFirst[it.name == port.name || it.turnedOutPortName == port.name]
			ecoreUtil.change(port, oldPort, statechart)
		}

		return statechart
	}

	protected def void resetVariablesOnViolation() {
		val effects = newArrayList
		for (variable : statechart.variableDeclarations) {
			effects += statechartUtil.createAssignment(variable, exprUtil.getInitialValue(variable))
		}
		coldViolation.entryActions += effects
	}

	protected def void resolveEqualPriorities() {
		for (state : firstRegion.states) {
			val outgoingTransitions = state.outgoingTransitions
			val groupByPriority = outgoingTransitions.groupBy[it.priority]
			var baseIncrease = 0
			for (group : groupByPriority.entrySet.sortBy[it.key]) {
				if (group.value.size > 1) {
					val transitions = group.value
					val groupedByDirection = transitions.groupBy[it.direction]
					val receives = groupedByDirection.get(InteractionDirection.RECEIVE)
					val sends = groupedByDirection.get(InteractionDirection.SEND)
					val currentBaseIcr = baseIncrease
					if (sends !== null) {
						sends.forEach[it.priority = it.priority + BigInteger.valueOf(sends.indexOf(it) + currentBaseIcr)]						
					}
					if (receives !== null) {
						receives.forEach [it.priority = it.priority + BigInteger.valueOf(
							receives.indexOf(it) + (sends !== null ? sends.size : 0) + currentBaseIcr
						)]
					}
				}
				baseIncrease += group.value.size
			}
		}
	}

	protected def void fixReplacedStates() {
		for (entry : replacedStateWithValue.entrySet) {
			for (transition : statechart.transitions.filter[it.sourceState == entry.key]) {
				transition.sourceState = entry.value
			}
			for (transition : statechart.transitions.filter[it.targetState == entry.key]) {
				transition.targetState = entry.value
			}
		}
	}

	protected def void copyTransitionsForOptional() {
		for (pair : copyOutgoingTransitionsForOptional) {
			val compulsory = replacedStateWithValue.getOrDefault(pair.key, pair.key)
			val optional = pair.value
			for (transition : compulsory.outgoingTransitions) {
				val targetState = transition.targetState
				if (targetState != optional && !targetState.reachableStates.contains(optional)) {
					val transitionCopy = transition.clone
					transitionCopy.sourceState = optional
					statechart.transitions += transitionCopy
					if (optional.name.contains(accepting)) {
						compulsory.name = compulsory.name.getCombinedStateAcceptingName
					}
				}
			}
		}
	}

	def protected void intializeStatechart() {
		addPorts(component)
		statechart.transitionPriority = TransitionPriority.VALUE_BASED
		statechart.name = scenario.name
		firstRegion = createRegion
		firstRegion.name = firstRegionName
		statechart.regions += firstRegion

		val initial = createInitialState
		initial.name = scenarioStatechartUtil.initial
		firstRegion.stateNodes += initial

		var State firstState = null
		if (scenario.initialblock === null) {
			firstState = createNewState
		} else {
			firstState = createState
			firstState.name = firstStateName
		}
		firstRegion.stateNodes += firstState
		previousState = firstState

		if (restartOnColdViolation) {
			coldViolation = firstState
		} else {
			coldViolation = createNewState(scenarioStatechartUtil.coldViolation)
			firstRegion.stateNodes += coldViolation
		}
		componentViolation = createNewState(scenarioStatechartUtil.hotComponentViolation)
		environmentViolation = createNewState(scenarioStatechartUtil.hotEnvironmentViolation)
		firstRegion.stateNodes += componentViolation
		firstRegion.stateNodes += environmentViolation
		statechartUtil.createTransition(initial, firstState)
		statechart.variableDeclarations += scenario.variableDeclarations
		if (scenario.initialblock !== null) {
			statechart.annotations += createHasInitialOutputsBlockAnnotation
			val syncBlock = createModalInteractionSet
			syncBlock.modalInteractions += scenario.initialblock.interactions
			scenario.chart.fragment.interactions.add(0, syncBlock)
		}
	}

	def dispatch void process(ModalInteractionSet interactionSet) {
		processModalInteractionSet(interactionSet, false)
	}

	def dispatch void process(Delay delay) {
		throw new UnsupportedOperationException("Single delays are placed into a set in a previous step")
	}

	def dispatch void process(NegatedModalInteraction negatedModalInteraction) {
		val modalInteraction = negatedModalInteraction.modalinteraction
		if (modalInteraction instanceof ModalInteractionSet) {
			processModalInteractionSet(modalInteraction, true)
		}
	}

	def dispatch void process(AlternativeCombinedFragment alternative) {
		val ends = newArrayList
		val prevprev = previousState
		for (i : 0 ..< alternative.fragments.size) {
			previousState = prevprev
			for (interaction : alternative.fragments.get(i).interactions) {
				process(interaction)
			}
			ends += previousState
		}
		
		val direction = prevprev.outgoingTransitions.head.direction
		val isSend = direction.equals(InteractionDirection.SEND)
		val violationState = if (isSend) {
			componentViolation
		} else {
			environmentViolation
		}
		val elseTransition = statechartUtil.createTransition(previousState, violationState)
		elseTransition.priority = BigInteger.ZERO
		elseTransition.trigger = createOnCycleTrigger
		
		val mergeState = createNewState(mergeName + exsistingMerges++)
		firstRegion.stateNodes += mergeState
		previousState = mergeState
		for (transition : statechart.transitions) {
			if (ends.contains(transition.targetState)) {
				replacedStateWithValue.put(transition.targetState, previousState)
			}
		}
		firstRegion.stateNodes -= ends
	}

	def dispatch void process(LoopCombinedFragment loop) {
		throw new UnsupportedOperationException
	}

	def dispatch void process(OptionalCombinedFragment optionalCombinedFragment) {
		val containingFragment = ecoreUtil.getContainerOfType(optionalCombinedFragment, InteractionFragment)
		val index = containingFragment.interactions.indexOf(optionalCombinedFragment)
		val prevprev = previousState
		val firstFragment = optionalCombinedFragment.fragments.get(0)
		for (interaction : firstFragment.interactions) {
			process(interaction)
		}
		if (containingFragment.interactions.size > index + 1) {
			val nextInteraction = containingFragment.interactions.get(index + 1)
			nextInteraction.process
			val previousAfterFirstProcess = previousState
			previousState = prevprev
			nextInteraction.process
			for (transition : previousState.incomingTransitions) {
				transition.targetState = previousAfterFirstProcess
			}
			firstRegion.stateNodes -= previousState
			previousState = previousAfterFirstProcess
			skipNextInteraction = true
		} else {
			copyOutgoingTransitionsForOptional.add(prevprev -> previousState)
			previousState = prevprev
		}
	}

	def processModalInteractionSet(ModalInteractionSet set, boolean isNegated) {
		val state = createNewState
		if (scenario.initialblock !== null && restartOnColdViolation && set.eContainer == scenario.chart.fragment &&
			scenario.chart.fragment.interactions.indexOf(set) == 0) {
			coldViolation = state
		}
		firstRegion.stateNodes += state
		val direction = set.direction
		val modality = set.modality
		val isSend = direction.equals(InteractionDirection.SEND)
		val forwardTransition = statechartUtil.createTransition(previousState, state)
		var StateNode violationState = null
		if (modality == ModalityType.COLD) {
			violationState = coldViolation
		} else {
			if (isSend) {
				violationState = componentViolation
			} else {
				violationState = environmentViolation
			}
		}
		val violationTransition = statechartUtil.createTransition(previousState, violationState)
		if (set.modalInteractions.empty) {
			val transition = statechartUtil.createTransition(previousState, state)
			transition.trigger = createOnCycleTrigger
			transition.guard = createTrueExpression
			firstRegion.stateNodes += state
			previousState = state
			return
		}
		handleDelays(set)
		setupForwardTransition(set, isSend, isNegated, forwardTransition)

		forwardTransition.priority = BigInteger.valueOf(3)
		violationTransition.priority = BigInteger.valueOf(1)
		handleArguments(set.modalInteractions, forwardTransition)
		val triggersWithCorrectDir = getAllTriggersForDirection(statechart, isSend)
		violationTransition.trigger = getBinaryTriggerFromTriggersIfPossible(triggersWithCorrectDir, BinaryType.OR)

		val delay = set.modalInteractions.filter(Delay).head
		if (delay !== null && !(delay.maximum instanceof InfinityExpression)) {
			val timeoutDeclaration = createTimeoutDeclaration
			val timeSpecification = createTimeSpecification(delay.maximum)
			setTimeoutDeclarationForState(previousState, timeoutDeclaration, timeSpecification)
			val timeoutTrigger = getEventTrigger(delay, true)
			val negatedTimeoutTrigger = createUnaryTrigger
			negatedTimeoutTrigger.type = UnaryType.NOT
			negatedTimeoutTrigger.operand = timeoutTrigger.clone
			val binaryOr = createBinaryTrigger
			binaryOr.type = BinaryType.OR
			val binaryAND = createBinaryTrigger
			binaryAND.type = BinaryType.AND

			binaryOr.leftOperand = timeoutTrigger
			binaryOr.rightOperand = violationTransition.trigger
			violationTransition.trigger = binaryOr

			binaryAND.leftOperand = negatedTimeoutTrigger
			binaryAND.rightOperand = forwardTransition.trigger
			forwardTransition.trigger = binaryAND
		}

		val otherDirViolationState = if (isSend) {
				useColdViolationForEnvironmentViolation ? coldViolation : environmentViolation
			} else {
				useHotViolationForComponentViolation ? componentViolation : coldViolation
			}
		val violationForOtherDirection = statechartUtil.createTransition(previousState, otherDirViolationState)
		violationForOtherDirection.priority = BigInteger.ZERO
		val triggersWithReverseDir = getAllTriggersForDirection(statechart, !isSend)
		violationForOtherDirection.trigger = getBinaryTriggerFromTriggersIfPossible(triggersWithReverseDir,
			BinaryType.OR)

		val signals = set.modalInteractions.filter(Signal).toList
		val otherTriggersWithCorrectDir = <Trigger>newArrayList
		for (trigger : getAllTriggersForDirection(statechart, isSend)) {
			if (trigger instanceof EventTrigger) {
				val eventRef = trigger.eventReference
				if (eventRef instanceof PortEventReference) {
					if (!signals.exists [
						(it.port.name == eventRef.port.name || it.port.turnedOutPortName == eventRef.port.name) &&
							it.event.name == eventRef.event.name
					]) {
						otherTriggersWithCorrectDir += trigger
					}
				}
			}
		}
		val othersNegated = getBinaryTriggerFromTriggersIfPossible(otherTriggersWithCorrectDir, BinaryType.OR).
				negateEventTrigger
		if (forwardTransition.trigger instanceof OnCycleTrigger) {
			forwardTransition.trigger = othersNegated
		} else {
			val binary = createBinaryTrigger
			binary.leftOperand = forwardTransition.trigger
			binary.rightOperand = othersNegated
			forwardTransition.trigger = binary
			binary.type = BinaryType.AND
		}
		previousState = state
		return
	}
}
