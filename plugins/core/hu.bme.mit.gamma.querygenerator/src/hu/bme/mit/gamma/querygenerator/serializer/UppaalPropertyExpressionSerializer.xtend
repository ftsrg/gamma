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

import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceQueueSizeReferenceExpression

class UppaalPropertyExpressionSerializer extends PropertyExpressionSerializer {
	
	new(AbstractReferenceSerializer referenceSerializer) {
		super(referenceSerializer)
	}
	
	override String serialize(Expression expression) {
		if (expression instanceof EnumerationLiteralExpression) {
			val literal = expression.reference
			return literal.index.toString
		}
		return super.serialize(expression)
	}
	
	// Unique - do not delete!
	
	protected override get1CapacityQueueEmptyExpression(ComponentInstanceQueueSizeReferenceExpression expression) {
		val instance = expression.instance
		val queue = expression.queue
		val queueName = queue.getId(instance)
		return '''«queueName»[0] == 0''' // Array structure is kept
				.createOpaqueExpression
	}
	
}