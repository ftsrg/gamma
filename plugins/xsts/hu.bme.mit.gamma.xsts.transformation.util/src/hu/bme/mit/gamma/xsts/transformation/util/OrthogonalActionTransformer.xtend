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
package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.EventGroup
import hu.bme.mit.gamma.xsts.model.EventParameterGroup
import hu.bme.mit.gamma.xsts.model.OrthogonalAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import java.util.Comparator
import java.util.List

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class OrthogonalActionTransformer {
	// Singleton
	public static final OrthogonalActionTransformer INSTANCE = new OrthogonalActionTransformer
	protected new() {}
	//
	
	protected extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected extension XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE
	
	def void transform(XSTS xSts) {
		val eventVariables = xSts.variableGroups
			.filter[it.annotation instanceof EventGroup || it.annotation instanceof EventParameterGroup]
			.map[it.variables].flatten.toSet
		if (!eventVariables.empty) {
			xSts.variableInitializingAction.transform(eventVariables)
			xSts.configurationInitializingAction.transform(eventVariables)
			xSts.entryEventAction.transform(eventVariables)
			xSts.mergedAction.transform(eventVariables)
			xSts.inEventAction.transform(eventVariables)
			xSts.outEventAction.transform(eventVariables)
		}
	}
	
	def void transform(Action action, Collection<VariableDeclaration> consideredVariables) {
		val xSts = action.root
		val orthogonalActions = action.getSelfAndAllContentsOfType(OrthogonalAction)
		orthogonalActions.sortAccordingToHierarchy // Enclosing ones must precede the enclosed ones
		val orthogonalBranches = newArrayList
		for (orthogonalAction : orthogonalActions) {
			val newAction = createSequentialAction
			val setupAction = createSequentialAction
			val mainAction = createSequentialAction
			val commonizeAction = createSequentialAction
			newAction => [
				it.actions += setupAction
				it.actions += mainAction
				it.actions += commonizeAction
			]
			
			orthogonalBranches.clear
			orthogonalBranches += orthogonalAction.actions
			if (orthogonalBranches.size > 1) {
				for (orthogonalBranch : orthogonalBranches) {
					val writtenVariables = orthogonalBranch.writtenVariables
					writtenVariables.retainAll(consideredVariables) // Transforming only considered variables
					for (writtenVariable : writtenVariables) {
						val orthogonalVariableDeclarationAction = writtenVariable
								.createOrthogonalVariableAction(consideredVariables)
						val orthogonalVariable = orthogonalVariableDeclarationAction.variableDeclaration
						// local _var_ := var
						setupAction.actions += orthogonalVariableDeclarationAction
						// Each written var is changed to _var_
						orthogonalVariable.change(writtenVariable, orthogonalBranch)
						mainAction.actions += orthogonalBranch
						// var := _var_
						commonizeAction.actions += writtenVariable.createAssignmentAction(orthogonalVariable)
					}
				}
			}
			else {
				// Only one (or zero branch), no use in orthogonizing
				mainAction.actions += orthogonalBranches
			}
			// If the orthogonal action is traced, this can cause trouble
			// (the original action is not contained in a resource)
			newAction.change(orthogonalAction, xSts)
			newAction.replace(orthogonalAction)
		}
	}
	
	protected def sortAccordingToHierarchy(List<OrthogonalAction> orthogonalActions) {
		// Orthogonal actions are sorted hierarchically: going from outside to inside,
		// that is, enclosing ones must precede enclosed ones (like in Gamma composition)
		orthogonalActions.sort(
			new Comparator<OrthogonalAction> {
				override compare(OrthogonalAction lhs, OrthogonalAction rhs) {
					if (lhs.contains(rhs)) {
						return -1
					}
					if (rhs.contains(lhs)) {
						return 1
					}
					return 0 // Neither contains the other one
				}
			}
		)
	}
	
	protected def createOrthogonalVariableAction(VariableDeclaration variable,
			Collection<VariableDeclaration> consideredVariables) {
		val orthogonalVariable = createVariableDeclaration => [
			it.type = variable.type.clone
			// If there are multiple ort variables with the same name
			// (variables written in multiple branches), the model is faulty
			it.name = variable.orthogonalName
			it.expression = createDirectReferenceExpression => [
				it.declaration = variable // local _var_ : boolean := var
			]
		]
		val variableDeclarationAction = createVariableDeclarationAction => [
			it.variableDeclaration = orthogonalVariable
		]
		consideredVariables += orthogonalVariable // Orthogonality must be hierarchical!
		return variableDeclarationAction
	}
	
}
	