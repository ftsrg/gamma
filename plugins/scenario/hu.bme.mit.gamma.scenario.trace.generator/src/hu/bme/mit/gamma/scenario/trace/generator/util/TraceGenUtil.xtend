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
package hu.bme.mit.gamma.scenario.trace.generator.util

import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.math.BigInteger
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TraceGenUtil {
	
	public static final TraceGenUtil INSTANCE =  new TraceGenUtil
	protected new() {}
	
	val extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	val extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	
	def ExecutionTrace mergeLastStepOfTraces(List<ExecutionTrace> traces) {
		if(traces.size == 1) {
			return traces.head
		}
		val lastSteps = traces.map[it.steps.last]
		val or = createOrAssert
		or.asserts += lastSteps.flatMap[it.asserts.clone]
		val result = traces.head
		result.steps.last.asserts.clear
		result.steps.last.asserts += or
		return result
	}
	
		def backAnnotateNegsChecksAndAssigns(Component component, ExecutionTrace trace) {
		val stateChecks = <State>newArrayList
		for (step : trace.steps) {
			val stateCheck = step.asserts.filter(InstanceStateConfiguration).head
			stateChecks += stateCheck.state
		}
		for (var i = 0; i < stateChecks.size - 1; i++) {
			val current = stateChecks.get(i)
			val next = stateChecks.get(i+1)
			val transitions = findTransitionChain(current, next, <Transition>newArrayList, <StateNode>newArrayList)
			val correctTransitions = transitions.filter[it.priority >= BigInteger.valueOf(2)].toList
			
			val checks = findCheckBasedGuards(correctTransitions)
			val assignments = findAssignmentBasedActions(correctTransitions)
			val negInteractions = finNegatedInteractions(correctTransitions)
			
			
			//TODO add to 
		}
		return null
	}
	
	def List<EventTrigger> finNegatedInteractions(List<Transition> transitions) {
		return transitions
			.map[it.trigger]
			.map[ecoreUtil.getAllContentsOfType(it, UnaryTrigger)]
			.flatten
			.filter[it.type == UnaryType.NOT && it.operand instanceof EventTrigger]
			.map[it.operand as EventTrigger]
			.toList
	}
	
	def List<AssignmentStatement> findAssignmentBasedActions(List<Transition> transitions) {
		return transitions
			.map[it.effects]
			.flatten
			.filter(AssignmentStatement)
			.toList
	}
	
	def List<Expression> findCheckBasedGuards(List<Transition> transitions) {
		return transitions
			.map[it.guard]
			.toList
	}
	
	def List<Transition> findTransitionChain(StateNode current, StateNode target, List<Transition> transitions, List<StateNode> states) {
		val resultTransitions = <Transition>newArrayList
		for (transition : current.outgoingTransitions) {
			val outgoingTarget = transition.targetState
			if (outgoingTarget == target) {
				transitions += transition
				return transitions
			} else {
				if (states.contains(outgoingTarget)) {
					//nop
				} else {
					val transitionsCopy = <Transition>newArrayList(transitions)
					val statesCopy = <StateNode>newArrayList(states)
					statesCopy += outgoingTarget
					transitionsCopy += transition
					resultTransitions += findTransitionChain(outgoingTarget,target,transitionsCopy, statesCopy)
				}
			}
		}
		return resultTransitions		
	}
}