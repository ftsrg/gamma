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
package hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.AssignmentActions
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.NotReadVariables
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
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
		val engine = ViatraQueryEngine.on(new EMFScope(xSts))
		
		val unreadXStsVariableMatcher = NotReadVariables.Matcher.on(engine)
		val unreadTransientXStsVariables = unreadXStsVariableMatcher.allValuesOfvariable
				.filter[it.transient || it.local]
		val xStsAssignmentMatcher = AssignmentActions.Matcher.on(engine)
		for (unreadTransientXStsVariable : unreadTransientXStsVariables) {
			val xStsAssignments = xStsAssignmentMatcher.getAllValuesOfaction(
					null, unreadTransientXStsVariable)
			for (xStsAssignment : xStsAssignments) {
				xStsAssignment.replaceWithEmptyAction
			}
			// Deleting the potential containing VariableDeclarationAction too
			unreadTransientXStsVariable.deleteDeclaration
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