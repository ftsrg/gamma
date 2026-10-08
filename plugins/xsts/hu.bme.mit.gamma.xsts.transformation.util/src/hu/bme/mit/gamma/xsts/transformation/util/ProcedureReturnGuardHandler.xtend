/********************************************************************************
 * Copyright (c) 2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.ReturnAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Set
import org.eclipse.emf.ecore.EObject

class ProcedureReturnGuardHandler {
	//
	protected VariableDeclaration isReturnedDeclaration
	protected final Set<Action> guardedActions = newHashSet // A block or for statement is guarded only once
	// Auxiliary objects
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil xStsUtil = XstsActionUtil.INSTANCE
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension XSTSModelFactory actionFactory = XSTSModelFactory.eINSTANCE
	
	new() {
		this(null)
	}
	
	new(VariableDeclaration isReturnedDeclaration) {
		this.isReturnedDeclaration = isReturnedDeclaration
	}
	
	def void createAndSetReturnedDeclarationAndAddReturnGuard(Action top) {
		val name = "isReturned"
		val isReturnedVariableDeclaration = name.createBooleanVariableDeclarationAction
		isReturnedVariableDeclaration.prependToAction(top)
		isReturnedDeclaration = isReturnedVariableDeclaration.variableDeclaration
		
		for (returnAction : top.getAllContentsOfType(ReturnAction)) {
			returnAction.setReturnedDeclarationAndAddReturnGuard
		}
	}
	
	def void setReturnedDeclarationAndAddReturnGuard(ReturnAction returnAction) {
		val setDeclarationAction = isReturnedDeclaration.createAssignmentAction(createTrueExpression)
		setDeclarationAction.prependToAction(returnAction)
		
		returnAction.addReturnGuard
	}
	
	// EObject is expected to handle branches too
	def void addReturnGuard(EObject action) {
		val container = action.eContainer
		
		if (container === null) {
			return
		}
		
		if (container instanceof SequentialAction) {
			if (!guardedActions.contains(container)) {
				val actions = container.actions
				val size = actions.size
				val firstGuardableActionIndex = action.index + 1
				
				if (firstGuardableActionIndex < size) {
					val guard = isReturnedDeclaration.createReferenceExpression
							.createNotExpression
					val guardedBlock = createSequentialAction => [
						it.actions += actions.subList(firstGuardableActionIndex, size)
					]
					val ifStatement = guard.createIfAction(guardedBlock)
					// Putting the guarded block to the end (guardable actions are inside)
					actions += ifStatement
				}
				
				guardedActions += container
			}
		}
		else if (container instanceof LoopAction) {
			if (!guardedActions.contains(container)) {
				val guard = createNotExpression => [
					it.operand = isReturnedDeclaration.createReferenceExpression
				]
				val ifStatement = guard.createIfAction(container.action)
				container.action = ifStatement
				
				guardedActions += container
			}
		}
		// No 'if (a < 5) return 5;' - every 'return' is contained by block due to 'addReturnGuard' call
		
		// Recursion to the top
		container.addReturnGuard
	}
	
}