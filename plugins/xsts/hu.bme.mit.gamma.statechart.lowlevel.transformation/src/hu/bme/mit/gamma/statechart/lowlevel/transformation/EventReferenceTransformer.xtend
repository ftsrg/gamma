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
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.statechart.ClockTickReference
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class EventReferenceTransformer {
	// Auxiliary objects
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	// Factory objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Trace
	protected final Trace trace
	
	new(Trace trace) {
		this(trace, true, 10)
	}
	
	new(Trace trace, boolean functionInlining, int maxRecursionDepth) {
		this.trace = trace
		this.expressionTransformer = new ExpressionTransformer(
				this.trace, functionInlining, maxRecursionDepth)
	}
	
	protected def transformToLowlevelGuard(EventDeclaration lowlevelEvent) {
		return lowlevelEvent.isRaised.createReferenceExpression
	}
	
	protected def dispatch Expression transformEventReference(AnyPortEventReference reference) {
		val port = reference.port
		val allEvents = trace.getAllLowlevelEvents(port, EventDirection.IN) // Considering only IN events
		val triggerGuards = newLinkedList
		for (event : allEvents) {
			triggerGuards += event.transformToLowlevelGuard
		}
		return createOrExpression => [
			it.operands += triggerGuards
		]
	}
	
	protected def dispatch Expression transformEventReference(ClockTickReference reference) {
		throw new UnsupportedOperationException("Clock references are not yet transformed: " + reference)
	}
	
	protected def dispatch Expression transformEventReference(PortEventReference reference) {
		val port = reference.port
		val event = reference.event
		val lowlevelEvent = trace.get(port, event, EventDirection.IN)
		return lowlevelEvent.transformToLowlevelGuard
	}
	
	protected def dispatch Expression transformEventReference(TimeoutEventReference reference) {
		// This rule is based on the restriction that in Gamma, a timeout declaration is set only a SINGLE time
		// Otherwise it would be very hard to transform the timing approach of Gamma in "compile time", as it is
		// not known what the actual value of a timeout declaration is due to possible multiple value assignments.
		// This problem derives from the different approaches to timings: Gamma - time elapses from a certain
		//  value to 0, whereas in lowlevel - from 0 to infinity.
		try {
			val timeout = reference.timeout
			val value = timeout.valueOfTimeout
			val lowlevelTimeoutVar = trace.get(timeout)
			// The timeouts are TRUE at start according to semantics, that is why they have to set to the highest value
			if (lowlevelTimeoutVar.expression === null) {
				lowlevelTimeoutVar.expression = value.clone // This is already a low-level expression
			}
			else {
				// Multiple timeouts can be transformed to a single variable (optimization)
				// We need the max initial value, to make sure each one is true at the beginning
				val oldValue = lowlevelTimeoutVar.expression
				val newValue = value.clone
				try {
					val evaluatedOldValue = oldValue.evaluateInteger
					val evaluatedNewValue = newValue.evaluateInteger
					if (evaluatedOldValue < evaluatedNewValue) {
						lowlevelTimeoutVar.expression = newValue
					}
				} catch (IllegalArgumentException e) {
					// One expression is a variable: better to do add expression
					lowlevelTimeoutVar.expression = createAddExpression => [
						it.operands += lowlevelTimeoutVar.expression
						it.operands += value.clone
					]
				}
			}
			// [500 <= timeoutClock]
			return createLessEqualExpression => [
				it.leftOperand = value
				it.rightOperand = lowlevelTimeoutVar.createReferenceExpression
			]
		} catch (IllegalArgumentException e) {
			// Timeout declaration is not started, always true
			return createTrueExpression
		}
	}
	
	private def Expression getValueOfTimeout(TimeoutDeclaration timeoutDeclaration) {
		val gammaStatechart = timeoutDeclaration.containingStatechart
		val timeoutSettings = gammaStatechart.getAllContentsOfType(SetTimeoutAction)
		val correctTimeoutSetting = timeoutSettings.filter[it.timeoutDeclaration == timeoutDeclaration]
		checkState(correctTimeoutSetting.size == 1, "Not one setting to the same timeout declaration: " + correctTimeoutSetting)
		// Single assignment, expected branch
		return correctTimeoutSetting.head.time.transform
	}
	
	protected def Expression transform(TimeSpecification time) {
		return time.value.transform(time.unit)
	}

	protected def Expression transform(Expression timeValue, TimeUnit timeUnit) {
		val plainValue = timeValue.transformSimpleExpression
		switch (timeUnit) {
			case TimeUnit.SECOND: {
				// S = 1000 MS
				return plainValue.wrapIntoMultiply(1000)
			}
			default: {
				// MS is base
				return plainValue
			}
		}
	}
	
}