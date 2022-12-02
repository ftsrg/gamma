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
import hu.bme.mit.gamma.statechart.lowlevel.model.DeepHistoryState
import hu.bme.mit.gamma.statechart.lowlevel.model.EntryState
import hu.bme.mit.gamma.statechart.lowlevel.model.HistoryState
import hu.bme.mit.gamma.statechart.lowlevel.model.InitialState
import hu.bme.mit.gamma.statechart.lowlevel.model.Region
import hu.bme.mit.gamma.statechart.lowlevel.model.ShallowHistoryState
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.statechart.lowlevel.model.StateNode
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.MultiaryAction
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*

class RegionActivator {
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Auxiliary objects
	protected final extension XstsActionUtil actionFactory = XstsActionUtil.INSTANCE
	protected final extension StateAssumptionCreator stateAssumptionCreator
	protected final RegionInitialStateLocator regionInitialStateLocator
	// Trace needed for variable references
	protected final ViatraQueryEngine engine
	protected final Trace trace
	
	//
	boolean traversedDeepHistory = false // This works only for single-threaded calls
	//
		
	new(ViatraQueryEngine engine, Trace trace) {
		this.engine = engine
		this.trace = trace
		this.regionInitialStateLocator = new RegionInitialStateLocator(this.engine, this.trace, this)
		this.stateAssumptionCreator = new StateAssumptionCreator(this.trace)
	}
	
	// Parent region handling
	
	// Sometimes orthogonality is not wanted (fork, join), therefore here is a separate method
	protected def Action createRecursiveXStsParentStateActivatingAction(StateNode lowlevelStateNode,
			State lowlevelTopState, boolean inclusiveTopState) {
		val lowlevelParentState = lowlevelStateNode.parentState
		val lowlevelParentRegion = lowlevelStateNode.parentRegion
		if (lowlevelParentRegion.isTopRegion ||
				(inclusiveTopState && lowlevelStateNode == lowlevelTopState) ||
				(!inclusiveTopState && lowlevelParentState == lowlevelTopState)) {
			// Works only if we have not reached the top state
			return createEmptyAction
		}
		return createSequentialAction => [
			// Recursion
			it.actions += lowlevelParentState.createRecursiveXStsParentStateActivatingAction(
				lowlevelTopState, inclusiveTopState)
			// This level
			it.actions += lowlevelStateNode.createSingleXStsParentStateActivatingAction
		]
	}
	
	/**
	 * Based on the given low-level state node, an xSTS action is created defining that the xSTS parent region variable
	 * of the parent state of the given node is set to the xSTS enum literal associated to the given low-level state, 
	 * and recursively all its parent regions up until the given top level state (its parent region is activated but its
	 * grandparent region is not), e.g., main_region (region variable) := Init (state enum literal). 
	 */
	protected def Action createRecursiveXStsParentStateActivatingActionWithOrthogonality(
			StateNode lowlevelStateNode, State lowlevelTopState) {
		if (lowlevelStateNode.parentRegion.topRegion || lowlevelStateNode == lowlevelTopState) {
			// Works only if we have not reached the top state
			return createEmptyAction
		}
		val lowlevelParentState = lowlevelStateNode.parentState
		val lowlevelGrandparentRegion = lowlevelParentState.parentRegion
		val singleXStsParentStateActivatingAction = lowlevelStateNode.createSingleXStsParentStateActivatingAction
		return createSequentialAction => [
			// Recursion
			it.actions += lowlevelParentState.createRecursiveXStsParentStateActivatingActionWithOrthogonality(lowlevelTopState)
			// This level
			if (lowlevelGrandparentRegion.hasOrthogonalRegion && !lowlevelGrandparentRegion.stateNodes.contains(lowlevelTopState)) {
				// Orthogonal
				it.actions += lowlevelGrandparentRegion.createRecursiveXStsOrthogonalRegionActivatingAction as MultiaryAction => [
					it.actions += singleXStsParentStateActivatingAction
				]
			}
			else {
				// No orthogonality
				it.actions += singleXStsParentStateActivatingAction
			}
		]
	}
	
	/**
	 * Based on the given low-level state node, an xSTS assignment action is created defining that the
	 * xSTS parent region variable of the parent state of the given node is set to the xSTS enum literal associated
	 * to the given low-level state, e.g., main_region (region variable) := Init (state enum literal). 
	 */
	protected def createSingleXStsParentStateActivatingAction(StateNode lowlevelStateNode) {
		if (lowlevelStateNode.parentRegion.topRegion) {
			return createEmptyAction
		}
		return lowlevelStateNode.parentState.createSingleXStsStateSettingAction
	}
	
	// Subregion handling
	
	// Same method for states and history nodes	(to avoid code duplication)
	protected def createRecursiveXStsStateAndSubstateActivatingActionWithOrthogonality(StateNode lowlevelStateNode) {
		checkArgument(lowlevelStateNode instanceof HistoryState || lowlevelStateNode instanceof State)
		// No parent state setting because of the parent state setter method
		val lowlevelParentRegion = lowlevelStateNode.parentRegion
		val xStsStateAndSubstateActivationAction = lowlevelStateNode.createRecursiveXStsStateAndSubstateActivatingAction
		// Has orthogonal regions
		if (lowlevelParentRegion.hasOrthogonalRegion) {
			return lowlevelParentRegion.createRecursiveXStsOrthogonalRegionActivatingAction as MultiaryAction => [
				it.actions += xStsStateAndSubstateActivationAction
			]
		}
		// No orthogonal regions
		return xStsStateAndSubstateActivationAction
	}
	
	protected def createRecursiveXStsOrthogonalRegionActivatingAction(Region lowlevelRegion) {
		if (!lowlevelRegion.hasOrthogonalRegion) {
			return createEmptyAction
		}
		return createRegionAction => [
			for (lowlevelOrthogonalRegion : lowlevelRegion.orthogonalRegions) {
				it.actions += lowlevelOrthogonalRegion.createRecursiveXStsRegionAndSubregionActivatingAction
			}
		]
	}
	
	// Dispatch - StateAndSubstateActivatingAction
	
	protected def dispatch Action createRecursiveXStsStateAndSubstateActivatingAction(InitialState lowlevelInitialState) {
		return regionInitialStateLocator.createRecursiveXStsStateAndSubstateActivatingAction(lowlevelInitialState)
	}
	
	protected def dispatch Action createRecursiveXStsStateAndSubstateActivatingAction(DeepHistoryState lowlevelHistory) {
		traversedDeepHistory = true
		val xStsAction = lowlevelHistory.createRecursiveXStsStateAndSubstateHistoryActivatingAction
		traversedDeepHistory = false
		return xStsAction
	}
	
	protected def dispatch Action createRecursiveXStsStateAndSubstateActivatingAction(ShallowHistoryState lowlevelHistory) {
		return lowlevelHistory.createRecursiveXStsStateAndSubstateHistoryActivatingAction
	}
	
	protected def Action createRecursiveXStsStateAndSubstateHistoryActivatingAction(EntryState lowlevelEntry) {
		// No parent state setting because of the parent state setter method
		val lowlevelRegion = lowlevelEntry.parentRegion
		val xStsInitialStateSettingAction = lowlevelEntry.createSingleXStsInitialStateSettingAction
		// Note: this action is executed only once for the shallow history node (later there will be history)
		val xStsIfDeactivatedAction = createIfAction(
			lowlevelRegion.createSingleXStsDeactivatedStateAssumption, // Has it been activated?
			xStsInitialStateSettingAction, // First activation
			lowlevelRegion.createSingleXStsInactiveActiveStateAction) // Reinstating history
		
		return createSequentialAction => [
			it.actions += xStsIfDeactivatedAction
			// The following action is executed every time the region is entered
			it.actions += lowlevelRegion.createRecursiveXStsHistoryBasedSubstateActivatingAction
		]
	}
	
	/**
	 * Based on the given low-level state (and implicitly its parent region), an assignment action is created
	 * defining that the xSTS parent region variable is set to the xSTS enum literal associated to the given
	 * low-level state,and recursively all states of contained regions in accordance with history states,
	 * e.g., main_region (region variable) := Init (state enum literal); subregion (region variable) := SubregionInit (state enum literal). 
	 */
	protected def dispatch Action createRecursiveXStsStateAndSubstateActivatingAction(State lowlevelState) {
		// No parent state setting because of the parent state setter method
		return createSequentialAction => [
			it.actions += lowlevelState.createSingleXStsStateSettingAction // State setting
			it.actions += lowlevelState.createRecursiveXStsSubstateActivatingAction // Substate setting
		]
	}
	
	//
		
	/**
	 * Based on the given low-level state (and implicitly its parent region), an xSTS assignment action
	 * is created defining that the xSTS parent region variable is set to the xSTS enum literal associated
	 * to the given low-level state, e.g., main_region (region variable) := Init (state enum literal). 
	 */
	protected def createSingleXStsStateSettingAction(State lowlevelState) {
		val lowlevelRegion = lowlevelState.parentRegion
		val xStsParentRegionVariable = trace.getXStsVariable(lowlevelRegion)
		val xStsEnumLiteral = trace.getXStsEnumLiteral(lowlevelState)
		return xStsParentRegionVariable.createAssignmentAction(
				xStsEnumLiteral.createEnumerationLiteralExpression)
	}
	
	/**
	 * Based on the given low-level state, a nondeterministic assignment action is created defining that
	 * the xSTS subregion variables (and NOT the parent region of the given state) of the state are set to
	 * the xSTS enum literal associated to the low-level substate, that needs to be activated on enter.
	 * It is done recursively for all contained subregions, e.g., main_region (region variable) := Init
	 * (state enum literal); assume (subregion == SubregionInit); subregion (region variable) := SubregionInit
	 * (state enum literal).
	 */
	protected def Action createRecursiveXStsSubstateActivatingAction(State lowlevelState) {
		if (lowlevelState.isComposite) {
			return createRegionAction => [
				// Setting the contained regions
				for (lowlevelSubregion : lowlevelState.regions) {
					it.actions += lowlevelSubregion.createRecursiveXStsRegionAndSubregionActivatingAction
				}
			]
		}
		// No subregion setting needed
		return createEmptyAction
	}
	
	protected def createSingleXStsInitialStateSettingAction(EntryState lowlevelEntry) {
		return regionInitialStateLocator.createSingleXStsInitialStateSettingAction(lowlevelEntry)
	}
	
	/**
	 * Not using the createSingleXStsRegionActivatingAction as this activates all subregions whereas
	 * that activates a single region.
	 */
	protected def createRecursiveXStsRegionAndSubregionActivatingAction(Region lowlevelRegion) {
		val xStsRegionSettingAction = createSequentialAction
		// Shallow history < deep history < initial state < traversed deep history above
		if (traversedDeepHistory) {
			// Deep history above: we traverse through the "history line"
			val lowlevelEntryState = lowlevelRegion.stateNodes.filter(EntryState).head
			xStsRegionSettingAction.actions += lowlevelEntryState.createRecursiveXStsStateAndSubstateHistoryActivatingAction
		}
		else if (lowlevelRegion.hasInitialState) {
			// Even if it has a history, an initial state has higher priority when entering a region
			val lowlevelInitialState = lowlevelRegion.stateNodes.filter(InitialState).head
			xStsRegionSettingAction.actions += lowlevelInitialState.createRecursiveXStsStateAndSubstateActivatingAction
		}
		else if (lowlevelRegion.hasDeepHistoryState) {
			val lowlevelDeepHistory = lowlevelRegion.stateNodes.filter(DeepHistoryState).head
			xStsRegionSettingAction.actions += lowlevelDeepHistory.createRecursiveXStsStateAndSubstateActivatingAction

		}
		else if (lowlevelRegion.hasShallowHistoryState) {
			val lowlevelShallowHistory = lowlevelRegion.stateNodes.filter(ShallowHistoryState).head
			xStsRegionSettingAction.actions += lowlevelShallowHistory.createRecursiveXStsStateAndSubstateActivatingAction
		}
		else {
			throw new IllegalStateException("Not known entry state combination")
		}
		return xStsRegionSettingAction
	}
	
	protected def createRecursiveXStsHistoryBasedSubstateActivatingAction(Region lowlevelRegion) {
		val xStsStateAndSubstateActivationActions = newArrayList
		for (lowlevelSubstate : lowlevelRegion.states) {
			xStsStateAndSubstateActivationActions +=
				lowlevelSubstate.createRecursiveXStsStateAssumptionAndSubstateActivatingAction
		}
		return xStsStateAndSubstateActivationActions.weave
	}
	
	/**
	 * Based on the given low-level state, a non deterministic action with an assumption action is created that is
	 * followed by a recursive state entry action sequence. Can be used for entering the substates of a low-level state
	 * while paying respect to the high-priority initial states in lower subregions.
	 */
	protected def createRecursiveXStsStateAssumptionAndSubstateActivatingAction(State lowlevelState) {
		val xStsStateAssumption = lowlevelState.createSingleXStsStateAssumption
		return xStsStateAssumption.createIfAction( // If this is the active state
			// Set all subregions too, that is why recursive method is called
			lowlevelState.createRecursiveXStsSubstateActivatingAction
		)
	}
	
	protected def createSingleXStsDeactivatedStateAssumption(Region lowlevelRegion) {
		val xStsParentRegionVariable = trace.getXStsVariable(lowlevelRegion)
		val xStsEnumLiteral = trace.getXStsInactiveEnumLiteral(lowlevelRegion)
		return xStsParentRegionVariable.createReferenceExpression.createEqualityExpression(
			xStsEnumLiteral.createEnumerationLiteralExpression)
	}
	
}