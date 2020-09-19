/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.model.AssertionStatement
import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.action.model.Block
import hu.bme.mit.gamma.action.model.BreakStatement
import hu.bme.mit.gamma.action.model.ChoiceStatement
import hu.bme.mit.gamma.action.model.ConstantDeclarationStatement
import hu.bme.mit.gamma.action.model.EmptyStatement
import hu.bme.mit.gamma.action.model.ExpressionStatement
import hu.bme.mit.gamma.action.model.ForStatement
import hu.bme.mit.gamma.action.model.IfStatement
import hu.bme.mit.gamma.action.model.ReturnStatement
import hu.bme.mit.gamma.action.model.SwitchStatement
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement
import hu.bme.mit.gamma.expression.model.AccessExpression
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.CompositeTypeDefinition
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DefaultExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.ElseExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.TypeDefinition
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.statechart.DeactivateTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.math.BigInteger
import java.util.ArrayList
import java.util.Collection
import java.util.LinkedList
import java.util.List
import java.util.Stack

class ActionTransformer {
	// Auxiliary objects
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ExpressionPreconditionTransformer preconditionTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	// Factory objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE
	// Trace
	protected final Trace trace
	// Transformation parameters
	protected final String assertionVariableName
	protected final boolean functionInlining
	protected final int maxRecursionDepth
	// Etc
	protected Stack<VariableDeclaration> returnStack = new Stack<VariableDeclaration>();
	
	new(Trace trace, boolean functionInlining, int maxRecursionDepth) {
		this.trace = trace
		this.functionInlining = functionInlining
		this.maxRecursionDepth = maxRecursionDepth
		this.expressionTransformer = new ExpressionTransformer(this.trace, this.functionInlining)
		this.assertionVariableName = "assertionFailed"
		this.preconditionTransformer = new ExpressionPreconditionTransformer(this.trace, this.expressionTransformer, this, assertionVariableName, functionInlining, maxRecursionDepth)
	}
	
	protected def transformActions(Collection<? extends Action> actions) {
		if (actions.empty) {
			return createEmptyStatement
		}
		val block = createBlock
		
		val following = new LinkedList<Action>
		following.addAll(actions)
		val next = following.removeFirst
		block.actions.addAll(next.transformAction(following))
		 
		if (block.actions.size == 1) {
			return block.actions.head
		}
		return block
	}
	
	// Gamma action language
	
	// action (trivially) must not be null
	// following (by definition) must not be null (but may be empty)
	protected def dispatch List<Action> transformAction(Action action, LinkedList<Action> following) {
		throw new IllegalArgumentException("Not known action: " + action)
	}
	
	protected def dispatch List<Action> transformAction(EmptyStatement action, LinkedList<Action> following) {
		// Create return variable and transform the current action
		var result = new LinkedList<Action>
		result += createEmptyStatement
		// Create new following-context variable and transform the following-context
		var newFollowing = new LinkedList<Action>
		newFollowing.addAll(following)
		if(newFollowing.size > 0) {
			var next = newFollowing.removeFirst()
			result.addAll(transformAction(next, newFollowing))
		}
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(Block action, LinkedList<Action> following) {
		// Create return variable
		var result = new LinkedList<Action>
		// Create new following-context variable and do the transformations
		var newFollowing = new LinkedList<Action>
		newFollowing.addAll(action.actions)

		newFollowing.addAll(following)
		if(newFollowing.size > 0) {
			var next = newFollowing.removeFirst()
			result.addAll(transformAction(next, newFollowing))
		}
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(VariableDeclarationStatement action, LinkedList<Action> following) {
		// Create return variable and transform the current action
		var result = new LinkedList<Action>
		var lowlevelPrecondition = action.variableDeclaration.expression.transformPrecondition
		val variableDeclaration = createVariableDeclarationStatement => [
			it.variableDeclaration = createVariableDeclaration => [
				it.name = action.variableDeclaration.name
				it.type = action.variableDeclaration.type.transformType
				it.expression = action.variableDeclaration.expression.transformExpression
			]
		]
		trace.put(action.variableDeclaration, variableDeclaration.variableDeclaration)
		result += lowlevelPrecondition
		result += variableDeclaration
		// Create new following-context variable and transform the following-context
		var newFollowing = new LinkedList<Action>
		newFollowing.addAll(following)
		if(newFollowing.size > 0) {
			var next = newFollowing.removeFirst()
			result.addAll(transformAction(next, newFollowing))
		}
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(ConstantDeclarationStatement action, LinkedList<Action> following) {
		throw new IllegalArgumentException("Not known action: " + action)
	}
	
	protected def dispatch List<Action> transformAction(ExpressionStatement action, LinkedList<Action> following) {
		// Create return variable
		var result = new LinkedList<Action>
		// Get expression precondition
		var lowlevelPrecondition = action.expression.transformPrecondition
		result += lowlevelPrecondition
		// Transform expression if it has side-effects
		if (!functionInlining) {
			
		}
		// Create new following-context variable and transform the following-context
		var newFollowing = new LinkedList<Action>
		newFollowing.addAll(following)
		if(newFollowing.size > 0) {
			var next = newFollowing.removeFirst()
			result.addAll(transformAction(next, newFollowing))
		}
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(BreakStatement action, LinkedList<Action> following) {
		return new LinkedList<Action>
	}
	
	protected def dispatch List<Action> transformAction(ReturnStatement action, LinkedList<Action> following) {
		// Create return variable and transform the current action (discard the following-context)
		var result = new LinkedList<Action>
		if (action.expression !== null) {
			val precondition = action.expression.transformPrecondition
			val transformedAction = createAssignmentStatement => [
				it.lhs = createDirectReferenceExpression => [
					//it.declaration = returnStack.pop()
					it.declaration = returnStack.peek()
				]
				it.rhs = action.expression.transformExpression
			]
			result.addAll(precondition)
			result.add(transformedAction)
		}
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(IfStatement action, LinkedList<Action> following) {
		// Create return variable
		var result = new LinkedList<Action>
		// Transform the guards (and their preconditions)
		var elseFlag = false
		val List<Expression> guardExpressions = new ArrayList<Expression>
		val List<Action> guardPreconditions = new ArrayList<Action>
		for (conditional : action.conditionals) {
			guardPreconditions.addAll(conditional.guard.transformPrecondition)
			guardExpressions += conditional.guard.transformExpression
			if (conditional.guard instanceof ElseExpression) {
				elseFlag = true
			}
		}
		result += guardPreconditions
		// Transform the statement itself (including the following-context)
		val transformedAction = createIfStatement => [
			for (i : 0 .. action.conditionals.size - 1) {
				it.conditionals += createBranch => [
					it.guard = guardExpressions.get(i)
					it.action = createBlock => [
						val newFollowing = new LinkedList<Action>
						newFollowing.addAll(following)
						it.actions += action.conditionals.get(i).action.transformAction(newFollowing)
					]
				]
			}
		]
		if (!elseFlag) {
			transformedAction.conditionals += createBranch => [
				it.guard = createElseExpression
				it.action = createBlock => [
					val newFollowing = new LinkedList<Action>
					newFollowing.addAll(following)
					if (newFollowing.size > 0) {
						val next = newFollowing.removeFirst
						it.actions += next.transformAction(newFollowing)
					}
				]
			]
		}
		result += transformedAction
		// Return the result
		return result
	}
	
	// No fallthrough functionality
	protected def dispatch List<Action> transformAction(SwitchStatement action, LinkedList<Action> following) {
		// Create return variable
		var result = new LinkedList<Action>
		// Transform the guards (and their preconditions)
		var defaultFlag = false
		val List<Expression> guardExpressions = new ArrayList<Expression>
		val List<Action> guardPreconditions = new ArrayList<Action>
		guardPreconditions.addAll(action.controlExpression.transformPrecondition)
		val controlExpression = action.controlExpression.transformExpression
		for (conditional : action.cases) {
			guardPreconditions.addAll(conditional.guard.transformPrecondition)
			guardExpressions += conditional.guard.transformExpression
			if (conditional.guard instanceof DefaultExpression) {
				defaultFlag = true
			}
		}
		result += guardPreconditions
		// Transform the statement itself (including the following-context)
		val transformedAction = createIfStatement => [
			for (i : 0 .. action.cases.size - 1) {
				it.conditionals += createBranch => [
					it.guard = createEqualityExpression => [
						it.leftOperand = controlExpression.transformExpression	//TODO not so nice: already transformed, just copying
						it.rightOperand = guardExpressions.get(i)
					]
					it.action = createBlock => [
						val newFollowing = new LinkedList<Action>
						newFollowing.addAll(following)
						it.actions += action.cases.get(i).action.transformAction(newFollowing)
					]
				]
			}
		]
		if (!defaultFlag) {
			transformedAction.conditionals += createBranch => [
				it.guard = createElseExpression
				it.action = createBlock => [
					val newFollowing = new LinkedList<Action>
					newFollowing.addAll(following)
					if (newFollowing.size > 0) {
						val next = newFollowing.removeFirst
						it.actions += next.transformAction(newFollowing)
					}
				]
			]
		}
		result += transformedAction
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(ForStatement action, LinkedList<Action> following) {
		// Create return variable and transform the current action
		var result = new LinkedList<Action>
		// enumerate parameter values
		val parameterValues = action.range.enumerateExpression
		// transform parameter variable and add to the result
		val parameterVariableDeclaration = createVariableDeclarationStatement => [
			it.variableDeclaration = createVariableDeclaration => [
				it.name = action.parameter.name
				it.type = action.parameter.type.transformType
			]
		]
		trace.put(action.parameter, parameterVariableDeclaration.variableDeclaration)
		result += parameterVariableDeclaration
		// create 'unrolled for' (to be transformed)
		val unrolledFor = new LinkedList<Action>
		for(parameterValue : parameterValues) {
			unrolledFor += createAssignmentStatement => [
				it.lhs = createDirectReferenceExpression => [
					it.declaration = action.parameter
				]
				it.rhs = parameterValue
			]
			unrolledFor += action.body
		}
		if(action.then !== null)
			unrolledFor += action.then
		// call transform on the 'unrolled for' and add to the transformed for
		val first = unrolledFor.removeFirst
		result += first.transformAction(unrolledFor)
		// Create new following-context variable and transform the following-context
		var newFollowing = new LinkedList<Action>
		newFollowing.addAll(following)
		if(newFollowing.size > 0) {
			var next = newFollowing.removeFirst()
			result.addAll(transformAction(next, newFollowing))
		}
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(ChoiceStatement action, LinkedList<Action> following) {
		// Create return variable
		var result = new LinkedList<Action>
		// Transform the guards (and their preconditions)
		val List<Expression> guardExpressions = new ArrayList<Expression>
		val List<Action> guardPreconditions = new ArrayList<Action>
		for (conditional : action.branches) {
			guardPreconditions.addAll(conditional.guard.transformPrecondition)
			guardExpressions += conditional.guard.transformExpression
		}
		result += guardPreconditions
		// Transform the statement itself (including the following-context)
		val transformedAction = createIfStatement => [
			it.conditionals += createBranch => [
				it.guard = createOrExpression => [
					for (guard : guardExpressions) {
						it.operands += guard.transformExpression	//TODO not so nice: already transformed, just copy
					}
				]
				it.action = createBlock => [
					it.actions += createChoiceStatement => [
						for (i : 0 .. action.branches.size - 1) {
							it.branches += createBranch => [
								it.guard = guardExpressions.get(i)
								it.action = createBlock => [
									val newFollowing = new LinkedList<Action>
									newFollowing.addAll(following)
									it.actions += action.branches.get(i).action.transformAction(newFollowing)
								]
							]
						}
					]
				]
			]
			it.conditionals += createBranch => [
				it.guard = createElseExpression
				it.action = createBlock => [
					val newFollowing = new LinkedList<Action>
					newFollowing.addAll(following)
					if (newFollowing.size > 0) {
						val next = newFollowing.removeFirst
						it.actions += next.transformAction(newFollowing)
					}
				]
			]
		]
		result += transformedAction
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(AssignmentStatement action, LinkedList<Action> following) {
		// Create return variable and transform the current action
		var result = new LinkedList<Action>
		val referredDeclaration = findDeclarationOfReference(action.lhs)
		if (referredDeclaration instanceof VariableDeclaration || referredDeclaration instanceof ParameterDeclaration) {
			// Transform lhs
			var ReferenceExpression lowlevelLhs = null
			if (!(referredDeclaration.type instanceof CompositeTypeDefinition)) {
				lowlevelLhs = createDirectReferenceExpression => [
					if(referredDeclaration instanceof VariableDeclaration)
						it.declaration = trace.get(referredDeclaration)
					else if(referredDeclaration instanceof ParameterDeclaration)
						it.declaration = trace.get(referredDeclaration)
				]
			} else {
				throw new IllegalArgumentException("Assignments to composite types are not yet supported: " + referredDeclaration.type.class)
			}
			// Get rhs precondition
			var lowlevelPrecondition = action.rhs.transformPrecondition
			// Transform rhs and create action
			val lowlevelAction = createAssignmentStatement
			lowlevelAction.lhs = lowlevelLhs
			lowlevelAction.rhs = action.rhs.transformExpression
			// Add the transformed actions in the correct order
			result += lowlevelPrecondition
			result += lowlevelAction
		}
		else {
			throw new IllegalArgumentException("Not assignable declaration: " + referredDeclaration)
		}
		// Create new following-context variable and transform the following-context
		var newFollowing = new LinkedList<Action>
		newFollowing.addAll(following)
		if(newFollowing.size > 0) {
			var next = newFollowing.removeFirst()
			result.addAll(transformAction(next, newFollowing))
		}
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(AssertionStatement action, LinkedList<Action> following) {
		throw new IllegalArgumentException("Not known action: " + action)
	}
	
	// Gamma statechart elements

	protected def dispatch List<Action> transformAction(RaiseEventAction action, LinkedList<Action> following) {
		// Create return variable and transform the current action
		var result = new LinkedList<Action>
		val port = action.port
		val event = action.event
		val lowlevelEvent = trace.get(port, event, EventDirection.OUT)
		var i = 0
		// Parameter setting
		for (exp : action.arguments) {
			val parameterDeclaration = lowlevelEvent.parameters.get(i++) // Getting the i-th parameter
			val parameterValue = exp.transformExpression
			val parameterAssignment = createAssignmentStatement => [
				it.lhs = createDirectReferenceExpression => [
					it.declaration = parameterDeclaration
				]
				it.rhs = parameterValue
			]
			result += parameterAssignment
		}
		// Setting IsRaised flag to true
		val flagRaising = createAssignmentStatement => [
			it.lhs = createDirectReferenceExpression => [
				it.declaration = lowlevelEvent.isRaised
			]
			it.rhs = createTrueExpression
		]
		result += flagRaising
		// Create new following-context variable and transform the following-context
		var newFollowing = new LinkedList<Action>
		newFollowing.addAll(following)
		if(newFollowing.size > 0) {
			var next = newFollowing.removeFirst()
			result.addAll(transformAction(next, newFollowing))
		}
		// Return the result
		return result
	}

	protected def dispatch List<Action> transformAction(SetTimeoutAction action, LinkedList<Action> following) {
		// Create return variable and transform the current action
		var result = new LinkedList<Action>
		val lowlevelTimeout = trace.get(action.timeoutDeclaration)
		// Setting the clock to 0 as contrary to Gamma, in the lowlevel language time elapses from 0 to infinity
		val clockInit = createAssignmentStatement => [
			it.lhs = createDirectReferenceExpression => [
				it.declaration = lowlevelTimeout
			]
			it.rhs = createIntegerLiteralExpression => [
				it.value = BigInteger.ZERO
			]
		]
		result += clockInit
		// Create new following-context variable and transform the following-context
		var newFollowing = new LinkedList<Action>
		newFollowing.addAll(following)
		if(newFollowing.size > 0) {
			var next = newFollowing.removeFirst()
			result.addAll(transformAction(next, newFollowing))
		}
		// Return the result
		return result
	}

	protected def dispatch List<Action> transformAction(DeactivateTimeoutAction action, LinkedList<Action> following) {
		throw new UnsupportedOperationException("DeactivateTimeoutActions are not yet transformed: " + action)
	}
	
	//TODO extract into util class
	private def Declaration findDeclarationOfReference(Expression reference) {
		if(reference instanceof DirectReferenceExpression) {
			return reference.declaration
		} else if (reference instanceof AccessExpression) {
			return findDeclarationOfReference(reference.operand)
		} else {
			throw new IllegalArgumentException("Not known reference type: " + reference.class)
		}
	}
	
	private def dispatch List<Expression> enumerateExpression(Expression expression) {
		//if reference to enum
		//LITERALS
		//else if array literal
		//else if ir literal
		//REFERENCES
		//else if direct ref (to array)
		//else if direct ref (to ir)
		//else if access to array
		//else if access to function
		//else if access to record
		throw new IllegalArgumentException("Cannot evaluate expression: " + expression)
	}
	
	private def dispatch List<Expression> enumerateExpression(ArrayLiteralExpression expression) {
		var result = new ArrayList<Expression>
		result.addAll(expression.operands)
		return result
	}
	
	private def dispatch List<Expression> enumerateExpression(IntegerRangeLiteralExpression expression) {
		val result = new ArrayList<Expression>()
		
		//check evaluability (TODO)
		if (!(expression.leftOperand instanceof IntegerLiteralExpression && expression.rightOperand instanceof IntegerLiteralExpression)) {
			throw new IllegalArgumentException("Cannot evaluate integer literal expression: " + expression)
		}
		
		//evaluate if possible
		val left = expression.leftOperand as IntegerLiteralExpression
		val start = expression.leftInclusive ? left.value.intValue : left.value.intValue + 1
		val right = expression.rightOperand as IntegerLiteralExpression
		val end = expression.rightInclusive ? right.value.intValue : right.value.intValue - 1
		for (var i = start; i <= end; i++) {
			val newLiteral = createIntegerLiteralExpression
			newLiteral.value = BigInteger.valueOf(i)
			result.add(newLiteral)
		}
		
		return result
	}
	
	//TODO extract into separate class
	private def TypeDefinition findTypeDefinitionOfDeclaration(Declaration declaration) {
		if (declaration.type instanceof TypeDefinition) {
			return declaration.type as TypeDefinition
		} else if (declaration.type instanceof TypeReference) {
			return findTypeDefinitionOfDeclaration((declaration.type as TypeReference).reference)
		} else {
			throw new IllegalArgumentException("Not known type: " + declaration.type)
		}
	}
	
}