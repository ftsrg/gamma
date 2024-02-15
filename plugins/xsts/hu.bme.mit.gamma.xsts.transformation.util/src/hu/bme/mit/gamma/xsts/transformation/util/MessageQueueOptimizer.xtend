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
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AtomicAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.transformation.serializer.ExpressionSerializer
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.List
import java.util.Map

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class MessageQueueOptimizer {
	// Singleton
	public static final MessageQueueOptimizer INSTANCE =  new MessageQueueOptimizer
	protected new() {}
	//
	
	// The V list retains the order of variables (indexes) in the original array
	protected final Map<Declaration, List<VariableDeclaration>> queueVariables = newHashMap
	//
	
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension MessageQueueUtil messageQueueUtil = MessageQueueUtil.INSTANCE
	protected final extension VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	// Model factories
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	//
	
	def void unfoldMessageQueues(XSTS xSts) {
		queueVariables.clear
		
		val messageQueueVariables = xSts.messageQueueGroup.variables
				.filter[it.array]
				
		if (messageQueueVariables.empty) {
			return // Nothing to optimize
		}
		
		for (messageQueueVariable : messageQueueVariables) {
			val arrayType = messageQueueVariable.typeDefinition as ArrayTypeDefinition
			val elementType = arrayType.elementType // Not typeDefinition as type can be enum, too
			val capacity = arrayType.size.evaluateInteger
			
			for (var i = 0; i < capacity; i++) {
				val clonedElementType = elementType.clone
				val name = messageQueueVariable.getFlattenedQueueVariableName(i)
				val queueVariable = clonedElementType.createVariableDeclarationWithDefaultInitialValue(name)
				
				val flattenedQueueVariables = queueVariables.getOrCreateList(messageQueueVariable)
				flattenedQueueVariables += queueVariable
				xSts.variableDeclarations += queueVariable
				
				// Adding the new variables to the corresponding variable group
				val messageQueueGroups = #[ xSts.masterMessageQueueGroup,
					 xSts.slaveMessageQueueGroup, xSts.systemMasterMessageQueueGroup,
					 xSts.systemSlaveMessageQueueGroup]
				
				for (messageQueueGroup : messageQueueGroups) {
					val queueVariables = messageQueueGroup.variables
					if (queueVariables.contains(messageQueueVariable)) {
						queueVariables += queueVariable
					}
				}
				//
			}
		}
		
		// Changing queue expressions where necessary
		val expressions = newArrayList
		
		val conditions = xSts.getAllContentsOfType(IfAction).map[it.condition]
		expressions += conditions.map[it.getSelfAndAllContentsOfType(Expression)].flatten
				.filter[it.queueExpression]
		
		for (expression : expressions) {
			expression.handleQueueExpression
		}
		//
		
		// Changing queue actions
		val atomicActions = xSts.getAllContentsOfType(AtomicAction)
		for (atomicAction : atomicActions) {
			atomicAction.handleQueueAction
		}
		
		// Delete message queues (not size variables)
		messageQueueVariables.forEach[it.delete]
	}
	
	//
	
	protected def getFlattenedQueueVariableName(Declaration queue, int index) {
		if (index <= 0) {
			return queue.name
		}
		return '''«queue.name»_«index»'''
	}
	
	//
	
	protected def getHead(Declaration queue) {
		val flattenedVariables = queueVariables.getOrCreateList(queue)
		val head = flattenedVariables.head
		return head
	}
	
	protected def getIndex(Declaration queue, int i) {
		val flattenedVariables = queueVariables.getOrCreateList(queue)
		val insideVariable = flattenedVariables.get(i)
		return insideVariable
	}
	
	protected def getLast(Declaration queue) {
		val flattenedVariables = queueVariables.getOrCreateList(queue)
		val last = flattenedVariables.last
		return last
	}
	
	// Entry point for queue expression handling
	
	protected def handleQueueExpression(Expression expression) {
		if (expression.queueExpression) {
			for (arrayAccess : expression.getSelfAndAllContentsOfType(ArrayAccessExpression)) {
				val queueVariable = arrayAccess.declaration
				val index = arrayAccess.index.evaluateInteger
				val variableSequence = queueVariables.get(queueVariable)
				val newVariable = variableSequence.get(index)
				
				newVariable.createReferenceExpression
						.replace(arrayAccess)
			}
		}
	}
	
	// Entry point for queue action handling
	
	def handleQueueAction(Action action) {
		if (action.queueAddAction) {
			action.handleQueueAddAction
		}
		else if (action.queuePeekAction) {
			action.handleQueuePeekAction
		}
		else if (action.queuePopAction) {
			action.handleQueuePopAction
		}
		else if (action.queueSizeAction) {
			action.handleQueueSizeAction
		}
		else if (action.queueInitializingAction) { // After queuePopAction
			action.handleQueueInitializingAction
		}
	}
	
	// add -> if (size == 0) {q0 := x } else if (size == 1) { q1 := x }...
	
	protected def handleQueueAddAction(Action action) {
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			val rhs = action.rhs
			if (lhs instanceof ArrayAccessExpression) {
				val array = lhs.declaration
				val index = lhs.index
				
				val flattenedQueueVariables = queueVariables.get(array)
				if (index.evaluable) { // q[1] := x;
					val i = index.evaluateInteger
					val flattenedQueueVariable = flattenedQueueVariables.get(i)
					val clonedRhs = rhs.clone
					
					val addAction = flattenedQueueVariable.createAssignmentAction(clonedRhs)
					
					addAction.replace(action)
				}
				else { // q[size] := x;
					val sizeVariable = index.declaration
					
					val ifActions = newArrayList
					for (var i = 0; i < flattenedQueueVariables.size; i++) {
						val condition = sizeVariable.createReferenceExpression
								.createEqualityExpression(i.toIntegerLiteral)
								
						val flattenedQueueVariable = flattenedQueueVariables.get(i)
						val clonedRhs = rhs.clone
						val addAction = flattenedQueueVariable.createAssignmentAction(clonedRhs)
						
						ifActions += condition.createIfAction(addAction)
					}
					
					val newAddAction = ifActions.weave
					newAddAction.replace(action)
				}
				return
			}
		}
		throw new IllegalArgumentException("Not known action: " + action)
	}
	
	// pop -> q0 := q1; q1 := q2; ... ; qn := 0/false/...;
	
	protected def handleQueuePopAction(Action action) {
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			if (lhs instanceof DirectReferenceExpression) {
				val array = lhs.declaration
				val type = array.typeDefinition
				if (type instanceof ArrayTypeDefinition) {
					val elementType = type.elementType.typeDefinition
					val newPopActions = newArrayList
					val flattenedQueueVariables = queueVariables.get(array)
					// q0 := q1; q1 := q2;
					for (var i = 0; i < flattenedQueueVariables.size - 1; i++) {
						val flattenedQueueVariable = flattenedQueueVariables.get(i)
						val nextFlattenedQueueVariable = flattenedQueueVariables.get(i + 1)
						
						newPopActions += flattenedQueueVariable
								.createAssignmentAction(nextFlattenedQueueVariable)
					}
					// qn := 0/false/...;
					val lastFlattenQueueVariable = array.last
					val emptyExpression = elementType.defaultExpression
					
					newPopActions += lastFlattenQueueVariable.createAssignmentAction(emptyExpression)
					
					val newPopAction = newPopActions.createSequentialAction
					newPopAction.replace(action)
					return
				}
			}
		}
		throw new IllegalArgumentException("Not known action: " + action)
	}
	
	// peek -> x := q0; (assume q0 != 0);
	
	protected def handleQueuePeekAction(Action action) {
		// We always merge peek and pop
		
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
			val arrayType = array.type.typeDefinition as ArrayTypeDefinition
			val elementType = arrayType.elementType.typeDefinition
			
			val head = array.head
			val headReference = head.createReferenceExpression
			
			headReference.replace(rhs)
			
			// Optimization for the solver: assume q0 != 0 (master queue)
			if (array.masterQueueVariable) {
				val emptyValue = elementType.defaultExpression
				val notEmptyExpression = head.createInequalityExpression(emptyValue)
				val notEmptyAssumption = notEmptyExpression.createAssumeAction
				//
				action.appendToAction(notEmptyAssumption) // Note that the XU mapping has to deal with this
			}
			return
		}
		throw new IllegalArgumentException("Not known action: " + action)
	}
	
	//
	
	protected def handleQueueInitializingAction(Action action) {
		if (action instanceof AssignmentAction) {
			val lhs = action.lhs
			val rhs = action.rhs
			if (lhs instanceof DirectReferenceExpression) {
				val array = lhs.declaration
				if (rhs instanceof ArrayLiteralExpression) {
					val newInitActions = newArrayList
					val flattenedQueueVariables = queueVariables.get(array)
					
					var i = 0
					for (flattenedQueueVariable : flattenedQueueVariables) {
						val literalExpression = rhs.operands.get(i++).clone
						newInitActions += flattenedQueueVariable.createAssignmentAction(literalExpression)
					}
					
					val newInitAction = newInitActions.createSequentialAction
					newInitAction.replace(action)
					return
				}
			}	
		}
		throw new IllegalArgumentException("Not known action: " + action)
	}
	
	// size := size + 1 / - 1
	
	protected def handleQueueSizeAction(Action action) {
		return // No operation
	}
	
	// TODO clear -> || queue := [0 -> 0, ...]
	
}