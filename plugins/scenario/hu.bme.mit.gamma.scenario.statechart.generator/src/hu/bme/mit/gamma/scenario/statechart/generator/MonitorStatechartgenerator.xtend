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
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.interface_.Trigger
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority
import java.math.BigInteger

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class MonitorStatechartgenerator extends AbstractContractStatechartGeneration {
	
	protected boolean skipNextinteraction = false
	protected State componentViolation = null
	protected State environmentViolation = null

	new(ScenarioDefinition scenario, Component component) {
		super(scenario, component)
	}

	override execute() {
		statechart = createStatechartDefinition
		intializeStatechart()

		for (modalInteraction : scenario.chart.fragment.interactions) {
			if(!skipNextinteraction){
				process(modalInteraction)				
			} else {
				skipNextinteraction=false;
			}
		}
		
		firstRegion.stateNodes.get(firstRegion.stateNodes.size - 1).name = scenarioStatechartUtil.accepting
		
		addScenarioContractAnnotation(NotDefinedEventMode.PERMISSIVE)
		
		return statechart
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

		coldViolation = firstState
		componentViolation = createNewState(scenarioStatechartUtil.hotComponentViolation)
		environmentViolation = createNewState(scenarioStatechartUtil.hotEnvironmentViolation)
		firstRegion.stateNodes += componentViolation
		firstRegion.stateNodes += environmentViolation
		statechartUtil.createTransition(initial, firstState)
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
		if(delay.modality == ModalityType.COLD){
			violationState = coldViolation
		} else {
			violationState = componentViolation //TODO biztos?
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
		ends -= previousState
		for (transition : statechart.transitions) {
			if (ends.contains(transition.targetState)) {
				transition.targetState = previousState
			}
		}
		firstRegion.stateNodes -= ends
	}

	def dispatch void process(LoopCombinedFragment loop) {
//		val loopDepth = scenarioStatechartUtil.getLoopDepth(loop)
//		var prevprev = previousState
//		for (interaction : loop.fragments.get(0).interactions) {
//			interaction.process
//		}
//		if (replacedStateWithValue.containsKey(prevprev)) {
//			prevprev = replacedStateWithValue -= prevprev
//		}
//		val choice = createNewChoiceState
//		for (transition : previousState.incomingTransitions) {
//			transition.targetState = choice
//		}
//
//		replacedStateWithValue.put(previousState, choice)
//		firstRegion.stateNodes -= previousState
//		firstRegion.stateNodes += choice
//		val stateNew = createNewState()
//		previousState = stateNew
//		firstRegion.stateNodes += stateNew
//		val t1 = statechartUtil.createTransition(choice, stateNew)
//		val t2 = statechartUtil.createTransition(choice, prevprev)
//
//		val variableForDepth = variableMap.getOrCreate(scenarioStatechartUtil.getLoopvariableNameForDepth(loopDepth))
//		t1.guard = getVariableGreaterEqualParamExpression(variableForDepth, exprEval.evaluateInteger(loop.minimum))
//		val maxCheck = createLessExpression
//		maxCheck.leftOperand = exprUtil.createReferenceExpression(variableForDepth)
//		maxCheck.rightOperand = exprUtil.toIntegerLiteral(exprEval.evaluateInteger(loop.maximum))
//		t2.guard = maxCheck
//		t2.effects += incrementVar(variableForDepth)
//		t1.effects += setIntVariable(variableForDepth, 1)
	}

	def dispatch void process(OptionalCombinedFragment optionalCombinedFragment) {
		val containingFragment = ecoreUtil.getContainerOfType(optionalCombinedFragment, InteractionFragment);
		val index = containingFragment.interactions.indexOf(optionalCombinedFragment)
		val prevprev = previousState
		val firstFragment = optionalCombinedFragment.fragments.get(0)
		for (interaction : firstFragment.interactions) {
			process(interaction)
		}
		if(containingFragment.interactions.size > index+1){
			val nextInteraction = containingFragment.interactions.get(index+1)
			nextInteraction.process
			val previousAfterFirstProcess = previousState
			previousState = prevprev
			nextInteraction.process
			for(transition : previousState.incomingTransitions){
				transition.targetState = previousAfterFirstProcess
			}
			firstRegion.stateNodes -= previousState
			previousState = previousAfterFirstProcess
			skipNextinteraction = true
		} else {
			//TODO fix naive implementation, allows infinite occurences of the content of the optional
			for(transition : previousState.incomingTransitions){
				transition.targetState = prevprev
			}
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
		if(mod == ModalityType.COLD){
			violationState = coldViolation
		} else {
			if(isSend) {
				violationState = componentViolation
			} else {
				violationState = environmentViolation
			}
		}
//		val violationTransition = statechartUtil.createTransition(previousState, violationState)

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
//		violationTransition.priority = BigInteger.valueOf(1)
		handleArguments(set.modalInteractions, forwardTransition);
//		violationTransition.trigger = createAnyTrigger
		previousState = state
		return
	}
}
