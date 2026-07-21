/********************************************************************************
 * Copyright (c) 2018-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ImplyExpression
import hu.bme.mit.gamma.expression.model.OpaqueExpression
import hu.bme.mit.gamma.property.util.PropertyUtil
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceQueueSizeReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.QueueNamings.*

abstract class PropertyExpressionSerializer extends ExpressionSerializer {
	//
	protected extension AbstractReferenceSerializer referenceSerializer
	//
	protected final extension PropertyUtil propertyUtil = PropertyUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	//
	new(AbstractReferenceSerializer referenceSerializer) {
		this.referenceSerializer = referenceSerializer
	}
	
	override String serialize(Expression expression) {
		if (expression instanceof ComponentInstanceElementReferenceExpression) {
			return expression.serializeStateExpression
		}
		return super.serialize(expression)
	}
	
	//
	
	override _serialize(ImplyExpression expression) '''(!(«expression.leftOperand.serialize») || («expression.rightOperand.serialize»))'''
	
	override _serialize(OpaqueExpression expression) '''«expression.expression»'''
	
	//
	
	protected def dispatch serializeStateExpression(ComponentInstanceStateReferenceExpression expression) {
		val instance = expression.instance
		val region = expression.region
		val state = expression.state
		return '''«state.getId(region, instance)»'''
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceVariableReferenceExpression expression) {
		val instance = expression.instance
		val variable = expression.variableDeclaration
		// TODO record?
		return '''«variable.getId(instance).head»'''
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceEventReferenceExpression expression) {
		val instance = expression.instance
		val port = expression.port
		val event = expression.event
		// Could be extended with in-events too
		return '''«event.getId(port, instance)»'''
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceEventParameterReferenceExpression expression) {
		val instance = expression.instance
		val port = expression.port
		val event = expression.event
		val parameter = expression.parameterDeclaration
		// Could be extended with in-events too
		// TODO record?
		return '''«event.getId(port, parameter, instance).head»'''
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceQueueSizeReferenceExpression expression) {
		val instance = expression.instance
		val queue = expression.queue
		val capacity = evaluator.evaluate(queue.capacity)
		return (capacity > 1) ?
			queue.getSizeId(instance) :
			"(" + expression.get1CapacityQueueEmptyExpression
					.createIfThenElseExpression(0.toIntegerLiteral, 1.toIntegerLiteral).serialize + ")"
	}
	
	protected def get1CapacityQueueEmptyExpression(ComponentInstanceQueueSizeReferenceExpression expression) {
		val instance = expression.instance
		val queue = expression.queue
		val queueName = queue.getId(instance)
		return '''«queueName» == «queueName.getQueueTypeName».«emptyLiteralName»'''
				.createOpaqueExpression
	}
	
	//
	
	def getReferenceSerializer() {
		return this.referenceSerializer
	}
	
}