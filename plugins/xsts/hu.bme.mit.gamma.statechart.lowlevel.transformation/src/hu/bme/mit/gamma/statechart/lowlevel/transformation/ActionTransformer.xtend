/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
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
import hu.bme.mit.gamma.action.model.Branch
import hu.bme.mit.gamma.action.model.BreakStatement
import hu.bme.mit.gamma.action.model.ChoiceStatement
import hu.bme.mit.gamma.action.model.ConstantDeclarationStatement
import hu.bme.mit.gamma.action.model.EmptyStatement
import hu.bme.mit.gamma.action.model.ExpressionStatement
import hu.bme.mit.gamma.action.model.ForStatement
import hu.bme.mit.gamma.action.model.HavocStatement
import hu.bme.mit.gamma.action.model.IfStatement
import hu.bme.mit.gamma.action.model.ReturnStatement
import hu.bme.mit.gamma.action.model.SwitchStatement
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement
import hu.bme.mit.gamma.action.util.ActionUtil
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.InitializableElement
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.statechart.DeactivateTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection
import java.util.List

import static extension com.google.common.collect.Iterables.getOnlyElement

class ActionTransformer {
	// Auxiliary objects
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ValueDeclarationTransformer valueDeclarationTransformer
	protected final extension ExpressionPreconditionTransformer preconditionTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ActionUtil actionUtil = ActionUtil.INSTANCE
	// Factory objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE
	// Trace
	protected final Trace trace
	
	new(Trace trace) {
		this(trace, true, 10, null)
	}
	
	new(Trace trace, boolean functionInlining, int maxRecursionDepth, TimeUnit baseTimeUnit) {
		this.trace = trace
		this.expressionTransformer = new ExpressionTransformer(this.trace,
				functionInlining, maxRecursionDepth, baseTimeUnit)
		this.preconditionTransformer = new ExpressionPreconditionTransformer(
			this.trace, this, functionInlining, maxRecursionDepth)
		this.valueDeclarationTransformer = new ValueDeclarationTransformer(this.trace)
	}
	
	protected def transformActions(Collection<? extends Action> actions) {
		if (actions.nullOrEmpty) {
			return createEmptyStatement
		}
		val result = newArrayList
		for (action : actions) {
			result += action.transformAction
		}
		return result.wrap
	}
	
	protected def transformSimpleAction(Action action) {
		return action.transformAction.onlyElement
	}
	
	// In order to support function inlining, before every expression transformation,
	// a transformPrecondition call must be made to create the potential inlining!
	
	protected def dispatch List<Action> transformAction(Action action) {
		throw new IllegalArgumentException("Not known action: " + action)
	}
	
	protected def dispatch List<Action> transformAction(EmptyStatement action) {
		return #[
			createEmptyStatement
		]
	}
	
	protected def dispatch List<Action> transformAction(Block action) {
		val result = <Action>newLinkedList
		for (subaction : action.actions) {
			result += subaction.transformAction
		}
		return result
	}
	
	protected def dispatch List<Action> transformAction(VariableDeclarationStatement action) {
		val variableDeclaration = action.variableDeclaration
		return variableDeclaration.transformValueDeclarationAction
	}
	
	protected def dispatch List<Action> transformAction(ConstantDeclarationStatement action) {
		val constantDeclaration = action.constantDeclaration
		return constantDeclaration.transformValueDeclarationAction
	}
	
	private def <T extends ValueDeclaration & InitializableElement> transformValueDeclarationAction(
			T valueDeclaration) {
		val result = newArrayList
		val initalExpression = valueDeclaration.expression
		var lowlevelPrecondition = initalExpression !== null ?
			initalExpression.transformPrecondition : <Action>newLinkedList
		result += lowlevelPrecondition
		
		val lowlevelVariableDeclarations = valueDeclaration.transform
		// Variables are traced in the transform call
		for (lowlevelVariableDeclaration : lowlevelVariableDeclarations) {
			result += createVariableDeclarationStatement => [
				it.variableDeclaration = lowlevelVariableDeclaration
			]	
		}
		return result
	}
	
	protected def dispatch List<Action> transformAction(ExpressionStatement action) {
		val expression = action.expression
		return expression.transformPrecondition
	}
	
	protected def dispatch List<Action> transformAction(BreakStatement action) {
		throw new UnsupportedOperationException("Not supported action: " + action)
	}
	
	protected def dispatch List<Action> transformAction(ReturnStatement action) {
		throw new UnsupportedOperationException("Not supported action: " + action)
	}
	
	protected def dispatch List<Action> transformAction(IfStatement action) {
		val actions = <Action>newArrayList
		
		val branches = action.conditionals
		val ifStatement = createIfStatement
		for (branch : branches) {
			ifStatement.conditionals += branch.transformBranch(actions)
		}
		// It is important that the statement is added AFTER the loop
		actions += ifStatement
		
		return actions
	}
	
	protected def dispatch List<Action> transformAction(SwitchStatement action) {
		val actions = <Action>newArrayList
		
		val controlExpression = action.controlExpression
		val branches = action.cases
		val switchStatement = createSwitchStatement
		actions += controlExpression.transformPrecondition
		switchStatement.controlExpression = controlExpression.transformSimpleExpression
		for (branch : branches) {
			switchStatement.cases += branch.transformBranch(actions)
		}
		// It is important that the statement is added AFTER the loop
		actions += switchStatement
		
		return actions
	}
	
	protected def dispatch List<Action> transformAction(ChoiceStatement action) {
		val actions = <Action>newArrayList
		
		val branches = action.branches
		val choiceStatement = createChoiceStatement
		for (branch : branches) {
			choiceStatement.branches += branch.transformBranch(actions)
		}
		// It is important that the statement is added AFTER the loop
		actions += choiceStatement
		
		return actions
	}
	
	private def Branch transformBranch(Branch branch, List<Action> preconditions) {
		val guard = branch.guard
		val action = branch.action
		
		preconditions += guard.transformPrecondition
		
		return createBranch => [
			it.guard = guard.transformSimpleExpression
			it.action = action.transformAction.wrap
		]
	}
	
	protected def dispatch List<Action> transformAction(ForStatement action) {
		return #[
			createForStatement => [
				it.parameter = action.parameter.transformForParameter
				it.range = action.range.transformSimpleExpression
				it.body = action.body.transformAction.wrap
			]
		]
	}
	
	protected def dispatch List<Action> transformAction(AssertionStatement action) {
		return #[
			createAssertionStatement => [
				it.assertion = action.assertion.transformSimpleExpression
			]
		]
	}
	
	protected def dispatch List<Action> transformAction(AssignmentStatement action) {
		val result = <Action>newLinkedList
		
		val actionLhs = action.lhs
		val lowlevelLhs = actionLhs.transformReferenceExpression // Potentially more references are expected
		// This addresses record1 := record2 like assignments
		
		val actionRhs = action.rhs
		// Precondition (function inlining)
		result += actionRhs.transformPrecondition
		// Transform right hand side and create actions
		val lowlevelRhs = actionRhs.transformExpression
		
		result += lowlevelLhs.createAssignments(lowlevelRhs)
		
		return result
	}
	
	protected def dispatch List<Action> transformAction(HavocStatement action) {
		val result = <Action>newLinkedList
		
		val actionLhs = action.lhs
		val lowlevelLhs = actionLhs.transformReferenceExpression // Potentially more references are expected
		// This addresses record1 := record2 like assignments
		
		val assumption = action.constraint
		// Precondition (function inlining)
		if (assumption !== null) {
			result += assumption.transformPrecondition
		}
		// Transform assumption and create actions
		val lowlevelAssumptions = (assumption === null) ? #[ createTrueExpression ] : assumption.transformExpression
		val lowlevelAssumption = (lowlevelAssumptions.size == 1) ? lowlevelAssumptions.head : lowlevelAssumptions.wrapIntoAndExpression
		
		for (lhs : lowlevelLhs) {
			val lowlevelHavoc = actionFactory.createHavocStatement
			result += lowlevelHavoc
			
			lowlevelHavoc.lhs = lhs
			if (lhs === lowlevelLhs.lastOrNull) { // One constraint is enough at the end
				lowlevelHavoc.constraint = lowlevelAssumption
			}
		}
		
		return result
	}
	
	protected def dispatch List<Action> transformAction(RaiseEventAction action) {
		val result = <Action>newLinkedList
		
		val port = action.port
		val event = action.event
		val lowlevelEvent = trace.get(port, event, EventDirection.OUT)
		
		// Parameter setting
		val lowlevelLhs = lowlevelEvent.parameters.map[it.createReferenceExpression].toList
		val lowlevelRhs = action.arguments.map[it.transformExpression].flatten.toList
		result += lowlevelLhs.createAssignments(lowlevelRhs)
		
		// Setting IsRaised flag to true
		result += lowlevelEvent.isRaised.createReferenceExpression
				.createAssignment(createTrueExpression)
		
		return result
	}

	protected def dispatch List<Action> transformAction(SetTimeoutAction action) {
		val lowlevelTimeout = trace.get(action.timeoutDeclaration)
		// Setting the clock to 0 as contrary to Gamma, in the lowlevel language time elapses from 0 to infinity
		return #[
			lowlevelTimeout.createReferenceExpression
				.createAssignment(0.toIntegerLiteral)
		]
	}

	protected def dispatch List<Action> transformAction(DeactivateTimeoutAction action) {
		throw new UnsupportedOperationException("DeactivateTimeoutActions are not supported: " + action)
	}
	
}