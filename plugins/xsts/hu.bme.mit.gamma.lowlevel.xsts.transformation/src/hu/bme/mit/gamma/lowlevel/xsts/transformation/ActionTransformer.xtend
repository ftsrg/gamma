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
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.action.model.Block
import hu.bme.mit.gamma.action.model.BreakStatement
import hu.bme.mit.gamma.action.model.ChoiceStatement
import hu.bme.mit.gamma.action.model.EmptyStatement
import hu.bme.mit.gamma.action.model.ForStatement
import hu.bme.mit.gamma.action.model.IfStatement
import hu.bme.mit.gamma.action.model.SwitchStatement
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.model.util.XSTSActionUtil
import java.util.Collection

class ActionTransformer {
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	// Action utility
	protected final extension XSTSActionUtil xStsActionUtil = XSTSActionUtil.INSTANCE
	// Needed for the transformation of assignment actions
	protected final extension ExpressionTransformer expressionTransformer
	// Trace
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
		this.expressionTransformer = new ExpressionTransformer(this.trace)
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
	
	def dispatch Action transformAction(AssignmentStatement action) {
		return createAssignmentAction => [
			it.lhs = action.lhs.transformExpression as ReferenceExpression
			it.rhs = action.rhs.transformExpression
		]
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
		val guards = newLinkedList
		val actions = newLinkedList
		for (branch : action.conditionals) {
			guards += branch.guard.clone
			actions += branch.action.transformAction
		}
		return createSwitchAction(guards, actions)
	}
	
	def dispatch Action transformAction(SwitchStatement action) {
		val guards = newLinkedList
		val actions = newLinkedList
		for (branch : action.cases) {
			guards += branch.guard.clone
			actions += branch.action.transformAction
		}
		// In this case it is assumed that each case contains a break at the end
		return createSwitchActionWithControlExpression(action.controlExpression, guards, actions)
	}
	
	def dispatch Action transformAction(ChoiceStatement action) {
		val guards = newLinkedList
		val actions = newLinkedList
		for (branch : action.branches) {
			guards += branch.guard.clone
			actions += branch.action.transformAction
		}
		return createChoiceAction(guards, actions)
	}
	
	def dispatch Action transformAction(ForStatement action) {
		throw new UnsupportedOperationException("For statements are not supported yet")
	}
	
}