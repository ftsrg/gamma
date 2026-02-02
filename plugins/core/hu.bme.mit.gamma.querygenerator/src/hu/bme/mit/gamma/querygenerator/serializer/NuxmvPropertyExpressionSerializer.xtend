/********************************************************************************
 * Copyright (c) 2023-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.ImplyExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.XorExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceQueueSizeReferenceExpression

import static hu.bme.mit.gamma.xsts.transformation.util.QueueNamings.*

class NuxmvPropertyExpressionSerializer extends ThetaPropertyExpressionSerializer {
	
	new(AbstractReferenceSerializer referenceSerializer) {
		super(referenceSerializer)
	}
	
	override String _serialize(EnumerationLiteralExpression expression) '''«expression.reference.name»'''
	
	override String serialize(Expression expression) {
		return super.serialize(expression)
	}
	
	override String _serialize(TrueExpression expression) '''TRUE'''

	override String _serialize(FalseExpression expression) '''FALSE'''
	
	override String _serialize(OrExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' | '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(XorExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' xor '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(AndExpression expression) '''(«FOR operand : expression.operands SEPARATOR ' & '»«operand.serialize»«ENDFOR»)'''

	override String _serialize(ImplyExpression expression) '''((«expression.leftOperand.serialize») -> («expression.rightOperand.serialize»))'''

	override String _serialize(EqualityExpression expression) '''(«expression.leftOperand.serialize» = «expression.rightOperand.serialize»)'''

	override String _serialize(IfThenElseExpression expression) '''((«expression.condition.serialize») ? («expression.then.serialize») : («expression.^else.serialize»))'''
	
	override String _serialize(ArrayAccessExpression arrayAccessExpression) '''READ(«arrayAccessExpression.operand.serialize», «arrayAccessExpression.index.serialize»)'''
	
	// Unique - do not delete!
	
	protected override get1CapacityQueueEmptyExpression(ComponentInstanceQueueSizeReferenceExpression expression) {
		val instance = expression.instance
		val queue = expression.queue
		val queueName = queue.getId(instance)
		return '''«queueName» = «emptyLiteralName»'''
				.createOpaqueExpression
	}
	
}