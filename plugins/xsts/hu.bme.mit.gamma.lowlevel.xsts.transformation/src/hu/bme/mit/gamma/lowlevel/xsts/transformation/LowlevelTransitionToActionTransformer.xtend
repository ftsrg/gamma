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

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.TransitionsBetweenSameRegionNodes
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.TransitionsToHigherAndLowerNodes
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.TransitionsToHigherNodes
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.TransitionsToLowerNodes
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.statechart.lowlevel.model.StateNode
import hu.bme.mit.gamma.statechart.lowlevel.model.Transition
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

import static com.google.common.base.Preconditions.checkState

class LowlevelTransitionToActionTransformer {
	// Auxiliary objects
	protected final extension XstsActionUtil actionFactory = XstsActionUtil.INSTANCE
	protected final extension StateAssumptionCreator stateAssumptionCreator
	protected final extension TransitionPreconditionCreator transitionPreconditionCreator
	protected final extension RegionActivator regionActivator
	protected final extension RegionDeactivator regionDeactivator
	protected final extension EntryActionRetriever entryActionRetriever
	protected final extension ExitActionRetriever exitActionRetriever
	protected final extension ActionTransformer actionTransformer
	protected final extension ExpressionTransformer expressionTransformer
	// Factories
	protected final extension XSTSModelFactory xStsModelFactory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintModelFactory = ExpressionModelFactory.eINSTANCE
	// VIATRA engine
	protected final ViatraQueryEngine engine
	// Trace
	protected final Trace trace
	
	new(ViatraQueryEngine engine, Trace trace) {
		this(engine, trace, null)
	}
	
	new(ViatraQueryEngine engine, Trace trace, RegionActivator regionActivator) {
		this.engine = engine
		this.trace = trace
		this.stateAssumptionCreator = new StateAssumptionCreator(this.trace)
		this.transitionPreconditionCreator = new TransitionPreconditionCreator(this.trace)
		if (regionActivator === null) {
			this.regionActivator = new RegionActivator(this.engine, this.trace)
		}
		else {
			this.regionActivator = regionActivator
		}
		this.regionDeactivator = new RegionDeactivator(this.trace)
		this.entryActionRetriever = new EntryActionRetriever(this.trace)
		this.exitActionRetriever = new ExitActionRetriever(this.trace)
		this.actionTransformer = new ActionTransformer(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace)
	}
	
	protected def boolean isBetweenSameRegionNodes(Transition lowlevelTransition) {
		return TransitionsBetweenSameRegionNodes.Matcher.on(engine).hasMatch(null, lowlevelTransition, null)
	}
	
	protected def boolean isToHigherNode(StateNode lowlevelSource, State lowlevelSourceAncestor,
			Transition lowlevelTransition, StateNode lowlevelTarget) {
		return TransitionsToHigherNodes.Matcher.on(engine).hasMatch(lowlevelSource, lowlevelSourceAncestor, lowlevelTransition, lowlevelTarget)
	}
	
	protected def boolean isToHigherNode(Transition lowlevelTransition) {
		return isToHigherNode(null, null, lowlevelTransition, null)
	}
	
	protected def boolean isToLowerNode(StateNode lowlevelSource, Transition lowlevelTransition,
			State lowlevelTargetAncestor, StateNode lowlevelTarget) {
		return TransitionsToLowerNodes.Matcher.on(engine).hasMatch(lowlevelSource, lowlevelTransition, lowlevelTargetAncestor, lowlevelTarget)
	}
	
	protected def boolean isToLowerNode(Transition lowlevelTransition) {
		return isToLowerNode(null, lowlevelTransition, null, null)
	}
	
	protected def boolean isToHigherAndLowerNode(StateNode lowlevelSource, State lowlevelSourceAncestor,
			Transition lowlevelTransition, State lowlevelTargetAncestor, StateNode lowlevelTarget) {
		return TransitionsToHigherAndLowerNodes.Matcher.on(engine).hasMatch(lowlevelSource, lowlevelSourceAncestor, lowlevelTransition, lowlevelTargetAncestor, lowlevelTarget)
	}
	
	protected def boolean isToHigherAndLowerNode(Transition lowlevelTransition) {
		return isToHigherAndLowerNode(null, null, lowlevelTransition, null, null)
	}
	
	protected def getSourceAncestor(Transition lowlevelTransition) {
		if (lowlevelTransition.isToHigherNode) {
			val sourceAncestors = TransitionsToHigherNodes.Matcher.on(engine).getAllValuesOfsourceAncestor(null, lowlevelTransition, null)
			checkState(sourceAncestors.size == 1)
			return sourceAncestors.head
		}
		else if (lowlevelTransition.isToHigherAndLowerNode) {
			val sourceAncestors = TransitionsToHigherAndLowerNodes.Matcher.on(engine).getAllValuesOfsourceAncestor(null, lowlevelTransition, null, null)
			checkState(sourceAncestors.size == 1)
			return sourceAncestors.head
		}
	}
	
	protected def getTargetAncestor(Transition lowlevelTransition) {
		if (lowlevelTransition.isToLowerNode) {
			val targetAncestors = TransitionsToLowerNodes.Matcher.on(engine).getAllValuesOftargetAncestor(null, lowlevelTransition, null)
			checkState(targetAncestors.size == 1)
			return targetAncestors.head
		}
		else if (lowlevelTransition.isToHigherAndLowerNode) {
			val targetAncestors = TransitionsToHigherAndLowerNodes.Matcher.on(engine).getAllValuesOftargetAncestor(null, null, lowlevelTransition, null)
			checkState(targetAncestors.size == 1)
			return targetAncestors.head
		}
	}
	
	// Exit
	
	protected def createSingleXStsStateExitActions(State lowlevelSource) {
		val actions = <Action>newLinkedList
		val lowlevelParentRegion = lowlevelSource.parentRegion
		actions += lowlevelSource.exitAction.transformAction
		actions += lowlevelParentRegion.createSingleXStsRegionDeactivatingAction
		return actions
	}
	
	protected def createRecursiveXStsTransitionExitActions(Transition lowlevelTransition,
			boolean inclusiveTopState) {
		val lowlevelSourceState = lowlevelTransition.source as State
		val actions = <Action>newArrayList
		// Always exiting regions of it is a toHigher transition, see the consequence in createRecursiveXStsTransitionEntryActions
		if (lowlevelTransition.isToHigherNode || lowlevelTransition.isToHigherAndLowerNode) {
			// To lower characteristics
			val lowlevelSourceAncestor = lowlevelTransition.sourceAncestor
			actions += lowlevelSourceState.createRecursiveXStsStateAndSubstateExitActions
			actions += lowlevelSourceState.createRecursiveXStsParentStateExitActions(lowlevelSourceAncestor, inclusiveTopState)
			actions += lowlevelSourceState.createRecursiveXStsParentStateDeactivatingAction(lowlevelSourceAncestor, inclusiveTopState) // Note: must be before state entry actions
			actions += lowlevelSourceState.createRecursiveXStsStateAndSubstateDeactivatingAction // Note: must be before state entry actions
		}
		else {
			// Not to lower characteristics
			actions += lowlevelSourceState.createRecursiveXStsStateAndSubstateExitActions
			actions += lowlevelSourceState.createRecursiveXStsStateAndSubstateDeactivatingAction // Note: must be before state entry actions
		}
		return actions
	}
	
	protected def createRecursiveXStsTransitionExitActionsWithOrthogonality(Transition lowlevelTransition) {
		val lowlevelSourceState = lowlevelTransition.source as State
		val actions = <Action>newArrayList
		// Always exiting regions of it is a toHigher transition, see the consequence in createRecursiveXStsTransitionEntryActionsWithOrthogonality
		if (lowlevelTransition.isToHigherNode || lowlevelTransition.isToHigherAndLowerNode) {
			// To higher characteristics
			val lowlevelSourceAncestor = lowlevelTransition.sourceAncestor
			actions += lowlevelSourceState.createRecursiveXStsStateAndSubstateExitActionsWithOrthogonality
			actions += lowlevelSourceState.createRecursiveXStsParentStateExitActionsWithOrthogonality(lowlevelSourceAncestor)
			actions += lowlevelSourceState.createRecursiveXStsParentStateDeactivatingActionWithOrthogonality(lowlevelSourceAncestor) // Note: must be after state exit actions
			actions += lowlevelSourceState.createRecursiveXStsStateAndSubstateDeactivatingActionWithOrthogonality // Note: must be after state exit actions
		}
		else {
			// Not to higher
			actions += lowlevelSourceState.createRecursiveXStsStateAndSubstateExitActions
			actions += lowlevelSourceState.createRecursiveXStsStateAndSubstateDeactivatingAction // Note: must be after state exit actions
		}
		return actions
	}
	
	protected def createRecursiveXStsTransitionParentExitActions(Transition lowlevelTransition) {
		val lowlevelSourceNode = lowlevelTransition.source
		val actions = newLinkedList
		if (isToHigherNode(lowlevelSourceNode, null, lowlevelTransition, null) || 
				isToHigherAndLowerNode(lowlevelSourceNode, null, lowlevelTransition, null, null)) {
			// To higher characteristics
			val lowlevelSourceAncestor = lowlevelTransition.sourceAncestor
			actions += lowlevelSourceNode.createRecursiveXStsParentStateExitActions(lowlevelSourceAncestor, false)
			actions += lowlevelSourceNode.createRecursiveXStsParentStateDeactivatingAction(lowlevelSourceAncestor, false) // Note: must be after state exit actions
		}
		return actions
	}
	
	protected def createRecursiveXStsOrthogonalRegionAndTransitionParentExitActionsWithOrthogonality(
			Transition lowlevelTransition) {
		val lowlevelSourceNode = lowlevelTransition.source
		val actions = newLinkedList
		if (isToHigherNode(lowlevelSourceNode, null, lowlevelTransition, null) || 
				isToHigherAndLowerNode(lowlevelSourceNode, null, lowlevelTransition, null, null)) {
			// To higher characteristics
			val lowlevelSourceAncestor = lowlevelTransition.sourceAncestor
			val lowlevelParentRegion = lowlevelSourceNode.parentRegion
			// Orthogonal regions have to be exited
			actions += lowlevelParentRegion.createRecursiveXStsOrthogonalRegionExitActions 
			actions += lowlevelParentRegion.createRecursiveXStsOrthogonalRegionDeactivatingAction
			//
			actions += lowlevelSourceNode.createRecursiveXStsParentStateExitActionsWithOrthogonality(lowlevelSourceAncestor)
			actions += lowlevelSourceNode.createRecursiveXStsParentStateDeactivatingActionWithOrthogonality(lowlevelSourceAncestor) // Note: must be after state exit actions
		}
		return actions
	}
	
	// Entry
	
	protected def createSingleXStsStateEntryActions(State lowlevelSource) {
		val actions = <Action>newLinkedList
		actions += lowlevelSource.createSingleXStsStateSettingAction
		actions += lowlevelSource.entryAction.transformAction
		return actions
	}
	
	protected def createRecursiveXStsTransitionEntryActions(Transition lowlevelTransition,
			boolean inclusiveTopState) {
		val lowlevelTargetState = lowlevelTransition.target as State
		val actions = <Action>newArrayList
		var ancestor = if (isToLowerNode(null, lowlevelTransition, null, lowlevelTargetState) || 
				isToHigherAndLowerNode(null, null, lowlevelTransition, null, lowlevelTargetState)) {
			lowlevelTransition.targetAncestor
		} else if (lowlevelTransition.isToHigherNode|| lowlevelTransition.isToHigherAndLowerNode) {
			// Consequence: The source ancestor has to be activated again, as it has been deactivated,
			// e.g., in case of to higher choice transitions
			lowlevelTransition.sourceAncestor
		}
		if (ancestor !== null) {
			// To lower characteristics
			actions += lowlevelTargetState.createRecursiveXStsStateAndSubstateActivatingAction // Note: must be before state entry actions
			actions += lowlevelTargetState.createRecursiveXStsParentStateActivatingAction(ancestor, inclusiveTopState) // Note: must be before state entry actions
			actions += lowlevelTargetState.createRecursiveXStsParentStateEntryActions(ancestor, inclusiveTopState)
			actions += lowlevelTargetState.createRecursiveXStsStateAndSubstateEntryActions
		}
		else {
			// Not to lower characteristics
			actions += lowlevelTargetState.createRecursiveXStsStateAndSubstateActivatingAction // Note: must be before state entry actions
			actions += lowlevelTargetState.createRecursiveXStsStateAndSubstateEntryActions
		}
		return actions
	}
	
	protected def createRecursiveXStsTransitionEntryActionsWithOrthogonality(Transition lowlevelTransition) {
		val lowlevelTargetState = lowlevelTransition.target as State
		val actions = <Action>newArrayList
		
		var ancestor = if (isToLowerNode(null, lowlevelTransition, null, lowlevelTargetState) || 
				isToHigherAndLowerNode(null, null, lowlevelTransition, null, lowlevelTargetState)) {
			lowlevelTransition.targetAncestor
		} else if (lowlevelTransition.isToHigherNode || lowlevelTransition.isToHigherAndLowerNode) {
			// Consequence: The source ancestor has to be activated again, as it has been deactivated,
			// e.g., in case of to higher choice transitions
//			lowlevelTransition.sourceAncestor // TODO This solution was not correct for sure for "toHigher" transitions
			null
		}
		if (ancestor !== null) {
			// To lower characteristics
			actions += lowlevelTargetState.createRecursiveXStsStateAndSubstateActivatingActionWithOrthogonality // Note: must be before state entry actions
			actions += lowlevelTargetState.createRecursiveXStsParentStateActivatingActionWithOrthogonality(ancestor) // Note: must be before state entry actions
			actions += lowlevelTargetState.createRecursiveXStsParentStateEntryActionsWithOrthogonality(ancestor)
			actions += lowlevelTargetState.createRecursiveXStsStateAndSubstateEntryActionsWithOrthogonality
		}
		else {
			// Not to lower characteristics
			actions += lowlevelTargetState.createRecursiveXStsStateAndSubstateActivatingAction // Note: must be before state entry actions
			actions += lowlevelTargetState.createRecursiveXStsStateAndSubstateEntryActions
		}
		return actions
	}
	
	protected def createRecursiveXStsTransitionParentEntryActions(Transition lowlevelTransition) {
		val lowlevelTargetNode = lowlevelTransition.target
		val actions = newLinkedList
		if (isToLowerNode(null, lowlevelTransition, null, lowlevelTargetNode) || 
				isToHigherAndLowerNode(null, null, lowlevelTransition, null, lowlevelTargetNode)) {
			// To lower characteristics
			var lowlevelTargetAncestor = lowlevelTransition.targetAncestor
			actions += lowlevelTargetNode.createRecursiveXStsParentStateActivatingAction(lowlevelTargetAncestor, false) // Note: must be before state entry actions
			actions += lowlevelTargetNode.createRecursiveXStsParentStateEntryActions(lowlevelTargetAncestor, false)
		}
		return actions
	}
	
	protected def createRecursiveXStsOrthogonalRegionAndTransitionParentEntryActionsWithOrthogonality(
			Transition lowlevelTransition) {
		val lowlevelTargetNode = lowlevelTransition.target
		val actions = newLinkedList
		if (isToLowerNode(null, lowlevelTransition, null, lowlevelTargetNode) || 
				isToHigherAndLowerNode(null, null, lowlevelTransition, null, lowlevelTargetNode)) {
			// To lower characteristics
			var lowlevelTargetAncestor = lowlevelTransition.targetAncestor
			val lowlevelParentRegion = lowlevelTargetNode.parentRegion
			actions += lowlevelTargetNode.createRecursiveXStsParentStateActivatingActionWithOrthogonality(lowlevelTargetAncestor) // Note: must be before state entry actions
			actions += lowlevelTargetNode.createRecursiveXStsParentStateEntryActionsWithOrthogonality(lowlevelTargetAncestor)
 			 // Orthogonal regions have to be entered
			actions += lowlevelParentRegion.createRecursiveXStsOrthogonalRegionActivatingAction
			actions += lowlevelParentRegion.createRecursiveXStsOrthogonalRegionEntryActions
		}
		return actions
	}
	
}