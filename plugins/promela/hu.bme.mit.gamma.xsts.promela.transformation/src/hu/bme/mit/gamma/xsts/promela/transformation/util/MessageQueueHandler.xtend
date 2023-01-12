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
package hu.bme.mit.gamma.xsts.promela.transformation.util

import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
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
import hu.bme.mit.gamma.lowlevel.xsts.transformation.VariableGroupRetriever
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.promela.transformation.serializer.ExpressionSerializer
import hu.bme.mit.gamma.xsts.promela.transformation.serializer.TypeSerializer
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.math.BigInteger

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class MessageQueueHandler {
	//
	public static final MessageQueueHandler INSTANCE = new MessageQueueHandler
	//
//	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE // Would cause a cyclic-dependency
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
//	protected final extension ExpressionTypeDeterminator typeDeterminator = ExpressionTypeDeterminator.INSTANCE
	
	protected final extension VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	// Declaration -> message queues new type - chan q = [8] of { byte };
	
	def isMasterQueueVariable(VariableDeclaration variable) {
		val type = variable.typeDefinition
		if (type instanceof ArrayTypeDefinition) {
			val xSts = variable.containingXsts
			val queueVariables = xSts.masterMessageQueueGroup.variables
			
			return queueVariables.contains(variable)
		}
		return false
	}
	
	def isQueueVariable(VariableDeclaration variable) {
		val type = variable.typeDefinition
		if (type instanceof ArrayTypeDefinition) {
			val xSts = variable.containingXsts
			val queueVariables = xSts.messageQueueGroup.variables
			
			return queueVariables.contains(variable)
		}
		return false
	}
	
	def serializeQueueVariable(VariableDeclaration queue) {
		val extension expressionSerializer = ExpressionSerializer.INSTANCE // Cannot be an attribute due to cyclic references
		val arrayType = queue.typeDefinition as ArrayTypeDefinition
		val elementType = arrayType.elementType
		var serializedType = elementType.serializeType
		if (queue.global) {
			val xSts = queue.containingXsts
			val masterQueues = xSts.masterMessageQueueGroup.variables
			if (masterQueues.contains(queue)) {
				serializedType = "byte" // Optimization
			}
		}
		return '''chan «queue.name» = [«arrayType.size.serialize»] of { «serializedType» };''' 
	}
	
	// Entry point for queue expression handling
	
	def isQueueExpression(Expression expression) {
		return expression.queueFullExpression || expression.queueNotFullExpression ||
			expression.queueEmptyExpression || expression.queueNotEmptyExpression ||
			expression.queueSizeExpression
	}
	
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
	
	protected def isQueueSizeExpression(Expression expression) {
		if (expression instanceof DirectReferenceExpression) {
			val sizeVariable = expression.declaration
			if (sizeVariable.global) {
				if (sizeVariable instanceof VariableDeclaration) {
					val xSts = sizeVariable.containingXsts
					val sizeVariables = xSts.messageQueueSizeGroup.variables
					return sizeVariables.contains(sizeVariable)
				}
			}
		}
		return false
	}
	
	protected def serializeQueueSizeExpression(Expression expression) {
		if (expression instanceof DirectReferenceExpression) {
			val sizeVariable = expression.declaration
			if (sizeVariable.global) {
				if (sizeVariable instanceof VariableDeclaration) {
					val xSts = sizeVariable.containingXsts
					val sizeVariables = xSts.messageQueueSizeGroup.variables
					if (sizeVariables.contains(sizeVariable)) {
						val declarationReferenceAnnotation = sizeVariable.declarationReferenceAnnotation
						val messageQueue = declarationReferenceAnnotation.declaration
						return '''len(«messageQueue.name»)'''
					}
				}
			}
		}
		throw new IllegalArgumentException("Not known expression: " + expression)
	}
	
	// isFull -> size variables or master queue - XSTS 8 <= sizeVar or master[0] != 0  || Promela full(q) 

	protected def isQueueFullExpression(Expression expression) {
		return expression.isQueueRightReferenceExpression(LessEqualExpression, InequalityExpression)
	}
	
	protected def serializeQueueFullExpression(Expression expression) {
		return expression.serializeQueueRightReferenceExpression(LessEqualExpression, InequalityExpression, "full")
	}
	
	// isNotFull -> size variables or master queue - XSTS 8 > sizeVar or master[0] == 0 || Promela - full(q) 
	
	protected def isQueueNotFullExpression(Expression expression) {
		return expression.isQueueRightReferenceExpression(GreaterExpression, EqualityExpression)
	}
	
	protected def serializeQueueNotFullExpression(Expression expression) {
		return expression.serializeQueueRightReferenceExpression(GreaterExpression, EqualityExpression, "nfull")
	}
	
	// isEmpty -> size variables or master queue - XSTS sizeVar <= 0 or master[0] == 0   || Promela - empty(q) 
	
	protected def isQueueEmptyExpression(Expression expression) {
		return expression.isQueueLeftReferenceExpression(LessEqualExpression, EqualityExpression)
	}
	
	protected def serializeQueueEmptyExpression(Expression expression) {
		return expression.serializeQueueLeftReferenceExpression(LessEqualExpression, EqualityExpression, "empty")
	}
	
	// isNotEmpty -> size variables or master queue - XSTS sizeVar > 0  or master[0] != 0  || Promela - nempty(q) 
	
	protected def isQueueNotEmptyExpression(Expression expression) {
		return expression.isQueueLeftReferenceExpression(GreaterExpression, InequalityExpression)
	}
	
	protected def serializeQueueNotEmptyExpression(Expression expression) {
		return expression.serializeQueueLeftReferenceExpression(GreaterExpression, InequalityExpression, "nempty")
	}

	//
	
	private def isQueueLeftReferenceExpression(Expression expression,
			Class<? extends BinaryExpression> normalQueueExpression,
			Class<? extends BinaryExpression> masterQueueExpression) {
		return expression.isQueueExpression(true, normalQueueExpression, masterQueueExpression)
	}
	
	private def isQueueRightReferenceExpression(Expression expression,
			Class<? extends BinaryExpression> normalQueueExpression,
			Class<? extends BinaryExpression> masterQueueExpression) {
		return expression.isQueueExpression(false, normalQueueExpression, masterQueueExpression)
	}
	
	private def isQueueExpression(Expression expression,
			boolean isLeftReference,
			Class<? extends BinaryExpression> normalQueueExpression,
			Class<? extends BinaryExpression> masterQueueExpression) {
		if (expression instanceof BinaryExpression) {
			if (normalQueueExpression.isInstance(expression)) { // Normal queue
				val left = expression.leftOperand
				val right = expression.rightOperand
				
				val reference = (isLeftReference) ? left : right
				val literal = (reference === left) ? right : left
				
				if (reference instanceof DirectReferenceExpression) {
					val sizeVariable = reference.declaration
					if (sizeVariable.global) {
						val xSts = sizeVariable.containingXsts
						val sizeVariables = xSts.messageQueueSizeGroup.variables
						return literal instanceof IntegerLiteralExpression &&
								sizeVariables.contains(sizeVariable)
					}
				}
			}
			else if (masterQueueExpression.isInstance(expression)) { // 1-capacity master queue
				val left = expression.leftOperand
				if (left instanceof ArrayAccessExpression) {
					val arrayDeclaration = left.declaration
					if (arrayDeclaration.global) {
						val xSts = arrayDeclaration.containingXsts
						val messageQueues = newArrayList
						messageQueues += xSts.masterMessageQueueGroup.variables
						messageQueues += xSts.systemMasterMessageQueueGroup.variables
						
						val right = expression.rightOperand
						if (right instanceof IntegerLiteralExpression) {
							return messageQueues.contains(arrayDeclaration) && right.value == BigInteger.ZERO
						}
					}
				}
			}
		}
		return false
	}
	
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
						val messageQueue = declarationReferenceAnnotation.declaration
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
			case "empty" : '''(len(«messageQueue.name») <= 0)'''
			case "nempty" : '''(len(«messageQueue.name») > 0)'''
			case "full" : '''(len(«messageQueue.name») >= «capacity.serialize»)'''
			case "nfull" : '''(len(«messageQueue.name») < «capacity.serialize»)'''
			default : throw new IllegalArgumentException("Not known function: " + functionName)
		}
	}

	///
	
	// Entry point for queue action handling
	
	def isQueueAction(Action action) {
		return action.queueAddAction || action.queuePeekAction || action.queuePopAction ||
			action.queueSizeAction || action.queueInitializingAction
	}
	
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
	
	protected def isQueueAddAction(Action action) {
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			if (lhs instanceof ArrayAccessExpression) {
				val array = lhs.declaration
				if (array.global) {
					val xSts = array.containingXsts
					val messageQueues = xSts.messageQueueGroup.variables
					
					return messageQueues.contains(array)
				}
			}
		}
		return false
	}
	
	protected def serializeQueueAddAction(Action action) {
		val extension expressionSerializer = ExpressionSerializer.INSTANCE
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			val rhs = action.rhs
			if (lhs instanceof ArrayAccessExpression) {
				val array = lhs.declaration
				return '''«array.name» ! «rhs.serialize»;'''
			}
		}
		throw new IllegalArgumentException("Not known action: " + action)
	}
	// pop -> q ? x || queue := [0 -> queue[1], ...]
	
	protected def isQueuePopAction(Action action) {
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			val rhs = action.rhs
			if (lhs instanceof DirectReferenceExpression) {
				val array = lhs.declaration
				if (array.global) {
					val xSts = array.containingXsts
					val messageQueues = xSts.messageQueueGroup.variables
					if (messageQueues.contains(array)) {
						if (rhs instanceof ArrayLiteralExpression) {
							val head = rhs.operands.head // [ 0 <- array[1], ...]
							if (head instanceof ArrayAccessExpression) {
								val declaration = head.declaration
								val index = head.index
								if (index instanceof IntegerLiteralExpression) {
									return declaration === array && index.value == BigInteger.ONE
								}
							}
						}
					}
				}
			}
		}
		return false
	}
	
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
						d_step {
							local «elementType.serializeType» «name» = «defaultExpression»;
							«array.name» ? «name»;
							«name» = «defaultExpression»;
						}
					'''
				}
			}
		}
	}
	
	// peek -> q ? <x> || := queue[0]?
	
	protected def isQueuePeekAction(Action action) {
		var Expression rhs = null
		
		if (action instanceof AssignmentAction) {
			rhs = action.rhs
		}
		else if (action instanceof VariableDeclarationAction) {
			val declaration = action.variableDeclaration
			rhs = declaration.expression
		}
		
		if (rhs instanceof ArrayAccessExpression) {
			val array = rhs.declaration
			if (array.global) {
				val index = rhs.index
				if (index instanceof IntegerLiteralExpression) {
					val xSts = array.containingXsts
					val messageQueues = xSts.messageQueueGroup.variables
					
					return messageQueues.contains(array) && index.value == BigInteger.ZERO
				}
			}
		}
		return false
	}
	
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
						return '''«array.name» ? <«lhs.serialize»>;'''
					}
				}
			}
		}
		throw new IllegalArgumentException("Not known action: " + action)
	}
	
	//
	
	protected def isQueueInitializingAction(Action action) {
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			val rhs = action.rhs
			if (lhs instanceof DirectReferenceExpression) {
				val array = lhs.declaration
				if (array.global) {
					val xSts = array.containingXsts
					val messageQueues = xSts.messageQueueGroup.variables
					if (messageQueues.contains(array)) {
						return rhs instanceof ArrayLiteralExpression
					}
				}
			}
		}
		return false
	}
	
	protected def serializeQueueInitializingAction(Action action) {
		return ''''''
	}
	
	// size := size + 1 / - 1
	
	protected def isQueueSizeAction(Action action) {
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			return lhs.queueSizeExpression
//			if (lhs instanceof DirectReferenceExpression) {
//				val declaration = lhs.declaration
//				if (declaration.global) {
//					val xSts = declaration.containingXsts
//					val queueSizeVariables = xSts.messageQueueSizeGroup.variables
//					return queueSizeVariables.contains(declaration)
//				}
//			}
		}
		return false
	}
	
	protected def serializeQueueSizeAction(Action action) {
		// In Promela, native channels store their own size
		return ''''''
	}
	
	// TODO clear -> || queue := [0 -> 0, ...]
	
}