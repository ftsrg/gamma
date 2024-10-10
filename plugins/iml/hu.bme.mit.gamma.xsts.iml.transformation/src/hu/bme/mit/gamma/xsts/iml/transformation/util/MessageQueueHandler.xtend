/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.iml.transformation.util

import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.GreaterExpression
import hu.bme.mit.gamma.expression.model.InequalityExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.LessEqualExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.xsts.iml.transformation.serialization.ExpressionSerializer
import hu.bme.mit.gamma.xsts.iml.transformation.serialization.TypeSerializer
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.transformation.util.MessageQueueUtil
import hu.bme.mit.gamma.xsts.transformation.util.VariableGroupRetriever
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.math.BigInteger

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class MessageQueueHandler {
	//
	public static final MessageQueueHandler INSTANCE = new MessageQueueHandler
	//
	protected final extension MessageQueueUtil messageQueueUtil = MessageQueueUtil.INSTANCE
	
	protected final extension VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	
	// Declaration -> message queues new type - q : Message list;
	
	def serializeQueueVariable(Declaration queue) {
		val extension expressionSerializer = ExpressionSerializer.INSTANCE
		val extension typeSerializer = TypeSerializer.INSTANCE // Cannot be an attribute due to cyclic references
		val arrayType = queue.typeDefinition as ArrayTypeDefinition
		val elementType = arrayType.elementType
		var serializedType = elementType.serializeType
		
		return '''«queue.serializeAsLhs» : «serializedType» list;''' 
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
			val variable = expression.declaration
			val type = variable.typeDefinition
			if (variable.global) {
				if (variable instanceof VariableDeclaration) {
					val extension expressionSerializer = ExpressionSerializer.INSTANCE
					val xSts = variable.containingXsts
					val queueVariables = xSts.messageQueueGroup.variables
					val sizeVariables = xSts.messageQueueSizeGroup.variables
					if (sizeVariables.contains(variable)) {
						val declarationReferenceAnnotation = variable.declarationReferenceAnnotation
						val messageQueue = declarationReferenceAnnotation.declarations.head
						if (messageQueue === null) {
							// The queue has been removed due to optimization
							return '''«variable.name»'''
						}
						return '''List.length («messageQueue.serializeAsRhs»)'''
					}
					else if (queueVariables.contains(variable)) {
						//
						// Unreachable due to 'if (expression instanceof DirectReferenceExpression)'?
						//
						val emptyLiteral = type.defaultExpression as EnumerationLiteralExpression
						return variable.createEqualityExpression(emptyLiteral)
							.createIfThenElseExpression(0.toIntegerLiteral, 1.toIntegerLiteral)
							.serialize
					}
				}
			}
		}
		
		throw new IllegalArgumentException("Not known expression: " + expression)
	}
	
	// isFull -> size variables or master queue - XSTS 8 <= sizeVar or master[0] != 0  || IML full(q) 

	protected def serializeQueueFullExpression(Expression expression) {
		return expression.serializeQueueRightReferenceExpression(LessEqualExpression, InequalityExpression, "full")
	}
	
	// isNotFull -> size variables or master queue - XSTS 8 > sizeVar or master[0] == 0 || IML - full(q) 
	
	protected def serializeQueueNotFullExpression(Expression expression) {
		return expression.serializeQueueRightReferenceExpression(GreaterExpression, EqualityExpression, "nfull")
	}
	
	// isEmpty -> size variables or master queue - XSTS sizeVar <= 0 or master[0] == 0   || IML - empty(q) 
	
	protected def serializeQueueEmptyExpression(Expression expression) {
		return expression.serializeQueueLeftReferenceExpression(LessEqualExpression, EqualityExpression, "empty")
	}
	
	// isNotEmpty -> size variables or master queue - XSTS sizeVar > 0  or master[0] != 0  || IML - nempty(q) 
	
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
	
	private def serializeQueueExpression(Expression expression,
			boolean isLeftReference,
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
						val messageQueue = declarationReferenceAnnotation.declarations.head
						if (messageQueue === null) { // Queue has been removed due to optimization
							val extension expressionSerializer = ExpressionSerializer.INSTANCE
							return expression.superSerialize
						}
						else {
							return messageQueue.serializeQueueExpression(functionName)
						}
					}
				}
			}
			else if (masterQueueExpression.isInstance(expression)) { // 1-capacity master queue
				val left = expression.leftOperand
				val queueDeclaration = left.declaration
				return queueDeclaration.serializeQueueExpression(functionName)
			}
		}
		throw new IllegalArgumentException("Not known expression: " + expression)
	}
	
	// IML does not support these functions in if-then-else structures
	private def serializeQueueExpression(Declaration messageQueue, String functionName) {
		val extension expressionSerializer = ExpressionSerializer.INSTANCE
		val type = messageQueue.typeDefinition
		val isArray = type.array
		val capacity = (type instanceof ArrayTypeDefinition) ? type.size : 1.toIntegerLiteral
		
		if (isArray) {
			return switch (functionName) {
				case "empty" : '''(«messageQueue.serializeAsRhs» = [])''' // (List.length «messageQueue.serializeAsRhs» <= 0)
				case "nempty" : '''(«messageQueue.serializeAsRhs» <> [])''' // (List.length «messageQueue.serializeAsRhs» > 0)
				case "full" : '''(List.length «messageQueue.serializeAsRhs» >= «capacity.serialize»)'''
				case "nfull" : '''(List.length «messageQueue.serializeAsRhs» < «capacity.serialize»)'''
				default : throw new IllegalArgumentException("Not known function: " + functionName)
			}
		}
		else {
			val emptyLiteral = type.defaultExpression
			return switch (functionName) {
				case "empty" : '''(«messageQueue.serializeAsRhs» = «emptyLiteral.serialize»)'''
				case "nempty" : '''(«messageQueue.serializeAsRhs» <> «emptyLiteral.serialize»)'''
				case "full" : '''(«messageQueue.serializeAsRhs» <> «emptyLiteral.serialize»)'''
				case "nfull" : '''(«messageQueue.serializeAsRhs» = «emptyLiteral.serialize»)'''
				default : throw new IllegalArgumentException("Not known function: " + functionName)
			}
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

	// add -> q ! 7 || queue[size] := 
	
	protected def serializeQueueAddAction(Action action) {
		val extension expressionSerializer = ExpressionSerializer.INSTANCE
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			val rhs = action.rhs
			val queue = lhs.declaration
			if (queue.global) {
				val isArray = queue.array
				return '''«queue.serializeAsLhs» = ''' +
					if (isArray) {
						'''(«queue.serializeAsRhs» @ [«rhs.serialize»]);'''
					}
					else {
						'''«rhs.serialize»;'''
					}
			}
		}
		
		throw new IllegalArgumentException("Not known action: " + action)
	}
	// pop -> q ? x || queue := [0 -> queue[1], ...]
	
	protected def serializeQueuePopAction(Action action) {
		val extension expressionSerializer = ExpressionSerializer.INSTANCE
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			if (lhs instanceof DirectReferenceExpression) {
				val queue = lhs.declaration
				val type = queue.typeDefinition
				val isArray = type.array
				if (queue.global) {
					return '''«queue.serializeAsLhs» = ''' +
						if (isArray) {
							'''(match «queue.serializeAsRhs» with | hd::tl -> tl | [] -> []);'''
						}
						else {
							'''«type.defaultExpression.serialize»;'''
						}
				}
			}
		}
	}
	
	// peek -> q ? <x> || := queue[0]?
	
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
		
		val queue = rhs.declaration
		if (queue.global) {
			val isArray = queue.array
			val declaration = lhs.declaration
			if (isArray) {
				val arrayAccess = rhs as ArrayAccessExpression
				val index = arrayAccess.index
				if (index instanceof IntegerLiteralExpression) {
					val xSts = queue.containingXsts
					val messageQueues = xSts.messageQueueGroup.variables
					if (messageQueues.contains(queue) && index.value == BigInteger.ZERO) {
						return '''«declaration.serializeAsLhs» = (match «queue.serializeAsRhs» with | hd::tl -> hd | [] -> «declaration.defaultExpression.serialize»);'''
					}
				}
			}
			else {
				return '''«declaration.serializeAsLhs» = «queue.serializeAsRhs»;'''
			}
		}
		
		throw new IllegalArgumentException("Not known action: " + action)
	}
	
	//
	
	protected def serializeQueueInitializingAction(Action action) {
		val extension expressionSerializer = ExpressionSerializer.INSTANCE
		val assignment = action as AssignmentAction
		val lhs = assignment.lhs
		val declaration = lhs.declaration
		if (!declaration.array) { // Single queue variable
			return '''«declaration.serializeAsLhs» = «declaration.defaultExpression.serialize»;'''
		}
		return '''«declaration.serializeAsLhs» = [];''' 
	}
	
	// size := size + 1 / - 1
	
	protected def serializeQueueSizeAction(Action action) {
		// In IML, native lists store their own size
		// Except if the master queue has been removed due to optimization
		// In this case: we set the variable
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			val declaration = lhs.declaration
			val xSts = declaration.containingXsts
			val sizeVariables = xSts.messageQueueSizeGroup.variables
			if (sizeVariables.contains(declaration)) {
				val sizeVariable = declaration as VariableDeclaration
				val declarationReferenceAnnotation = sizeVariable.declarationReferenceAnnotation
				val messageQueue = declarationReferenceAnnotation.declarations.head
				if (messageQueue === null) {
					val extension expressionSerializer = ExpressionSerializer.INSTANCE
					val rhs = action.rhs
					return '''«sizeVariable.serializeAsLhs» = «rhs.serialize»;'''
				}
			}
		}
		
		return '''''' // In IML, native lists store their own size
	}
	
	// TODO clear -> || queue := [0 -> 0, ...]
	
}