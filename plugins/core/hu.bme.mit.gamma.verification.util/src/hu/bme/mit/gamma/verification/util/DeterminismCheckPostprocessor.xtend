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

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.OpaqueExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.ClockTickReference
import hu.bme.mit.gamma.statechart.statechart.OnCycleTrigger
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.transformation.util.UnfoldedExecutionTraceBackAnnotator
import java.util.Collection
import java.util.List
import java.util.Map.Entry
import java.util.regex.Pattern

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class DeterminismCheckPostprocessor extends VerificationPostprocessor {
	//
	protected final List<Collection<? extends Entry<
			ComponentInstanceReferenceExpression, Transition>>> nondeterministicTransitions = newArrayList
	//
	
	override execute(ExecutionTrace trace) {
		trace.saveTrace
		
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
		
		val persistentRaiseEvents = trace.persistentRaiseEvents
		val lastRaiseEvents = lastStep.actions.filter(RaiseEventAct)
		val enabledTimeouts = trace.enabledTimeouts // Note: not complete
		
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
				nondeterministicTransitions += transitions.map[instance.createTransitionReference(it)]
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
				val instanceEnabledTimeouts = enabledTimeouts
						.filter[it.key.name == instance.name].map[it.value]
				// TODO add parameter declarations (will be hard)
				val instanceVariableValues = variableValues
						.filter[it.key.instance.name == instance.name]
						.map[it.key.variableDeclaration -> it.value]
				
				// Partitioning the outgoing transitions of the non-deterministic state
				val enabledTransitions = newLinkedHashSet
				val unevaluableTransitions = newLinkedHashSet
				for (transition : transitions) {
					try {
						if (transition.isEnabled(instancePersistentRaiseEvents,
									instanceLastRaiseEvents, instanceEnabledTimeouts, instanceVariableValues)) {
							enabledTransitions += instance.createTransitionReference(transition)
						}
					} catch (IllegalArgumentException e) {
						// Unevaluable trigger or guard
						unevaluableTransitions += instance.createTransitionReference(transition)
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
			println(elementSerializer.serialize(transition.value))
		}
		//
		
		this.nondeterministicTransitions += nondeterministicTransitions
		
		return nondeterministicTransitions
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
		val enabledTimeouts = newHashSet
		val setTimeouts = newHashMap
		
		var elapsedTime = 0
		val reverseSteps = trace.steps.reverseView
		for (var i = 0; i < reverseSteps.size - 1; i++) {
			val step = reverseSteps.get(i)
			val previousStep = reverseSteps.get(i + 1)
			
			val timeElapses = step.actions.filter(TimeElapse)
			val states = previousStep.instanceStateConfigurations
			
			elapsedTime = timeElapses.map[it.elapsedTime.evaluateInteger]
					.fold(elapsedTime, [p1, p2 | p1 + p2])
			val elapsedTimeSpecification = elapsedTime.createTimeSpecification(
					trace.timeUnitAnnotation.timeUnit)
			
			for (instanceState : states) {
				val instance = instanceState.instance
				val state = instanceState.state
				val setTimeoutActions = state.entryActions.filter(SetTimeoutAction)
				for (setTimeout : setTimeoutActions) {
					val timeout = setTimeout.timeoutDeclaration
					val time = setTimeout.time
					
					val instanceTimeout = instance -> timeout
					val instanceNameTimeout = instance.name -> timeout
					
					if (!setTimeouts.containsKey(instanceNameTimeout) ||
								setTimeouts.get(instanceNameTimeout) == state) {
						if (i == 0 ||
								state.ancestorsAndSelf.map[it.loopTransitions].flatten.empty) {
							if (time.isLessThanOrEqualTo(elapsedTimeSpecification)) {
								enabledTimeouts += instanceTimeout
							}
						}
						
						setTimeouts += instanceNameTimeout -> state
					}
				}
				
				// No support for set timeout actions on transitions and in state exit actions
				val undhandledSetTimeoutActions = newHashSet
				undhandledSetTimeoutActions += state.incomingTransitions.map[it.effects].flatten.filter(SetTimeoutAction)
				undhandledSetTimeoutActions += state.exitActions.filter(SetTimeoutAction)
				
				val undhandledSetTimeouts = undhandledSetTimeoutActions.map[it.timeoutDeclaration]
				for (undhandledSetTimeout : undhandledSetTimeouts) {
					val instanceNameTimeout = instance.name -> undhandledSetTimeout
					setTimeouts += instanceNameTimeout -> null
				}
			}
		}
		
		return enabledTimeouts
	}
	
	//
	
	protected def isEnabled(Transition transition,
			Iterable<? extends RaiseEventAction> persistentActs,
			Iterable<? extends RaiseEventAction> acts,
			Iterable<? extends TimeoutDeclaration> timeouts,
			Iterable<? extends Pair<? extends Declaration, Expression>> values) {
		val trigger = transition.trigger
		val guard = transition.guard
		
		var Boolean isTriggered = null
		var Boolean isGuardEnabled = null
		try {
			isTriggered = trigger.isTriggeredBy(acts, timeouts) // Contains persistent raises, too
			if (!isTriggered) {
				return false // Transition is not triggered; not worth evaluating the guard
			}
		} catch (IllegalArgumentException e) {}
		try {
			if (guard === null) {
				isGuardEnabled = true
			}
			else {
				isGuardEnabled = guard.evaluate(persistentActs + acts, values) // Persistent values AND simple raises
				if (!isGuardEnabled) {
					return false
				}
			}
		} catch (IllegalArgumentException e) {}
		
		// Analyzing the result: transition is enabled iff 'trigger is raised' && 'guard is true' (both evaluable)
		if (Boolean.TRUE.equals(isTriggered) && Boolean.TRUE.equals(isGuardEnabled)) {
			return true
		}
		
		throw new IllegalArgumentException("Unevaluable trigger or guard: " + transition)
	}
	
	//
	
	protected def dispatch boolean isTriggeredBy(EventTrigger trigger,
			Iterable<? extends RaiseEventAction> acts,
			Iterable<? extends TimeoutDeclaration> timeouts) {
		val eventReference = trigger.eventReference
		if (eventReference instanceof ClockTickReference) {
			throw new IllegalArgumentException("Unsupported time-related trigger: " + eventReference)
		}
		// Note: support for timed transitions is not complete
		if (eventReference instanceof TimeoutEventReference) {
			val timeout = eventReference.timeout
			return timeouts.contains(timeout)
		}
		
		val inputEvents = eventReference.inputEvents
		return inputEvents.exists[pe | acts.exists[it.port == pe.key && it.event == pe.value]]
	}
	
	protected def dispatch boolean isTriggeredBy(AnyTrigger trigger,
			Iterable<? extends RaiseEventAction> acts,
			Iterable<? extends TimeoutDeclaration> timeouts) {
		return !acts.empty
	}
	
	protected def dispatch boolean isTriggeredBy(OnCycleTrigger trigger,
			Iterable<? extends RaiseEventAction> acts,
			Iterable<? extends TimeoutDeclaration> timeouts) {
		return true
	}

	protected def dispatch boolean isTriggeredBy(BinaryTrigger trigger,
			Iterable<? extends RaiseEventAction> acts,
			Iterable<? extends TimeoutDeclaration> timeouts) {
		val lhs = trigger.leftOperand
		val rhs = trigger.rightOperand
		
		val evalLhs = lhs.isTriggeredBy(acts, timeouts)
		val evalRhs = rhs.isTriggeredBy(acts, timeouts)
		
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
	
	protected def dispatch boolean isTriggeredBy(UnaryTrigger trigger,
			Iterable<? extends RaiseEventAction> acts,
			Iterable<? extends TimeoutDeclaration> timeouts) {
		val operand = trigger.operand
		val evalOperand = operand.isTriggeredBy(acts, timeouts)
		
		val type = trigger.type
		
		return switch (type) {
			case NOT: !evalOperand
			default: throw new IllegalArgumentException("Not known trigger type: " + type)
		}
	}
	
	//
	
	protected def boolean evaluate(Expression expression,
			Iterable<? extends RaiseEventAction> acts,
			Iterable<? extends Pair<? extends Declaration, Expression>> values) {
		val clone = expression.clone
		
		// Note: works for records too, as there is a maximal record literal in the trace
		val variableReferences = clone.getSelfAndAllContentsOfType(DirectReferenceExpression)
		for (variableReference : variableReferences) {
			val variable = variableReference.accessedDeclaration as VariableDeclaration
			val variableValues = values
					.filter[it.key == variable]
					.map[it.value]
			val value = (!variableValues.empty) ?
					variableValues.onlyElement :
					(variable.unwritten) ?
						variable.initialValue :
						throw new IllegalArgumentException("Not known value") // Due to model reduction or slicing
			
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
		
		val evaluation = clone.evaluateBoolean // Takes care of constant declarations, too
		return evaluation
	}
	
	//
	
	def getNondeterministicTransitions() {
		return nondeterministicTransitions
	}
	
	//
	
}