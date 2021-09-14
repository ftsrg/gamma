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

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
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
import hu.bme.mit.gamma.scenario.model.util.ScenarioModelSwitch
import hu.bme.mit.gamma.scenario.statechart.util.ScenarioStatechartUtil
import hu.bme.mit.gamma.statechart.contract.ContractModelFactory
import hu.bme.mit.gamma.statechart.contract.NotDefinedEventMode
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.interface_.Trigger
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.math.BigInteger
import java.util.ArrayList
import java.util.List
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

enum StatechartGenerationMode {
	GENERATE_MERGE_STATE,
	GENERATE_ORIGINAL_STRUCTURE,
	GENERATE_ONLY_FORWARD,
	GENERATE_DUPLICATED_CHOICES
}

class StatechartGenerator extends ScenarioModelSwitch<EObject> {
	val extension StatechartModelFactory statechartfactory = StatechartModelFactory.eINSTANCE
	val extension ExpressionModelFactory expressionfactory = ExpressionModelFactory.eINSTANCE
	val extension InterfaceModelFactory interfacefactory = InterfaceModelFactory.eINSTANCE
	val extension ActionModelFactory actionfactory = ActionModelFactory.eINSTANCE
	val extension ContractModelFactory contractfactory = ContractModelFactory.eINSTANCE
	val extension GammaEcoreUtil ecureUtil = GammaEcoreUtil.INSTANCE
	val ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE

	var Component component = null
	var ScenarioDefinition scenario = null
	var StatechartDefinition statechart = null
	var allowedGlobalWaitMax = 0
	var allowedGlobalWaitMin = 0
	var allowedGlobalWaitNegMax = 0
	int exsistingChoices = 0;
	int exsistingMerges = 0;
	var StateNode previousState = null
	var State hotViolation = null
	var State coldViolation = null
	var stateCount = 0
	var timeoutCount = 0
	var nonDeclaredMessageMode = 0
	var nonDeclaredNegMessageMode = 1
	var coldViolationExisits = true
	val StatechartGenerationMode generationMode

	new(boolean coldViolationExisits, ScenarioDefinition scenario, Component component, StatechartGenerationMode mode) {
		this.component = component
		this.generationMode = mode
		this.scenario = scenario
		this.coldViolationExisits = coldViolationExisits
	}

	new(boolean coldViolationExisits, ScenarioDefinition scenario, Component component) {
		this(coldViolationExisits, scenario, component, StatechartGenerationMode.GENERATE_MERGE_STATE)
	}

	def StatechartDefinition execute() {
		statechart = createStatechartDefinition
		initializeStateChart(scenario.name)
		addPorts(component)
		for (a : scenario.annotation) {
			if (a instanceof WaitAnnotation) {
				allowedGlobalWaitMax = a.maximum.intValue
				allowedGlobalWaitMin = (a as WaitAnnotation).minimum.intValue
			} else if (a instanceof StrictAnnotation) {
				nonDeclaredMessageMode = 1
			} else if (a instanceof PermissiveAnnotation) {
				nonDeclaredMessageMode = 0
			} else if (a instanceof NegatedWaitAnnotation) {
				allowedGlobalWaitNegMax = a.maximum.intValue
			} else if (a instanceof NegStrictAnnotation) {
				nonDeclaredNegMessageMode = 1
			} else if (a instanceof NegPermissiveAnnotation) {
				nonDeclaredNegMessageMode = 0
			}
		}

		for (mi : scenario.chart.fragment.interactions) {
			process(mi)
		}

		var remove = new ArrayList<StateNode>()
		for (s : statechart.regions.get(0).stateNodes) {
			if (StatechartModelDerivedFeatures::getIncomingTransitions(s).isEmpty &&
				!(s.name == scenarioStatechartUtil.initial))
				remove += s
		}
		statechart.regions.get(0).stateNodes.removeAll(remove)
		val lastState = statechart.regions.get(0).stateNodes.get(statechart.regions.get(0).stateNodes.size - 1)
		lastState.name = scenarioStatechartUtil.accepting

		for (t : statechart.transitions) {
			if (t.getTargetState == coldViolation) {
				t.effects.add(setIntVariable(0, 1))
			} else if (t.targetState == hotViolation) {
				t.effects.add(setIntVariable(0, 0))
			} else if (t.targetState == lastState) {
				t.effects.add(setIntVariable(0, 2))
			}
		}

		val a = createScenarioContractAnnotation
		a.monitoredComponent = component
		a.scenarioType = nonDeclaredMessageMode == 1 ? NotDefinedEventMode.STRICT : NotDefinedEventMode.PERMISSIVE
		statechart.annotations += a
		
		val waitingAnnotation= createScenarioAllowedWaitAnnotation
		val lower = createIntegerLiteralExpression
		lower.value = BigInteger.valueOf(allowedGlobalWaitMin)
		val upper = createIntegerLiteralExpression
		upper.value = BigInteger.valueOf(allowedGlobalWaitMax)
		waitingAnnotation.lowerLimit = lower
		waitingAnnotation.upperLimit = upper
		statechart.annotations +=waitingAnnotation
		return statechart
	}

	def dispatch Interaction process(ModalInteractionSet s) {
		processModalInteractionSet(s, false)
		return null;
	}

	def dispatch Interaction process(Delay d) {
		var state = createNewState("state" + String.valueOf(stateCount++))
		var t = createTransition
		t.sourceState = previousState
		t.targetState = state
		var td = createTimeoutDeclaration
		td.name = "delay" + timeoutCount++
		statechart.timeoutDeclarations += td
		var ts = createTimeSpecification
		ts.unit = TimeUnit.MILLISECOND
		ts.value = d.minimum.clone
		var a = createSetTimeoutAction
		a.timeoutDeclaration = td
		a.time = ts
		if (previousState instanceof State)
			previousState.entryActions += a
		var e = createEventTrigger
		var er = createTimeoutEventReference
		er.timeout = td
		t.trigger = e
		e.eventReference = er
		var t2 = createTransition
		t2.sourceState = previousState
		if (d.modality == ModalityType.COLD)
			t2.targetState = coldViolation
		else
			t2.targetState = hotViolation
		var e2 = createEventTrigger
		var er2 = createTimeoutEventReference
		er2.setTimeout(td)
		e2.eventReference = er2
		t2.trigger = negateEventTrigger(e2)

		previousState = state
		statechart.transitions.add(t)
		statechart.transitions.add(t2)
		statechart.regions.get(0).stateNodes.add(state)
		return null;
	}

	def dispatch Interaction process(NegatedModalInteraction n) {
		if (n.modalinteraction instanceof ModalInteractionSet) {
			processModalInteractionSet(n.modalinteraction as ModalInteractionSet, true)
			return null
		}
	}

	def dispatch Interaction process(AlternativeCombinedFragment a) {
		var ends = newArrayList
		var choice = addChoiceState
		for (t : statechart.transitions) {
			if (t.targetState.equals(previousState))
				t.targetState = choice
		}
		statechart.regions.get(0).stateNodes.remove(previousState)
		statechart.regions.get(0).stateNodes.add(choice)
		var n = stateCount++
		for (i : 0 ..< a.fragments.size) {
			var state = createNewState("state" + String.valueOf(n) + "_" + String.valueOf(i))
			previousState = state
			statechart.regions.get(0).stateNodes.add(state)
			var t = createTransition
			t.sourceState = choice
			t.targetState = state
			statechart.transitions.add(t)
			for (ints : a.fragments.get(i).interactions)
				process(ints)
			ends.add(previousState)
			stateCount--
		}
		var merg = createState
		for (t : statechart.transitions)
			if (ends.contains(t.targetState))
				t.targetState = merg
		statechart.regions.get(0).stateNodes.removeAll(ends)

		merg.name = "merge" + String.valueOf(exsistingMerges++)
		statechart.regions.get(0).stateNodes.add(merg)
		previousState = merg
		return null
	}

	def dispatch Interaction process(LoopCombinedFragment loop) {

		val prevprev = previousState
		for (i : loop.fragments.get(0).interactions) {
			i.process
		}
		var choice = addChoiceState
		for (t : statechart.transitions) {
			if (t.targetState.equals(previousState))
				t.targetState = choice
		}
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

		val evaluator = ExpressionEvaluator.INSTANCE;
		t1.guard = getMinCheck(2, evaluator.evaluateInteger(loop.minimum))
		var maxCheck = createLessExpression
		var ref1 = createDirectReferenceExpression
		ref1.declaration = statechart.variableDeclarations.get(2)
		maxCheck.leftOperand = ref1
		var max = createIntegerLiteralExpression
		max.value = BigInteger.valueOf(evaluator.evaluateInteger(loop.maximum))
		maxCheck.rightOperand = max
		t2.guard = maxCheck

		t2.effects += incrementVar(2)
		t1.effects += setIntVariable(2, 1)

		return null;

	}

	def dispatch Interaction process(OptionalCombinedFragment ocf) {
		var choice = addChoiceState
		for (t : statechart.transitions) {
			if (t.targetState.equals(previousState))
				t.targetState = choice
		}
		statechart.regions.get(0).stateNodes.remove(previousState)
		statechart.regions.get(0).stateNodes.add(choice)
		var stateNew = createNewState("state" + String.valueOf(stateCount++))
		previousState = stateNew
		statechart.regions.get(0).stateNodes.add(stateNew)
		for (i : ocf.fragments.get(0).interactions) {
			process(i)
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

	protected def processModalInteractionSet(ModalInteractionSet set, boolean isNegated) {
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
			if (nonDeclaredMessageMode == 1) {
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
			
			if (generationMode != StatechartGenerationMode.GENERATE_ONLY_FORWARD){
				forwardTransition.guard = getGuard(1, allowedGlobalWaitMin, allowedGlobalWaitMax)
				forwardTransition.effects.add(setIntVariable(1, 0))				
			}


			t3.sourceState = tmpChoice
			t3.targetState = previousState
			t3.effects.add(incrementVar(1))
			t3.priority = BigInteger.valueOf(2)
			t3.guard = getMaxCheck(1, allowedGlobalWaitMax)

			var mode = -1
			if (isAllNeg(set) || isNegated) {
				mode = nonDeclaredNegMessageMode
				// does not need to be added, as it is overshadowed by the forward going transition
				if (mode != 1)
					statechart.transitions.add(t3)
			} else {
				statechart.transitions.add(t3)
				mode = nonDeclaredMessageMode
			}

			if (mode == 1) {
				var BinaryTrigger tmp = getAllEvents(BinaryType.AND)
				negateBinaryTree(tmp)
				t3.trigger = tmp
			}

			violationTransition.priority = BigInteger.valueOf(1)
			violationTransition.guard = createElseExpression

			if (isAllNeg(set) || isNegated) {
				forwardTransition.guard = null
				var maxCheck = createLessExpression
				var ref1 = createDirectReferenceExpression
				ref1.declaration = statechart.variableDeclarations.get(1)
				maxCheck.leftOperand = ref1
				var max = createIntegerLiteralExpression
				max.value = BigInteger.valueOf(allowedGlobalWaitNegMax)
				maxCheck.rightOperand = max
				t3.guard = maxCheck
			}

			if (nonDeclaredMessageMode == 1) {
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
					for (t : statechart.transitions) {
						if (t.targetState == previousState && t !== t3) {
							t.targetState = mergeState
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
					for (t : previousState.incomingTransitions) {
						if (t.sourceState !== tmpChoice) {
							val tmpChoice2 = addChoiceState
							val forwardCopy = forwardTransition.clone
							val violationCopy = violationTransition.clone
							val t3Copy = t3.clone
							t3Copy.sourceState = tmpChoice2
							forwardCopy.sourceState = tmpChoice2
							violationCopy.sourceState = tmpChoice2
							t.targetState = tmpChoice2
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
			for (mi : set.modalInteractions) {
				var a = getRaiseEventAction(mi, !reversed)
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

	protected def List<Trigger> createOtherNegatedTriggers(ModalInteractionSet set) {
		var triggers = newArrayList
		var ports = newArrayList
		val events = newArrayList
		var allPorts = statechart.ports.filter[!it.inputEvents.empty]
		for (s : set.modalInteractions) {
			if (s instanceof Signal) {
				val portName = s.direction == InteractionDirection.SEND
						? scenarioStatechartUtil.getTurnedOutPortName(s.port)
						: s.port.name
				ports.add(getPort(portName))
				events.add(getEvent(s.event.name, getPort(portName)))
			} else if (s instanceof NegatedModalInteraction) {
				val m = s.modalinteraction
				if (m instanceof Signal) {
					val portName = m.direction == InteractionDirection.SEND
							? scenarioStatechartUtil.getTurnedOutPortName(m.port)
							: m.port.name
					ports.add(getPort(portName))
					events.add(getEvent(m.event.name, getPort(portName)))
				}
			}
		}
		for (p : allPorts) {
			if (!ports.contains(p)) {
				var any = createAnyPortEventReference
				any.port = p
				var t = createEventTrigger
				t.eventReference = any
				var u = createUnaryTrigger
				u.operand = t
				u.type = UnaryType.NOT
				triggers.add(u)
			} else {
				var concrateEvents = p.inputEvents.filter[!(events.contains(it))]
				for (c : concrateEvents) {
					var t = createEventTrigger
					var e = createPortEventReference
					e.event = c
					e.port = p
					t.eventReference = e
					var u = createUnaryTrigger
					u.operand = t
					u.type = UnaryType.NOT
					triggers.add(u)
				}
			}
		}
		return triggers
	}

	def protected BinaryTrigger getBinaryTriggerFromTriggers(List<Trigger> triggers, BinaryType type) {
		var bin = createBinaryTrigger
		bin.type = type
		var runningbin = bin
		var signalCount = 0
		for (t : triggers) {
			signalCount++

			if (runningbin.leftOperand === null)
				runningbin.leftOperand = t
			else if (signalCount == triggers.size) {
				runningbin.rightOperand = t
			} else {
				var newbin = createBinaryTrigger
				runningbin.rightOperand = newbin
				newbin.type = type
				runningbin = newbin
				runningbin.leftOperand = t
			}
		}
		return bin
	}

	protected def boolean isAllNeg(ModalInteractionSet set) {
		for (i : set.modalInteractions)
			if (!( i instanceof NegatedModalInteraction))
				return false
		return true
	}

	protected def AssignmentStatement incrementVar(int n) {
		var assign = createAssignmentStatement
		var refe = createDirectReferenceExpression
		refe.declaration = statechart.variableDeclarations.get(n)
		var addition = createAddExpression
		var ref3 = createDirectReferenceExpression
		ref3.declaration = statechart.variableDeclarations.get(n)
		addition.operands.add(ref3)
		var intLiteral = createIntegerLiteralExpression
		intLiteral.value = BigInteger.valueOf(1)
		addition.operands.add(intLiteral)
		assign.rhs = addition
		assign.lhs = refe
		return assign
	}

	protected def setIntVariable(int number, int Value) {
		var nullVariableValue = createAssignmentStatement
		var lhs = createDirectReferenceExpression
		var rhs = createIntegerLiteralExpression
		lhs.declaration = statechart.variableDeclarations.get(number)
		rhs.value = BigInteger.valueOf(Value)
		nullVariableValue.lhs = lhs
		nullVariableValue.rhs = rhs
		return nullVariableValue
	}

	def protected dispatch ModalityType getModality(Signal s) {
		return s.modality
	}

	def protected dispatch ModalityType getModality(Delay d) {
		return d.modality
	}

	def protected dispatch ModalityType getModality(NegatedModalInteraction s) {
		if (s.modalinteraction instanceof Signal)
			return s.modalinteraction.modality
		return ModalityType.COLD
	}

	def protected dispatch InteractionDirection getDirection(Signal s) {
		return s.direction
	}

	def protected dispatch InteractionDirection getDirection(Delay s) {
		return InteractionDirection.RECEIVE
	}

	def protected dispatch InteractionDirection getDirection(NegatedModalInteraction s) {
		if (s.modalinteraction instanceof Signal)
			return s.modalinteraction.direction
		return InteractionDirection.RECEIVE
	}

	def protected Expression getMaxCheck(int variableNumber, int maxV) {
		var maxCheck = createLessEqualExpression
		var ref1 = createDirectReferenceExpression
		ref1.declaration = statechart.variableDeclarations.get(variableNumber)
		maxCheck.leftOperand = ref1
		var max = createIntegerLiteralExpression
		max.value = BigInteger.valueOf(maxV)
		maxCheck.rightOperand = max
		return maxCheck
	}

	def protected Expression getMinCheck(int variableNumber, int minV) {
		var minCheck = createGreaterEqualExpression
		var ref2 = createDirectReferenceExpression
		ref2.declaration = statechart.variableDeclarations.get(variableNumber)
		minCheck.leftOperand = ref2
		var min = createIntegerLiteralExpression
		min.value = BigInteger.valueOf(minV)
		minCheck.rightOperand = min
		return minCheck
	}

	def protected Expression getGuard(int variableNumber, int minV, int maxV) {
		var and = createAndExpression
		and.operands.add(getMinCheck(variableNumber, minV))
		and.operands.add(getMaxCheck(variableNumber, maxV))
		return and
	}

	def protected void negateBinaryTree(BinaryTrigger b) {
		if (b.rightOperand instanceof EventTrigger) {
			b.rightOperand = negateEventTrigger(b.rightOperand as EventTrigger)
		}
		if (b.leftOperand instanceof EventTrigger) {
			b.leftOperand = negateEventTrigger(b.leftOperand as EventTrigger)
		}
		if (b.leftOperand instanceof BinaryTrigger) {
			negateBinaryTree(b.leftOperand as BinaryTrigger)
		}
		if (b.rightOperand instanceof BinaryTrigger) {
			negateBinaryTree(b.rightOperand as BinaryTrigger)
		}
	}

	def protected Trigger negateEventTrigger(Trigger t) {
		if (t instanceof UnaryTrigger && (t as UnaryTrigger).type == UnaryType.NOT)
			return (t as UnaryTrigger).operand
		var n = createUnaryTrigger
		n.type = UnaryType.NOT
		n.operand = t
		return n
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
			var t = createEventTrigger
			t.eventReference = ref
			if (runningbin.leftOperand === null)
				runningbin.leftOperand = t
			else if (signalCount == size) {
				runningbin.rightOperand = t
			} else {
				var newbin = createBinaryTrigger
				runningbin.rightOperand = newbin
				newbin.type = type
				runningbin = newbin
				runningbin.leftOperand = t
			}
		}
		return bin
	}

	def protected BinaryTrigger getBinaryTrigger(EList<InteractionDefinition> i, BinaryType type, boolean reversed) {
		var bin = createBinaryTrigger
		bin.type = type
		var runningbin = bin
		var signalCount = 0
		for (interaction : i) {
			signalCount++
			var t = getEventTrigger(interaction, reversed)
			if (runningbin.leftOperand === null)
				runningbin.leftOperand = t
			else if (signalCount == i.size) {
				runningbin.rightOperand = t
			} else {
				var newbin = createBinaryTrigger
				runningbin.rightOperand = newbin
				newbin.type = type
				runningbin = newbin
				runningbin.leftOperand = t
			}
		}
		return bin
	}

	def protected dispatch Trigger getEventTrigger(Signal s, boolean reversed) {
		var t = createEventTrigger
		var eventref = createPortEventReference
		var port = createPort;
		if (reversed)
			port = getPort(scenarioStatechartUtil.getTurnedOutPortName(s.port))
		else
			port = getPort(s.port.name)
		eventref.event = getEvent(s.event.name, port)
		eventref.port = port
		t.eventReference = eventref
		return t
	}

	def protected dispatch Trigger getEventTrigger(Delay s, boolean reversed) {
		var t = createEventTrigger
		var er = createTimeoutEventReference
		var td = statechart.timeoutDeclarations.last
		er.setTimeout(td)
		t.eventReference = er
		return t
	}

	def protected dispatch Trigger getEventTrigger(NegatedModalInteraction s, boolean reversed) {
		var t = createEventTrigger

		if (s.modalinteraction instanceof Signal) {
			var signal = s.modalinteraction as Signal
			var port = createPort
			var event = createEvent
			if (signal.direction.equals(InteractionDirection.SEND)) {
				port = getPort(scenarioStatechartUtil.getTurnedOutPortName(signal.port))
			} else {
				port = getPort(signal.port.name)
			}
			event = getEvent(signal.event.name, port)
			var eventRef = createPortEventReference
			eventRef.event = event
			eventRef.port = port
			t.eventReference = eventRef

			var unary = createUnaryTrigger
			unary.operand = t
			unary.type = UnaryType.NOT
			return unary
		}

		return t
	}

	def protected dispatch Action getRaiseEventAction(Signal s, boolean reversed) {
		var a = createRaiseEventAction
		var port2 = createPort;
		if (reversed)
			port2 = getPort(scenarioStatechartUtil.getTurnedOutPortName(s.port))
		else
			port2 = getPort(s.port.name)
		a.event = getEvent(s.event.name, port2)
		a.port = port2
		for (p : (s as Signal).arguments)
			a.arguments.add(ecureUtil.clone(p))
		return a
	}

	def protected dispatch Action getRaiseEventAction(Delay s, boolean reversed) {
		return null
	}

	def protected dispatch Action getRaiseEventAction(NegatedModalInteraction s, boolean reversed) {
		return null
	}

	def protected VariableDeclaration createIntegerVariable(String name) {
		var variable = createVariableDeclaration
		variable.name = name
		var e = createIntegerLiteralExpression
		e.value = BigInteger.valueOf(0)
		variable.expression = e
		var type = createIntegerTypeDefinition
		variable.type = type
		return variable
	}

	def protected Expression getIntVariableValue(VariableDeclaration d) {
		var e = createIntegerLiteralExpression
		var tmp = (d.expression as IntegerLiteralExpression).value
		e.value = tmp
		return e
	}

	def protected StateNode getState(String name) {
		for (s : statechart.regions.get(0).stateNodes)
			if (s.name.equals(name))
				return s
		return null
	}

	def protected Port getPort(String name) {
		for (s : statechart.ports)
			if (s.name.equals(name))
				return s
		return null
	}

	def protected Event getEvent(String name, Port port) {
		for (s : port.interfaceRealization.interface.events)
			if (s.event.name.equals(name))
				return s.event
		return null
	}

	def protected ChoiceState addChoiceState() {
		exsistingChoices++;
		var choice = createChoiceState
		var name = String.valueOf("Choice" + exsistingChoices++)
		choice.name = name
		return choice
	}

	def protected createNewState(String name) {
		var state = createState
		state.name = name
		return state
	}

	def protected initializeStateChart(String scenarioName) {
		statechart.transitionPriority = TransitionPriority.VALUE_BASED
		statechart.name = scenarioName
		var region = createRegion
		region.name = "region"
		statechart.regions.add(region)

		statechart.variableDeclarations.add(createIntegerVariable("result"))
		statechart.variableDeclarations.add(createIntegerVariable("IteratingVariable"))
		statechart.variableDeclarations.add(createIntegerVariable("LoopIteratingVariable"))

		var initial = createInitialState
		initial.name = scenarioStatechartUtil.initial
		region.stateNodes.add(initial)

		var s = createState
		s.name = "firstState"
		region.stateNodes.add(s)
		previousState = s

		var t = createTransition
		t.sourceState = initial
		t.targetState = s
		t.effects += setIntVariable(0, 1)
		t.effects += setIntVariable(2, 1)
		statechart.transitions.add(t)

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
	}

	def protected addPorts(Component c) {
		for (p : c.ports) {
			var pcopy = createPort
			var iReali = createInterfaceRealization
			iReali.realizationMode = p.interfaceRealization.realizationMode
			iReali.interface = p.interfaceRealization.interface
			pcopy.interfaceRealization = iReali
			pcopy.name = p.name
			statechart.ports.add(pcopy)
			var preverse = createPort
			preverse.name = scenarioStatechartUtil.getTurnedOutPortName(p)
			var iRealiR = createInterfaceRealization
			iRealiR.interface = p.interfaceRealization.interface
			iRealiR.realizationMode = p.interfaceRealization.realizationMode.opposite
			preverse.interfaceRealization = iRealiR
			statechart.ports.add(preverse)
		}
	}
}
