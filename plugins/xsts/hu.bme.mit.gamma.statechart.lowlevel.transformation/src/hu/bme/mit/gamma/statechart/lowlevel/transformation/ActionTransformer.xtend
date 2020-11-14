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
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.CompositeTypeDefinition
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DefaultExpression
import hu.bme.mit.gamma.expression.model.ElseExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FieldDeclaration
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.TypeDefinition
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
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
import java.util.Set
import java.util.Stack

import static com.google.common.base.Preconditions.checkState

import static extension com.google.common.collect.Iterables.getOnlyElement

class ActionTransformer {
	// Auxiliary objects
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ExpressionPreconditionTransformer preconditionTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
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
	
	new(Trace trace, boolean functionInlining, int maxRecursionDepth, String assertionVariableName) {
		this.trace = trace
		this.functionInlining = functionInlining
		this.maxRecursionDepth = maxRecursionDepth
		this.expressionTransformer = new ExpressionTransformer(this.trace, this.functionInlining)
		this.assertionVariableName = assertionVariableName
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
		} else if (block.actions.size == 0) {
			return createEmptyStatement;
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
		var lowlevelPrecondition = action.variableDeclaration.expression !== null ? action.variableDeclaration.expression.transformPrecondition : new LinkedList<Action>
		
		val variableDeclarations = action.variableDeclaration.transformVariable
		result += lowlevelPrecondition
		for (variableDeclaration : variableDeclarations) {
			result += createVariableDeclarationStatement => [
				it.variableDeclaration = variableDeclaration
			]	
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
	
	protected def dispatch List<Action> transformAction(ConstantDeclarationStatement action, LinkedList<Action> following) {
		throw new IllegalArgumentException("Constant declaration statements are not yet transformed: " + action)
	}
	
	protected def dispatch List<Action> transformAction(ExpressionStatement action, LinkedList<Action> following) {
		// Create return variable
		var result = new LinkedList<Action>
		// Get expression precondition
		var lowlevelPrecondition = action.expression.transformPrecondition
		result += lowlevelPrecondition
		// Transform expression if it has side-effects
		if (!(action.expression instanceof FunctionAccessExpression)) {
			result += createEmptyStatement;
		} else if (functionInlining) {	//if function access
			result += createEmptyStatement;
		} else {	//if function access without inlining
			throw new IllegalArgumentException("Non-inlined functions currently not allowed: " + action)
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
				it.rhs = action.expression.transformExpression.getOnlyElement
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
			guardExpressions += conditional.guard.transformExpression.getOnlyElement
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
	
	protected def dispatch List<Action> transformAction(SwitchStatement action, LinkedList<Action> following) {
		// No fallthrough functionality!
		// Create return variable
		var result = new LinkedList<Action>
		// Transform the guards (and their preconditions)
		var defaultFlag = false
		val List<Expression> guardExpressions = new ArrayList<Expression>
		val List<Action> guardPreconditions = new ArrayList<Action>
		guardPreconditions.addAll(action.controlExpression.transformPrecondition)
		val controlExpression = action.controlExpression.transformExpression.getOnlyElement
		for (conditional : action.cases) {
			guardPreconditions.addAll(conditional.guard.transformPrecondition)
			guardExpressions += conditional.guard.transformExpression.getOnlyElement
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
						it.leftOperand = controlExpression.transformExpression.getOnlyElement
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
			guardExpressions += conditional.guard.transformExpression.getOnlyElement
		}
		result += guardPreconditions
		// Transform the statement itself (including the following-context)
		val transformedAction = createIfStatement => [
			it.conditionals += createBranch => [
				it.guard = createOrExpression => [
					for (guard : guardExpressions) {
						it.operands += guard.transformExpression.getOnlyElement
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
		//Get the referred high-level declaration (assuming a single, assignable element)
		val Set<ValueDeclaration> referredDeclarations = newHashSet
		referredDeclarations.addAll(action.lhs.referredVariables)
		referredDeclarations.addAll(action.lhs.referredParameters)
		val referredDeclaration = referredDeclarations.getOnlyElement
		checkState(referredDeclaration instanceof VariableDeclaration || referredDeclaration instanceof ParameterDeclaration)	//transformed to assignable type (=variable)
		// Transform lhs
		val List<ReferenceExpression> lowlevelLhs = new ArrayList<ReferenceExpression>
		System.out.println("Assignment to type: " + referredDeclaration.type)	//TODO delete
		var typeToAssign = referredDeclaration.type.typeDefinitionFromType;
		if (!(typeToAssign instanceof CompositeTypeDefinition)) {
			lowlevelLhs += createDirectReferenceExpression => [
				if(referredDeclaration instanceof VariableDeclaration)
					it.declaration = trace.get(referredDeclaration as VariableDeclaration)
				else if(referredDeclaration instanceof ParameterDeclaration)
					it.declaration = trace.get(referredDeclaration as ParameterDeclaration)
			]
		} else {
			var originalLhsVariables = exploreComplexType(referredDeclaration, typeToAssign, new ArrayList<FieldDeclaration>)
			System.out.println("OriginalLhs: " + originalLhsVariables)	//TODO delete
			
			// access expressions:
			var List<Object> accessList = action.lhs.collectAccessList
			var List<String> recordAccessList = new ArrayList<String>
			for (elem : accessList) {
				if (elem instanceof String) {
					recordAccessList.add(elem)
				}
			}
			System.out.println("AccessList:" + recordAccessList + " --- size:" + recordAccessList.size);
			
			for (elem : originalLhsVariables) {	
				if (isSameAccessTree(elem.value, recordAccessList)) {	//filter according to the access list
					// Create lhs
					lowlevelLhs += createDirectReferenceExpression => [
						if (trace.isMapped(elem)) {	//mapped as complex type
							it.declaration = trace.get(elem)
						} else if ((elem.key instanceof VariableDeclaration && trace.isMapped(elem.key as VariableDeclaration)) || 
							(elem.key instanceof ParameterDeclaration && trace.isMapped(elem.key as ParameterDeclaration))
						) {	//simple arrays are mapped as a simple type (either var or par)
							if (elem.key instanceof VariableDeclaration)
								it.declaration = trace.get(elem.key as VariableDeclaration)
							else if (elem.key instanceof ParameterDeclaration)
								it.declaration = trace.get(elem.key as ParameterDeclaration)
						} else {
							throw new IllegalArgumentException("Transformed variable declaration not found!")
						}
					]
				}
			}
		}
		
		// Get rhs precondition
		val lowlevelPrecondition = action.rhs.transformPrecondition
		result += lowlevelPrecondition
		// Transform rhs and create action
		val List<Expression> lowlevelRhs = new ArrayList<Expression>
		lowlevelRhs += action.rhs.transformExpression
		System.out.println("LowlevelRhs: " + lowlevelRhs)	//TODO delete
		if (lowlevelLhs.size != lowlevelRhs.size) {	
			throw new IllegalArgumentException("Impossible assignment: " + lowlevelRhs.size + " elements to " + lowlevelLhs.size)
		}
		for (var i = 0; i < lowlevelLhs.size; i++) {
			val lhs = lowlevelLhs.get(i)
			val rhs = lowlevelRhs.get(i)
			result += createAssignmentStatement => [
				it.lhs = lhs
				it.rhs = rhs
			]
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
		// Create return variable and transform the current action
		var result = new LinkedList<Action>
		var lowlevelPrecondition = action.assertion.transformPrecondition
		result.addAll(lowlevelPrecondition)
		// If there is an assertion variable, branch and assign, otherwise discard
		val lhsVariable = trace.getAssertionVariable(assertionVariableName)
		if (lhsVariable !== null) {
			result += createIfStatement => [
				it.conditionals += createBranch => [
					it.guard = action.assertion.transformExpression.getOnlyElement
					it.action = createBlock => [
						it.actions += createAssignmentStatement => [
							it.lhs = createDirectReferenceExpression => [
								it.declaration = lhsVariable
							]
							it.rhs = createTrueExpression
						]
						val newFollowing = new LinkedList<Action>
						newFollowing.addAll(following)
						val next = newFollowing.removeFirst
						it.actions += next.transformAction(newFollowing)
					]
				]
				it.conditionals += createBranch => [
					it.guard = createElseExpression
					it.action = createBlock => [
						val newFollowing = new LinkedList<Action>
						newFollowing.addAll(following)
						val next = newFollowing.removeFirst
						it.actions += next.transformAction(newFollowing)
					]
				]
			]
			
		} else {
			// Create new following-context variable and transform the following-context
			var newFollowing = new LinkedList<Action>
			newFollowing.addAll(following)
			if(newFollowing.size > 0) {
				var next = newFollowing.removeFirst()
				result.addAll(transformAction(next, newFollowing))
			}
		}
		
		// Return the result
		return result
	}
	
	// Gamma statechart elements

	protected def dispatch List<Action> transformAction(RaiseEventAction action, LinkedList<Action> following) {
		// TODO complex parameter types if needed?
		// Create return variable and transform the current action
		var result = new LinkedList<Action>
		val port = action.port
		val event = action.event
		val lowlevelEvent = trace.get(port, event, EventDirection.OUT)
		var i = 0
		// Parameter setting
		for (exp : action.arguments) {
			val parameterDeclaration = lowlevelEvent.parameters.get(i++) // Getting the i-th parameter
			val parameterValue = exp.transformExpression.getOnlyElement
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
	
	//TODO remove (alternative found, see Assignment)
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