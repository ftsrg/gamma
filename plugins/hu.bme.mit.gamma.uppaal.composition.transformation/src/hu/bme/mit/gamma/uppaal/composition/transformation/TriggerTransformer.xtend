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
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.AnyPortEventReference
import hu.bme.mit.gamma.statechart.model.AnyTrigger
import hu.bme.mit.gamma.statechart.model.BinaryTrigger
import hu.bme.mit.gamma.statechart.model.EventTrigger
import hu.bme.mit.gamma.statechart.model.OnCycleTrigger
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.PortEventReference
import hu.bme.mit.gamma.statechart.model.TimeoutEventReference
import hu.bme.mit.gamma.statechart.model.UnaryTrigger
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import java.util.Collection
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DeclarationsFactory
import uppaal.expressions.CompareOperator
import uppaal.expressions.Expression
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.LogicalOperator
import uppaal.types.TypesFactory

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class TriggerTransformer {
	// UPPAAL factories
	protected final extension DeclarationsFactory declFact = DeclarationsFactory.eINSTANCE
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	protected final extension TypesFactory typesFact = TypesFactory.eINSTANCE
	// Auxiliary objects
	protected final extension EventHandler eventHandler = new EventHandler
	//
	extension Trace trace
	
	new(Trace trace) {
		this.trace = trace
	}
	
	def dispatch Expression transformTrigger(OnCycleTrigger trigger, ComponentInstance owner) {
		return createLiteralExpression => [it.text = "true"]			
	}
	
	def dispatch Expression transformTrigger(AnyTrigger trigger, ComponentInstance owner) {
		return owner.derivedType.ports.createLogicalExpressionOfPortInEvents(LogicalOperator.OR, owner)			
	}
	
	private def Expression createLogicalExpressionOfPortInEvents(Collection<Port> ports,
			LogicalOperator operator, ComponentInstance owner) {
		val events = ports.map[#[it].getSemanticEvents(EventDirection.IN)].flatten
		val eventCount = events.size
		if (eventCount == 0) {
			return createLiteralExpression => [
				it.text = "false"
			]
		}
		if (eventCount == 1) {
			val port = ports.head
			val event = events.head
			return createIdentifierExpression => [
				it.identifier = event.getIsRaisedVariable(port, owner).variable.head
			]
		}
		var i = 0
		var orExpression = createLogicalExpression => [
			it.operator = operator
		]
		for (port : ports) {
			for (event : #[port].getSemanticEvents(EventDirection.IN)) {
				if (i == 0) {
					orExpression.firstExpr = createIdentifierExpression => [
						it.identifier = event.getIsRaisedVariable(port, owner).variable.head
					]
				}
				else if (i == 1) {
					orExpression.secondExpr = createIdentifierExpression => [
						it.identifier = event.getIsRaisedVariable(port, owner).variable.head
					]
				}
				else {
					orExpression = orExpression.createLogicalExpression(
						LogicalOperator.OR,
						createIdentifierExpression => [
							it.identifier = event.getIsRaisedVariable(port, owner).variable.head
						]
					)
				}
			}
		}
		return orExpression
	}
	
	private def createLogicalExpression(Expression lhs, LogicalOperator operator,
			Expression rhs) {
		return createLogicalExpression => [
			it.firstExpr = lhs
			it.operator = operator
			it.secondExpr = rhs
		]
	}
	
	def dispatch Expression transformTrigger(EventTrigger trigger, ComponentInstance owner) {
		return trigger.eventReference.transformEventTrigger(owner)
	}
	
	def dispatch Expression transformTrigger(BinaryTrigger trigger, ComponentInstance owner) {
		switch (trigger.type) {
			case AND: {
				return createLogicalExpression => [
					it.firstExpr = trigger.leftOperand.transformTrigger(owner)
					it.operator = LogicalOperator.AND
					it.secondExpr = trigger.rightOperand.transformTrigger(owner)
				]
			}
			case EQUAL: {
				return createCompareExpression => [
					it.firstExpr = trigger.leftOperand.transformTrigger(owner)
					it.operator = CompareOperator.EQUAL
					it.secondExpr = trigger.rightOperand.transformTrigger(owner)
				]
			}
			case IMPLY: {
				return createLogicalExpression => [
					it.firstExpr = trigger.leftOperand.transformTrigger(owner)
					it.operator = LogicalOperator.IMPLY
					it.secondExpr = trigger.rightOperand.transformTrigger(owner)
				]
			}
			case OR: {
				return createLogicalExpression => [
					it.firstExpr = trigger.leftOperand.transformTrigger(owner)
					it.operator = LogicalOperator.OR
					it.secondExpr = trigger.rightOperand.transformTrigger(owner)
				]
			}
			case XOR: {
				return createLogicalExpression => [
					it.firstExpr = trigger.leftOperand.transformTrigger(owner)
					it.operator = LogicalOperator.XOR
					it.secondExpr = trigger.rightOperand.transformTrigger(owner)
				]
			}
			default: {
				throw new IllegalArgumentException
			}
		}
	}
	
	def dispatch Expression transformTrigger(UnaryTrigger trigger, ComponentInstance owner) {
		switch (trigger.getType) {
			case NOT: {
				return createNegationExpression => [
					it.negatedExpression = trigger.operand.transformTrigger(owner)
				]
			}
			default: {
				throw new IllegalArgumentException
			}
		}
	}

	def dispatch Expression transformEventTrigger(PortEventReference reference, ComponentInstance owner) {
		val port = reference.port
		val event = reference.event
		return createIdentifierExpression => [
			it.identifier = event.getIsRaisedVariable(port, owner).variable.head
		]
	}

	def dispatch Expression transformEventTrigger(AnyPortEventReference reference, ComponentInstance owner) {
		val port = #[reference.getPort]
		return port.createLogicalExpressionOfPortInEvents(LogicalOperator.OR, owner)
	}
	
	def dispatch Expression transformEventTrigger(TimeoutEventReference reference, ComponentInstance owner) {
		val boolVariable = reference.timeout.allValuesOfTo.filter(DataVariableDeclaration).head
		return createIdentifierExpression => [
			it.identifier = boolVariable.variable.head
		]
	}
	
}