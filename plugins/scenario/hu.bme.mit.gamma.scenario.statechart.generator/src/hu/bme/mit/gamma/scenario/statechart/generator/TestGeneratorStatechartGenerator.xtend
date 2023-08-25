/********************************************************************************
 * Copyright (c) 2020-2022 Contributors to the Gamma project
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
import hu.bme.mit.gamma.scenario.model.NegPermissiveAnnotation
import hu.bme.mit.gamma.scenario.model.NegStrictAnnotation
import hu.bme.mit.gamma.scenario.model.NegatedDeterministicOccurrence
import hu.bme.mit.gamma.scenario.model.NegatedWaitAnnotation
import hu.bme.mit.gamma.scenario.model.OptionalCombinedFragment
import hu.bme.mit.gamma.scenario.model.PermissiveAnnotation
import hu.bme.mit.gamma.scenario.model.ScenarioAssignmentStatement
import hu.bme.mit.gamma.scenario.model.ScenarioCheckExpression
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration
import hu.bme.mit.gamma.scenario.model.StrictAnnotation
import hu.bme.mit.gamma.scenario.model.WaitAnnotation
import hu.bme.mit.gamma.statechart.contract.NotDefinedEventMode
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority
import java.math.BigInteger

import static extension hu.bme.mit.gamma.scenario.model.derivedfeatures.ScenarioModelDerivedFeatures.*
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

	var NotDefinedEventMode nonDeclaredMessageMode = NotDefinedEventMode.PERMISSIVE
	var NotDefinedEventMode nonDeclaredNegMessageMode = NotDefinedEventMode.STRICT
	val boolean coldViolationExisits
	val StatechartGenerationMode generationMode
	val boolean negativeTest

	new(ScenarioDeclaration scenario, Component component, StatechartGenerationMode mode,
		boolean dedicatedColdViolation, boolean negativeTest) {
		super(scenario, component)
		this.generationMode = mode
		this.coldViolationExisits = dedicatedColdViolation
		this.negativeTest = negativeTest
	}

	new(ScenarioDeclaration scenario, Component component) {
		this(scenario, component, StatechartGenerationMode.GENERATE_ONLY_FORWARD, true, false)
	}

	override StatechartDefinition execute() {
		statechart = createSynchronousStatechartDefinition
		for (annotation : scenario.annotation) {
			if (annotation instanceof WaitAnnotation) {
				allowedGlobalWaitMax = annotation.maximum.evaluateInteger
				allowedGlobalWaitMin = annotation.minimum.evaluateInteger
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

		for (modalInteraction : scenario.fragment.interactions) {
			process(modalInteraction)
		}

		val remove = <StateNode>newArrayList
		for (stateNode : firstRegion.stateNodes) {
			if (stateNode.incomingTransitions.isEmpty && stateNode.name != scenarioStatechartUtil.initial)
				remove += stateNode
		}
		firstRegion.stateNodes -= remove
		val lastState = firstRegion.stateNodes.get(firstRegion.stateNodes.size - 1)
		lastState.name = scenarioStatechartUtil.accepting

		for (transition : statechart.transitions) {
			if (transition.getTargetState == coldViolation) {
				transition.effects += setIntVariable(variableMap.getOrCreate(scenarioStatechartUtil.result), 1)
			} else if (transition.targetState == hotViolation) {
				transition.effects += setIntVariable(variableMap.getOrCreate(scenarioStatechartUtil.result), 0)
			} else if (transition.targetState == lastState) {
				transition.effects += setIntVariable(variableMap.getOrCreate(scenarioStatechartUtil.result), 2)
			}
		}

		val newMergeStates = newArrayList
		val states = firstRegion.stateNodes
		for (stateNode : states) {
			if (stateNode instanceof ChoiceState && stateNode.incomingTransitions.size > 1) {
				val choice = stateNode
				val merge = createMergeState
				merge.name = scenarioStatechartUtil.mergeName + stateCount++
				for (transition : choice.incomingTransitions) {
					transition.targetState = merge
				}
				val transition = createTransition
				transition.sourceState = merge
				transition.targetState = choice
				statechart.transitions += transition
				newMergeStates += merge
			}
		}
		states += newMergeStates

		addScenarioContractAnnotation(nonDeclaredMessageMode)

		val waitingAnnotation = createScenarioAllowedWaitAnnotation
		waitingAnnotation.lowerLimit = allowedGlobalWaitMin.toIntegerLiteral
		waitingAnnotation.upperLimit = allowedGlobalWaitMax.toIntegerLiteral
		statechart.annotations += waitingAnnotation
		return statechart
	}

	def protected initializeStateChart(String scenarioName) {
		addPorts(component)
		statechart.transitionPriority = TransitionPriority.VALUE_BASED
		statechart.name = scenarioName
		firstRegion = createRegion
		firstRegion.name = firstRegionName
		statechart.regions += firstRegion
		
		statechart.parameterDeclarations += component.parameterDeclarations.clone

		val initial = createInitialState
		initial.name = scenarioStatechartUtil.initial
		firstRegion.stateNodes += initial

		firstState = createState
		firstState.name = firstStateName
		firstRegion.stateNodes += firstState
		previousState = firstState
		var tmp = createNewState(scenarioStatechartUtil.hotViolation)
		firstRegion.stateNodes += tmp
		hotViolation = tmp;
		if (coldViolationExisits) {
			tmp = createNewState(scenarioStatechartUtil.coldViolation)
			firstRegion.stateNodes += tmp
			coldViolation = tmp
		} else {
			coldViolation = firstState
		}

		val initBlock = scenario.initialBlock
		if (initBlock === null) {
			val transition = statechartUtil.createTransition(initial, firstState)
			if (generationMode != StatechartGenerationMode.GENERATE_ONLY_FORWARD) {
				transition.effects += setIntVariable(variableMap.getOrCreate(scenarioStatechartUtil.iteratingVariable), 1)
			}
			if (!scenario.getContentsOfType(LoopCombinedFragment).empty) {
				transition.effects +=
					setIntVariable(variableMap.getOrCreate(scenarioStatechartUtil.getLoopvariableNameForDepth(0)), 1)
			}
		} else {
			val initChoice = createNewChoiceState
			firstRegion.stateNodes += initChoice
			statechartUtil.createTransition(initial, initChoice)
			val initChoiceToFirstStateTransition = statechartUtil.createTransition(initChoice, firstState)
			retargetAllEventParamRefs(initBlock, true)
			val checks = initBlock.interactions.filter(ScenarioCheckExpression)
			val assignments = initBlock.interactions.filter(ScenarioAssignmentStatement)
			addChecksToTransition(checks, initChoiceToFirstStateTransition)
			addAssignmentsToTransition(assignments, initChoiceToFirstStateTransition)
			val nonCheckOrAssignmentInteractitons = initBlock.interactions.filter [
				!(it instanceof ScenarioCheckExpression) && ! (it instanceof ScenarioAssignmentStatement)
			].toList
			for (interaction : nonCheckOrAssignmentInteractitons) {
				val action = getRaiseEventAction(interaction, false)
				if (action !== null) {
					initChoiceToFirstStateTransition.effects += action
				}
			}
			if (!scenario.getContentsOfType(LoopCombinedFragment).empty) {
				initChoiceToFirstStateTransition.effects +=
					setIntVariable(variableMap.getOrCreate(scenarioStatechartUtil.getLoopvariableNameForDepth(0)), 1)
			}
			statechart.transitions += initChoiceToFirstStateTransition

			val violation = (initBlock.interactions.head.modality == ModalityType.HOT) ? hotViolation : coldViolation
			val initialViolationTransition = statechartUtil.createTransition(initChoice, violation)
			initialViolationTransition.guard = createElseExpression
		}
		statechart.variableDeclarations += scenario.variableDeclarations
	}

	def dispatch void process(DeterministicOccurrenceSet interactionSet) {
		processDeterministicOccurrenceSet(interactionSet, false)
	}

	def dispatch void process(Delay delay) {
		throw new UnsupportedOperationException("Single delays are placed into a set in a previous step")
	}

	def dispatch void process(NegatedDeterministicOccurrence negatedDeterministicOccurrence) {
		val modalInteraction = negatedDeterministicOccurrence.deterministicOccurrence
		if (modalInteraction instanceof DeterministicOccurrenceSet) {
			processDeterministicOccurrenceSet(modalInteraction, true)
		}
	}

	def dispatch void process(AlternativeCombinedFragment alternative) {
		val ends = newArrayList
		val choice = createNewChoiceState
		for (transition : previousState.incomingTransitions) {
			transition.targetState = choice
		}
		replacedStateWithValue.put(previousState, choice)
		firstRegion.stateNodes -= previousState
		firstRegion.stateNodes += choice
		val savedStateCount = stateCount++
		for (i : 0 ..< alternative.fragments.size) {
			val state = createNewState(scenarioStatechartUtil.stateName + String.valueOf(savedStateCount) + "_" +
				String.valueOf(i))
			previousState = state
			firstRegion.stateNodes += state
			statechartUtil.createTransition(choice, state)
			for (interaction : alternative.fragments.get(i).interactions) {
				process(interaction)
			}
			ends += previousState
			stateCount--
		}
		var merge = createState
		for (transition : statechart.transitions) {
			if (ends.contains(transition.targetState)) {
				transition.targetState = merge
			}
		}
		firstRegion.stateNodes -= ends
		merge.name = scenarioStatechartUtil.mergeName + String.valueOf(exsistingMerges++)
		firstRegion.stateNodes += merge
		previousState = merge
	}

	def dispatch void process(LoopCombinedFragment loop) {
		val loopDepth = scenarioStatechartUtil.getLoopDepth(loop)
		var prevprev = previousState
		for (interaction : loop.fragments.get(0).interactions) {
			interaction.process
		}
		if (replacedStateWithValue.containsKey(prevprev)) {
			prevprev = replacedStateWithValue -= prevprev
		}
		val choice = createNewChoiceState
		for (transition : previousState.incomingTransitions) {
			transition.targetState = choice
		}

		replacedStateWithValue.put(previousState, choice)
		firstRegion.stateNodes -= previousState
		firstRegion.stateNodes += choice
		val stateNew = createNewState()
		previousState = stateNew
		firstRegion.stateNodes += stateNew
		val forwardGoingTransition = statechartUtil.createTransition(choice, stateNew)
		val iteratingTransition = statechartUtil.createTransition(choice, prevprev)

		val variableForDepth = variableMap.getOrCreate(scenarioStatechartUtil.getLoopvariableNameForDepth(loopDepth))
		forwardGoingTransition.guard = getVariableGreaterEqualParamExpression(variableForDepth,
			exprEval.evaluateInteger(loop.minimum))
		val maxCheck = createLessExpression
		maxCheck.leftOperand = exprUtil.createReferenceExpression(variableForDepth)
		maxCheck.rightOperand = exprUtil.toIntegerLiteral(exprEval.evaluateInteger(loop.maximum))
		iteratingTransition.guard = maxCheck
		iteratingTransition.effects += incrementVar(variableForDepth)
		forwardGoingTransition.effects += setIntVariable(variableForDepth, 1)
	}

	def dispatch void process(OptionalCombinedFragment optionalCombinedFragment) {
		val choice = createNewChoiceState
		for (transition : statechart.transitions) {
			if (transition.targetState.equals(previousState)) {
				transition.targetState = choice
			}
		}
		replacedStateWithValue.put(previousState, choice)
		firstRegion.stateNodes -= previousState
		firstRegion.stateNodes += choice
		val stateNew = createNewState()
		previousState = stateNew
		firstRegion.stateNodes += stateNew
		val firstFragment = optionalCombinedFragment.fragments.get(0)
		for (interaction : firstFragment.interactions) {
			process(interaction)
		}
		statechartUtil.createTransition(choice, stateNew)
		statechartUtil.createTransition(choice, previousState)
	}

	def processDeterministicOccurrenceSet(DeterministicOccurrenceSet set, boolean isNegated) {
		val state = createNewState
		val newChoice = createNewChoiceState
		firstRegion.stateNodes += newChoice
		firstRegion.stateNodes += state
		val dir = set.direction
		val mod = set.modality
		val forwardTransition = statechartUtil.createTransition(newChoice, state)
		forwardTransition.priority = BigInteger.valueOf(3)
		val violationTransition = statechartUtil.createTransition(newChoice,
			(mod == ModalityType.COLD) ? coldViolation : hotViolation)
		val cycleTransition = statechartUtil.createTransition(previousState, newChoice)
		cycleTransition.trigger = createOnCycleTrigger
		val backwardTransition = createTransition
		violationTransition.guard = createElseExpression
		

		if (set.deterministicOccurrences.empty) {
			val emptyTransition = statechartUtil.createTransition(previousState, state)
			emptyTransition.trigger = createOnCycleTrigger
			emptyTransition.guard = createTrueExpression
			firstRegion.stateNodes += state
			previousState = state
			return
		}
		handleDelays(set, forwardTransition, violationTransition)
		setupForwardTransition(set, dir.equals(InteractionDirection.SEND), isNegated, forwardTransition)

		if (nonDeclaredMessageMode == NotDefinedEventMode.STRICT) {
			val binary = createBinaryTrigger
			binary.leftOperand = forwardTransition.trigger
			binary.rightOperand = getBinaryTriggerFromTriggers(createOtherNegatedTriggers(set, true), BinaryType.AND)
			binary.type = BinaryType.AND
			forwardTransition.trigger = binary
		}

		if (dir.equals(InteractionDirection.SEND)) {
			handleSends(set, isNegated, forwardTransition, backwardTransition, cycleTransition, violationTransition,
				newChoice)
		}
		handleArguments(set.deterministicOccurrences, forwardTransition)
		handleSingleNegatedIfNeeded(set, forwardTransition, violationTransition)
		
		if(negativeTest && dir == InteractionDirection.SEND && mod == ModalityType.HOT) {
			val source = violationTransition.sourceState
			val target = violationTransition.targetState
			statechart.transitions -= violationTransition
			val negatedInteractions = set.deterministicOccurrences.filter(NegatedDeterministicOccurrence).toList
			set.deterministicOccurrences -= negatedInteractions // this is fine, as no other transformation will handle it
			val otherTriggers = createOtherTriggers(set, false,true)
			for(transition : source.outgoingTransitions) {
				transition.priority = BigInteger.valueOf(otherTriggers.size) + transition.priority + BigInteger.ONE
			}
			var i = 0
			for(trigger : otherTriggers) {
				val newTransition =statechartUtil.createTransition(source, target)
				newTransition.priority = BigInteger.valueOf(i++)
				newTransition.trigger = trigger
			}
			val interactions = set.deterministicOccurrences.filter(Interaction)
			if (interactions.size == 1 && interactions.head.arguments.size == 1) {
				val negatedForward = statechartUtil.createTransition(source, target)
				handleArguments(set.deterministicOccurrences.clone, negatedForward)
				negatedForward.guard = negatedForward.guard.clone.createNotExpression
				negatedForward.trigger = forwardTransition.trigger.clone
				negatedForward.priority = BigInteger.valueOf(otherTriggers.size) + BigInteger.ONE
			}
		}
		previousState = state
		return
	}

	def handleSends(DeterministicOccurrenceSet set, boolean isNegated, Transition forwardTransition,
		Transition backwardTransition, Transition cycleTransition, Transition violationTransition,
		ChoiceState newChoice) {
		val iteratingVariable = variableMap.getOrCreate(scenarioStatechartUtil.iteratingVariable)

		forwardTransition.priority = BigInteger.valueOf(3)
		backwardTransition.priority = BigInteger.valueOf(2)
		violationTransition.priority = BigInteger.valueOf(1)
		backwardTransition.sourceState = newChoice
		backwardTransition.targetState = previousState
		backwardTransition.effects += incrementVar(iteratingVariable)
		backwardTransition.guard = getVariableLessEqualParamExpression(iteratingVariable, allowedGlobalWaitMax)

		if (generationMode != StatechartGenerationMode.GENERATE_ONLY_FORWARD) {
			forwardTransition.guard = getVariableInIntervalExpression(iteratingVariable, allowedGlobalWaitMin,
				allowedGlobalWaitMax)
			forwardTransition.effects += setIntVariable(iteratingVariable, 0)
		}

		val onlyNegated = set.isAllInteractionsOrBlockNegated || isNegated
		val NotDefinedEventMode mode = (onlyNegated) ? nonDeclaredNegMessageMode : nonDeclaredMessageMode
		if (!onlyNegated || mode == NotDefinedEventMode.STRICT) {
			// does not need to be added for allneg and strict, as it is overshadowed by the forward going transition
			statechart.transitions += backwardTransition
		}

		if (mode == NotDefinedEventMode.STRICT) {
			val BinaryTrigger tmp = getAllEvents(BinaryType.AND)
			negateBinaryTree(tmp)
			backwardTransition.trigger = tmp
		}

		if (onlyNegated) {
			forwardTransition.guard = null
			val maxCheck = createLessExpression
			maxCheck.leftOperand = exprUtil.createReferenceExpression(
				variableMap.getOrCreate(scenarioStatechartUtil.iteratingVariable))
			maxCheck.rightOperand = exprUtil.toIntegerLiteral(allowedGlobalWaitNegMax)
			backwardTransition.guard = maxCheck
		}

		switch (generationMode) {
			case GENERATE_MERGE_STATE: { // legacy option, not used currently
				val mergeState = createMergeState
				mergeState.name = scenarioStatechartUtil.mergeName + stateCount++
				for (transition : statechart.transitions) {
					if (transition.targetState == previousState && transition !== backwardTransition) {
						transition.targetState = mergeState
					}
				}
				firstRegion.stateNodes += mergeState
				statechartUtil.createTransition(mergeState, newChoice)
				cycleTransition.targetState = mergeState
			}
			case GENERATE_ONLY_FORWARD: {
				statechart.transitions -= backwardTransition
			}
			case GENERATE_DUPLICATED_CHOICES: { // legacy option, not used currently
				for (transition : previousState.incomingTransitions) {
					if (transition.sourceState !== newChoice) {
						val tmpChoice2 = createNewChoiceState
						val forwardCopy = forwardTransition.clone
						val violationCopy = violationTransition.clone
						val t3Copy = backwardTransition.clone
						t3Copy.sourceState = tmpChoice2
						forwardCopy.sourceState = tmpChoice2
						violationCopy.sourceState = tmpChoice2
						transition.targetState = tmpChoice2
						firstRegion.stateNodes += tmpChoice2
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
				throw new IllegalArgumentException("Unhandled generation mode: " + generationMode)
			}
		}
	}

	def handleSingleNegatedIfNeeded(DeterministicOccurrenceSet set, Transition forwardTransition,
		Transition violationTransition) {
		var Interaction signal = null
		var singleNegetedSignalWithArguments = false
		val firstModalinteraction = set.deterministicOccurrences.get(0)
		if (set.deterministicOccurrences.size == 1 && firstModalinteraction instanceof NegatedDeterministicOccurrence) {
			val negatedDeterministicOccurrence = firstModalinteraction as NegatedDeterministicOccurrence
			val innerModalInteraction = negatedDeterministicOccurrence.deterministicOccurrence
			if (innerModalInteraction instanceof Interaction) {
				singleNegetedSignalWithArguments = !(innerModalInteraction.arguments.empty)
				if (singleNegetedSignalWithArguments) {
					signal = innerModalInteraction
				}
			}
		}
		if (singleNegetedSignalWithArguments) {
			if (!signal.arguments.empty) {
				val tmp = violationTransition.targetState
				violationTransition.targetState = forwardTransition.targetState
				forwardTransition.targetState = tmp
				forwardTransition.trigger = negateTrigger(forwardTransition.trigger)
			}
		}
	}
}
