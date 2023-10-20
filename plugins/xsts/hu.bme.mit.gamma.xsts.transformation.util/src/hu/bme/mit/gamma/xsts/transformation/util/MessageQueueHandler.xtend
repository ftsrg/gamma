/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.GreaterExpression
import hu.bme.mit.gamma.expression.model.InequalityExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.LessEqualExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.TypeSerializer
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.transformation.serializer.ExpressionSerializer
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.math.BigInteger

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

@Deprecated
class MessageQueueHandler {
	//
	public static final MessageQueueHandler INSTANCE = new MessageQueueHandler
	//
	protected final extension MessageQueueUtil messageQueueUtil = MessageQueueUtil.INSTANCE
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	
	protected final extension VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	
	// Declaration -> message queues new type - TODO
	
	def serializeQueueVariable(VariableDeclaration queue) {
		val extension expressionSerializer = ExpressionSerializer.INSTANCE // Cannot be an attribute due to cyclic references
		val arrayType = queue.typeDefinition as ArrayTypeDefinition
		val elementType = arrayType.elementType
		var serializedType = elementType.serialize
		if (queue.global) {
			val xSts = queue.containingXsts
			val masterQueues = xSts.masterMessageQueueGroup.variables
			if (masterQueues.contains(queue)) {
				serializedType = "integer" // Optimization
			}
		}
		return ''' ''' // TODO 
	}
	
	// Entry point for queue expression handling
	
	def serializeQueueExpression(Expression expression) {
		if (expression.queueEmptyExpression) {
			return expression.serializeQueueEmptyExpression
		}
		else if (expression.queueNotEmptyExpression) {
			return expression.serializeQueueNotEmptyExpression
		}
		else if (expression.queueFullExpression) {
			return expression.serializeQueueFullExpression
		}
		else if (expression.queueNotFullExpression) {
			return expression.serializeQueueNotFullExpression
		}
		else if (expression.queueSizeExpression) { // Last to handle basic variables
			return expression.serializeQueueSizeExpression
		}
		throw new IllegalArgumentException("Not known expression: " + expression)
	}
	
	//
	
	protected def serializeQueueSizeExpression(Expression expression) {
		if (expression instanceof DirectReferenceExpression) {
			val sizeVariable = expression.declaration
			if (sizeVariable.global) {
				if (sizeVariable instanceof VariableDeclaration) {
					val xSts = sizeVariable.containingXsts
					val sizeVariables = xSts.messageQueueSizeGroup.variables
					if (sizeVariables.contains(sizeVariable)) {
						val declarationReferenceAnnotation = sizeVariable.declarationReferenceAnnotation
						val messageQueue = declarationReferenceAnnotation.declarations.onlyElement
						return ''' ''' // TODO
					}
				}
			}
		}
		throw new IllegalArgumentException("Not known expression: " + expression)
	}
	
	// isFull -> TODO

	protected def serializeQueueFullExpression(Expression expression) {
		return expression.serializeQueueRightReferenceExpression(LessEqualExpression, InequalityExpression, "full")
	}
	
	// isNotFull -> TODO
	
	protected def serializeQueueNotFullExpression(Expression expression) {
		return expression.serializeQueueRightReferenceExpression(GreaterExpression, EqualityExpression, "nfull")
	}
	
	// isEmpty -> TODO
	
	protected def serializeQueueEmptyExpression(Expression expression) {
		return expression.serializeQueueLeftReferenceExpression(LessEqualExpression, EqualityExpression, "empty")
	}
	
	// isNotEmpty -> TODO
	
	protected def serializeQueueNotEmptyExpression(Expression expression) {
		return expression.serializeQueueLeftReferenceExpression(GreaterExpression, InequalityExpression, "nempty")
	}

	//
	
	private def serializeQueueLeftReferenceExpression(Expression expression,
			Class<? extends BinaryExpression> normalQueueExpression,
			Class<? extends BinaryExpression> masterQueueExpression,
			String functionName) {
		return expression.serializeQueueExpression(
				true, normalQueueExpression, masterQueueExpression, functionName)
	}
	
	private def serializeQueueRightReferenceExpression(Expression expression,
			Class<? extends BinaryExpression> normalQueueExpression,
			Class<? extends BinaryExpression> masterQueueExpression,
			String functionName) {
		return expression.serializeQueueExpression(
				false, normalQueueExpression, masterQueueExpression, functionName)
	}
	
	private def serializeQueueExpression(Expression expression, boolean isLeftReference,
			Class<? extends BinaryExpression> normalQueueExpression,
			Class<? extends BinaryExpression> masterQueueExpression,
			String functionName) {
		if (expression instanceof BinaryExpression) {
			if (normalQueueExpression.isInstance(expression)) { // Normal queue
				val left = expression.leftOperand
				val right = expression.rightOperand
				
				val reference = (isLeftReference) ? left : right
				
				if (reference instanceof DirectReferenceExpression) {
					val sizeVariable = reference.declaration
					if (sizeVariable instanceof VariableDeclaration) {
						val declarationReferenceAnnotation = sizeVariable.declarationReferenceAnnotation
						val messageQueue = declarationReferenceAnnotation.declarations.onlyElement
//						if (expression.isContainedBy(IfThenElseExpression)) {
							return messageQueue.serializeQueueExpression(functionName)
//						}
//						else {
//							return '''«functionName»(«messageQueue.name»)'''
//						}
					}
				}
			}
			else if (masterQueueExpression.isInstance(expression)) { // 1-capacity master queue
				val arrayAccess = expression.leftOperand as ArrayAccessExpression
				val arrayDeclaration = arrayAccess.declaration
//				if (expression.isContainedBy(IfThenElseExpression)) {
					return arrayDeclaration.serializeQueueExpression(functionName)
//				}
//				else {
//					return '''«functionName»(«arrayDeclaration.name»)'''
//				}
			}
		}
		throw new IllegalArgumentException("Not known expression: " + expression)
	}
	
	// Promela does not support these functions in if-then-else structures
	private def serializeQueueExpression(Declaration messageQueue, String functionName) {
		val extension expressionSerializer = ExpressionSerializer.INSTANCE
		val type = messageQueue.typeDefinition as ArrayTypeDefinition
		val capacity = type.size
		
		return switch (functionName) {
			case "empty" : ''' ''' // TODO
			case "nempty" : ''' '''
			case "full" : ''' '''
			case "nfull" : ''' '''
			default : throw new IllegalArgumentException("Not known function: " + functionName)
		}
	}

	///
	
	// Entry point for queue action handling
	
	def serializeQueueAction(Action action) {
		if (action.queueAddAction) {
			return action.serializeQueueAddAction
		}
		else if (action.queuePeekAction) {
			return action.serializeQueuePeekAction
		}
		else if (action.queuePopAction) {
			return action.serializeQueuePopAction
		}
		else if (action.queueSizeAction) {
			return action.serializeQueueSizeAction
		}
		else if (action.queueInitializingAction) { // After queuePopAction
			return action.serializeQueueInitializingAction
		}
		throw new IllegalArgumentException("Not known action: " + action)
	}

	// add -> TODO
	
	protected def serializeQueueAddAction(Action action) {
		val extension expressionSerializer = ExpressionSerializer.INSTANCE
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			val rhs = action.rhs
			if (lhs instanceof ArrayAccessExpression) {
				val array = lhs.declaration
				return ''' ''' // TODO
			}
		}
		throw new IllegalArgumentException("Not known action: " + action)
	}
	// pop -> TODO
	
	protected def serializeQueuePopAction(Action action) {
		val extension expressionSerializer = ExpressionSerializer.INSTANCE
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			if (lhs instanceof DirectReferenceExpression) {
				val array = lhs.declaration
				if (array.global) {
					val type = array.type as ArrayTypeDefinition
					val elementType = type.elementType
					val defaultExpression= elementType.defaultExpression.serialize
					
					val name = "pop_placeholder_" + action.hashCode.toString.replaceAll("-", "_")
					
					return '''
						 
					''' // TODO
				}
			}
		}
	}
	
	// peek -> TODO
	
	protected def serializeQueuePeekAction(Action action) {
		val extension expressionSerializer = ExpressionSerializer.INSTANCE
		// We always merge peek and pop
		
		var Expression lhs = null
		var Expression rhs = null
		
		if (action instanceof AssignmentAction) {
			lhs = action.lhs
			rhs = action.rhs
		}
		else if (action instanceof VariableDeclarationAction) {
			val declaration = action.variableDeclaration
			lhs = declaration.createReferenceExpression
			rhs = declaration.expression
		}
		
		if (rhs instanceof ArrayAccessExpression) {
			val array = rhs.declaration
			if (array.global) {
				val index = rhs.index
				if (index instanceof IntegerLiteralExpression) {
					val xSts = array.containingXsts
					val messageQueues = xSts.messageQueueGroup.variables
					if (messageQueues.contains(array) && index.value == BigInteger.ZERO) {
						return ''' ''' // TODO
					}
				}
			}
		}
		throw new IllegalArgumentException("Not known action: " + action)
	}
	
	//
	
	protected def serializeQueueInitializingAction(Action action) {
		return '''''' // TODO
	}
	
	// size := size + 1 / - 1
	
	protected def serializeQueueSizeAction(Action action) {
		return '''''' // TODO
	}
	
	// TODO clear -> || queue := [0 -> 0, ...]
	
}