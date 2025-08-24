/********************************************************************************
 * Copyright (c) 2018-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.AssignmentActions
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.NotReadVariables
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.SlaveMessageQueueGroup
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.function.Predicate
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class RemovableVariableRemover {
	// Singleton
	public static final RemovableVariableRemover INSTANCE =  new RemovableVariableRemover
	protected new() {}
	//
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	//
	
	def void removeTransientVariables(XSTS xSts) {
		xSts.removeUnreadVariables([it.transient || it.local])
	}
	
	def void removeUnusedSlaveQueueVariables(XSTS xSts) {
		val xStsSlaveQueueVariables = xSts.variableGroups
				.filter[it.annotation instanceof SlaveMessageQueueGroup]
				.map[it.variables].flatten
		
		xSts.removeUnreadVariables([xStsSlaveQueueVariables.contains(it)])
	}
	
	def void removeUnreadVariables(XSTS xSts, Predicate<VariableDeclaration> include) {
		val engine = ViatraQueryEngine.on(
				new EMFScope(xSts))
		
		val unreadXStsVariableMatcher = NotReadVariables.Matcher.on(engine)
		val unreadXStsVariables = unreadXStsVariableMatcher.allValuesOfvariable
					.filter[include.test(it)] // Keeping ones set by the predicate
		val xStsAssignmentMatcher = AssignmentActions.Matcher.on(engine)
		for (unreadXStsVariable : unreadXStsVariables) {
			val xStsAssignments = xStsAssignmentMatcher.getAllValuesOfaction(
					null, unreadXStsVariable)
			for (xStsAssignment : xStsAssignments) {
				// Handling function calls if needed
				if (xStsAssignment instanceof AssignmentAction) {
					val rhs = xStsAssignment.rhs
					val functionCalls = rhs.getSelfAndAllContentsOfType(FunctionAccessExpression)
					for (funcitonCall : functionCalls) {
						val functionCallAction = funcitonCall.createFunctionCallAction
						xStsAssignment.appendToAction(functionCallAction)
					}
				}
				
				xStsAssignment.replaceWithEmptyAction
			}
			// Deleting the potential containing VariableDeclarationAction too
			unreadXStsVariable.deleteDeclaration
		}
	}
	
	def void removeReadOnlyVariables(XSTS xSts) {
		removeReadOnlyVariables(xSts, false)
	}
	
	def void removeReadOnlyVariables(XSTS xSts, boolean keepInternalVariables) {
		val readOnlyVariables = xSts.readOnlyVariables
				.filter[it.global && (!keepInternalVariables || !it.internal)].toSet
		// Local variables cannot be optimized like this: e.g., local a : integer = b; b := x; ... (a cannot be substituted by b anymore)
		if (!readOnlyVariables.empty) {
			val references = xSts.getAllContentsOfType(DirectReferenceExpression)
			for (reference : references) {
				val declaration = reference.declaration
				if (readOnlyVariables.contains(declaration)) {
					val isContainedByAssignment = reference.isContainedBy(AbstractAssignmentAction)
					var needReplace = true
					if (isContainedByAssignment) {
						val assignment = reference.getContainerOfType(AbstractAssignmentAction)
						val lhs = assignment.lhs
						val lhsDeclaration = lhs.declaration
						if (lhsDeclaration == declaration) {
							assignment.replaceWithEmptyAction // Deleting assignment; supposed to be in "init" trans
							needReplace = false
						}
					}
					
					if (needReplace) {
						val initialValue = (declaration instanceof VariableDeclaration) ?
								declaration.initialValue : declaration.defaultExpression
						initialValue.replace(reference)
					}
				}
			}
			
			readOnlyVariables.forEach[it.delete] // Considering variable groups, too, hence the delete
		}
	}
	
}