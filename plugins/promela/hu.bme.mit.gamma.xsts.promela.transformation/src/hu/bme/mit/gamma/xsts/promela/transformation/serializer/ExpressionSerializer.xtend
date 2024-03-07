/********************************************************************************
 * Copyright (c) 2022-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.promela.transformation.serializer

import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.DivExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.ModExpression
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator2
import hu.bme.mit.gamma.xsts.promela.transformation.util.Configuration
import hu.bme.mit.gamma.xsts.promela.transformation.util.MessageQueueHandler
import hu.bme.mit.gamma.xsts.transformation.util.MessageQueueUtil

import static extension hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*

class ExpressionSerializer extends hu.bme.mit.gamma.expression.util.ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer
	protected new() {}
	//
	
	protected final extension MessageQueueUtil messageQueueUtil = MessageQueueUtil.INSTANCE
	protected final extension MessageQueueHandler messageQueueHandler = MessageQueueHandler.INSTANCE
	protected final extension ExpressionTypeDeterminator2 expressionTypeDeterminator = ExpressionTypeDeterminator2.INSTANCE
	
	//
	
	override String _serialize(IfThenElseExpression expression) '''(«expression.condition.serialize» -> («expression.then.serialize») : («expression.^else.serialize»))'''
	
	override String _serialize(EnumerationLiteralExpression expression) '''«expression.customizeEnumLiteralName»'''
	
	override String _serialize(ModExpression expression) '''(«expression.leftOperand.serialize» % «expression.rightOperand.serialize»)'''
	
	override String _serialize(DivExpression expression) '''(«expression.leftOperand.serialize» / «expression.rightOperand.serialize»)'''
	
	override String _serialize(NotExpression expression) '''(«super._serialize(expression)»)'''
	
	override String _serialize(ArrayAccessExpression expression) '''«expression.operand.serialize»«IF expression.operand instanceof ArrayAccessExpression»«arrayFieldAccess»[«expression.index.serialize»]«ELSE»[«expression.index.serialize»]«ENDIF»'''
	
	override String _serialize(ArrayLiteralExpression expression) '''{ «FOR operand : expression.operands SEPARATOR ', '»«operand.serialize»«ENDFOR» }'''
	
	override String _serialize(DirectReferenceExpression expression)  '''«expression.declaration.name»'''
	
	//
	
	override String serialize(Expression expression) {
		if (Configuration.HANDLE_NATIVE_MESSAGE_QUEUES) {
			if (expression.queueExpression) {
				return expression.serializeQueueExpression
			}
		}
		return super.serialize(expression)
	}
	
	//
	
	def String superSerialize(Expression expression) {
		return super.serialize(expression)
	}
	
}