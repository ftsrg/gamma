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
import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.action.model.Block
import hu.bme.mit.gamma.action.model.Branch
import hu.bme.mit.gamma.action.model.BreakStatement
import hu.bme.mit.gamma.action.model.ChoiceStatement
import hu.bme.mit.gamma.action.model.EmptyStatement
import hu.bme.mit.gamma.action.model.ExpressionStatement
import hu.bme.mit.gamma.action.model.ForStatement
import hu.bme.mit.gamma.action.model.IfStatement
import hu.bme.mit.gamma.action.model.ReturnStatement
import hu.bme.mit.gamma.action.model.SwitchStatement
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.model.DeactivateTimeoutAction
import hu.bme.mit.gamma.statechart.model.RaiseEventAction
import hu.bme.mit.gamma.statechart.model.SetTimeoutAction
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.math.BigInteger
import java.util.Collection
import java.util.List

class ActionTransformer {
	// Auxiliary objects
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = new GammaEcoreUtil
	// Factory objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE
	// Trace
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
		this.expressionTransformer = new ExpressionTransformer(this.trace)
	}
	
	protected def transformActions(Collection<? extends Action> actions) {
		if (actions.empty) {
			return createEmptyStatement
		}
		val block = createBlock
		for (containedAction : actions) {
			block.actions += containedAction.transformAction
		}
		if (block.actions.size == 1) {
			return block.actions.head
		}
		return block
	}
	
	protected def dispatch Action transformAction(Action action) {
		throw new IllegalArgumentException("Not known action: " + action)
	}

	// Gamma statechart elements

	protected def dispatch Action transformAction(AssignmentStatement action) {
		val referredDeclaration = action.lhs.declaration
		if (referredDeclaration instanceof VariableDeclaration) {
			val lowlevelDeclaration = trace.get(referredDeclaration)
			val lowLevelAction = createAssignmentStatement => [
				it.lhs = createReferenceExpression => [
					it.declaration = lowlevelDeclaration
				]
				it.rhs = action.rhs.transformExpression
			]
			return lowLevelAction
		}
		else {
			throw new IllegalArgumentException("Not known declaration: " + referredDeclaration)
		}
	}

	protected def dispatch Action transformAction(RaiseEventAction action) {
		val port = action.port
		val event = action.event
		val lowlevelEvent = trace.get(port, event, EventDirection.OUT)
		val List<Action> assignmentList = newLinkedList 
		var i = 0
		// Parameter setting
		for (exp : action.arguments) {
			val parameterDeclaration = lowlevelEvent.parameters.get(i++) // Getting the i. parameter
			val parameterValue = exp.transformExpression
			val parameterAssignment = createAssignmentStatement => [
				it.lhs = createReferenceExpression => [
					it.declaration = parameterDeclaration
				]
				it.rhs = parameterValue
			]
			assignmentList += parameterAssignment
		}
		// Setting IsRaised flag to true
		val flagRaising = createAssignmentStatement => [
			it.lhs = createReferenceExpression => [
				it.declaration = lowlevelEvent.isRaised
			]
			it.rhs = createTrueExpression
		]
		assignmentList += flagRaising
		return createBlock => [
			it.actions += assignmentList
		]
	}

	protected def dispatch Action transformAction(SetTimeoutAction action) {
		val lowlevelTimeout = trace.get(action.timeoutDeclaration)
		// Setting the clock to 0 as contrary to Gamma, in the lowlevel language time elapses from 0 to infinity
		val clockInit = createAssignmentStatement => [
			it.lhs = createReferenceExpression => [
				it.declaration = lowlevelTimeout
			]
			it.rhs = createIntegerLiteralExpression => [
				it.value = BigInteger.ZERO
			]
		]
		return clockInit
	}

	protected def dispatch Action transformAction(DeactivateTimeoutAction action) {
		throw new UnsupportedOperationException("DeactivateTimeoutActions are not yet transformed: " + action)
	}
	
	//
	// Gamma action language
	
	protected def dispatch Action transformAction(Block action) {
		return createBlock => [
			for (subaction : action.actions) {
				it.actions += subaction.transformAction
			}
		]
	}
	
	protected def dispatch Action transformAction(EmptyStatement action) {
		return createEmptyStatement
	}
	
	protected def dispatch Action transformAction(BreakStatement action) {
		return createBreakStatement
	}
	
	protected def dispatch Action transformAction(ReturnStatement action) {
		return createReturnStatement => [
			it.expression = action.expression.transformExpression
		]
	}
	
	protected def dispatch Action transformAction(ChoiceStatement action) {
		return createChoiceStatement => [
			for (branch : action.branches) {
				it.branches += branch.transformBranch
			}
		]
	}
	
	protected def dispatch Action transformAction(ForStatement action) {
		return createForStatement => [
			it.parameter = createParameterDeclaration => [
				it.name = action.parameter.name
				it.type = action.parameter.type.clone(true, true)
			]
			it.range = action.range.transformExpression
			it.body = action.body.transformAction
			it.then = action.then.transformAction
		]
	}
	
	protected def dispatch Action transformAction(IfStatement action) {
		return createIfStatement => [
			for (branch : action.conditionals) {
				it.conditionals += branch.transformBranch
			}
		]
	}
	
	protected def dispatch Action transformAction(SwitchStatement action) {
		return createSwitchStatement => [
			it.controlExpression = action.controlExpression.transformExpression
			for (branch : action.cases) {
				it.cases += branch.transformBranch
			}
		]
	}
	
	protected def dispatch Action transformAction(ExpressionStatement action){
		return createExpressionStatement => [
			it.expression = action.expression.transformExpression
		]
	}
	
	//
	
	private def transformBranch(Branch branch) {
		return createBranch => [
			it.guard = branch.guard.transformExpression
			it.action = branch.action.transformAction
		]
	}
	
}