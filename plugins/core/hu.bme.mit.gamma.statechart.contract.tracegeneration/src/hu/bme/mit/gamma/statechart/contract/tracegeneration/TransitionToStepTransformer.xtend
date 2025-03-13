/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.contract.tracegeneration

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression
import hu.bme.mit.gamma.expression.model.GreaterExpression
import hu.bme.mit.gamma.expression.model.LessEqualExpression
import hu.bme.mit.gamma.expression.model.LessExpression
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.OnCycleTrigger
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.Act
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class TransitionToStepTransformer {

	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected final extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	def execute(Transition transition) {
		val step = createStep
		// Acts
		step.actions += transition.trigger.transformTrigger
		val guard = transition.guard
		if (guard !== null) {
			step.actions += transition.guard.transformExpression
		}
		if (transition.targetState instanceof State) {
			step.actions += createComponentSchedule
		}
		// Assertions
		for (action : transition.effects.filter(RaiseEventAction)) {
			step.outEvents += action.transformAction
		}
		return step
	}
	
	// Triggers
	
	private def dispatch Collection<Act> transformTrigger(EventTrigger trigger) {
		return #[trigger.eventReference.transformEventReference]
	}
	
	private def dispatch Collection<Act> transformTrigger(OnCycleTrigger trigger) {
		return #[]
	}
	
	private def dispatch Collection<Act> transformTrigger(BinaryTrigger trigger) {
		val acts = newArrayList
		val triggerType = trigger.type
		switch (triggerType) {
			case AND: {
				acts += trigger.leftOperand.transformTrigger
				acts += trigger.rightOperand.transformTrigger
			}
			default:
				throw new IllegalArgumentException("Not transformable trigger: " + trigger)
		}
		return acts
	}
	
	private def dispatch transformEventReference(PortEventReference eventReference) {
		return createRaiseEventAct => [
			it.port = eventReference.port
			it.event = eventReference.event
			// Arguments are transformed in the guards
		]
	}
	
	private def dispatch transformEventReference(TimeoutEventReference eventReference) {
		val timeout = eventReference.timeout
		val value = timeout.timeoutValue
		val elapsedTime = value.evaluateMilliseconds
		return createTimeElapse => [
			it.elapsedTime = elapsedTime.toIntegerLiteral
		]
	}
	
	// Guards: only AndExpressions, equalityExpressions and EventParameterReferenceExpressions
	
	private def Collection<Act> transformExpression(Expression expression) {
		val Collection<Act> acts = newArrayList
		val parameterValues = expression.calculateParameterValue
		for (portGroup : parameterValues.groupBy[it.key.port].entrySet) {
			val port = portGroup.key
			for (eventGroup : portGroup.value.groupBy[it.key.event].entrySet) {
				val event = eventGroup.key
				val parameterSize = event.parameterDeclarations.size
				val act = createRaiseEventAct => [
					it.port = port
					it.event = event
					for (var i = 0; i < parameterSize; i++) {
						it.arguments += createFalseExpression // As we do not know the order of parameters
					}
				]
				acts += act
				for (parameterGroup : eventGroup.value.groupBy[it.key.parameter].entrySet) {
					val parameter = parameterGroup.key
					val parameterIndex = event.parameterDeclarations.indexOf(parameter)
					val value = parameterGroup.value.lastOrNull.value // Last assigned expression
					act.arguments.set(parameterIndex, value) // Resetting the false expression
				}
			}
		}
		return acts
	}
	
	private def dispatch List<Pair<EventParameterReferenceExpression, Expression>> calculateParameterValue(Expression expression) {
		throw new IllegalArgumentException("Not supported expression: " + expression)
	}
	
	private def dispatch List<Pair<EventParameterReferenceExpression, Expression>> calculateParameterValue(AndExpression expression) {
		val acts = newArrayList
		for (subexpression : expression.operands) {
			acts += subexpression.calculateParameterValue
		}
		return acts
	}
	
	private def dispatch List<Pair<EventParameterReferenceExpression, Expression>> calculateParameterValue(EqualityExpression expression) {
		val eventParameterReference	= expression.findEventParameterReferenceExpression
		val value = expression.calculateEventParameterReferenceExpressionValue
		return #[new Pair(eventParameterReference, value)]
	}
	
	private def dispatch List<Pair<EventParameterReferenceExpression, Expression>> calculateParameterValue(LessEqualExpression expression) {
		val eventParameterReference	= expression.findEventParameterReferenceExpression
		val value = expression.calculateEventParameterReferenceExpressionValue
		return #[new Pair(eventParameterReference, value)]
	}
	
	private def dispatch List<Pair<EventParameterReferenceExpression, Expression>> calculateParameterValue(GreaterEqualExpression expression) {
		val eventParameterReference	= expression.findEventParameterReferenceExpression
		val value = expression.calculateEventParameterReferenceExpressionValue
		return #[new Pair(eventParameterReference, value)]
	}
	
	private def dispatch List<Pair<EventParameterReferenceExpression, Expression>> calculateParameterValue(LessExpression expression) {
		val eventParameterReference	= expression.findEventParameterReferenceExpression
		var value = expression.calculateEventParameterReferenceExpressionValue
		if (expression.leftOperand == eventParameterReference) {
			value = value.subtract(1)
		}
		else {
			value = value.add(1)
		}
		return #[new Pair(eventParameterReference, value)]
	}
	
	private def dispatch List<Pair<EventParameterReferenceExpression, Expression>> calculateParameterValue(GreaterExpression expression) {
		val eventParameterReference	= expression.findEventParameterReferenceExpression
		var value = expression.calculateEventParameterReferenceExpressionValue
		if (expression.leftOperand == eventParameterReference) {
			value = value.add(1)
		}
		else {
			value = value.subtract(1)
		}
		return #[new Pair(eventParameterReference, value)]
	}
	
	// Finding the values of the parameters
	
	private def findEventParameterReferenceExpression(Expression expression) {
		checkState(expression.eContents.size == 2)
		val expressions = expression.eContents.filter(EventParameterReferenceExpression)
		checkState(expressions.size == 1)
		return expressions.head
	}
	
	private def calculateEventParameterReferenceExpressionValue(Expression expression) {
		checkState(expression.eContents.size == 2)
		val foundExpression = expression.eContents.filter(Expression)
			.filter[it !== expression.findEventParameterReferenceExpression].head
		return foundExpression.clone
	}
	
	// Out events
	
	private dispatch def transformAction(Action action) {
		throw new IllegalArgumentException("Not known action: " + action)
	}
	
	private dispatch def transformAction(RaiseEventAction action) {
		return createRaiseEventAct => [
			it.port = action.port
			it.event = action.event
			for (argument : action.arguments) {
				it.arguments += argument.clone
			}
		]
	}
	
}