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
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.statechart.OnCycleTrigger
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger

class TriggerTransformer {
	// Auxiliary objects
	protected final extension EventReferenceTransformer eventReferenceTransformer
	// Factory objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Trace
	protected final Trace trace
	// Transformation parameters
	protected final boolean functionInlining
	
	new(Trace trace, boolean functionInlining) {
		this.trace = trace
		this.functionInlining = functionInlining
		this.eventReferenceTransformer = new EventReferenceTransformer(this.trace, this.functionInlining)
	}
	
	protected def dispatch Expression transformTrigger(BinaryTrigger trigger) {
		switch (trigger.type) {
			case AND:
				return createAndExpression => [
					it.operands += trigger.leftOperand.transformTrigger
					it.operands += trigger.rightOperand.transformTrigger
				]
			case EQUAL: 
				return createEqualityExpression => [
					it.leftOperand = trigger.leftOperand.transformTrigger
					it.rightOperand = trigger.rightOperand.transformTrigger
				]
			case IMPLY:
				return createImplyExpression => [
					it.leftOperand = trigger.leftOperand.transformTrigger
					it.rightOperand = trigger.rightOperand.transformTrigger
				]
			case OR:
				return createOrExpression => [
					it.operands += trigger.leftOperand.transformTrigger
					it.operands += trigger.rightOperand.transformTrigger
				]
			case XOR:
				return createXorExpression => [
					it.operands += trigger.leftOperand.transformTrigger
					it.operands += trigger.rightOperand.transformTrigger
				]
			default:
				throw new IllegalArgumentException("Not known trigger: " + trigger)
		}
	}

	protected def dispatch Expression transformTrigger(UnaryTrigger trigger) {
		switch (trigger.type) {
			case NOT: 
				return createNotExpression => [
					it.operand = trigger.operand.transformTrigger
				]
			default:
				throw new IllegalArgumentException("Not known trigger: " + trigger)
		}
	}
	
	protected def dispatch Expression transformTrigger(OnCycleTrigger trigger) {
		return createTrueExpression
	}
	
	protected def dispatch Expression transformTrigger(AnyTrigger trigger) {
		val allEvents = trace.getAllLowlevelEvents(EventDirection.IN) // Considering only IN events
		val triggerGuards = newLinkedList
		for (event : allEvents) {
			triggerGuards += event.transformToLowlevelGuard
		}
		if (triggerGuards.empty) {
			// No possible incoming event
			return createFalseExpression
		}
		if (triggerGuards.size == 1) {
			// No need for or expression
			return triggerGuards.head
		}
		return createOrExpression => [
			it.operands += triggerGuards
		]
	}

	protected def dispatch Expression transformTrigger(EventTrigger trigger) {
		return trigger.eventReference.transformEventReference
	}
	
}