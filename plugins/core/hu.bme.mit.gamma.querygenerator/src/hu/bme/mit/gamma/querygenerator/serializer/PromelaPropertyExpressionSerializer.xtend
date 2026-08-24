/********************************************************************************
 * Copyright (c) 2022-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.ImplyExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceQueueSizeReferenceExpression

import static extension hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.QueueNamings.*

class PromelaPropertyExpressionSerializer extends ThetaPropertyExpressionSerializer {
	
	new(AbstractReferenceSerializer referenceSerializer) {
		super(referenceSerializer)
	}
	
	override String serialize(Expression expression) {
		if (expression instanceof EnumerationLiteralExpression) {
			return expression.customizeEnumLiteralName
		}
		return super.serialize(expression)
	}
	
	//
	
	override String _serialize(IfThenElseExpression expression) '''((«expression.condition.serialize») -> («expression.then.serialize») : («expression.^else.serialize»))'''
	
	override String _serialize(ImplyExpression expression) '''(!(«expression.leftOperand.serialize») || («expression.rightOperand.serialize»))'''
	
	// Unique - do not delete!
	
	protected override get1CapacityQueueEmptyExpression(ComponentInstanceQueueSizeReferenceExpression expression) {
		val instance = expression.instance
		val queue = expression.queue
		val queueName = queue.getId(instance)
		return '''«queueName» == «queueName.getQueueTypeName.customizeEnumLiteralName(emptyLiteralName)»'''
				.createOpaqueExpression
	}
	
}