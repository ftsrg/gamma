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
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.scenario.statechart.util.ScenarioStatechartUtil
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.math.BigInteger
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TraceGenUtil {
	
	public static final TraceGenUtil INSTANCE =  new TraceGenUtil
	protected new() {}
	
	protected val extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected val extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	protected val extension ExpressionModelFactory exprFactory = ExpressionModelFactory.eINSTANCE
	protected val extension ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE
	
	
	def ExecutionTrace mergeLastStepOfTraces(List<ExecutionTrace> traces) {
		if(traces.size == 1) {
			return traces.head
		}
		val lastSteps = traces.map[it.steps.lastOrNull]
		val or = createOrExpression
		or.operands += lastSteps.flatMap[it.asserts.clone].filterNull
		val result = traces.head
		val lastAsserts = result.steps.lastOrNull.asserts
		if (or.operands.size >= 2) {
			lastAsserts.clear
			lastAsserts += or
		}
		else if (or.operands.size == 1) {
			lastAsserts.clear
			lastAsserts += or.operands.head
		}
		else {
			//nop
		}
		return result
	}
	
	def backAnnotateNegsChecksAndAssigns(Component component, ExecutionTrace trace) {
		val stateChecks = <State>newArrayList
		for (step : trace.steps) {
			val stateCheck = step.asserts.filter(ComponentInstanceStateReferenceExpression).head
			stateChecks += stateCheck.state
		}
		for (var i = 0; i < stateChecks.size - 1; i++) {
			val current = stateChecks.get(i)
			val next = stateChecks.get(i+1)
			val transitions = findTransitionChain(current, next, <Transition>newArrayList, <StateNode>newArrayList)
			
			val correctTransitions = transitions.findForwardTransitions
			
			val checks = findCheckBasedGuards(correctTransitions).filterNull
			val assignments = findAssignmentBasedActions(correctTransitions).filterNull
			val negInteractions = finNegatedInteractions(correctTransitions).filterNull
			
			val currentStep = trace.steps.get(i+1)
			
			val nextStep = if (trace.steps.size > i+2) {
					trace.steps.get(i+2)
				} else {
					val newStep = createStep
					trace.steps += newStep
					newStep
				}
			
			
			for (assignment : assignments) {
				val traceAssign = createAssignmentAct
				traceAssign.rhs = assignment.rhs.clone
				traceAssign.lhs = assignment.lhs.clone
				nextStep.actions.add(0,traceAssign)
				traceAssign.rhs.fixParamRefs(trace.component, currentStep)
			}
			
			for (check : checks) {
				val clone = check.clone
				currentStep.asserts += clone
				clone.fixParamRefs(trace.component, currentStep)
			}
		}
	}
	
	def List<Transition> findForwardTransitions(List<Transition> transitions){
		transitions.filter[it.priority >= BigInteger.valueOf(2)].toList
	}
	
	def fixParamRefs(Expression expression, Component component, Step step) {
		val refs = expression.getAllContentsOfType(EventParameterReferenceExpression)
		if (expression instanceof EventParameterReferenceExpression) {
			refs += expression
		}
		val raiseEventActs = step.actions.filter(RaiseEventAct)
		for (ref : refs) {
			var foundMatch = false
			for (act : raiseEventActs) {
				if (act.port.name == ref.port.name && act.event.name == ref.event.name) {
					val arguments = act.arguments
					val params = act.event.parameterDeclarations
					for (var i = 0; i < params.size; i++) {
						if (ref.parameter.name == params.get(i).name) {
							val clone = arguments.get(i).clone
							ecoreUtil.changeAndReplace(clone, ref, ref.eContainer)
							foundMatch = true
						}
					}
				}
			}
			if (!foundMatch) {
				if (scenarioStatechartUtil.isTurnedOut(ref.port)) {
					ref.port = component.getPort(scenarioStatechartUtil.getTurnedOutPortName(ref.port))
				} else {
					ref.port = component.getPort(ref.port.name)
				}
				ref.event = ref.port.getEvent(ref.event.name)
				ref.parameter = ref.event.getEventParam(ref.parameter.name)
			}
		}
	}
	
	def getPort(Component component, String name) {
		component.ports.findFirst[it.name == name]
	}

	def getEvent(Port port, String name) {
		port.interfaceRealization.interface.events.findFirst[it.event.name == name]?.event
	}
	
	def getEventParam(Event event, String paramName) {
		event.parameterDeclarations.findFirst[it.name == paramName]
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
			.filter[!((it.lhs as DirectReferenceExpression).declaration as VariableDeclaration).name.startsWith("__id_")]
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