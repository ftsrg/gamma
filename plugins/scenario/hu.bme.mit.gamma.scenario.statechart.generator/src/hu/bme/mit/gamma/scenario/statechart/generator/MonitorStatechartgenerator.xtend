package hu.bme.mit.gamma.scenario.statechart.generator

import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment
import hu.bme.mit.gamma.scenario.model.Delay
import hu.bme.mit.gamma.scenario.model.InteractionDirection
import hu.bme.mit.gamma.scenario.model.InteractionFragment
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet
import hu.bme.mit.gamma.scenario.model.ModalityType
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction
import hu.bme.mit.gamma.scenario.model.OptionalCombinedFragment
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition
import hu.bme.mit.gamma.statechart.contract.NotDefinedEventMode
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.interface_.Trigger
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger
import java.math.BigInteger
import java.util.List

import static extension hu.bme.mit.gamma.scenario.model.derivedfeatures.ScenarioModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class MonitorStatechartgenerator extends AbstractContractStatechartGeneration {

	protected boolean skipNextInteraction = false
	protected State componentViolation = null
	protected State environmentViolation = null
	protected List<Pair<StateNode, StateNode>> copyOutgoingTransitionsForOpt = newLinkedList
	protected boolean restartOnColdViolation = false

	new(ScenarioDefinition scenario, Component component, boolean restartOnColdViolation) {
		super(scenario, component)
		this.restartOnColdViolation = restartOnColdViolation
	}

	override execute() {
		statechart = createSynchronousStatechartDefinition
		intializeStatechart()
		for (modalInteraction : scenario.chart.fragment.interactions) {
			if (!skipNextInteraction) {
				process(modalInteraction)
			} else {
				skipNextInteraction = false;
			}
		}
		firstRegion.stateNodes.get(firstRegion.stateNodes.size - 1).name = scenarioStatechartUtil.accepting
		fixReplacedStates()
		copyTransitionsForOpt()
		addScenarioContractAnnotation(NotDefinedEventMode.PERMISSIVE)
		return statechart
	}

	def fixReplacedStates() {
		for (entry : replacedStateWithValue.entrySet) {
			for (transition : statechart.transitions.filter[it.sourceState == entry.key]) {
				transition.sourceState = entry.value
			}
			for (transition : statechart.transitions.filter[it.targetState == entry.key]) {
				transition.targetState = entry.value
			}
		}
	}

	def void copyTransitionsForOpt() {
		for (pair : copyOutgoingTransitionsForOpt) {
			val compulsory = replacedStateWithValue.getOrDefault(pair.key, pair.key)
			val optional = pair.value
			for (transition : compulsory.outgoingTransitions) {
				if (transition.targetState != optional && !transition.targetState.reachableStates.contains(optional)) {
					val tCopy = transition.clone
					tCopy.sourceState = optional
					statechart.transitions += tCopy
					if (optional.name.contains(accepting)) {
						compulsory.name = compulsory.name.getCombinedStateAcceptingName
					}
				}
			}
		}
	}

	def protected intializeStatechart() {
		addPorts(component)
		statechart.transitionPriority = TransitionPriority.VALUE_BASED
		statechart.name = scenario.name
		firstRegion = createRegion
		firstRegion.name = firstRegionName
		statechart.regions += firstRegion

		val initial = createInitialState
		initial.name = scenarioStatechartUtil.initial
		firstRegion.stateNodes += initial

		val firstState = createState
		firstState.name = firstStateName
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

		if (scenario.initialblock !== null) {
			statechart.annotations += createHasInitialOutputsBlockAnnotation
			val syncBlock = createModalInteractionSet
			syncBlock.modalInteractions += scenario.initialblock.modalInteractions
			scenario.chart.fragment.interactions.add(0, syncBlock)
		}
	}

	def dispatch void process(ModalInteractionSet interactionSet) {
		processModalInteractionSet(interactionSet, false)
	}

	def dispatch void process(Delay delay) {
		val newState = createNewState()
		firstRegion.stateNodes += newState
		val transition = statechartUtil.createTransition(previousState, newState)
		val timeoutDecl = createTimeoutDeclaration
		timeoutDecl.name = "delay" + timeoutCount++
		statechart.timeoutDeclarations += timeoutDecl
		val timeSpecification = createTimeSpecification
		timeSpecification.unit = TimeUnit.MILLISECOND
		timeSpecification.value = delay.minimum.clone
		val timeoutAction = createSetTimeoutAction
		timeoutAction.timeoutDeclaration = timeoutDecl
		timeoutAction.time = timeSpecification
		if (previousState instanceof State) {
			previousState.entryActions += timeoutAction
		}
		val eventTrigger = createEventTrigger
		val eventRef = createTimeoutEventReference
		eventRef.timeout = timeoutDecl
		transition.trigger = eventTrigger
		eventTrigger.eventReference = eventRef
		var StateNode violationState
		if (delay.modality == ModalityType.COLD) {
			violationState = coldViolation
		} else {
			violationState = componentViolation
		}
		val violationTransition = statechartUtil.createTransition(previousState, violationState)
		val violationTrigger = createEventTrigger
		val violationRventRef = createTimeoutEventReference
		violationRventRef.setTimeout(timeoutDecl)
		violationTrigger.eventReference = violationRventRef
		violationTransition.trigger = negateEventTrigger(violationTrigger)
		previousState = newState
	}

	def dispatch void process(NegatedModalInteraction negatedModalInteraction) {
		val modalInteraction = negatedModalInteraction.modalinteraction
		if (modalInteraction instanceof ModalInteractionSet) {
			processModalInteractionSet(modalInteraction, true)
		}
	}

	def dispatch void process(AlternativeCombinedFragment a) {
		val ends = newArrayList
		val prevprev = previousState
		for (i : 0 ..< a.fragments.size) {
			previousState = prevprev
			for (interaction : a.fragments.get(i).interactions) {
				process(interaction)
			}
			ends += previousState
		}
		val mergeState = createNewState(mergeName + exsistingMerges)
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
		val containingFragment = ecoreUtil.getContainerOfType(optionalCombinedFragment, InteractionFragment);
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
			copyOutgoingTransitionsForOpt.add(new Pair(prevprev, previousState))
			previousState = prevprev
		}
	}

	def processModalInteractionSet(ModalInteractionSet set, boolean isNegated) {
		val state = createNewState
		firstRegion.stateNodes += state
		val dir = set.direction
		val mod = set.modality
		val isSend = dir.equals(InteractionDirection.SEND)
		val forwardTransition = statechartUtil.createTransition(previousState, state)
		var StateNode violationState = null
		if (mod == ModalityType.COLD) {
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
			val t = statechartUtil.createTransition(previousState, state)
			t.trigger = createOnCycleTrigger
			t.guard = createTrueExpression
			firstRegion.stateNodes += state
			previousState = state
			return
		}
		handleDelays(set)
		setupForwardTransition(set, isSend, isNegated, forwardTransition)

		forwardTransition.priority = BigInteger.valueOf(3)
		violationTransition.priority = BigInteger.valueOf(1)
		handleArguments(set.modalInteractions, forwardTransition);
		val eventRefs = createOtherNegatedTriggers(set).filter(UnaryTrigger).map[it.operand].filter(EventTrigger).map [
			it.eventReference
		]
		val triggersWithCorrectDir = <Trigger>newArrayList
		for (eventRef : eventRefs) {
			var Port port = null
			if (eventRef instanceof PortEventReference) {
				port = eventRef.port
			} else if (eventRef instanceof AnyPortEventReference) {
				port = eventRef.port
			}
			if ((port.isTurnedOut && isSend) || (!port.isTurnedOut && !isSend)) {
				val trigger = createEventTrigger
				trigger.eventReference = eventRef
				triggersWithCorrectDir += trigger
			} 
		}
		if (triggersWithCorrectDir.size > 1) {
			violationTransition.trigger = getBinaryTriggerFromTriggers(triggersWithCorrectDir, BinaryType.OR)
		} else if (triggersWithCorrectDir.size == 1) {
			violationTransition.trigger = triggersWithCorrectDir.head
		} else {
			violationTransition.trigger = createAnyTrigger
			violationTransition.guard = createFalseExpression
		}
		previousState = state
		return
	}
}
