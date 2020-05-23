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

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.model.AnyPortEventReference
import hu.bme.mit.gamma.statechart.model.ClockTickReference
import hu.bme.mit.gamma.statechart.model.PortEventReference
import hu.bme.mit.gamma.statechart.model.SetTimeoutAction
import hu.bme.mit.gamma.statechart.model.TimeSpecification
import hu.bme.mit.gamma.statechart.model.TimeUnit
import hu.bme.mit.gamma.statechart.model.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.model.TimeoutEventReference
import java.math.BigInteger

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class EventReferenceTransformer {
	// Auxiliary objects
	protected final extension ExpressionTransformer expressionTransformer
	// Factory objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Trace
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
		this.expressionTransformer = new ExpressionTransformer(this.trace)
	}
	
	protected def transformToLowlevelGuard(EventDeclaration lowlevelEvent) {
		val refExpr = createReferenceExpression => [
			it.declaration = lowlevelEvent.isRaised
		] 
		return createEqualityExpression => [
			it.leftOperand = refExpr
			it.rightOperand = createTrueExpression
		]
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
			val lowlevelTimeoutVar = trace.get(timeout) => [
				// Note a fault as these timeouts are always initialized to 0 when used
				// Needed so later we can now the timeout without complicated patterns
				it.expression = value.clone // This is already a low-level expression
			]
			// [500 <= timeoutClock]
			return createLessEqualExpression => [
				it.leftOperand = value
				it.rightOperand = createReferenceExpression => [
					it.declaration = lowlevelTimeoutVar
				]
			]
		} catch (IllegalArgumentException e) {
			// Timeout declaration is not started, always true
			return createTrueExpression
		}
	}
	
	private def Expression getValueOfTimeout(TimeoutDeclaration timeoutDeclaration) {
		val gammaStatechart = timeoutDeclaration.containingStatechart
		val gammaTransitions = gammaStatechart.transitions
		val gammaStates = gammaStatechart.allStates
		val actions = (gammaTransitions.map[it.effects] + gammaStates.map[it.entryActions] + gammaStates.map[it.exitActions]).flatten
		val timeoutSettings = actions.filter(SetTimeoutAction)
		val correctTimeoutSetting = timeoutSettings.filter[it.timeoutDeclaration == timeoutDeclaration]
		checkState(correctTimeoutSetting.size == 1, "Not one setting to the same timeout declaration: " + correctTimeoutSetting)
		// Single assignment, expected branch
		return correctTimeoutSetting.head.time.transform
	}
	
	protected def Expression transform(TimeSpecification time) {
		return time.value.transform(time.unit)
	}

	protected def Expression transform(Expression timeValue, TimeUnit timeUnit) {
		val plainValue = timeValue.transformExpression
		switch (timeUnit) {
			case TimeUnit.SECOND: {
				// S = 1000 MS
				return createMultiplyExpression => [
					it.operands += createIntegerLiteralExpression => [
						it.value = BigInteger.valueOf(1000)
					]
					it.operands += plainValue
				]
			}
			default: {
				// MS is base
				return plainValue
			}
		}
	}
	
}