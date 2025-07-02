/********************************************************************************
 * Copyright (c) 2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.OpaqueExpression
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.OnCycleTrigger
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.transformation.util.UnfoldedExecutionTraceBackAnnotator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.util.Collection
import java.util.regex.Pattern

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class DeterminismCheckPostprocessor extends VerificationPostprocessor {
	//
	protected final extension ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	//
	override execute(Collection<? extends Result> results) {
		return results.map[it.execute]
				.toList
	}
	
	def execute(Result result) {
		val trace = result.trace
		if (trace !== null) {
			return trace.execute
		}
	}
	
	def execute(Iterable<? extends ExecutionTrace> traces) {
		return traces.map[it.execute]
				.toList
	}
	
	// TODO unfolded traces or original traces? Probably both
	def execute(ExecutionTrace trace) {
		val steps = trace.steps
		val beforeLastStep = steps.beforeLastElement
		val lastStep = steps.lastElement
		
		val lastStateAsserts = lastStep.asserts
		val beforeLastStepStates = beforeLastStep.instanceStateConfigurations
		
		val nondeterministicStates = newArrayList
		val nondeterministicTransitions = newArrayList
		
		// TODO for unfolded traces, too
		val stringBeginning = UnfoldedExecutionTraceBackAnnotator.TRAP_STATE_MESSAGE_BEGINNING
		val trapStateEntries = lastStateAsserts.filter(OpaqueExpression)
				.filter[it.expression.startsWith(stringBeginning)]
		for (trapStateEntry : trapStateEntries) {
			// Parsing non-deterministic instance and region
			val string = trapStateEntry.expression
			val pattern = Pattern.compile('''«stringBeginning» region (.*) of (.*)''')
			val matcher = pattern.matcher(string)
			if (!matcher.find) {
				throw new IllegalArgumentException("Not found pattern: " + string)
			}
			
			val regionName = matcher.group(1)
			val instanceName = matcher.group(2)
			
			// Selecting next to last control location (state)
			val nondeterministicState = beforeLastStepStates.filter[
					it.instance.componentInstanceChain.map[it.name].join(".") == instanceName &&
					it.region.name == regionName]
					.onlyElement
			nondeterministicStates += nondeterministicState
					
			val state = nondeterministicState.state
			println('''Found nondeterministic state «state.name» in region «regionName» of «instanceName»''')
		}
		
		// Note: 'timing' (elapse) does not work
		val acts = beforeLastStep.actions
		val simpleRaiseEvents = acts.filter(RaiseEventAct)
				.map[pe | pe.port.allBoundSimplePorts.map[it.createRaiseEventAction(pe.event, pe.arguments)]]
				.flatten
		for (nondeterministicState : nondeterministicStates) {
			val step = nondeterministicState.containingStep
			val variables = step.uniqueInstanceVariableStates
			val variableValues = variables.map[it -> it.otherOperandIfContainedByEquality].toList
			
			val state = nondeterministicState.state
			
			val transitions = state.outgoingTransitions
			for (transition : transitions) {
				if (transition.isEnabled(simpleRaiseEvents, variableValues)) {
					nondeterministicTransitions += transition
				}
			}
		}
		
		println(nondeterministicTransitions)
		
		return new Object
	}
	
	protected def isEnabled(Transition transition,
			Iterable<? extends RaiseEventAction> acts,
			Iterable<? extends Pair<ComponentInstanceVariableReferenceExpression, Expression>> values) {
		val trigger = transition.trigger
		val guard = transition.guard
		
		val isTriggerCovered = trigger.isCoveredBy(acts)
		val isGuardTrue = guard.evaluate(acts, values)
		
		return isTriggerCovered && isGuardTrue
	}
	
	//
	
	protected def dispatch boolean isCoveredBy(EventTrigger trigger, Iterable<? extends RaiseEventAction> acts) {
		val eventReference = trigger.eventReference
		// Note: NO timed transitions
		val inputEvents = eventReference.inputEvents
		return inputEvents.exists[pe | acts.exists[it.port == pe.key && it.event == pe.value]]
	}
	
	protected def dispatch boolean isCoveredBy(AnyTrigger trigger, Iterable<? extends RaiseEventAction> acts) {
		return !acts.empty
	}
	
	protected def dispatch boolean isCoveredBy(OnCycleTrigger trigger, Iterable<? extends RaiseEventAction> acts) {
		return true
	}

	protected def dispatch boolean isCoveredBy(BinaryTrigger trigger, Iterable<? extends RaiseEventAction> acts) {
		val lhs = trigger.leftOperand
		val rhs = trigger.rightOperand
		
		val evalLhs = lhs.isCoveredBy(acts)
		val evalRhs = rhs.isCoveredBy(acts)
		
		val type = trigger.type
		
		return
		switch (type) {
			case AND: evalLhs && evalRhs
			case EQUAL: evalLhs == evalRhs
			case IMPLY: !evalLhs || evalRhs
			case OR: evalLhs || evalRhs
			case XOR: evalLhs && !evalRhs || !evalLhs && evalRhs
			default: throw new IllegalArgumentException("Not known trigger type: " + type)
		}
	}
	
	protected def dispatch boolean isCoveredBy(UnaryTrigger trigger, Iterable<? extends RaiseEventAction> acts) {
		val operand = trigger.operand
		val evalOperand = operand.isCoveredBy(acts)
		
		val type = trigger.type
		
		return
		switch (type) {
			case NOT: !evalOperand
			default: throw new IllegalArgumentException("Not known trigger type: " + type)
		}
	}
	
	//
	
	protected def boolean evaluate(Expression expression,
			Iterable<? extends RaiseEventAction> acts,
			Iterable<? extends Pair<ComponentInstanceVariableReferenceExpression, Expression>> values) {
		val clone = expression.clone
		
		// Works for records too, as there is a record literal in the trace
		val variableReferences = clone.getSelfAndAllContentsOfType(DirectReferenceExpression)
		for (variableReference : variableReferences) {
			val declaration = variableReference.accessedDeclaration
			val value = values.filter[it.key.variableDeclaration == declaration]
					.map[it.value]
					.onlyElement
					.clone
			value.replace(variableReference)
		}
		
		// Note: does not work for 'persistent' events
		val eventReferences = clone.getSelfAndAllContentsOfType(EventParameterReferenceExpression)
		for (eventReference : eventReferences) {
			val port = eventReference.port
			val event = eventReference.event
			val parameter = eventReference.parameter
			val i = parameter.index
			
			val act = acts.filter[it.port == port && it.event == event].lastElement
			if (act !== null) {
				val arguments = act.arguments
				val argument = arguments.get(i)
				argument.replace(eventReference)
			}
		}
		
		val evaluation = clone.evaluateBoolean
		return evaluation
	}
	
}