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
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.statechart.lowlevel.model.Region
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.statechart.lowlevel.model.StateNode
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.MultiaryAction
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class ExitActionRetriever {
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Auxiliary object
	protected final extension XstsActionUtil actionFactory = XstsActionUtil.INSTANCE
	protected final extension StateAssumptionCreator stateAssumptionCreator
	protected final extension ActionTransformer actionTransformer
	// Trace
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
		this.stateAssumptionCreator = new StateAssumptionCreator(this.trace)
		this.actionTransformer = new ActionTransformer(this.trace)
	}
	
	// Parent region handling
	
	protected def Action createRecursiveXStsParentStateExitActions(StateNode lowlevelState,
			State lowlevelTopState, boolean inclusiveTopState) {
		val lowlevelParentState = lowlevelState.parentState
		val lowlevelParentRegion = lowlevelState.parentRegion
		if (lowlevelParentRegion.isTopRegion ||
				(inclusiveTopState && lowlevelState == lowlevelTopState) || 
				(!inclusiveTopState && lowlevelParentState == lowlevelTopState)) {
			// Works for the exit action of parent states IF the top level state is not yet reached
			return createEmptyAction
		}
		val xStsExitAction = createSequentialAction => [
			// Action taken only if the state is "active" (assume action)
			val xStsStateAssumption = lowlevelParentState.createSingleXStsStateAssumption
			val xStsStateExitAction = xStsStateAssumption.createIfAction(lowlevelParentState.exitAction.transformAction)
			// Action taken only if the state is "active" (assume action)
			it.actions += xStsStateExitAction
			// Recursion
			it.actions += lowlevelParentState.createRecursiveXStsParentStateExitActions(lowlevelTopState, inclusiveTopState)
		]
		return xStsExitAction
	}
	
	/**
	 * Creates the xSTS exit actions of the parent state (in correct order) and all ancestor
	 * states recursively up until the given top level state (its exit action is still regarded but its parent states' are not).
	 */
	protected def Action createRecursiveXStsParentStateExitActionsWithOrthogonality(
			StateNode lowlevelStateNode, State lowlevelTopState) {
		val lowlevelParentRegion = lowlevelStateNode.parentRegion
		if (lowlevelParentRegion.isTopRegion || lowlevelStateNode == lowlevelTopState) {
			// Works for the exit action of parent states IF the top level state is not yet reached
			return createEmptyAction
		}
		val lowlevelParentState = lowlevelStateNode.parentState
		val lowlevelGrandparentRegion = lowlevelParentState.parentRegion
		val xStsExitAction = createSequentialAction => [
			// Action taken only if the state is "active" (assume action)
			val xStsStateAssumption = lowlevelParentState.createSingleXStsStateAssumption
			val xStsStateExitAction = xStsStateAssumption.createIfAction(lowlevelParentState.exitAction.transformAction)
			// Action taken only if the state is "active" (assume action)
			if (lowlevelGrandparentRegion.hasOrthogonalRegion && !lowlevelGrandparentRegion.stateNodes.contains(lowlevelTopState)) {
				// Orthogonal region exit actions
				it.actions += lowlevelGrandparentRegion.createRecursiveXStsOrthogonalRegionExitActions as MultiaryAction => [
					it.actions += xStsStateExitAction
				]
			}
			// No orthogonality
			else {
				it.actions += xStsStateExitAction
			} 
			// Recursion
			it.actions += lowlevelParentState.createRecursiveXStsParentStateExitActionsWithOrthogonality(lowlevelTopState)
		]
		return xStsExitAction
	}
	
	// Subregion handling
	
	protected def createRecursiveXStsOrthogonalRegionExitActions(Region lowlevelRegion) {
		if (!lowlevelRegion.hasOrthogonalRegion) {
			return createEmptyAction
		}
		return createRegionAction => [
			for (lowlevelOrthogonalRegion : lowlevelRegion.orthogonalRegions) {
				for (lowlevelSubstate : lowlevelOrthogonalRegion.states) {
					it.actions += lowlevelSubstate.createRecursiveXStsStateAndSubstateExitActions
				}
			}
		]
	}
	
	/**
	 * Creates the xSTS exit actions of the given state (in correct order) and all contained states 
	 * and all states of all orthogonal regions recursively.
	 */
	protected def Action createRecursiveXStsStateAndSubstateExitActionsWithOrthogonality(State lowlevelState) {
		val xStsStateAndSubstateExitActions = lowlevelState.createRecursiveXStsStateAndSubstateExitActions
		val lowlevelParentRegion = lowlevelState.parentRegion
		if (!lowlevelParentRegion.hasOrthogonalRegion) {
			return xStsStateAndSubstateExitActions
		}
		// Has orthogonal regions
		return createRegionAction => [
			it.actions += xStsStateAndSubstateExitActions
			// Orthogonal region actions
			for (lowlevelOrthogonalRegion : lowlevelParentRegion.orthogonalRegions) {
				for (lowlevelSubstate : lowlevelOrthogonalRegion.states) {
					it.actions += lowlevelSubstate.createRecursiveXStsStateAndSubstateExitActions
				}
			}
		]
	}
	
	protected def IfAction createRecursiveXStsStateAndSubstateExitActions(State lowlevelState) {
		val xStsStateExitActions = lowlevelState.exitAction.transformAction
		val xStsSubstateExitActions = createRegionAction
		// Recursion for the exit action of contained states
		for (lowlevelSubregion : lowlevelState.regions) {
			val xStsExitActions = newArrayList
			for (lowlevelSubstate : lowlevelSubregion.states) {
				xStsExitActions += lowlevelSubstate.createRecursiveXStsStateAndSubstateExitActions
			}
			//
			xStsExitActions.removeIf[it.effectlessAction] // Optimization
			//
			if (!xStsExitActions.empty) {
				xStsSubstateExitActions.actions += xStsExitActions.weave
			}
		}	
		val xStsStateAssumption = lowlevelState.createSingleXStsStateAssumption
		// Action taken only if the state is "active" (assume action)
		return xStsStateAssumption.createIfAction(
			createSequentialAction => [
				it.actions += xStsSubstateExitActions
				// Order is very important
				it.actions += xStsStateExitActions
			]
		)
	}

}