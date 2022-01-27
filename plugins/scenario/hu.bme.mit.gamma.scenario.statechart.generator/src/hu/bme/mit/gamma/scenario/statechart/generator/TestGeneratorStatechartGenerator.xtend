/********************************************************************************
 * Copyright (c) 2020-2021 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.statechart.generator

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.scenario.model.AlternativeCombinedFragment
import hu.bme.mit.gamma.scenario.model.Delay
import hu.bme.mit.gamma.scenario.model.Interaction
import hu.bme.mit.gamma.scenario.model.InteractionDefinition
import hu.bme.mit.gamma.scenario.model.InteractionDirection
import hu.bme.mit.gamma.scenario.model.LoopCombinedFragment
import hu.bme.mit.gamma.scenario.model.ModalInteractionSet
import hu.bme.mit.gamma.scenario.model.ModalityType
import hu.bme.mit.gamma.scenario.model.NegPermissiveAnnotation
import hu.bme.mit.gamma.scenario.model.NegStrictAnnotation
import hu.bme.mit.gamma.scenario.model.NegatedModalInteraction
import hu.bme.mit.gamma.scenario.model.NegatedWaitAnnotation
import hu.bme.mit.gamma.scenario.model.OptionalCombinedFragment
import hu.bme.mit.gamma.scenario.model.PermissiveAnnotation
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition
import hu.bme.mit.gamma.scenario.model.Signal
import hu.bme.mit.gamma.scenario.model.StrictAnnotation
import hu.bme.mit.gamma.scenario.model.WaitAnnotation
import hu.bme.mit.gamma.scenario.model.derivedfeatures.ScenarioModelDerivedFeatures
import hu.bme.mit.gamma.statechart.contract.NotDefinedEventMode
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.interface_.Trigger
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority
import java.math.BigInteger
import java.util.HashMap
import org.eclipse.emf.common.util.EList

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

enum StatechartGenerationMode {
	GENERATE_MERGE_STATE,
	GENERATE_ORIGINAL_STRUCTURE,
	GENERATE_ONLY_FORWARD,
	GENERATE_DUPLICATED_CHOICES
}

class TestGeneratorStatechartGenerator extends AbstractContractStatechartGeneration {

	var allowedGlobalWaitMax = 0
	var allowedGlobalWaitMin = 0
	var allowedGlobalWaitNegMax = 0
	var StateNode previousState = null
	var State hotViolation = null
	var State coldViolation = null
	var NotDefinedEventMode nonDeclaredMessageMode = NotDefinedEventMode.PERMISSIVE
	var NotDefinedEventMode nonDeclaredNegMessageMode = NotDefinedEventMode.STRICT
	var coldViolationExisits = true
	val StatechartGenerationMode generationMode
	val replacedStateWithValue = new HashMap<StateNode,StateNode>()

	new(ScenarioDefinition scenario, Component component, StatechartGenerationMode mode, boolean dedicatedColdViolation) {
		this.component = component
		this.generationMode = mode
		this.scenario = scenario
		this.coldViolationExisits = dedicatedColdViolation
	}

	new(ScenarioDefinition scenario, Component component) {
		this(scenario, component, StatechartGenerationMode.GENERATE_ONLY_FORWARD, true)
	}

	def StatechartDefinition execute() {
		statechart = createStatechartDefinition
		for (annotation : scenario.annotation) {
			if (annotation instanceof WaitAnnotation) {
				allowedGlobalWaitMax = annotation.maximum.evaluateInteger
				allowedGlobalWaitMin = (annotation as WaitAnnotation).minimum.evaluateInteger
			} else if (annotation instanceof StrictAnnotation) {
				nonDeclaredMessageMode = NotDefinedEventMode.STRICT
			} else if (annotation instanceof PermissiveAnnotation) {
				nonDeclaredMessageMode = NotDefinedEventMode.PERMISSIVE
			} else if (annotation instanceof NegatedWaitAnnotation) {
				allowedGlobalWaitNegMax = annotation.maximum.evaluateInteger
			} else if (annotation instanceof NegStrictAnnotation) {
				nonDeclaredNegMessageMode = NotDefinedEventMode.STRICT
			} else if (annotation instanceof NegPermissiveAnnotation) {
				nonDeclaredNegMessageMode = NotDefinedEventMode.PERMISSIVE
			}
		}
		
		initializeStateChart(scenario.name)

		for (modalInteraction : scenario.chart.fragment.interactions) {
			process(modalInteraction)
		}

		var remove = <StateNode>newArrayList
		for (stateNode : statechart.regions.get(0).stateNodes) {
			if (stateNode.incomingTransitions.isEmpty &&
					stateNode.name != scenarioStatechartUtil.initial)
				remove += stateNode
		}
		statechart.regions.get(0).stateNodes -= remove
		val lastState = statechart.regions.get(0).stateNodes.get(
				statechart.regions.get(0).stateNodes.size - 1)
		lastState.name = scenarioStatechartUtil.accepting

		for (transition : statechart.transitions) {
			if (transition.getTargetState == coldViolation) {
				transition.effects += setIntVariable(
					variableMap.getOrCreate(scenarioStatechartUtil.result), 1)
			} else if (transition.targetState == hotViolation) {
				transition.effects += setIntVariable(
					variableMap.getOrCreate(scenarioStatechartUtil.result), 0)
			} else if (transition.targetState == lastState) {
				transition.effects += setIntVariable(
					variableMap.getOrCreate(scenarioStatechartUtil.result), 2)
			}
		}
		
		val newMergeStates = newArrayList
		val states = statechart.regions.get(0).stateNodes
		for (stateNode : states) {
			if (stateNode instanceof ChoiceState &&	stateNode.incomingTransitions.size > 1){
				val choice = stateNode as ChoiceState
				val merge = createMergeState
				merge.name = "merge" + stateCount++
				for (transition : choice.incomingTransitions) {
					transition.targetState = merge
				}
				val mergeTransition = createTransition
				mergeTransition.sourceState = merge
				mergeTransition.targetState = choice
				statechart.transitions += mergeTransition
				newMergeStates += merge
			}
		}
		states += newMergeStates

		val annotation = createScenarioContractAnnotation
		annotation.monitoredComponent = component
		annotation.scenarioType = nonDeclaredMessageMode
		statechart.annotations += annotation
		
		val waitingAnnotation= createScenarioAllowedWaitAnnotation
		waitingAnnotation.lowerLimit = allowedGlobalWaitMin.toIntegerLiteral
		waitingAnnotation.upperLimit = allowedGlobalWaitMax.toIntegerLiteral
		statechart.annotations += waitingAnnotation
		return statechart
	}
	
	def protected initializeStateChart(String scenarioName) {
		addPorts(component)
		statechart.transitionPriority = TransitionPriority.VALUE_BASED
		statechart.name = scenarioName
		var region = createRegion
		region.name = "region"
		statechart.regions+=region		

		var initial = createInitialState
		initial.name = scenarioStatechartUtil.initial
		region.stateNodes+=initial

		var s = createState
		s.name = "firstState"
		region.stateNodes+=s
		previousState = s
		
		var tmp = createNewState(scenarioStatechartUtil.hotViolation)
		region.stateNodes+=tmp
		hotViolation = tmp;
		if (coldViolationExisits) {
			tmp = createNewState(scenarioStatechartUtil.coldViolation)
			region.stateNodes+=tmp
			coldViolation = tmp
		} else {
			coldViolation = s
		}
		
		val initBlock = scenario.initialblock
		if (initBlock === null){
			var t = createTransition
			setupTransition(t, initial, s, null, null, null)
			t.effects += setIntVariable(variableMap.getOrCreate(scenarioStatechartUtil.iteratingVariable), 1)
			t.effects += setIntVariable(variableMap.getOrCreate(scenarioStatechartUtil.getLoopvariableNameForDepth(0)), 1)
			statechart.transitions+=t
		} 
		else {
			val initChoice = addChoiceState
			region.stateNodes += initChoice
			var t1 = createTransition
			setupTransition(t1, initial, initChoice, null, null, null)
			statechart.transitions+=t1
			var t2 = createTransition
			setupTransition(t2, initChoice, s, null, null, null)
			for (interaction : initBlock.modalInteractions){
				var a = getRaiseEventAction(interaction, false)
				if (a !== null){
					t2.effects += a
				}
			}
			t2.effects += setIntVariable(variableMap.getOrCreate(scenarioStatechartUtil.getLoopvariableNameForDepth(0)), 1)
			statechart.transitions+=t2
			
			var t3 = createTransition
			val violation = (initBlock.modalInteractions.get(0).modality == ModalityType.HOT) ? hotViolation : coldViolation
			setupTransition(t3, initChoice, violation, null, createElseExpression, null)
			statechart.transitions+=t3
		}
	}

	def protected addPorts(Component c) {
		for (port : c.ports) {
			var pcopy = createPort
			var iReali = createInterfaceRealization
			iReali.realizationMode = port.interfaceRealization.realizationMode
			iReali.interface = port.interfaceRealization.interface
			pcopy.interfaceRealization = iReali
			pcopy.name = port.name
			statechart.ports+=pcopy
			var preverse = createPort
			preverse.name = scenarioStatechartUtil.getTurnedOutPortName(port)
			var iRealiR = createInterfaceRealization
			iRealiR.interface = port.interfaceRealization.interface
			iRealiR.realizationMode = port.interfaceRealization.realizationMode.opposite
			preverse.interfaceRealization = iRealiR
			statechart.ports+=preverse
		}
	}

	def dispatch void process(ModalInteractionSet interactionSet) {
		processModalInteractionSet(interactionSet, false)
	}

	def dispatch void process(Delay delay) {
		var newState = createNewState()
		var transition = createTransition
		transition.sourceState = previousState
		transition.targetState = newState
		var timeoutDecl = createTimeoutDeclaration
		timeoutDecl.name = "delay" + timeoutCount++
		statechart.timeoutDeclarations += timeoutDecl
		var timeSpecification = createTimeSpecification
		timeSpecification.unit = TimeUnit.MILLISECOND
		timeSpecification.value = delay.minimum.clone
		var timeoutAction = createSetTimeoutAction
		timeoutAction.timeoutDeclaration = timeoutDecl
		timeoutAction.time = timeSpecification
		if (previousState instanceof State) {
			previousState.entryActions += timeoutAction
		}
		var eventTrigger = createEventTrigger
		var eventRef = createTimeoutEventReference
		eventRef.timeout = timeoutDecl
		transition.trigger = eventTrigger
		eventTrigger.eventReference = eventRef
		var violationTransition = createTransition
		violationTransition.sourceState = previousState
		if (delay.modality == ModalityType.COLD) {
			violationTransition.targetState = coldViolation
		} else {
			violationTransition.targetState = hotViolation
		}
		var violationTrigger = createEventTrigger
		var violationRventRef = createTimeoutEventReference
		violationRventRef.setTimeout(timeoutDecl)
		violationTrigger.eventReference = violationRventRef
		violationTransition.trigger = negateEventTrigger(violationTrigger)

		previousState = newState
		statechart.transitions += transition
		statechart.transitions += violationTransition
		statechart.regions.get(0).stateNodes += newState
	}

	def dispatch void process(NegatedModalInteraction negatedModalInteraction) {
		val modalInteraction = negatedModalInteraction.modalinteraction
		if (modalInteraction instanceof ModalInteractionSet) {
			processModalInteractionSet(modalInteraction, true)
		}
	}

	def dispatch void process(AlternativeCombinedFragment a) {
		var ends = newArrayList
		var choice = addChoiceState
		for (transition : previousState.incomingTransitions) {
			transition.targetState = choice
		}
		replacedStateWithValue.put(previousState,choice)
		statechart.regions.get(0).stateNodes -= previousState
		statechart.regions.get(0).stateNodes += choice
		var n = stateCount++
		for (i : 0 ..< a.fragments.size) {
			var state = createNewState("state" + String.valueOf(n) + "_" + String.valueOf(i))
			previousState = state
			statechart.regions.get(0).stateNodes+=state
			var t = createTransition
			t.sourceState = choice
			t.targetState = state
			statechart.transitions+=t
			for (interaction : a.fragments.get(i).interactions) {
				process(interaction)
			}
			ends+=previousState
			stateCount--
		}
		var merg = createState
		for (transition : statechart.transitions) {
			if (ends.contains(transition.targetState)) {
				transition.targetState = merg
			}
		}
		statechart.regions.get(0).stateNodes-=ends
		merg.name = "merge" + String.valueOf(exsistingMerges++)
		statechart.regions.get(0).stateNodes+=merg
		previousState = merg
	}
 
	def dispatch void process(LoopCombinedFragment loop) {
		val loopDepth = scenarioStatechartUtil.getLoopDepth(loop)
		var prevprev = previousState
		for (interaction : loop.fragments.get(0).interactions) {
			interaction.process
		}
		if (replacedStateWithValue.containsKey(prevprev)){
			prevprev = replacedStateWithValue-=prevprev
		}
		var choice = addChoiceState
		for (transition : previousState.incomingTransitions) {
			transition.targetState = choice
		}

		replacedStateWithValue.put(previousState,choice)
		statechart.regions.get(0).stateNodes-=previousState
		statechart.regions.get(0).stateNodes+=choice
		var stateNew = createNewState()
		previousState = stateNew
		statechart.regions.get(0).stateNodes+=stateNew
		var t1 = createTransition
		var t2 = createTransition
		t1.sourceState = choice
		t2.sourceState = choice
		t1.targetState = stateNew
		t2.targetState = prevprev
		statechart.transitions+=t1
		statechart.transitions+=t2

		val variableForDepth = variableMap.getOrCreate(scenarioStatechartUtil.getLoopvariableNameForDepth(loopDepth))
		t1.guard = getVariableGreaterEqualParamExpression(variableForDepth, exprEval.evaluateInteger(loop.minimum))
		var maxCheck = createLessExpression
		maxCheck.leftOperand = exprUtil.createReferenceExpression(variableForDepth)
		maxCheck.rightOperand = exprUtil.toIntegerLiteral(exprEval.evaluateInteger(loop.maximum))
		t2.guard = maxCheck
		t2.effects += incrementVar(variableForDepth)
		t1.effects += setIntVariable(variableForDepth, 1)
	}

	def dispatch void process(OptionalCombinedFragment ocf) {
		var choice = addChoiceState
		for (transition : statechart.transitions) {
			if (transition.targetState.equals(previousState))
				transition.targetState = choice
		}
		replacedStateWithValue.put(previousState,choice)
		statechart.regions.get(0).stateNodes-=previousState
		statechart.regions.get(0).stateNodes+=choice
		var stateNew = createNewState()
		previousState = stateNew
		statechart.regions.get(0).stateNodes+=stateNew
		for (interaction : ocf.fragments.get(0).interactions) {
			process(interaction)
		}
		var t1 = createTransition
		var t2 = createTransition
		t1.sourceState = choice
		t2.sourceState = choice
		t1.targetState = stateNew
		t2.targetState = previousState
		statechart.transitions+=t1
		statechart.transitions+=t2
	}

	def processModalInteractionSet(ModalInteractionSet set, boolean isNegated) {
		var state = createNewState()
		var forwardTransition = createTransition
		var violationTransition = createTransition
		var cycleTransition = createTransition
		cycleTransition.trigger = createOnCycleTrigger
		var backwardTransition = createTransition
		cycleTransition.sourceState = previousState
		var newChoice = addChoiceState
		cycleTransition.targetState = newChoice
		forwardTransition.sourceState = newChoice
		forwardTransition.targetState = state
		violationTransition.guard = createElseExpression

		if (set.modalInteractions.empty) {
			var t = createTransition
			setupTransition(t, previousState, state, createOnCycleTrigger, createTrueExpression, null)
			statechart.transitions += t
			statechart.regions.get(0).stateNodes += state
			previousState = state
			return
		}
		var dir = ScenarioModelDerivedFeatures.getDirection(set)
		var mod = ScenarioModelDerivedFeatures.getModality(set)
		violationTransition.sourceState = newChoice
		violationTransition.targetState = (mod == ModalityType.COLD) ? coldViolation : hotViolation
		
		handleDelays(set)
		setupForwardTransition(set, dir.equals(InteractionDirection.SEND), isNegated, forwardTransition)
		
		if (nonDeclaredMessageMode == NotDefinedEventMode.STRICT) {
				var binary = createBinaryTrigger
				binary.leftOperand = forwardTransition.trigger
				binary.rightOperand = getBinaryTriggerFromTriggers(createOtherNegatedTriggers(set), BinaryType.AND)
				binary.type = BinaryType.AND
				forwardTransition.trigger = binary
		}
		
		if (dir.equals(InteractionDirection.SEND)) {
			handleSends(set, isNegated, forwardTransition, backwardTransition, cycleTransition, violationTransition, newChoice)
		}
		
		handleArguments(set.modalInteractions, forwardTransition);
		handleSingleNegatedIfNeeded(set, forwardTransition, violationTransition)
		
		statechart.transitions+=forwardTransition
		statechart.transitions+=violationTransition
		statechart.transitions+=cycleTransition
		
		statechart.regions.get(0).stateNodes+=newChoice
		statechart.regions.get(0).stateNodes+=state
		previousState = state
		return
	}
	
	def handleSends(ModalInteractionSet set, boolean isNegated, Transition forwardTransition,
		Transition backwardTransition, Transition cycleTransition, Transition violationTransition, ChoiceState newChoice) {
		val iteratingVariable = variableMap.getOrCreate(scenarioStatechartUtil.iteratingVariable)
		
		forwardTransition.priority = BigInteger.valueOf(3)
		backwardTransition.priority = BigInteger.valueOf(2)
		violationTransition.priority = BigInteger.valueOf(1)
		backwardTransition.sourceState = newChoice
		backwardTransition.targetState = previousState
		backwardTransition.effects+=incrementVar(iteratingVariable)
		backwardTransition.guard = getVariableLessEqualParamExpression(iteratingVariable, allowedGlobalWaitMax)
		
		if (generationMode != StatechartGenerationMode.GENERATE_ONLY_FORWARD){
			forwardTransition.guard = getVariableInIntervalExpression(iteratingVariable, allowedGlobalWaitMin, allowedGlobalWaitMax)
			forwardTransition.effects+=setIntVariable(iteratingVariable, 0)			
		}
		
		var onlyNegated = ScenarioModelDerivedFeatures.isAllNeg(set) || isNegated
		var NotDefinedEventMode mode = (onlyNegated) ? nonDeclaredNegMessageMode : nonDeclaredMessageMode
		if (!onlyNegated || mode == NotDefinedEventMode.STRICT) {
			// does not need to be added for allneg and strict, as it is overshadowed by the forward going transition
			statechart.transitions+=backwardTransition
		}
		
		if (mode == NotDefinedEventMode.STRICT) {
			var BinaryTrigger tmp = getAllEvents(BinaryType.AND)
			negateBinaryTree(tmp)
			backwardTransition.trigger = tmp
		}

		if (onlyNegated) {
			forwardTransition.guard = null
			var maxCheck = createLessExpression
			maxCheck.leftOperand = exprUtil.createReferenceExpression(variableMap.getOrCreate(scenarioStatechartUtil.iteratingVariable))
			maxCheck.rightOperand = exprUtil.toIntegerLiteral(allowedGlobalWaitNegMax)
			backwardTransition.guard = maxCheck
		}

		switch (generationMode) {
			case GENERATE_MERGE_STATE: {
				val mergeState = createMergeState
				mergeState.name = "merge" + stateCount++
				for (transition : statechart.transitions) {
					if (transition.targetState == previousState && transition !== backwardTransition) {
						transition.targetState = mergeState
					}
				}
				val newTransition = createTransition
				newTransition.sourceState = mergeState
				newTransition.targetState = newChoice
				cycleTransition.targetState = mergeState
				statechart.transitions += newTransition
				statechart.regions.get(0).stateNodes += mergeState
			}
			case GENERATE_ONLY_FORWARD: {
				statechart.transitions-=backwardTransition
			}
			case GENERATE_DUPLICATED_CHOICES: {
				for (transition : previousState.incomingTransitions) {
					if (transition.sourceState !== newChoice) {
						val tmpChoice2 = addChoiceState
						val forwardCopy = forwardTransition.clone
						val violationCopy = violationTransition.clone
						val t3Copy = backwardTransition.clone
						t3Copy.sourceState = tmpChoice2
						forwardCopy.sourceState = tmpChoice2
						violationCopy.sourceState = tmpChoice2
						transition.targetState = tmpChoice2
						statechart.regions.get(0).stateNodes += tmpChoice2
						statechart.transitions += t3Copy
						statechart.transitions += forwardCopy
						statechart.transitions += violationCopy
					}
				}
			}
			case GENERATE_ORIGINAL_STRUCTURE: {
				// does not need to be changed
			}
			default: {
				throw new IllegalArgumentException("Unhandled generation mode.")
			}
		}
	}
	
	def handleSingleNegatedIfNeeded(ModalInteractionSet set, Transition forwardTransition, Transition violationTransition) {
		var singleNegetedSignalWithArguments = false
		if (set.modalInteractions.size == 1 && set.modalInteractions.get(0) instanceof NegatedModalInteraction) {
			val negatedModalInteraction = set.modalInteractions.get(0) as NegatedModalInteraction
			if (negatedModalInteraction.modalinteraction instanceof Signal) {
				val negatedSignal = negatedModalInteraction.modalinteraction as Signal
				singleNegetedSignalWithArguments = !(negatedSignal.arguments.empty)
			}
		}
		if (singleNegetedSignalWithArguments) {
			var signal = (set.modalInteractions.get(0) as NegatedModalInteraction).modalinteraction as Signal
			if (!signal.arguments.empty) {
				var tmp = violationTransition.targetState
				violationTransition.targetState = forwardTransition.targetState
				forwardTransition.targetState = tmp
				forwardTransition.trigger = negateEventTrigger(forwardTransition.trigger)

			}
		}
	}

	def setupForwardTransition(ModalInteractionSet set, boolean reversed,
			boolean isNegated, Transition forwardTransition) {
		var Trigger t = null
		if (set.modalInteractions.size > 1) {
			t = getBinaryTrigger(set.modalInteractions, BinaryType.AND, reversed)
		} else {
			t = getEventTrigger(set.modalInteractions.get(0), reversed)
		}
		
		
		if (isNegated) {
			forwardTransition.trigger = negateEventTrigger(t)
		} else {
			forwardTransition.trigger = t
			for (modalInteraction : set.modalInteractions) {
				var a = getRaiseEventAction(modalInteraction, !reversed)
				if (a !== null) {
					forwardTransition.effects+=a
				}
			}
		}
	}

	def handleDelays(ModalInteractionSet set) {
		var delays = set.modalInteractions.filter(Delay)
		if (!delays.empty) {
			var delay = delays.get(0) as Delay
			var timeoutDeclaration = createTimeoutDeclaration
			timeoutDeclaration.name = "delay" + timeoutCount++
			statechart.timeoutDeclarations += timeoutDeclaration
			var timeSpecification = createTimeSpecification
			timeSpecification.unit = TimeUnit.MILLISECOND
			timeSpecification.value = delay.minimum.clone
			var a = createSetTimeoutAction
			a.timeoutDeclaration = timeoutDeclaration
			a.time = timeSpecification
			if (previousState instanceof State) {
				previousState.entryActions += a
			}
		}
	}

	def handleArguments(EList<InteractionDefinition> set, Transition t1) {
		var signals = set.filter[it instanceof Signal].filter[!(it as Signal).arguments.empty]
		if (signals.empty) {
			if (set.size == 1 && set.get(0) instanceof NegatedModalInteraction){
				val interaction = set.get(0) as NegatedModalInteraction
				if (interaction.modalinteraction instanceof Signal){
					val signal = interaction.modalinteraction as Signal
					if (!signal.arguments.empty){
						signals = newArrayList(signal)
					}
				}
			}
		}
		if (signals.empty) {
			return
		}
		var guard1 = createAndExpression
		for (signal : signals) {
			var tmp = signal as Signal
			var i = 0
			var String portName = tmp.port.name
			if (tmp.direction.equals(InteractionDirection.SEND)) {
				if (!scenarioStatechartUtil.isTurnedOut(tmp.port)) {
					portName = scenarioStatechartUtil.getTurnedOutPortName(tmp.port)
				}
			}
			var port = getPort(portName)
			var event = getEvent(tmp.event.name, port)
			for (paramDec : event.parameterDeclarations) {
				var equal = createEqualityExpression
				var paramRef = createEventParameterReferenceExpression
				paramRef.parameter = paramDec
				paramRef.port = port
				paramRef.event = event
				equal.leftOperand = paramRef
				equal.rightOperand = tmp.arguments.get(i).clone
				guard1.operands+=equal
				i++
			}
		}
		var Expression expr = null
		if (guard1.operands.size == 1) {
			expr = guard1.operands.get(0)
		} else {
			expr = guard1
		}
		var guard = t1.guard
		if (guard === null) {
			t1.guard = expr
		} else {
			var and = createAndExpression
			and.operands+=expr
			and.operands+=guard
			t1.guard = and
		}
	}

}