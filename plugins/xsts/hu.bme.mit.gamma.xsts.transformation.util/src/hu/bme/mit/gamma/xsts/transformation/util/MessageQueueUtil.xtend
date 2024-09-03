/********************************************************************************
 * Copyright (c) 2023-2024 Contributors to the Gamma project
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
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DeclarationReferenceAnnotation
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.GreaterExpression
import hu.bme.mit.gamma.expression.model.InequalityExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.LessEqualExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.math.BigInteger

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class MessageQueueUtil {
	//
	public static final MessageQueueUtil INSTANCE = new MessageQueueUtil
	//
	
	protected final extension VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE
	
	//
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	
	// Declaration -> message queues new type - chan q = [8] of { byte };
	
	def isMasterQueueVariable(Declaration variable) {
		val type = variable.typeDefinition
		if (type instanceof ArrayTypeDefinition) {
			val xSts = variable.containingXsts
			val queueVariables = xSts.masterMessageQueueGroup.variables
			
			return queueVariables.contains(variable)
		}
		return false
	}
	
	def isQueueVariable(Declaration variable) {
		val type = variable.typeDefinition
		if (type instanceof ArrayTypeDefinition) {
			val xSts = variable.containingXsts
			val queueVariables = xSts.messageQueueGroup.variables
			
			return queueVariables.contains(variable)
		}
		return false
	}
	
	def isQueueSizeVariable(Declaration variable) {
		val type = variable.typeDefinition
		if (type instanceof IntegerTypeDefinition) {
			val xSts = variable.containingXsts
			val sizeVariables = xSts.messageQueueSizeGroup.variables
			
			return sizeVariables.contains(variable)
		}
		return false
	}
	
	def getQueueOfQueueSizeVariable(Declaration variable) {
		if (variable.queueSizeVariable) {
			val _variable = variable as VariableDeclaration
			val annotation = _variable.annotations.filter(DeclarationReferenceAnnotation).onlyElement
			val declaration = annotation.declarations.head // Can be null
			
			return declaration
		}
		return null
	}
	
	def hasQueueOfQueueSizeVariable(Declaration variable) {
		return variable.queueOfQueueSizeVariable !== null
	}
	
	// Entry point for queue expression handling
	
	def isQueueExpression(Expression expression) {
		return expression.queueFullExpression || expression.queueNotFullExpression ||
			expression.queueEmptyExpression || expression.queueNotEmptyExpression ||
			expression.queueSizeExpression
	}
	
	//
	
	def isQueueSizeExpression(Expression expression) {
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
		else if (expression instanceof BinaryExpression) {
			val left = expression.leftOperand
			val right = expression.rightOperand
			
			if (left instanceof ReferenceExpression) {
				val queueVariable = left.declaration
				if (queueVariable.global && !queueVariable.array) {
					val xSts = queueVariable.containingXsts
					val queueVariables = xSts.messageQueueGroup.variables
					
					if (queueVariables.contains(queueVariable) &&
							right instanceof EnumerationLiteralExpression) {
						throw new IllegalArgumentException("A previous (n)empty/(n)full should have handled this already")
//						return true
					}
				}
			}
		}
		
		return false
	}
	
	// isFull -> size variables or master queue - XSTS 8 <= sizeVar or master[0] != EMPTY || Promela full(q) 

	def isQueueFullExpression(Expression expression) {
		return expression.isQueueRightReferenceExpression(LessEqualExpression, InequalityExpression)
	}
	
	// isNotFull -> size variables or master queue - XSTS 8 > sizeVar or master[0] == EMPTY || Promela - full(q) 
	
	def isQueueNotFullExpression(Expression expression) {
		return expression.isQueueRightReferenceExpression(GreaterExpression, EqualityExpression)
	}
	
	// isEmpty -> size variables or master queue - XSTS sizeVar <= 0 or master[0] == EMPTY || Promela - empty(q) 
	
	def isQueueEmptyExpression(Expression expression) {
		return expression.isQueueLeftReferenceExpression(LessEqualExpression, EqualityExpression)
	}
	
	// isNotEmpty -> size variables or master queue - XSTS sizeVar > 0  or master[0] != EMPTY || Promela - nempty(q) 
	
	def isQueueNotEmptyExpression(Expression expression) {
		return expression.isQueueLeftReferenceExpression(GreaterExpression, InequalityExpression)
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
	
	private def isQueueExpression(Expression expression, boolean isLeftReference,
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
				if (left instanceof ArrayAccessExpression || // Original array
						left instanceof DirectReferenceExpression) { // Unfolded array
					val queueDeclaration = left.declaration
					if (queueDeclaration.global) {
						val xSts = queueDeclaration.containingXsts
						val messageQueues = newArrayList
						messageQueues += xSts.masterMessageQueueGroup.variables
						messageQueues += xSts.systemMasterMessageQueueGroup.variables
						
						val right = expression.rightOperand
						if (right instanceof EnumerationLiteralExpression) {
							val literal = right.reference
							val index = literal.index
							return messageQueues.contains(queueDeclaration) && index == 0
						}
					}
				}
			}
		}
		return false
	}
	
	// Entry point for queue action handling
	
	def isQueueAction(Action action) {
		return action.queueAddAction || action.queuePeekAction || action.queuePopAction ||
			action.queueSizeAction || action.queueInitializingAction
	}
	
	def isQueueAddAction(Action action) {
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			val queue = lhs.declaration
			if (queue.global) {
				val xSts = queue.containingXsts
				val messageQueues = xSts.messageQueueGroup.variables
				
				if (messageQueues.contains(queue)) {
					if (lhs instanceof ArrayAccessExpression) {
						checkState(queue.array)
						return true // Array
					}
					else if (!queue.array) { // Single variable
						val rhs = action.rhs
						val type = queue.typeDefinition
						val defaultExpression = type.defaultExpression
						
						return !rhs.helperEquals(defaultExpression) // As this is a reset action
					}
				}
			}
		}
		
		return false
	}
	
	def isQueuePopAction(Action action) {
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			val rhs = action.rhs
			if (lhs instanceof DirectReferenceExpression) {
				val queue = lhs.declaration
				if (queue.global) {
					val xSts = queue.containingXsts
					val messageQueues = xSts.messageQueueGroup.variables
					if (messageQueues.contains(queue)) {
						if (rhs instanceof ArrayLiteralExpression) {
							val head = rhs.operands.head // [ 0 <- array[1], ...]
							if (head instanceof ArrayAccessExpression) {
								checkState(queue.array)
								val declaration = head.declaration
								val index = head.index
								if (index instanceof IntegerLiteralExpression) {
									return declaration === queue && index.value == BigInteger.ONE
									// Good for now; additional checking needed if functions are extended
								}
							}
						}
						else if (!queue.array) { // master = _EMPTY
							val defaultExpression = queue.defaultExpression
							return rhs.helperEquals(defaultExpression)
						}
					}
				}
			}
		}
		
		return false
	}
	
	def isQueuePeekAction(Action action) {
		var Expression rhs = null
		
		if (action instanceof AssignmentAction) {
			rhs = action.rhs
		}
		else if (action instanceof VariableDeclarationAction) {
			val declaration = action.variableDeclaration
			rhs = declaration.expression
		}
		
		if (rhs instanceof ReferenceExpression) {
			val queue = rhs.declaration
			if (queue.global) {
				val xSts = queue.containingXsts
				val messageQueues = xSts.messageQueueGroup.variables
				
				if (messageQueues.contains(queue)) {
					if (rhs instanceof ArrayAccessExpression) {
						checkState(queue.array)
						val index = rhs.index.evaluateInteger
						return index == 0
					}
					else if (!queue.array) { // 1-capacity array
						return rhs instanceof DirectReferenceExpression
					}
				}
			}
		}
		
		return false
	}
	
	//
	
	def isQueueInitializingAction(Action action) {
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			val rhs = action.rhs
			if (lhs instanceof DirectReferenceExpression) {
				val queue = lhs.declaration
				if (queue.global) {
					val xSts = queue.containingXsts
					val messageQueues = xSts.messageQueueGroup.variables
					if (messageQueues.contains(queue)) {
						return rhs.helperEquals(
								queue.defaultExpression)
					}
				}
			}
		}
		return false
	}
	
	def isQueueSizeAction(Action action) {
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
	
}