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

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class EntryActionRetriever {
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
	
	protected def Action createRecursiveXStsParentStateEntryActions(StateNode lowlevelState,
			State lowlevelTopState, boolean inclusiveTopState) {
		val lowlevelParentState = lowlevelState.parentState
		val lowlevelParentRegion = lowlevelState.parentRegion
		if (lowlevelParentRegion.isTopRegion ||
				(inclusiveTopState && lowlevelState == lowlevelTopState) ||
				(!inclusiveTopState && lowlevelParentState == lowlevelTopState)) {
			// Recursion for the exit action of parent states IF the top level state is not yet reached
			return createEmptyAction
		}
		val xStsEntryAction = createSequentialAction => [
			// Recursion
			it.actions += lowlevelParentState.createRecursiveXStsParentStateEntryActions(lowlevelTopState, inclusiveTopState)
			// This level
			val xStsStateAssumption = lowlevelParentState.createSingleXStsStateAssumption
			it.actions += xStsStateAssumption.createIfAction(lowlevelParentState.entryAction.transformAction)
			// Action taken only if the state is "active" (assume action)
		]
		return xStsEntryAction
	}
	
	/**
	 * Creates the xSTS entry actions of the parent state (in correct order) and all ancestor
	 * states recursively up until the given top level state (its entry action is still regarded, but its parent states' are not).
	 */
	protected def Action createRecursiveXStsParentStateEntryActionsWithOrthogonality(
			StateNode lowlevelStateNode, State lowlevelTopState) {
		val lowlevelParentRegion = lowlevelStateNode.parentRegion
		if (lowlevelParentRegion.isTopRegion || lowlevelStateNode == lowlevelTopState) {
			// Recursion for the exit action of parent states IF the top level state is not yet reached
			return createEmptyAction
		}
		val lowlevelParentState = lowlevelStateNode.parentState
		val lowlevelGrandparentRegion = lowlevelParentState.parentRegion
		val xStsEntryAction = createSequentialAction => [
			// Recursion
			it.actions += lowlevelParentState.createRecursiveXStsParentStateEntryActionsWithOrthogonality(lowlevelTopState)
			// This level
			val xStsStateAssumption = lowlevelParentState.createSingleXStsStateAssumption
			// Action taken only if the state is "active" (assume action)
			val xStsStateEntryAction = xStsStateAssumption.createIfAction(lowlevelParentState.entryAction.transformAction)
			if (lowlevelGrandparentRegion.hasOrthogonalRegion  && !lowlevelGrandparentRegion.stateNodes.contains(lowlevelTopState)) {
				// Orthogonal region exit actions
				it.actions += lowlevelGrandparentRegion.createRecursiveXStsOrthogonalRegionEntryActions as MultiaryAction => [
					it.actions += xStsStateEntryAction
				]
			}
			// No orthogonality
			else {
				it.actions += xStsStateEntryAction
			}
		]
		return xStsEntryAction
	}
	
	
	// Subregion handling
	
	protected def createRecursiveXStsRegionAndSubregionEntryActions(Region lowlevelRegion) {
		val xStsEntryActions = newArrayList
		for (lowlevelSubstate : lowlevelRegion.states) {
			xStsEntryActions += lowlevelSubstate.createRecursiveXStsStateAndSubstateEntryActions
		}
		//
		xStsEntryActions.removeIf[it.effectlessAction] // Optimization
		//
		val xStsEntryAction = (xStsEntryActions.empty) ? createEmptyAction : xStsEntryActions.weave 
		return xStsEntryAction
	}
	
	protected def createRecursiveXStsOrthogonalRegionEntryActions(Region lowlevelRegion) {
		if (!lowlevelRegion.hasOrthogonalRegion) {
			return createEmptyAction
		}
		return createRegionAction => [
			for (lowlevelOrthogonalRegion : lowlevelRegion.orthogonalRegions) {
				it.actions += lowlevelOrthogonalRegion.createRecursiveXStsRegionAndSubregionEntryActions
			}
		]
	}
	
	/**
	 * Creates the xSTS entry actions of the given state (in correct order) all contained states 
	 * and all states of all orthogonal regions recursively.
	 */
	protected def Action createRecursiveXStsStateAndSubstateEntryActionsWithOrthogonality(State lowlevelState) {
		val XStsStateAndSubstateEntryActions = lowlevelState.createRecursiveXStsStateAndSubstateEntryActions
		val lowlevelParentRegion = lowlevelState.parentRegion
		if (!lowlevelParentRegion.hasOrthogonalRegion) {
			return XStsStateAndSubstateEntryActions
		}
		// Has orthogonal regions
		return createRegionAction => [
			it.actions += XStsStateAndSubstateEntryActions
			// Orthogonal region actions
			for (lowlevelOrthogonalRegion : lowlevelParentRegion.orthogonalRegions) {
				for (lowlevelSubstate : lowlevelOrthogonalRegion.states) {
					it.actions += lowlevelSubstate.createRecursiveXStsStateAndSubstateEntryActions
				}
			}
		]
	}
	
	protected def IfAction createRecursiveXStsStateAndSubstateEntryActions(State lowlevelState) {
		val xStsStateAssumption = lowlevelState.createSingleXStsStateAssumption
		// Action taken only if the state is "active" (assume action)
		val xStsStateEntryActions = lowlevelState.entryAction.transformAction
		val xStsSubstateEntryActions = createRegionAction
		// Recursion for the entry action of contained states
		for (lowlevelSubregion : lowlevelState.regions) {
			// Actions on initial transitions
			val xStsInitialTransitionAction = lowlevelSubregion.createInitialXStsTransitionAction
			//
			val xStsEntryActions = newArrayList
			for (lowlevelSubstate : lowlevelSubregion.states) {
				xStsEntryActions += lowlevelSubstate.createRecursiveXStsStateAndSubstateEntryActions
			}
			//
			xStsEntryActions.removeIf[it.effectlessAction] // Optimization
			val xStsEntryAction = (xStsEntryActions.empty) ? createEmptyAction : xStsEntryActions.weave
			//
			val xStsRegionAction = createSequentialAction => [
//				it.actions += xStsInitialTransitionAction // Already addressed by region initial state locator - even though the order is incorrect 
				it.actions += xStsEntryAction
			]
			//
			if (!xStsRegionAction.effectlessAction) {
				xStsSubstateEntryActions.actions += xStsRegionAction
			}
		}
		return xStsStateAssumption.createIfAction(
			createSequentialAction => [
				it.actions += xStsStateEntryActions
				// Order is very important
				it.actions += xStsSubstateEntryActions
			]
		)
	}
	
	protected def createInitialXStsTransitionAction(Region lowleveRegion) {
		val lowlevelInitialTransition = lowleveRegion.initialTransition
		checkState(lowlevelInitialTransition.target instanceof State) // Only simple transitions are supported
		val lowlevelAction = lowlevelInitialTransition.action
		
		if (lowlevelAction !== null) {
			return lowlevelAction.transformAction
		}
		else {
			return createEmptyAction
		}
	}
	
}