/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.statechart.generator

import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment
import hu.bme.mit.gamma.scenario.model.Delay
import hu.bme.mit.gamma.scenario.model.DeterministicOccurrenceSet
import hu.bme.mit.gamma.scenario.model.Interaction
import hu.bme.mit.gamma.scenario.model.InteractionDirection
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment
import hu.bme.mit.gamma.scenario.model.ModalityType
import hu.bme.mit.gamma.scenario.model.NegatedDeterministicOccurrence
import hu.bme.mit.gamma.scenario.model.OptionalCombinedFragment
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
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
import java.math.BigInteger
import java.util.List

import static extension hu.bme.mit.gamma.scenario.model.derivedfeatures.ScenarioModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class MonitorStatechartGenerator extends AbstractContractStatechartGeneration {

	protected State componentViolation = null
	protected State environmentViolation = null
	protected final List<Pair<StateNode, StateNode>> copyOutgoingTransitionsForOptional = newLinkedList

	protected final boolean restartOnColdViolation
	protected final boolean restartOnAccept

	protected final boolean useColdViolationForEnvironmentViolation = true
	protected final boolean useHotViolationForComponentViolation = false
	
	new(ScenarioDeclaration scenario, Component component, boolean restartOnColdViolation, boolean restartOnAccept) {
		super(scenario, component)
		this.restartOnColdViolation = restartOnColdViolation
		this.restartOnAccept = restartOnAccept
	}

	override execute() {
		if (component.isSynchronousStatechart) {
			statechart = createSynchronousStatechartDefinition
		}
		else {
			statechart = createAsynchronousStatechartDefinition
		}
		intializeStatechart()
		for (modalInteraction : scenario.fragment.interactions) {
			process(modalInteraction)
		}
		fixReplacedStates()
		addScenarioContractAnnotation(NotDefinedEventMode.PERMISSIVE)
		resetVariablesOnViolation()
		resolveEqualPriorities()
		removeZeroDelays()
		val lastState = firstRegion.stateNodes.get(firstRegion.stateNodes.size - 1)
		if (!restartOnAccept) {
			lastState.name = scenarioStatechartUtil.accepting
		}
		else {
			for (transition : lastState.incomingTransitions) {
				transition.targetState = firstState
			}
			firstRegion.stateNodes -= lastState
		}
		copyTransitionsForOptional()
		addColdViolationRestartTransitions()
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
							receives.indexOf(it) + (sends !== null ? sends.size : 0) + currentBaseIcr)]
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
			val compulsory = pair.key
			val optional = replacedStateWithValue.getOrDefault(pair.value, pair.value)
			for (transition : optional.outgoingTransitions) {
				val targetState = transition.targetState
				if (targetState != compulsory && !targetState.reachableStates.contains(compulsory)) {
					val transitionCopy = transition.clone
					transitionCopy.sourceState = compulsory
					statechart.transitions += transitionCopy
				}
			}
			if (optional.name.contains(accepting)) {
				compulsory.name = compulsory.name.getCombinedStateAcceptingName
			}
		}
	}
	
	/**
	 * With this, there are 4 transitions leaving a certain state (in priority).
	 * 1. accepting transition,
	 * 2. restart transition if the incoming event matches in a "cold modality" state (see code below),
	 * 3. violation transition,
	 * 4. cold violation transition triggered by event coming from the opposite direction. 
	 */
	protected def void addColdViolationRestartTransitions() {
		if (restartOnColdViolation) { // Makes sense only here
			val firstStateStartTransitions = firstState.outgoingTransitions.reject[it.loop ||
					it.targetState == coldViolation || it.targetState == hotViolation] // Accepting state?
			val coldModalityStates = statechart.allStates.filter[
					it.reachableStates.contains(coldViolation) && !it.reachableStates.contains(hotViolation)]
			for (coldModalityState : coldModalityStates) {
				val outgoingTransitions = coldModalityState.outgoingTransitions
				val previousMaxPriority = outgoingTransitions.map[it.priority].max
				outgoingTransitions.filter[it.priority == previousMaxPriority]
						.forEach[it.priority = it.priority.add(BigInteger.ONE)]
				
				val clonedFirstStateStartTransitions = firstStateStartTransitions.clone
				for (clonedFirstStateStartTransition : clonedFirstStateStartTransitions) {
					clonedFirstStateStartTransition.sourceState = coldModalityState
					clonedFirstStateStartTransition.priority = previousMaxPriority
					
					statechart.transitions += clonedFirstStateStartTransition
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

		firstState = null
		if (scenario.initialBlock === null) {
			firstState = createNewState
		}
		else {
			firstState = createState
			firstState.name = firstStateName
		}
		firstRegion.stateNodes += firstState
		previousState = firstState

		if (restartOnColdViolation) {
			coldViolation = firstState
		}
		else {
			coldViolation = createNewState(scenarioStatechartUtil.coldViolation)
			firstRegion.stateNodes += coldViolation
		}
		componentViolation = createNewState(scenarioStatechartUtil.hotComponentViolation)
		environmentViolation = createNewState(scenarioStatechartUtil.hotEnvironmentViolation)
		firstRegion.stateNodes += componentViolation
		firstRegion.stateNodes += environmentViolation
		statechartUtil.createTransition(initial, firstState)
		statechart.variableDeclarations += scenario.variableDeclarations
		if (scenario.initialBlock !== null) {
			statechart.annotations += createHasInitialOutputsBlockAnnotation
			val syncBlock = createDeterministicOccurrenceSet
			syncBlock.deterministicOccurrences += scenario.initialBlock.interactions
			scenario.fragment.interactions.add(0, syncBlock)
		}
	}
	
	///
	def dispatch void process(DeterministicOccurrenceSet interactionSet) {
		processDeterministicOccurrenceSet(interactionSet, false)
	}

	def dispatch void process(Delay delay) {
		throw new UnsupportedOperationException("Single delays are placed into a set in a previous step")
	}

	def dispatch void process(NegatedDeterministicOccurrence negatedModalInteraction) {
		val modalInteraction = negatedModalInteraction.deterministicOccurrence
		if (modalInteraction instanceof DeterministicOccurrenceSet) {
			processDeterministicOccurrenceSet(modalInteraction, true)
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
		
		val mergeState = createNewState(mergeName + exsistingMerges++)
		firstRegion.stateNodes += mergeState
		previousState = mergeState
		for (transition : statechart.transitions) {
			if (ends.contains(transition.targetState)) {
				replacedStateWithValue.put(transition.targetState, previousState)
			}
		}
//		firstRegion.stateNodes -= ends
	}

	def dispatch void process(LoopCombinedFragment loop) {
		throw new UnsupportedOperationException
	}

	def dispatch void process(OptionalCombinedFragment optionalCombinedFragment) {
		val prevprev = previousState
		val firstFragment = optionalCombinedFragment.fragments.get(0)
		for (interaction : firstFragment.interactions) {
			process(interaction)
		}
		copyOutgoingTransitionsForOptional.add(prevprev -> previousState)
	}
	///

	def void processDeterministicOccurrenceSet(DeterministicOccurrenceSet set, boolean isNegated) {
		val state = createNewState
		if (scenario.initialBlock !== null && restartOnColdViolation &&
				set.eContainer == scenario.fragment && scenario.fragment.interactions.indexOf(set) == 0) {
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
		}
		else {
			if (isSend) {
				violationState = componentViolation
			}
			else {
				violationState = environmentViolation
			}
		}
		val violationTransition = statechartUtil.createTransition(previousState, violationState)
		if (set.deterministicOccurrences.empty) {
			val transition = statechartUtil.createTransition(previousState, state)
			transition.trigger = createOnCycleTrigger
			transition.guard = createTrueExpression
			firstRegion.stateNodes += state
			previousState = state
			return
		}
		
		handleDelays(set, forwardTransition, violationTransition)
		setupForwardTransition(set, isSend, isNegated, forwardTransition)

		forwardTransition.priority = BigInteger.valueOf(3)
		violationTransition.priority = BigInteger.valueOf(1)
		handleArguments(set.deterministicOccurrences, forwardTransition)
		val triggersWithCorrectDir = getAllTriggersForDirection(statechart, isSend)
		violationTransition.setOrExtendTrigger(
				getBinaryTriggerFromTriggersIfPossible(triggersWithCorrectDir, BinaryType.OR), BinaryType.OR)
		var otherDirViolationState = if (isSend) {
				useColdViolationForEnvironmentViolation ? coldViolation : environmentViolation
			}
			else {
				useHotViolationForComponentViolation ? componentViolation : coldViolation
			}
		if (set.deterministicOccurrences.size == 1 && set.deterministicOccurrences.head instanceof Delay) {
			otherDirViolationState = componentViolation
		}
		val violationForOtherDirection = statechartUtil.createTransition(previousState, otherDirViolationState)
		violationForOtherDirection.priority = BigInteger.ZERO
		val triggersWithReverseDir = getAllTriggersForDirection(statechart, !isSend)
		violationForOtherDirection.trigger = getBinaryTriggerFromTriggersIfPossible(triggersWithReverseDir, BinaryType.OR)

		val signals = set.deterministicOccurrences.filter(Interaction).toList
		val otherTriggersWithCorrectDir = <Trigger>newArrayList
		for (trigger : getAllTriggersForDirection(statechart, isSend)) {
			if (trigger instanceof EventTrigger) {
				val eventRef = trigger.eventReference
				if (eventRef instanceof PortEventReference) {
					if (!signals.exists[
							(it.getPort.name == eventRef.port.name || it.getPort.turnedOutPortName == eventRef.port.name) &&
								it.getEvent.name == eventRef.event.name]) {
						otherTriggersWithCorrectDir += trigger
					}
				}
			}
		}
		
		if (otherTriggersWithCorrectDir.size > 0) {
			val othersNegated = getBinaryTriggerFromTriggersIfPossible(otherTriggersWithCorrectDir, BinaryType.OR).
				negateTrigger
			if (forwardTransition.trigger instanceof OnCycleTrigger) {
				forwardTransition.trigger = othersNegated
			}
			else {
				val binary = createBinaryTrigger
				binary.leftOperand = forwardTransition.trigger
				binary.rightOperand = othersNegated
				forwardTransition.trigger = binary
				binary.type = BinaryType.AND
			}
		}
		previousState = state
	}
}
