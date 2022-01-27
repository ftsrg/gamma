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
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
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
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import java.math.BigInteger
import java.util.HashMap
import java.util.List
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
		statechart.regions.add(region)		

		var initial = createInitialState
		initial.name = scenarioStatechartUtil.initial
		region.stateNodes.add(initial)

		var s = createState
		s.name = "firstState"
		region.stateNodes.add(s)
		previousState = s
		
		var tmp = createNewState(scenarioStatechartUtil.hotViolation)
		region.stateNodes.add(tmp)
		hotViolation = tmp;
		if (coldViolationExisits) {
			tmp = createNewState(scenarioStatechartUtil.coldViolation)
			region.stateNodes.add(tmp)
			coldViolation = tmp
		} else {
			coldViolation = s
		}
		
		val initBlock = scenario.initialblock
		if (initBlock === null){
			var t = createTransition
			t.sourceState = initial
			t.targetState = s
			t.effects += setIntVariable(variableMap.getOrCreate(scenarioStatechartUtil.iteratingVariable), 1)
			t.effects += setIntVariable(variableMap.getOrCreate(scenarioStatechartUtil.getLoopvariableNameForDepth(0)), 1)
			statechart.transitions.add(t)
		} 
		else {
			val initChoice = addChoiceState
			region.stateNodes += initChoice
			var t1 = createTransition
			t1.sourceState = initial
			t1.targetState = initChoice
			statechart.transitions.add(t1)
			
			var t2 = createTransition
			t2.sourceState = initChoice
			t2.targetState = s
			for (interaction : initBlock.modalInteractions){
				var a = getRaiseEventAction(interaction, false)
				if (a !== null){
					t2.effects += a
				}
			}
			t2.effects += setIntVariable(variableMap.getOrCreate(scenarioStatechartUtil.getLoopvariableNameForDepth(0)), 1)
			statechart.transitions.add(t2)
			
			var t3 = createTransition
			t3.sourceState = initChoice
			t3.targetState = (initBlock.modalInteractions.get(0).modality == ModalityType.HOT) ? hotViolation : coldViolation
			t3.guard = createElseExpression
			statechart.transitions.add(t3)
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
			statechart.ports.add(pcopy)
			var preverse = createPort
			preverse.name = scenarioStatechartUtil.getTurnedOutPortName(port)
			var iRealiR = createInterfaceRealization
			iRealiR.interface = port.interfaceRealization.interface
			iRealiR.realizationMode = port.interfaceRealization.realizationMode.opposite
			preverse.interfaceRealization = iRealiR
			statechart.ports.add(preverse)
		}
	}

	def dispatch Interaction process(ModalInteractionSet interactionSet) {
		processModalInteractionSet(interactionSet, false)
		return null;
	}

	def dispatch Interaction process(Delay delay) {
		var state = createNewState("state" + String.valueOf(stateCount++))
		var t = createTransition
		t.sourceState = previousState
		t.targetState = state
		// TODO use more descriptive names
		var td = createTimeoutDeclaration
		td.name = "delay" + timeoutCount++
		statechart.timeoutDeclarations += td
		var ts = createTimeSpecification
		ts.unit = TimeUnit.MILLISECOND
		ts.value = delay.minimum.clone
		var a = createSetTimeoutAction
		a.timeoutDeclaration = td
		a.time = ts
		if (previousState instanceof State) {
			previousState.entryActions += a
		}
		var e = createEventTrigger
		var er = createTimeoutEventReference
		er.timeout = td
		t.trigger = e
		e.eventReference = er
		var t2 = createTransition
		t2.sourceState = previousState
		if (delay.modality == ModalityType.COLD) {
			t2.targetState = coldViolation
		} else {
			t2.targetState = hotViolation
		}
		var e2 = createEventTrigger
		var er2 = createTimeoutEventReference
		er2.setTimeout(td)
		e2.eventReference = er2
		t2.trigger = negateEventTrigger(e2)

		previousState = state
		statechart.transitions += t
		statechart.transitions += t2
		statechart.regions.get(0).stateNodes += state
		return null;
	}

	def dispatch Interaction process(NegatedModalInteraction negatedModalInteraction) {
		val modalInteraction = negatedModalInteraction.modalinteraction
		if (modalInteraction instanceof ModalInteractionSet) {
			processModalInteractionSet(modalInteraction, true)
			return null
		}
	}

	def dispatch Interaction process(AlternativeCombinedFragment a) {
		var ends = newArrayList
		var choice = addChoiceState
		for (transition : previousState.incomingTransitions) {
			transition.targetState = choice
		}
		replacedStateWithValue.put(previousState,choice)
		statechart.regions.get(0).stateNodes -= previousState
		statechart.regions.get(0).stateNodes += choice
		// TODO Use += and -= instead of add and remove
		var n = stateCount++
		for (i : 0 ..< a.fragments.size) {
			var state = createNewState("state" + String.valueOf(n) + "_" + String.valueOf(i))
			previousState = state
			statechart.regions.get(0).stateNodes.add(state)
			var t = createTransition
			t.sourceState = choice
			t.targetState = state
			statechart.transitions.add(t)
			for (interaction : a.fragments.get(i).interactions) {
				process(interaction)
			}
			ends.add(previousState)
			stateCount--
		}
		var merg = createState
		// TODO Use brackets
		for (transition : statechart.transitions)
			if (ends.contains(transition.targetState))
				transition.targetState = merg
		statechart.regions.get(0).stateNodes.removeAll(ends)

		merg.name = "merge" + String.valueOf(exsistingMerges++)
		statechart.regions.get(0).stateNodes.add(merg)
		previousState = merg
		return null
	}

	def dispatch Interaction process(LoopCombinedFragment loop) {
		val loopDepth = scenarioStatechartUtil.getLoopDepth(loop)

		var prevprev = previousState
		for (interaction : loop.fragments.get(0).interactions) {
			interaction.process
		}
		if (replacedStateWithValue.containsKey(prevprev)){
			prevprev = replacedStateWithValue.remove(prevprev)
		}
		var choice = addChoiceState
		for (transition : previousState.incomingTransitions) {
			transition.targetState = choice
		}

		replacedStateWithValue.put(previousState,choice)
		statechart.regions.get(0).stateNodes.remove(previousState)
		statechart.regions.get(0).stateNodes.add(choice)
		var stateNew = createNewState("state" + String.valueOf(stateCount++))
		previousState = stateNew
		statechart.regions.get(0).stateNodes.add(stateNew)
		var t1 = createTransition
		var t2 = createTransition
		t1.sourceState = choice
		t2.sourceState = choice
		t1.targetState = stateNew
		t2.targetState = prevprev
		statechart.transitions.add(t1)
		statechart.transitions.add(t2)

		val variableForDepth = variableMap.getOrCreate(
				scenarioStatechartUtil.getLoopvariableNameForDepth(loopDepth))
		val evaluator = ExpressionEvaluator.INSTANCE;
		t1.guard = getVariableGreaterEqualParamExpression(variableForDepth, evaluator.evaluateInteger(loop.minimum))
		var maxCheck = createLessExpression
		// TODO Use ExpressionUtil.createReference
		var ref1 = createDirectReferenceExpression
		ref1.declaration = variableForDepth
		maxCheck.leftOperand = ref1
		// TODO Use ExpressionUtil.toIntegerLiteral
		var max = createIntegerLiteralExpression
		max.value = BigInteger.valueOf(evaluator.evaluateInteger(loop.maximum))
		maxCheck.rightOperand = max
		t2.guard = maxCheck

		t2.effects += incrementVar(variableForDepth)
		t1.effects += setIntVariable(variableForDepth, 1)

		return null;

	}

	def dispatch Interaction process(OptionalCombinedFragment ocf) {
		var choice = addChoiceState
		for (transition : statechart.transitions) {
			if (transition.targetState.equals(previousState))
				transition.targetState = choice
		}
		replacedStateWithValue.put(previousState,choice)
		statechart.regions.get(0).stateNodes.remove(previousState)
		statechart.regions.get(0).stateNodes.add(choice)
		var stateNew = createNewState("state" + String.valueOf(stateCount++))
		previousState = stateNew
		statechart.regions.get(0).stateNodes.add(stateNew)
		for (interaction : ocf.fragments.get(0).interactions) {
			process(interaction)
		}
		var t1 = createTransition
		var t2 = createTransition
		t1.sourceState = choice
		t2.sourceState = choice
		t1.targetState = stateNew
		t2.targetState = previousState
		statechart.transitions.add(t1)
		statechart.transitions.add(t2)
		return null
	}

	def processModalInteractionSet(ModalInteractionSet set, boolean isNegated) {
		var singleNegetedSignalWithArguments = false
		if (set.modalInteractions.size == 1 && set.modalInteractions.get(0) instanceof NegatedModalInteraction) {
			val negatedModalInteraction = set.modalInteractions.get(0) as NegatedModalInteraction
			if (negatedModalInteraction.modalinteraction instanceof Signal) {
				val negatedSignal = negatedModalInteraction.modalinteraction as Signal
				singleNegetedSignalWithArguments = !(negatedSignal.arguments.empty)
			}
		}

		var state = createNewState("state" + String.valueOf(stateCount++))
		var forwardTransition = createTransition
		var violationTransition = createTransition
		var cycleTransition = createTransition
		cycleTransition.trigger = createOnCycleTrigger
		var t3 = createTransition
		cycleTransition.sourceState = previousState
		var tmpChoice = addChoiceState
		statechart.regions.get(0).stateNodes.add(tmpChoice)
		cycleTransition.targetState = tmpChoice
		forwardTransition.sourceState = tmpChoice
		forwardTransition.targetState = state
		violationTransition.guard = createElseExpression

		if (set.modalInteractions.empty) {
			var t = createTransition
			t.sourceState = previousState
			t.targetState = state
			t.trigger = createOnCycleTrigger
			t.guard = createTrueExpression
			statechart.transitions += t
			statechart.regions.get(0).stateNodes += state
			previousState = state
			return
		}

		var first = set.modalInteractions.get(0)
		var dir = InteractionDirection.RECEIVE
		var mod = ModalityType.COLD
		dir = ScenarioModelDerivedFeatures.getDirection(set)
		mod = ScenarioModelDerivedFeatures.getModality(set)

		violationTransition.sourceState = tmpChoice
		if (mod == ModalityType.COLD) {
			violationTransition.targetState = coldViolation
		} else {
			violationTransition.targetState = hotViolation
		}

		if (dir.equals(InteractionDirection.RECEIVE)) {
			handleDelays(set)
			setupForwardTransition(set, first, false, isNegated, forwardTransition)
			if (nonDeclaredMessageMode == NotDefinedEventMode.STRICT) {
				var binary = createBinaryTrigger
				binary.leftOperand = forwardTransition.trigger
				binary.rightOperand = getBinaryTriggerFromTriggers(createOtherNegatedTriggers(set), BinaryType.AND)
				binary.type = BinaryType.AND
				forwardTransition.trigger = binary
			}
		} else {
			handleDelays(set)
			setupForwardTransition(set, first, true, isNegated, forwardTransition)
			forwardTransition.priority = BigInteger.valueOf(3)
			val iteratingVariable = variableMap.getOrCreate(scenarioStatechartUtil.iteratingVariable)
			
			if (generationMode != StatechartGenerationMode.GENERATE_ONLY_FORWARD){
				forwardTransition.guard = getVariableInIntervalExpression(iteratingVariable, allowedGlobalWaitMin, allowedGlobalWaitMax)
				forwardTransition.effects.add(setIntVariable(iteratingVariable, 0))				
			}


			t3.sourceState = tmpChoice
			t3.targetState = previousState
			t3.effects.add(incrementVar(iteratingVariable))
			t3.priority = BigInteger.valueOf(2)
			t3.guard = getVariableLessEqualParamExpression(iteratingVariable, allowedGlobalWaitMax)

			var NotDefinedEventMode mode 
			if (ScenarioModelDerivedFeatures.isAllNeg(set) || isNegated) {
				mode = nonDeclaredNegMessageMode
				// does not need to be added, as it is overshadowed by the forward going transition
				if (mode != NotDefinedEventMode.STRICT) {
					statechart.transitions.add(t3)
				}
			} else {
				statechart.transitions.add(t3)
				mode = nonDeclaredMessageMode
			}

			if (mode == NotDefinedEventMode.STRICT) {
				var BinaryTrigger tmp = getAllEvents(BinaryType.AND)
				negateBinaryTree(tmp)
				t3.trigger = tmp
			}

			violationTransition.priority = BigInteger.valueOf(1)
			violationTransition.guard = createElseExpression

			if (ScenarioModelDerivedFeatures.isAllNeg(set) || isNegated) {
				forwardTransition.guard = null
				var maxCheck = createLessExpression
				var ref1 = createDirectReferenceExpression
				ref1.declaration = variableMap.getOrCreate(scenarioStatechartUtil.iteratingVariable)
				maxCheck.leftOperand = ref1
				var max = createIntegerLiteralExpression
				max.value = BigInteger.valueOf(allowedGlobalWaitNegMax)
				maxCheck.rightOperand = max
				t3.guard = maxCheck
			}

			if (nonDeclaredMessageMode == NotDefinedEventMode.STRICT) {
				var binary = createBinaryTrigger
				binary.leftOperand = forwardTransition.trigger
				binary.rightOperand = getBinaryTriggerFromTriggers(createOtherNegatedTriggers(set), BinaryType.AND)
				binary.type = BinaryType.AND
				forwardTransition.trigger = binary
			}

			switch (generationMode) {
				case GENERATE_MERGE_STATE: {
					val mergeState = createMergeState
					mergeState.name = "merge" + stateCount++
					for (transition : statechart.transitions) {
						if (transition.targetState == previousState && transition !== t3) {
							transition.targetState = mergeState
						}
					}
					val newTransition = createTransition
					newTransition.sourceState = mergeState
					newTransition.targetState = tmpChoice
					cycleTransition.targetState = mergeState
					statechart.transitions += newTransition
					statechart.regions.get(0).stateNodes += mergeState
				}
				case GENERATE_ONLY_FORWARD: {
					statechart.transitions.remove(t3)
				}
				case GENERATE_DUPLICATED_CHOICES: {
					for (transition : previousState.incomingTransitions) {
						if (transition.sourceState !== tmpChoice) {
							val tmpChoice2 = addChoiceState
							val forwardCopy = forwardTransition.clone
							val violationCopy = violationTransition.clone
							val t3Copy = t3.clone
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

		statechart.transitions.add(forwardTransition)
		statechart.transitions.add(violationTransition)
		statechart.transitions.add(cycleTransition)

		handleArguments(set.modalInteractions, forwardTransition);
		if (singleNegetedSignalWithArguments) {
			var signal = (set.modalInteractions.get(0) as NegatedModalInteraction).modalinteraction as Signal
			if (!signal.arguments.empty) { 
				var tmp = violationTransition.targetState
				violationTransition.targetState = forwardTransition.targetState
				forwardTransition.targetState = tmp
				forwardTransition.trigger = negateEventTrigger(forwardTransition.trigger)

			}
		}
		statechart.regions.get(0).stateNodes.add(state)
		previousState = state
		return
	}

	def setupForwardTransition(ModalInteractionSet set, InteractionDefinition first, boolean reversed,
			boolean isNegated, Transition forwardTransition) {
		var Trigger t = null
		if (set.modalInteractions.size > 1) {
			t = getBinaryTrigger(set.modalInteractions, BinaryType.AND, reversed)
		} else {
			t = getEventTrigger(first, reversed)
		}
		if (!isNegated) {
			for (modalInteraction : set.modalInteractions) {
				var a = getRaiseEventAction(modalInteraction, !reversed)
				if (a !== null)
					forwardTransition.effects.add(a)
			}
			forwardTransition.trigger = t
		} else {
			forwardTransition.trigger = negateEventTrigger(t)
		}
	}

	def handleDelays(ModalInteractionSet set) {
		var delays = set.modalInteractions.filter(Delay)
		if (!delays.empty) {
			var delay = delays.get(0) as Delay
			var td = createTimeoutDeclaration
			td.name = "delay" + timeoutCount++
			statechart.timeoutDeclarations += td
			var ts = createTimeSpecification
			ts.unit = TimeUnit.MILLISECOND
			ts.value = delay.minimum.clone
			var a = createSetTimeoutAction
			a.timeoutDeclaration = td
			a.time = ts
			if (previousState instanceof State) {
				previousState.entryActions += a
			}
		}
	}

	def handleArguments(EList<InteractionDefinition> set, Transition t1) {
		var signals = set.filter[it instanceof Signal].filter[!(it as Signal).arguments.empty]

		if (signals.empty) {
			if (set.size == 1 && set.get(0) instanceof NegatedModalInteraction &&
				(set.get(0) as NegatedModalInteraction).modalinteraction instanceof Signal &&
				!((set.get(0) as NegatedModalInteraction).modalinteraction as Signal).arguments.empty) {
				signals = set.filter[set.size == 1].filter(NegatedModalInteraction).filter [
					it.modalinteraction instanceof Signal
				].map[it.modalinteraction].filter[!(it as Signal).arguments.empty]

			} else {
				return
			}
		}
		var guard1 = createAndExpression
		for (signal : signals) {
			var tmp = signal as Signal
			var i = 0
			var String portName = tmp.port.name
			if (tmp.direction.equals(InteractionDirection.SEND)) {
				if (!scenarioStatechartUtil.isTurnedOut(tmp.port))
					portName = scenarioStatechartUtil.getTurnedOutPortName(tmp.port)
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
				guard1.operands.add(equal)
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
			and.operands.add(expr)
			and.operands.add(guard)
			t1.guard = and
		}
	}

}