/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
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
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.InEventGroup
import hu.bme.mit.gamma.xsts.model.InEventParameterGroup
import hu.bme.mit.gamma.xsts.model.OrthogonalAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import java.util.Comparator
import java.util.List
import java.util.Map
import java.util.Map.Entry
import java.util.Set

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class OrthogonalActionTransformer {
	// Singleton
	public static final OrthogonalActionTransformer INSTANCE = new OrthogonalActionTransformer
	protected new() {}
	//
	
	protected extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected extension XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE
	
	def void transform(XSTS xSts) {
		xSts.variableInitializingTransition.action.transform(xSts)
		xSts.configurationInitializingTransition.action.transform(xSts)
		xSts.entryEventTransition.action.transform(xSts)
		xSts.mergedAction.transform(xSts)
		xSts.inEventTransition.action.transform(xSts)
		xSts.outEventTransition.action.transform(xSts)
	}
	
	def void transform(Action action, XSTS xSts) {
		val eventAndParameterVariables = xSts.eventAndParameterVariables
		action.transform(eventAndParameterVariables)
	}
	
	def void transform(OrthogonalAction action, XSTS xSts) {
		val eventAndParameterVariables = xSts.eventAndParameterVariables
		action.transform(eventAndParameterVariables)
	}
	
	//
	
	def void transform(Action action, Collection<VariableDeclaration> consideredVariables) {
		val orthogonalActions = action.getSelfAndAllContentsOfType(OrthogonalAction)
		orthogonalActions.sortAccordingToHierarchy // Enclosing ones must precede the enclosed ones
		for (orthogonalAction : orthogonalActions) {
			orthogonalAction.transform(consideredVariables)
		}
	}
	
	def void transform(OrthogonalAction orthogonalAction,
				Collection<VariableDeclaration> consideredVariables) {
		val newAction = createSequentialAction
		val setupAction = createSequentialAction
		val mainAction = createSequentialAction
		val commonizeAction = createSequentialAction
		newAction => [
			it.actions += setupAction
			it.actions += mainAction
			it.actions += commonizeAction
		]
		
		val orthogonalBranches = newArrayList
		orthogonalBranches += orthogonalAction.actions
		if (orthogonalBranches.size > 1) {
			val readAndWrittenVariablesOfActions = orthogonalAction.readAndWrittenVariablesOfActions
			checkState(orthogonalBranches.size == readAndWrittenVariablesOfActions.size)
			
			for (orthogonalBranch : orthogonalBranches) {
				val orthogonalizableVariables = orthogonalBranch
						.getVariablesNeedingOrthogonality(
							readAndWrittenVariablesOfActions, consideredVariables)
				for (writtenVariable : orthogonalizableVariables) {
					val orthogonalVariableDeclarationAction = writtenVariable
							.createOrthogonalVariableAction(consideredVariables)
					val orthogonalVariable = orthogonalVariableDeclarationAction.variableDeclaration
					// Extend name to help with debugging
					orthogonalVariable.name = orthogonalVariable.name + "_" + orthogonalBranch.indexOrZero
					// local _var_ := var
					setupAction.actions += orthogonalVariableDeclarationAction
					// Each written var reference is changed to _var_ - note that reads are too
					orthogonalVariable.change(writtenVariable, orthogonalBranch)
					// var := _var_
					commonizeAction.actions += writtenVariable.createAssignmentAction(orthogonalVariable)
				}
				mainAction.actions += orthogonalBranch
			}
		}
		else {
			// Only one (or zero branch), no use in orthogonizing
			mainAction.actions += orthogonalBranches
		}
		// If the orthogonal action is traced, this can cause trouble
		// (the original action is not contained in a resource)
		val xSts = orthogonalAction.root
		newAction.change(orthogonalAction, xSts)
		newAction.replace(orthogonalAction)
	}
	
	protected def getEventAndParameterVariables(XSTS xSts) {
		return xSts.variableGroups
			.filter[it.annotation instanceof InEventGroup || // Out events are not considered
				it.annotation instanceof InEventParameterGroup]
			.map[it.variables].flatten.toSet
	}
	
	protected def sortAccordingToHierarchy(List<OrthogonalAction> orthogonalActions) {
		if (orthogonalActions.size <= 1) {
			return
		}
		// Orthogonal actions are sorted hierarchically: going from outside to inside,
		// that is, enclosing ones must precede enclosed ones (like in Gamma composition)
		orthogonalActions.sort(
			new Comparator<OrthogonalAction> {
				override compare(OrthogonalAction lhs, OrthogonalAction rhs) {
					if (lhs.containsTransitively(rhs)) {
						return -1
					}
					if (rhs.containsTransitively(lhs)) {
						return 1
					}
					return 0 // Neither contains the other one
				}
			}
		)
	}
	
	protected def getVariablesNeedingOrthogonality(Action orthogonalBranch,
		Map<Action, Entry<Set<VariableDeclaration>, Set<VariableDeclaration>>> readAndWrittenVariablesOfActions,
			Collection<VariableDeclaration> consideredVariables) {
		val readAndWrittenVariables = readAndWrittenVariablesOfActions.checkAndGet(orthogonalBranch)
		val writtenVariables = newHashSet // Variables written by this branch
		writtenVariables += readAndWrittenVariables.value
		writtenVariables.retainAll(consideredVariables)
		
		val otherReadVariables = newHashSet // Variables read by other branches
		
		for (otherBranch : readAndWrittenVariablesOfActions.keySet
				.reject[it === orthogonalBranch]) {
			val otherReadAndWrittenVariables = readAndWrittenVariablesOfActions.get(otherBranch)
			otherReadVariables += otherReadAndWrittenVariables.key
		}
		otherReadVariables.retainAll(writtenVariables) // These variables must be orthogonalized
		
		return otherReadVariables
	}
	
	protected def createOrthogonalVariableAction(VariableDeclaration variable,
			Collection<VariableDeclaration> consideredVariables) {
		val orthogonalVariable = createVariableDeclaration => [
			it.type = variable.type.clone
			// If there are multiple ort variables with the same name
			// (variables written in multiple branches), the model is faulty
			it.name = variable.orthogonalName
			it.expression = variable.createReferenceExpression // local _var_ : boolean := var
		]
		val variableDeclarationAction = createVariableDeclarationAction => [
			it.variableDeclaration = orthogonalVariable
		]
		consideredVariables += orthogonalVariable // Orthogonality must be hierarchical!
		return variableDeclarationAction
	}
	
}