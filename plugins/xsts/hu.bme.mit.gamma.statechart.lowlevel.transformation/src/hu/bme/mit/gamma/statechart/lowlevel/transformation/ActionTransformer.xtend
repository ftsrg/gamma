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
import hu.bme.mit.gamma.expression.model.CompositeTypeDefinition
import hu.bme.mit.gamma.expression.model.DefaultExpression
import hu.bme.mit.gamma.expression.model.ElseExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.InitializableElement
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.statechart.DeactivateTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.math.BigInteger
import java.util.Collection
import java.util.List
import java.util.Stack

import static com.google.common.base.Preconditions.checkState

import static extension com.google.common.collect.Iterables.getOnlyElement
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class ActionTransformer {
	// Auxiliary objects
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ValueDeclarationTransformer valueDeclarationTransformer
	protected final extension ExpressionPreconditionTransformer preconditionTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
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
	protected Stack<List<VariableDeclaration>> returnStack = new Stack<List<VariableDeclaration>>
	
	new(Trace trace, boolean functionInlining, int maxRecursionDepth, String assertionVariableName) {
		this.trace = trace
		this.functionInlining = functionInlining
		this.maxRecursionDepth = maxRecursionDepth
		this.expressionTransformer = new ExpressionTransformer(this.trace, this.functionInlining)
		this.valueDeclarationTransformer = new ValueDeclarationTransformer(this.trace)
		this.assertionVariableName = assertionVariableName
		this.preconditionTransformer = new ExpressionPreconditionTransformer(this.trace,
			this.expressionTransformer, this.valueDeclarationTransformer,
			new TypeTransformer(trace), this, assertionVariableName,
			functionInlining, maxRecursionDepth
		)
	}
	
	protected def transformActions(Collection<? extends Action> actions) {
		if (actions.empty) {
			return createEmptyStatement
		}
		val block = createBlock
		
		val following = <Action>newLinkedList
		following += actions
		val next = following.removeFirst
		block.actions += next.transformAction(following)
		 
		if (block.actions.size == 1) {
			return block.actions.head
		}
		else if (block.actions.size == 0) {
			return createEmptyStatement
		}
		return block
	}
	
	// Gamma action language
	
	// action (trivially) must not be nullf
	// following (by definition) must not be null (but may be empty)
	protected def dispatch List<Action> transformAction(Action action, List<Action> following) {
		throw new IllegalArgumentException("Not known action: " + action)
	}
	
	protected def dispatch List<Action> transformAction(EmptyStatement action, List<Action> following) {
		// Create return variable and transform the current action
		val result = <Action>newLinkedList
		result += createEmptyStatement
		// Create new following-context variable and transform the following-context
		val newFollowing = <Action>newLinkedList
		newFollowing += following
		if (newFollowing.size > 0) {
			val next = newFollowing.removeFirst
			result += transformAction(next, newFollowing)
		}
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(Block action, List<Action> following) {
		// Create return variable
		val result = <Action>newLinkedList
		// Create new following-context variable and do the transformations
		val newFollowing = <Action>newLinkedList
		newFollowing += action.actions

		newFollowing += following
		if (newFollowing.size > 0) {
			val next = newFollowing.removeFirst
			result += transformAction(next, newFollowing)
		}
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(VariableDeclarationStatement action, List<Action> following) {
		// Create return variable and transform the current action
		val result = <Action>newLinkedList
		val variableDeclaration = action.variableDeclaration
		
		variableDeclaration.transformValueDeclarationAction(result)
		// Create new following-context variable and transform the following-context
		var newFollowing = <Action>newLinkedList
		newFollowing += following
		if (newFollowing.size > 0) {
			val next = newFollowing.removeFirst
			result += next.transformAction(newFollowing)
		}
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(ConstantDeclarationStatement action, List<Action> following) {
		val result = <Action>newLinkedList
		val constantDeclaration = action.constantDeclaration
		
		constantDeclaration.transformValueDeclarationAction(result)
		// Create new following-context variable and transform the following-context
		val newFollowing = <Action>newLinkedList
		newFollowing += following
		if (newFollowing.size > 0) {
			val next = newFollowing.removeFirst
			result += transformAction(next, newFollowing)
		}
		// Return the result
		return result
	}
	
	private def <T extends ValueDeclaration & InitializableElement> transformValueDeclarationAction(
			T valueDeclaration, List<Action> result) {
		val initalExpression = valueDeclaration.expression
		var lowlevelPrecondition = initalExpression !== null ?
			initalExpression.transformPrecondition : <Action>newLinkedList
		result += lowlevelPrecondition
		
		val lowlevelVariableDeclarations = valueDeclaration.transformValue
		for (lowlevelVariableDeclaration : lowlevelVariableDeclarations) {
			result += createVariableDeclarationStatement => [
				it.variableDeclaration = lowlevelVariableDeclaration
			]	
		}
	}
	
	protected def dispatch List<Action> transformAction(ExpressionStatement action, List<Action> following) {
		// Create return variable
		val result = <Action>newLinkedList
		// Get expression precondition
		var lowlevelPrecondition = action.expression.transformPrecondition
		result += lowlevelPrecondition
		// Transform expression if it has side-effects
		if (!(action.expression instanceof FunctionAccessExpression)) {
			result += createEmptyStatement
		}
		else if (functionInlining) {	//if function access
			result += createEmptyStatement
		}
		else {	//if function access without inlining
			throw new IllegalArgumentException("Non-inlined functions currently not allowed: " + action)
		}
		// Create new following-context variable and transform the following-context
		val newFollowing = <Action>newLinkedList
		newFollowing += following
		if (newFollowing.size > 0) {
			val next = newFollowing.removeFirst
			result += transformAction(next, newFollowing)
		}
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(BreakStatement action, List<Action> following) {
		return <Action>newLinkedList
	}
	
	protected def dispatch List<Action> transformAction(ReturnStatement action, List<Action> following) {
		// Create return variable and transform the current action (discard the following-context)
		val result = <Action>newLinkedList
		if (action.expression !== null) {
			val precondition = action.expression.transformPrecondition
			result += precondition
			
			val transformExpression = action.expression.transformExpression
			val returnVariableDeclarations = returnStack.peek
			for (var i = 0; i < returnVariableDeclarations.size; i++) {
				val index = i
				val transformedAction = createAssignmentStatement => [
					it.lhs = createDirectReferenceExpression => [
						it.declaration = returnVariableDeclarations.get(index)
					]
					it.rhs = transformExpression.get(index)
				]
				result += transformedAction
			}
		}
		// Return the result (branch terminates, so following discarded)
		return result
	}
	
	protected def dispatch List<Action> transformAction(IfStatement action, List<Action> following) {
		// Create return variable
		val result = <Action>newLinkedList
		// Transform the guards (and their preconditions)
		var elseFlag = false
		val List<Expression> guardExpressions = <Expression>newArrayList
		val List<Action> guardPreconditions = <Action>newArrayList
		for (conditional : action.conditionals) {
			guardPreconditions += conditional.guard.transformPrecondition
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
						val newFollowing = <Action>newLinkedList
						newFollowing += following
						it.actions += action.conditionals.get(i).action.transformAction(newFollowing)
					]
				]
			}
		]
		if (!elseFlag) {
			transformedAction.conditionals += createBranch => [
				it.guard = createElseExpression
				it.action = createBlock => [
					val newFollowing = <Action>newLinkedList
					newFollowing += following
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
	
	protected def dispatch List<Action> transformAction(SwitchStatement action, List<Action> following) {
		// No fall-through functionality!
		// Create return variable
		val result = <Action>newLinkedList
		// Transform the guards (and their preconditions)
		var defaultFlag = false
		val List<Expression> guardExpressions = <Expression>newArrayList
		val List<Action> guardPreconditions = <Action>newArrayList
		guardPreconditions += action.controlExpression.transformPrecondition
		val controlExpression = action.controlExpression.transformExpression.getOnlyElement
		for (conditional : action.cases) {
			guardPreconditions += conditional.guard.transformPrecondition
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
						val newFollowing = <Action>newLinkedList
						newFollowing += following
						it.actions += action.cases.get(i).action.transformAction(newFollowing)
					]
				]
			}
		]
		if (!defaultFlag) {
			transformedAction.conditionals += createBranch => [
				it.guard = createElseExpression
				it.action = createBlock => [
					val newFollowing = <Action>newLinkedList
					newFollowing += following
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
	
	protected def dispatch List<Action> transformAction(ForStatement action, List<Action> following) {
		// Create return variable and transform the current action
		val result = <Action>newLinkedList
		// enumerate parameter values
		val parameterValues = action.range.enumerateExpression
		// TRANSFORM parameter variable and add to the result
		val parameterVariableDeclarations = action.parameter.transformValue
		result += parameterVariableDeclarations.map[vari |
			createVariableDeclarationStatement => [
				it.variableDeclaration = vari
			]
		]
		// create 'unrolled for' (TO BE TRANSFORMED)
		val unrolledFor = <Action>newLinkedList
		for (parameterValue : parameterValues) {
			unrolledFor += createAssignmentStatement => [
				it.lhs = createDirectReferenceExpression => [
					it.declaration = action.parameter
				]
				it.rhs = parameterValue
			]
			unrolledFor += action.body
		}
		if (action.then !== null) {
			unrolledFor += action.then
		}
		// call TRANSFORM on the 'unrolled for' and add to the transformed for
		val first = unrolledFor.removeFirst
		result += first.transformAction(unrolledFor)
		// Create new following-context variable and transform the following-context
		val newFollowing = <Action>newLinkedList
		newFollowing += following
		if (newFollowing.size > 0) {
			val next = newFollowing.removeFirst
			result += transformAction(next, newFollowing)
		}
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(ChoiceStatement action, List<Action> following) {
		// Create return variable
		val result = <Action>newLinkedList
		// Transform the guards (and their preconditions)
		val List<Expression> guardExpressions = newArrayList
		val List<Action> guardPreconditions = newArrayList
		for (conditional : action.branches) {
			guardPreconditions += conditional.guard.transformPrecondition
			guardExpressions += conditional.guard.transformExpression.getOnlyElement
		}
		result += guardPreconditions
		// Transform the statement itself (including the following-context)
		val transformedAction = createIfStatement => [
			it.conditionals += createBranch => [
				it.guard = createOrExpression => [
					for (guard : guardExpressions) {
						it.operands += guard		// the expressions are already transformed
					}
				]
				it.action = createBlock => [
					it.actions += createChoiceStatement => [
						for (i : 0 .. action.branches.size - 1) {
							it.branches += createBranch => [
								it.guard = guardExpressions.get(i)
								it.action = createBlock => [
									val newFollowing = <Action>newLinkedList
									newFollowing += following
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
					val newFollowing = <Action>newLinkedList
					newFollowing += following
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
	
	protected def dispatch List<Action> transformAction(AssignmentStatement action, List<Action> following) {
		// Create return variable and transform the current action
		val result = <Action>newLinkedList
		// Get the referred high-level declaration (assuming a single, assignable element)
		val actionLhs = action.lhs
		val referredDeclaration = actionLhs.referredValues.getOnlyElement
		checkState(referredDeclaration instanceof VariableDeclaration ||
			referredDeclaration instanceof ParameterDeclaration) //transformed to assignable type (=variable)
		// Transform lhs
		val List<ReferenceExpression> lowlevelLhs = newArrayList
		val typeToAssign = referredDeclaration.type.typeDefinition
		if (!(typeToAssign instanceof CompositeTypeDefinition)) {
			lowlevelLhs += createDirectReferenceExpression => [
				if (trace.isMapped(referredDeclaration)) {
					it.declaration = trace.get(referredDeclaration)
				}
			]
		}
		else {
			var originalLhsFields = exploreComplexType(referredDeclaration)			
			// access expressions
			val recordAccessList = actionLhs.collectRecordAccessList
			for (elem : originalLhsFields) {
				val key = elem.key
				val value = elem.value
				if (isSameAccessTree(value, recordAccessList)) {	//filter according to the access list
					// Create lhs
					lowlevelLhs += createDirectReferenceExpression => [
						if (trace.isMapped(elem)) {	//mapped as complex type
							it.declaration = trace.get(elem)
						}
						else if (trace.isMapped(key)) {	//simple arrays are mapped as a simple type (either var or par)
							it.declaration = trace.get(key)
						}
						else {
							throw new IllegalArgumentException("Transformed variable declaration not found!")
						}
					]
				}
			}
		}
		val actionRhs = action.rhs
		// Get rhs precondition
		val lowlevelPrecondition = actionRhs.transformPrecondition
		result += lowlevelPrecondition
		// Transform rhs and create action
		val List<Expression> lowlevelRhs = <Expression>newArrayList
		lowlevelRhs += actionRhs.transformExpression
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
		val newFollowing = <Action>newLinkedList
		newFollowing += following
		if (newFollowing.size > 0) {
			val next = newFollowing.removeFirst
			result += transformAction(next, newFollowing)
		}
		// Return the result
		return result
	}
	
	protected def dispatch List<Action> transformAction(AssertionStatement action, List<Action> following) {
		// Create return variable and transform the current action
		val result = <Action>newLinkedList
		var lowlevelPrecondition = action.assertion.transformPrecondition
		result += lowlevelPrecondition
		// If there is an assertion variable, branch and assign, otherwise discard
		val lhsVariable = trace.getAssertionVariable(assertionVariableName)
		if (lhsVariable !== null) {	// if there is an assertion variable
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
						val newFollowing = <Action>newLinkedList
						newFollowing += following
						val next = newFollowing.removeFirst
						it.actions += next.transformAction(newFollowing)
					]
				]
				it.conditionals += createBranch => [
					it.guard = createElseExpression
					it.action = createBlock => [
						val newFollowing = <Action>newLinkedList
						newFollowing += following
						val next = newFollowing.removeFirst
						it.actions += next.transformAction(newFollowing)
					]
				]
			]
			
		}
		else {	// ignore assertion and continue
			// Create new following-context variable and transform the following-context
			val newFollowing = <Action>newLinkedList
			newFollowing += following
			if (newFollowing.size > 0) {
				val next = newFollowing.removeFirst
				result += transformAction(next, newFollowing)
			}
		}
		
		// Return the result
		return result
	}
	
	// Gamma statechart elements

	protected def dispatch List<Action> transformAction(RaiseEventAction action, List<Action> following) {
		// Create return variable and transform the current action
		val result = <Action>newLinkedList
		val port = action.port
		val event = action.event
		val lowlevelEvent = trace.get(port, event, EventDirection.OUT)
		// Parameter setting
		val parameters = lowlevelEvent.parameters
		val values = action.arguments.map[it.transformExpression].flatten.toList
		checkState(parameters.size == values.size) // Record literals can be added as arguments
		for (var i = 0; i < values.size; i++) {
			val declaration = parameters.get(i)
			val value = values.get(i)
			val parameterAssignment = createAssignmentStatement => [
				it.lhs = createDirectReferenceExpression => [
					it.declaration = declaration
				]
				it.rhs = value
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
		val newFollowing = <Action>newLinkedList
		newFollowing += following
		if (newFollowing.size > 0) {
			val next = newFollowing.removeFirst
			result += transformAction(next, newFollowing)
		}
		// Return the result
		return result
	}

	protected def dispatch List<Action> transformAction(SetTimeoutAction action, List<Action> following) {
		// Create return variable and transform the current action
		val result = <Action>newLinkedList
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
		val newFollowing = <Action>newLinkedList
		newFollowing += following
		if (newFollowing.size > 0) {
			var next = newFollowing.removeFirst
			result += transformAction(next, newFollowing)
		}
		// Return the result
		return result
	}

	protected def dispatch List<Action> transformAction(DeactivateTimeoutAction action, List<Action> following) {
		throw new UnsupportedOperationException("DeactivateTimeoutActions are not yet transformed: " + action)
	}
	
}