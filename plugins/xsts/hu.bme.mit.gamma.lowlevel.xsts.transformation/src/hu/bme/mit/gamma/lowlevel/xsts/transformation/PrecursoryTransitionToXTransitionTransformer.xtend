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

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.statechart.lowlevel.model.JoinState
import hu.bme.mit.gamma.statechart.lowlevel.model.MergeState
import hu.bme.mit.gamma.statechart.lowlevel.model.PrecursoryState
import hu.bme.mit.gamma.statechart.lowlevel.model.PseudoState
import hu.bme.mit.gamma.statechart.lowlevel.model.Region
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.statechart.lowlevel.model.StateNode
import hu.bme.mit.gamma.statechart.lowlevel.model.Transition
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import java.util.List
import java.util.Set
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*

class PrecursoryTransitionToXTransitionTransformer extends LowlevelTransitionToXTransitionTransformer {
	
	protected final extension TerminalTransitionToXTransitionTransformer terminalTransitionToActionTransformer
	
	new(ViatraQueryEngine engine, Trace trace) {
		super(engine, trace)
		this.terminalTransitionToActionTransformer =
			new TerminalTransitionToXTransitionTransformer(this.engine, this.trace)
	}
	
	def transform(JoinState lowlevelLastJoinState) {
		val xStsAction = lowlevelLastJoinState.transformBackward
		val xStsParallelAction = xStsAction.actions.head as ParallelAction
		val xStsRecursivePrecondition = lowlevelLastJoinState.createRecursiveXStsBackwardPrecondition
		// The precondition has to be contained in an EMF tree (trace serialization) at index 0
		xStsAction.actions.add(0, xStsRecursivePrecondition.createAssumeAction)
		val xStsForwardAction = lowlevelLastJoinState.transformForward
		xStsAction.actions += xStsForwardAction
		val xStsComplexTransition = xStsAction.createXStsTransition
		trace.put(lowlevelLastJoinState, xStsComplexTransition, xStsRecursivePrecondition, xStsParallelAction)
		return xStsComplexTransition
	}
	
	def transform(MergeState lowlevelLastMergeState) {
		// Not supported anymore, a preprocessing step takes care of merge states
		throw new IllegalArgumentException("Merge states are not supported")
	}
	
	// Backward
	
	protected def dispatch SequentialAction transformBackward(PseudoState lowlevelPseudoState) {
		throw new IllegalArgumentException("Not known pseudo state: " + lowlevelPseudoState)
	}
	
	protected def dispatch SequentialAction transformBackward(JoinState lowlevelJoinState) {
		val lowlevelIncomingTransitions = lowlevelJoinState.incomingTransitions
		checkArgument(lowlevelIncomingTransitions.size >= 1)
		val lowlevelOutgoingTransitions = lowlevelJoinState.outgoingTransitions
		checkArgument(lowlevelOutgoingTransitions.size == 1)
		val exitedLowlevelRegions = lowlevelJoinState.recursiveLowlevelDeactivatedRegions
		val lowlevelSourceAncestor = lowlevelJoinState.sourceAncestor
		// Fork action that is traced
		val xStsParallelAction = createParallelAction => [
			// Deactivating regions that are not going to be exited
			it.actions += lowlevelSourceAncestor.createXStsUnexitedRegionExitAction(exitedLowlevelRegions)
			// Going backward
			for (lowlevelIncomingTransition : lowlevelJoinState.incomingTransitions) {
				val lowlevelSource = lowlevelIncomingTransition.source
				it.actions += lowlevelJoinState.createRecursiveXStsBackwardNodeConnection(lowlevelIncomingTransition, lowlevelSource)
			}
		]
		// Postcondition
		val xStsTransitionAction = createSequentialAction => [
			it.actions += xStsParallelAction // "Backward" actions
			// No guard, it is in the xStsRecursivePrecondition
			// Source ancestor exit only once
			it.actions += lowlevelSourceAncestor.createSingleXStsStateExitActions
			// No forward: it would lead to infinite recursion
		]
		return xStsTransitionAction
		// The caller needs to add xStsRecursivePrecondition by hand!
	}
	
	protected def dispatch SequentialAction transformBackward(MergeState lowlevelMergeState) {
		// Not supported anymore, a preprocessing step takes care of merge states
		throw new IllegalArgumentException("Merge states are not supported")
	}
	
	// Note that choices and forks cannot be before merges and joins
	//
	
	// Connecting complex transitions backward through nodes
	
	protected def dispatch createRecursiveXStsBackwardNodeConnection(MergeState lowlevelMerge, 
			Transition lowlevelTransition, State lowlevelSource) { 
		checkArgument(lowlevelTransition.source == lowlevelSource && lowlevelTransition.target == lowlevelMerge)
		val lowlevelTransitionAction = lowlevelTransition.action
		return createSequentialAction => [
			it.actions += lowlevelTransition.createRecursiveXStsTransitionExitActionsWithOrthogonality
			if (lowlevelTransitionAction !== null) {
				it.actions += lowlevelTransitionAction.transformAction
			}
			it.actions += lowlevelTransition.createRecursiveXStsOrthogonalRegionAndTransitionParentEntryActionsWithOrthogonality
		]
	}
	
	protected def dispatch createRecursiveXStsBackwardNodeConnection(JoinState lowlevelJoin, 
			Transition lowlevelTransition, State lowlevelSource) {
		checkArgument(lowlevelTransition.source == lowlevelSource && lowlevelTransition.target == lowlevelJoin)
		val lowlevelTransitionAction = lowlevelTransition.action
		return createSequentialAction => [
			it.actions += lowlevelTransition.createRecursiveXStsTransitionExitActions(false /* So source ancestors are not exited multiple times */)
			if (lowlevelTransitionAction !== null) {
				it.actions += lowlevelTransitionAction.transformAction
			}
			it.actions += lowlevelTransition.createRecursiveXStsTransitionParentEntryActions
		]
		// The deactivation of the unexited regions still need to be deactivated by the caller
		// See lowlevelSourceAncestor.createSingleXStsStateExitActions in the Join transformer
	}
	
	protected def dispatch createRecursiveXStsBackwardNodeConnection(MergeState lowlevelMerge, 
			Transition lowlevelTransition, PseudoState lowlevelSource) {
		checkArgument(lowlevelTransition.source == lowlevelSource 
			&& lowlevelTransition.target == lowlevelMerge && lowlevelSource.outgoingTransitions.size == 1)
		val lowlevelTransitionAction = lowlevelTransition.action
		return lowlevelSource.transformBackward => [
			// Known issue: as this is a sequential action, the additional orthogonal region exits come
			// after the deactivation of the source region (they should be all in one parallel action)
			// Possible solution? lowlevelSource.transformBackward is placed inside the OrthogonalRegion... action?
			it.actions += lowlevelTransition.createRecursiveXStsOrthogonalRegionAndTransitionParentExitActionsWithOrthogonality
			if (lowlevelTransitionAction !== null) {
				it.actions += lowlevelTransitionAction.transformAction
			}
			it.actions += lowlevelTransition.createRecursiveXStsOrthogonalRegionAndTransitionParentEntryActionsWithOrthogonality
		]
	}
	protected def dispatch createRecursiveXStsBackwardNodeConnection(JoinState lowlevelJoin, 
			Transition lowlevelTransition, PseudoState lowlevelSource) {
		checkArgument(lowlevelTransition.source == lowlevelSource 
			&& lowlevelTransition.target == lowlevelJoin && lowlevelSource.outgoingTransitions.size == 1)
		val lowlevelTransitionAction = lowlevelTransition.action
		return lowlevelSource.transformBackward => [
			it.actions += lowlevelTransition.createRecursiveXStsTransitionParentExitActions
			if (lowlevelTransitionAction !== null) {
				it.actions += lowlevelTransitionAction.transformAction
			}
			it.actions += lowlevelTransition.createRecursiveXStsTransitionParentEntryActions
		]
	}
	
	// Precondition creation: only assumptions of transitions going out from states are regarded,
	// in-action assumptions are not, as on this level, the assignments to variables cannot be considered correctly
	
	protected def dispatch createRecursiveXStsBackwardPrecondition(StateNode lowlevelStateNode) {
		throw new IllegalArgumentException("Not supported state node: " + lowlevelStateNode)
	}
	
	protected def dispatch Expression createRecursiveXStsBackwardPrecondition(MergeState lowlevelPrecursoryState) {
		return createOrExpression => [
			for (lowlevelIncomingTransition : lowlevelPrecursoryState.incomingTransitions) {
				val lowlevelSource = lowlevelIncomingTransition.source
				it.operands += lowlevelSource.createRecursiveXStsBackwardPrecondition(lowlevelIncomingTransition)
			}
		]
	}
	
	protected def dispatch Expression createRecursiveXStsBackwardPrecondition(JoinState lowlevelPrecursoryState) {
		return createAndExpression => [
			for (lowlevelIncomingTransition : lowlevelPrecursoryState.incomingTransitions) {
				val lowlevelSource = lowlevelIncomingTransition.source
				it.operands += lowlevelSource.createRecursiveXStsBackwardPrecondition(lowlevelIncomingTransition)
			}
		]
	}
	
	protected def dispatch createRecursiveXStsBackwardPrecondition(State lowlevelState, Transition lowlevelOutgoingTransition) {
		return lowlevelOutgoingTransition.createXStsTransitionPrecondition
	}
	
	protected def dispatch createRecursiveXStsBackwardPrecondition(PrecursoryState lowlevelPrecursoryState,
			Transition lowlevelOutgoingTransition) {
		checkArgument(lowlevelOutgoingTransition.guard === null,
			"Transitions going out from precursory states cannot have guards: " + lowlevelOutgoingTransition)
		return lowlevelPrecursoryState.createRecursiveXStsBackwardPrecondition
	}
	
	//
	
	// Join auxiliary
	
	protected def getSourceAncestor(JoinState lowlevelForkState) {
		var State lowlevelSourceAncestor
		for (lowlevelIncomingTransition : lowlevelForkState.incomingTransitions) {
			val lowlevelSourceAncestorCandidate = lowlevelIncomingTransition.sourceAncestor
			lowlevelSourceAncestor = if (lowlevelSourceAncestor === null || (lowlevelSourceAncestorCandidate !== null &&
					lowlevelSourceAncestor.parentRegionsRecursively.contains(lowlevelSourceAncestorCandidate.parentRegion))) {
				lowlevelSourceAncestorCandidate
			}
		}
		return lowlevelSourceAncestor
	}
	
	protected def Set<Region> getRecursiveLowlevelDeactivatedRegions(JoinState lowlevelJoinState) {
		val exitedLowlevelRegions = newHashSet
		for (lowlevelIncomingTransition : lowlevelJoinState.incomingTransitions) {
			exitedLowlevelRegions += lowlevelIncomingTransition.getRecursiveLowlevelDeactivatedRegions
		}
		return exitedLowlevelRegions
	}
	
	protected def Set<Region> getRecursiveLowlevelDeactivatedRegions(Transition lowlevelTransition) {
		val lowlevelSourceAncestor = lowlevelTransition.sourceAncestor  // Checking activated parent regions until this state
		val deactivatedLowlevelRegions = newHashSet
		val lowlevelSource = lowlevelTransition.source
		if (lowlevelSource instanceof State) {
			val deactivatedLowlevelRegionFraction = lowlevelSource.getParentRegionsRecursively(lowlevelSourceAncestor)
			deactivatedLowlevelRegionFraction += lowlevelSource.getSubregionsRecursively
			deactivatedLowlevelRegions += deactivatedLowlevelRegionFraction
		}
		else if (lowlevelSource instanceof JoinState) {
			// Important to denote the parent region of the junction deactivated
			deactivatedLowlevelRegions += lowlevelSource.parentRegion
			// Recursion
			deactivatedLowlevelRegions += lowlevelSource.getRecursiveLowlevelDeactivatedRegions
		}
		else if (lowlevelSource instanceof MergeState) {
			val lowlevelIncomingTransitions = lowlevelSource.incomingTransitions
			val firstIncomingLowlevelTransition = lowlevelIncomingTransitions.head
			val lowlevelParentRegion = firstIncomingLowlevelTransition.source.parentRegion
			if (lowlevelIncomingTransitions.map[it.source]
					.forall[it instanceof State && it.parentRegion == lowlevelParentRegion]) {
				// All branches are from the same region
				deactivatedLowlevelRegions += lowlevelParentRegion
			}
			else if (lowlevelIncomingTransitions.map[it.source]
					.forall[it instanceof JoinState]) {
				for (lowlevelIncomingTransition : lowlevelIncomingTransitions) {
					deactivatedLowlevelRegions += lowlevelIncomingTransition.getRecursiveLowlevelDeactivatedRegions
				}
			}
			else {
				throw new IllegalArgumentException("Not supported merge -> join structure: " + lowlevelSource)
			}
		}
		return deactivatedLowlevelRegions
	}
	
	/** Basically a DFS. */
	protected def List<Action> createXStsUnexitedRegionExitAction(State lowlevelState, Set<Region> exitedRegions) {
		val xStsRegionExitActions = <Action>newLinkedList
		for (lowlevelSubregion : lowlevelState.regions) {
			if (!exitedRegions.contains(lowlevelSubregion)) {
				xStsRegionExitActions += createSequentialAction => [
					// State exits
					for (lowlevelSubstate : lowlevelSubregion.states) {
						it.actions += lowlevelSubstate.createRecursiveXStsStateAndSubstateExitActions
					}
					// Region deactivations
					it.actions += lowlevelSubregion.createRecursiveXStsRegionAndSubregionDeactivatingAction
				]
			}
			else {
				// Recursion
				for (lowlevelCompositeSubstate : lowlevelSubregion.states.filter[it.composite]) {
					xStsRegionExitActions += lowlevelCompositeSubstate.createXStsUnexitedRegionExitAction(exitedRegions)
				}
			}
		}
		return xStsRegionExitActions
	}
	
}