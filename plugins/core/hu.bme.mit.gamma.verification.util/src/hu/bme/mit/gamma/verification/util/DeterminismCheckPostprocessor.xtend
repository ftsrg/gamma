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
import hu.bme.mit.gamma.expression.model.VariableDeclaration
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
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer
import hu.bme.mit.gamma.statechart.util.TriggerSerializer
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.TimeElapse
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
	protected final extension TriggerSerializer triggerSerializer = TriggerSerializer.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
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
	
	def execute(ExecutionTrace trace) {
		val steps = trace.steps
		val beforeLastStep = steps.beforeLastElement
		val lastStep = steps.lastElement
		
		val lastStateAsserts = lastStep.asserts
		val beforeLastStepStates = beforeLastStep.instanceStateConfigurations
		
		val nondeterministicStates = newArrayList
		val nondeterministicTransitions = newArrayList
		val trapStates = newArrayList // If any, in the case of unfolded traces
		
		val unfolded = trace.unfolded
		if (unfolded) {
			val trapStateId = UnfoldedExecutionTraceBackAnnotator.TRAP_STATE_ID
			
			trapStates += lastStep.instanceStateConfigurations
					.filter[it.state.name == trapStateId]
			val regions = trapStates.map[it.region]
			nondeterministicStates += beforeLastStepStates
					.filter[regions.contains(it.region)]
		}
		else {
			// Original model
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
						it.instance.name == instanceName && it.region.name == regionName]
						.onlyElement
				nondeterministicStates += nondeterministicState
			}
		}
		
		nondeterministicStates.forEach[
				println('''Found nondeterministic state «state.name» in region «
						region.name» of «instance.name»''')]
		
		// TODO add time lapse - will not always be sound due to self-loops
		val persistentRaiseEvents = trace.persistentRaiseEvents
		val lastRaiseEvents = lastStep.actions.filter(RaiseEventAct)
		
		for (nondeterministicState : nondeterministicStates) {
			val step = nondeterministicState.containingStep
			val variables = step.uniqueInstanceVariableStates
			val variableValues = variables.map[it -> it.otherOperandIfContainedByEquality].toList
			
			val instance = nondeterministicState.instance
			val state = nondeterministicState.state
			
			val transitions = state.outgoingTransitions
					.reject[trapStates.map[it.state].contains(it.targetState)]
			if (transitions.size <= 2) {
				// No need to compute anything - two transitions are needed for nondeterministic behavior
				nondeterministicTransitions += transitions
			}
			else {
				val instancePortFilter = [ Iterable<? extends RaiseEventAction> rea |
						rea.filter[unfolded || // No need to filter port bindings by name
								it.port.allBoundInstances.map[it.name].contains(instance.name)]
						.map[pe | pe.port.allBoundSimplePorts
						.map[it.createRaiseEventAction(pe.event, pe.arguments.clone)]]
						.flatten ]
				val instancePersistentRaiseEvents = instancePortFilter.apply(persistentRaiseEvents)
				val instanceLastRaiseEvents = instancePortFilter.apply(lastRaiseEvents)
				// TODO add parameter declarations (will be hard)
				val instanceVariableValues = variableValues
						.filter[it.key.instance.name == instance.name]
				
				// Partitioning the outgoing transitions of the non-deterministic state
				val enabledTransitions = newLinkedHashSet
				val unevaluableTransitions = newLinkedHashSet
				for (transition : transitions) {
					try {
						if (transition.isEnabled(instancePersistentRaiseEvents,
									instanceLastRaiseEvents, instanceVariableValues)) {
							enabledTransitions += transition
						}
					} catch (IllegalArgumentException e) {
						// Unevaluable trigger or guard
						unevaluableTransitions += transition
					}
				}
				
				// Determining non-deterministic transitions
				nondeterministicTransitions += enabledTransitions
				if (enabledTransitions.size < 2 && enabledTransitions.size + unevaluableTransitions.size == 2) {
					nondeterministicTransitions += unevaluableTransitions
				}
				// Note that 'nondeterministicTransitions.size' my still be ' < 2' here
			}
		}
		
		// Pretty printing
		for (transition : nondeterministicTransitions) {
			val trigger = transition.trigger
			val guard = transition.guard
			
			println('''«transition.sourceState.name»  -> «transition.targetState.name» when «
					trigger.serialize» [«guard.serialize»]''')
		}
		//
		
		return new Object
	}
	
	//
	
	protected def getPersistentRaiseEvents(ExecutionTrace trace) {
		val persistentActs = newLinkedHashSet
		
		val component = trace.component
		val ports = component.allPorts
		
		for (port : ports) {
			val persistentEvents = port.allEvents.filter[it.persistent]
			for (event : persistentEvents) {
				persistentActs += port.createRaiseEventAction(event)
			}
		}
		
		val steps = trace.steps
		for (step : steps) {
			val acts = step.actions.filter(RaiseEventAction)
			for (act : acts) {
				val port = act.port
				val event = act.event
				if (event.persistent) {
					// Removing the old value
					persistentActs.removeIf[it.port == port && it.event == event]
					// Adding the new value
					persistentActs += act.clone
				}
			}
		}
		
		return persistentActs
	}
	
	protected def getEnabledTimeouts(ExecutionTrace trace) {
		val reverseSteps = trace.steps.reverseView
		for (var i = 0; i < reverseSteps.size - 1; i++) {
			val step = reverseSteps.get(i)
			val previousStep = reverseSteps.get(i + 1)
			
			val timeElapses = step.actions.filter(TimeElapse)
			val states = previousStep.instanceStateConfigurations
			
		}
	
	}
	
	//
	
	protected def isEnabled(Transition transition,
			Iterable<? extends RaiseEventAction> persistentActs,
			Iterable<? extends RaiseEventAction> acts,
			Iterable<? extends Pair<ComponentInstanceVariableReferenceExpression, Expression>> values) {
		val trigger = transition.trigger
		val guard = transition.guard
		
		val isTriggered = trigger.isTriggeredBy(acts) // Contains persistent raises, too
		val isGuardTrue = guard.evaluate(persistentActs + acts, values) // Persistent values AND simple raises (order matters due to .lastElement call)
		
		return isTriggered && isGuardTrue
	}
	
	//
	
	protected def dispatch boolean isTriggeredBy(EventTrigger trigger, Iterable<? extends RaiseEventAction> acts) {
		val eventReference = trigger.eventReference
		// Note: NO timed transitions
		val inputEvents = eventReference.inputEvents
		return inputEvents.exists[pe | acts.exists[it.port == pe.key && it.event == pe.value]]
	}
	
	protected def dispatch boolean isTriggeredBy(AnyTrigger trigger, Iterable<? extends RaiseEventAction> acts) {
		return !acts.empty
	}
	
	protected def dispatch boolean isTriggeredBy(OnCycleTrigger trigger, Iterable<? extends RaiseEventAction> acts) {
		return true
	}

	protected def dispatch boolean isTriggeredBy(BinaryTrigger trigger, Iterable<? extends RaiseEventAction> acts) {
		val lhs = trigger.leftOperand
		val rhs = trigger.rightOperand
		
		val evalLhs = lhs.isTriggeredBy(acts)
		val evalRhs = rhs.isTriggeredBy(acts)
		
		val type = trigger.type
		
		return switch (type) {
			case AND: evalLhs && evalRhs
			case EQUAL: evalLhs == evalRhs
			case IMPLY: !evalLhs || evalRhs
			case OR: evalLhs || evalRhs
			case XOR: evalLhs && !evalRhs || !evalLhs && evalRhs
			default: throw new IllegalArgumentException("Not known trigger type: " + type)
		}
	}
	
	protected def dispatch boolean isTriggeredBy(UnaryTrigger trigger, Iterable<? extends RaiseEventAction> acts) {
		val operand = trigger.operand
		val evalOperand = operand.isTriggeredBy(acts)
		
		val type = trigger.type
		
		return switch (type) {
			case NOT: !evalOperand
			default: throw new IllegalArgumentException("Not known trigger type: " + type)
		}
	}
	
	//
	
	protected def boolean evaluate(Expression expression,
			Iterable<? extends RaiseEventAction> acts,
			Iterable<? extends Pair<ComponentInstanceVariableReferenceExpression, Expression>> values) {
		val clone = expression.clone
		
		// Note: works for records too, as there is a maximal record literal in the trace
		val variableReferences = clone.getSelfAndAllContentsOfType(DirectReferenceExpression)
		for (variableReference : variableReferences) {
			val variable = variableReference.accessedDeclaration as VariableDeclaration
			val variableValues = values
					.filter[it.key.variableDeclaration == variable]
					.map[it.value]
			val value = (!variableValues.empty) ?
					variableValues.onlyElement :
					(variable.unwritten) ?
						variable.initialValue :
						throw new IllegalArgumentException("Not known value") // Model reduction or slicing
			
			value.replace(variableReference)
		}
		
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
		
		val evaluation = clone.evaluateBoolean // Takes care of constant declarations
		return evaluation
	}
	
}