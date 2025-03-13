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
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.action.model.AssertionStatement
import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.action.model.Block
import hu.bme.mit.gamma.action.model.Branch
import hu.bme.mit.gamma.action.model.BreakStatement
import hu.bme.mit.gamma.action.model.ChoiceStatement
import hu.bme.mit.gamma.action.model.EmptyStatement
import hu.bme.mit.gamma.action.model.ForStatement
import hu.bme.mit.gamma.action.model.HavocStatement
import hu.bme.mit.gamma.action.model.IfStatement
import hu.bme.mit.gamma.action.model.SwitchStatement
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement
import hu.bme.mit.gamma.expression.model.DefaultExpression
import hu.bme.mit.gamma.expression.model.ElseExpression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection

class ActionTransformer {
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	// Action utility
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	// Needed for the transformation of assignment actions
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension VariableDeclarationTransformer variableDeclarationTransformer
	// Trace
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		this.variableDeclarationTransformer = new VariableDeclarationTransformer(this.trace)
	}

	def transformActions(Collection<? extends hu.bme.mit.gamma.action.model.Action> actions) {
		if (actions.empty) {
			return createEmptyAction
		}
		val xStsAction = createSequentialAction
		for (containedAction : actions) {
			xStsAction.actions += containedAction.transformAction
		}
		return xStsAction
	}
	
	// Basic Gamma statechart actions
	
	def dispatch Action transformAction(EmptyStatement action) {
		return createEmptyAction
	}
	
	def dispatch Action transformAction(AssertionStatement action) {
		return createEmptyAction
		// Theta does not support assertions yet
//		return createAssertAction => [
//			it.assertion = action.assertion.transformExpression
//		]
	}
	
	def dispatch Action transformAction(VariableDeclarationStatement action) {
		val lowlevelVariable = action.variableDeclaration
		val xStsVariable = lowlevelVariable.transformVariableDeclarationAndInitialExpression
		return createVariableDeclarationAction => [
			it.variableDeclaration = xStsVariable
		]
	}
	
	def dispatch Action transformAction(AssignmentStatement action) {
		return createAssignmentAction => [
			it.lhs = action.lhs.transformExpression as ReferenceExpression
			it.rhs = action.rhs.transformExpression
		]
	}
	
	def dispatch Action transformAction(HavocStatement action) {
		val lhs = action.lhs
		val constraint = action.constraint
		
		val havoc = createHavocAction
		havoc.lhs = lhs.transformExpression as ReferenceExpression
		
		if (constraint === null || constraint.definitelyTrueExpression) {
			return havoc
		}
		
		val xStsAssumption = constraint.transformExpression
		val assumption = xStsAssumption.createAssumeAction
		
		return #[ havoc, assumption ].createSequentialAction
	}
	
	def dispatch Action transformAction(Block action) {
		val xStsAction = createSequentialAction
		for (containedAction : action.actions) {
			xStsAction.actions += containedAction.transformAction
		}
		return xStsAction
	}
	
	// Extended actions
	
	def dispatch Action transformAction(BreakStatement action) {
		// We cannot handle break statements on this level
		return createEmptyAction
	}
	
	def dispatch Action transformAction(IfStatement action) {
		val branches = action.conditionals.transformBranches
		val guards = branches.key
		val actions = branches.value
		
		return createIfAction(guards, actions)
	}
	
	def dispatch Action transformAction(SwitchStatement action) {
		val branches = action.cases.transformBranches
		val guards = branches.key
		val actions = branches.value
		
		// In this case it is assumed that each case contains a break at the end
		return createSwitchAction(action.controlExpression, guards, actions)
	}
	
	def dispatch Action transformAction(ChoiceStatement action) {
		val branches = action.branches.transformBranches
		val guards = branches.key
		val actions = branches.value
		
		return createChoiceAction(guards, actions)
	}
	
	protected def transformBranches(Collection<Branch> branches) {
		var Action elseAction = createEmptyAction // If we found one in the collection, we change this
		val expressions = newArrayList
		val actions = newArrayList
		for (branch : branches) {
			val guard = branch.guard
			val action = branch.action
			val xStsAction = action.transformAction
			if (guard instanceof ElseExpression || guard instanceof DefaultExpression) {
				elseAction = xStsAction // Found an else action, no need for the empty action
			}
			else {
				expressions += guard.transformExpression
				actions += xStsAction
			}
		}
		actions += elseAction // Else actions must be at the end
		// If we did not find an else expression, we add plus one empty action at the end
		
		return expressions -> actions
	}
	
	def dispatch Action transformAction(ForStatement action) {
		val loopAction = createLoopAction => [
			it.iterationParameterDeclaration = action.parameter.transformParameterDeclaration
			it.range = action.range.transformExpression.integerRangeLiteralExpression
			it.action = action.body.transformAction
		]
		return loopAction
	}
	
}