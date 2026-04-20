/********************************************************************************
 * Copyright (c) 2025-2026 Contributors to the Gamma project
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
import hu.bme.mit.gamma.action.model.Block
import hu.bme.mit.gamma.action.model.ForStatement
import hu.bme.mit.gamma.action.model.ReturnStatement
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Set
import org.eclipse.emf.ecore.EObject

class ProcedureReturnGuardHandler {
	//
	protected VariableDeclaration isReturnedDeclaration
	protected final Set<Action> guardedActions = newHashSet // A block or for statement is guarded only once
	// Auxiliary objects
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE
	
	new() {
		this(null)
	}
	
	new(VariableDeclaration isReturnedDeclaration) {
		this.isReturnedDeclaration = isReturnedDeclaration
	}
	
	def void createAndSetReturnedDeclarationAndAddReturnGuard(Action top) {
		val name = "isReturned"
		val isReturnedVariableDeclaration = createBooleanTypeDefinition
				.createDeclarationStatement(name)
		isReturnedVariableDeclaration.prepend(top)
		isReturnedDeclaration = isReturnedVariableDeclaration.variableDeclaration
		
		for (returnAction : top.getAllContentsOfType(ReturnStatement)) {
			returnAction.setReturnedDeclarationAndAddReturnGuard
		}
	}
	
	def void setReturnedDeclarationAndAddReturnGuard(ReturnStatement returnAction) {
		val setDeclarationAction = isReturnedDeclaration.createAssignment(createTrueExpression)
		setDeclarationAction.prepend(returnAction)
		
		returnAction.addReturnGuard
	}
	
	// EObject is expected to handle branches too
	def void addReturnGuard(EObject action) {
		val container = action.eContainer
		
		if (container === null) {
			return
		}
		
		if (container instanceof Block) {
			if (!guardedActions.contains(container)) {
				val actions = container.actions
				val size = actions.size
				val firstGuardableActionIndex = action.index + 1
				
				if (firstGuardableActionIndex < size) {
					val guard = isReturnedDeclaration.createReferenceExpression
							.createNotExpression
					val guardedBlock = createBlock => [
						it.actions += actions.subList(firstGuardableActionIndex, size)
					]
					val branch = guard.createBranch(guardedBlock)
					val ifStatement = createIfStatement => [
						it.conditionals += branch
					]
					// Putting the guarded block to the end (guardable actions are inside)
					actions += ifStatement
				}
				
				guardedActions += container
			}
		}
		else if (container instanceof ForStatement) {
			if (!guardedActions.contains(container)) {
				val guard = createNotExpression => [
					it.operand = isReturnedDeclaration.createReferenceExpression
				]
				val branch = guard.createBranch(container.body)
				val ifStatement = createIfStatement => [
					it.conditionals += branch
				]
				container.body = ifStatement
				
				guardedActions += container
			}
		}
		// No 'if (a < 5) return 5;' - every 'return' is contained by block due to 'addReturnGuard' call
		
		// Recursion to the top
		container.addReturnGuard
	}
	
}