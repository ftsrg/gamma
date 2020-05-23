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

import hu.bme.mit.gamma.statechart.lowlevel.model.ChoiceState
import hu.bme.mit.gamma.statechart.lowlevel.model.ForkState
import hu.bme.mit.gamma.statechart.lowlevel.model.PseudoState
import hu.bme.mit.gamma.statechart.lowlevel.model.Region
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.statechart.lowlevel.model.Transition
import hu.bme.mit.gamma.xsts.model.model.Action
import hu.bme.mit.gamma.xsts.model.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.model.SequentialAction
import java.util.List
import java.util.Set
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.lowlevel.model.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*

class TerminalTransitionToXTransitionTransformer extends LowlevelTransitionToXTransitionTransformer {
	
	new(ViatraQueryEngine engine, Trace trace) {
		super(engine, trace)
	}
	
	new(ViatraQueryEngine engine, Trace trace, RegionActivator regionActivator) {
		super(engine, trace, regionActivator)
	}
	
	def transform(ForkState lowlevelFirstForkState) {
		val xStsAction = lowlevelFirstForkState.transformForward
		val xStsPreconditionAction = xStsAction.actions.head as AssumeAction
		val xStsPrecondition = xStsPreconditionAction.assumption
		val xStsChoiceAction = xStsAction.actions.last as ParallelAction
		val xStsComplexTransition = xStsAction.createXStsTransition
		trace.put(lowlevelFirstForkState, xStsComplexTransition, xStsPrecondition, xStsChoiceAction)
		return xStsComplexTransition
	}
	
	def transform(ChoiceState lowlevelFirstChoiceState) {
		val xStsAction = lowlevelFirstChoiceState.transformForward
		val xStsPreconditionAction = xStsAction.actions.head as AssumeAction
		val xStsPrecondition = xStsPreconditionAction.assumption
		val xStsChoiceAction = xStsAction.actions.last as NonDeterministicAction
		val xStsComplexTransition = xStsAction.createXStsTransition
		trace.put(lowlevelFirstChoiceState, xStsComplexTransition, xStsPrecondition, xStsChoiceAction)
		return xStsComplexTransition
	}
	
	// Forward
	
	def dispatch SequentialAction transformForward(PseudoState lowlevelPseudoState) {
		// This can be called after a transformBackward on the same Join or Merge state
		val lowlevelOutgoingTransitions = lowlevelPseudoState.outgoingTransitions
		checkArgument(lowlevelOutgoingTransitions.size == 1, lowlevelOutgoingTransitions)
		val lowlevelOutgoingTransition = lowlevelOutgoingTransitions.head
		val lowlevelTargetNode = lowlevelOutgoingTransition.target
		return lowlevelPseudoState.createRecursiveXStsForwardNodeConnection(lowlevelOutgoingTransition, lowlevelTargetNode)
	}

	def dispatch SequentialAction transformForward(ForkState lowlevelForkState) {
		val lowlevelIncomingTransitions = lowlevelForkState.incomingTransitions
		checkArgument(lowlevelIncomingTransitions.size == 1)
		val lowlevelIncomingTransition = lowlevelIncomingTransitions.head
		val lowlevelOutgoingTransitions = lowlevelForkState.outgoingTransitions
		checkArgument(lowlevelOutgoingTransitions.size >= 1)
		val xStsPrecondition = lowlevelIncomingTransition.createXStsTransitionPrecondition // State and guard
		// Note: precondition is easy now, as currently incoming actions are NOT supported
		val enteredLowlevelRegions = lowlevelForkState.recursiveLowlevelActivatedRegions
		val lowlevelTargetAncestor = lowlevelForkState.targetAncestor
		val xStsParallelForkAction = createParallelAction => [
			// Activating regions that are not going to be entered
			it.actions += lowlevelTargetAncestor.createXStsUnenteredRegionEntryAction(enteredLowlevelRegions)
			// Going forward
			for (lowlevelOutgoingTransition : lowlevelOutgoingTransitions) {
				val lowlevelTargetNode = lowlevelOutgoingTransition.target
				it.actions += lowlevelForkState.createRecursiveXStsForwardNodeConnection(lowlevelOutgoingTransition, lowlevelTargetNode)
			}
		]
		val lowlevelSourceNode = lowlevelIncomingTransition.source
		// Main action
		val xStsTransitionAction = createSequentialAction => [
			// A precondition is needed even if it is a true expression due to tracing
			it.actions += xStsPrecondition.createAssumeAction
			// No backward: it would lead to infinite recursion, just checking if it the source is a state
			if (lowlevelSourceNode instanceof State) {
				it.actions += lowlevelIncomingTransition.createRecursiveXStsTransitionExitActionsWithOrthogonality
			}
			// Target ancestor entry only once
			it.actions += lowlevelTargetAncestor.createSingleXStsStateEntryActions
			it.actions += xStsParallelForkAction
		]
		return xStsTransitionAction
	}
	
	def dispatch SequentialAction transformForward(ChoiceState lowlevelChoiceState) {
		val lowlevelIncomingTransitions = lowlevelChoiceState.incomingTransitions
		checkArgument(lowlevelIncomingTransitions.size == 1)
		val lowlevelIncomingTransition = lowlevelIncomingTransitions.head
		val lowlevelOutgoingTransitions = lowlevelChoiceState.outgoingTransitions
		checkArgument(lowlevelOutgoingTransitions.size >= 1)
		val lowlevelSourceNode = lowlevelIncomingTransition.source
		val xStsPrecondition = lowlevelIncomingTransition.createXStsTransitionPrecondition // State and guard
		// Note: precondition is easy now, as currently incoming actions are NOT supported
		// Precondition (contains this source precondition and all upcoming ones as well)
		val xStsChoicePostcondition = createNonDeterministicAction // Will contain the branches
		val xStsChoiceAction = createSequentialAction => [
			// A precondition is needed even if it is a true expression due to tracing
			it.actions += xStsPrecondition.createAssumeAction
			// No backward: it would lead to infinite recursion, just checking if it the source is a state
			if (lowlevelSourceNode instanceof State) {
				it.actions += lowlevelIncomingTransition.createRecursiveXStsTransitionExitActionsWithOrthogonality
			}
			it.actions += xStsChoicePostcondition
		]
		// Postcondition
		for (lowlevelOutgoingTransition : lowlevelOutgoingTransitions) {
			val lowlevelTargetGuard = lowlevelOutgoingTransition.guard.transformExpression
			checkArgument(lowlevelTargetGuard !== null)
			val lowlevelTargetNode = lowlevelOutgoingTransition.target
			xStsChoicePostcondition.extendChoiceWithBranch(lowlevelTargetGuard,
				lowlevelChoiceState.createRecursiveXStsForwardNodeConnection(lowlevelOutgoingTransition, lowlevelTargetNode)
			)
		}	
		return xStsChoiceAction
	}
	
	// Note that  merges and joins cannot be after choices and forks
	//
	
	// Connecting complex transitions forward through nodes
	
	protected def dispatch createRecursiveXStsForwardNodeConnection(PseudoState lowlevelPseudoState,
			Transition lowlevelTransition, State lowlevelTarget) { 
		// Single target elements: merges or joins
		checkArgument(lowlevelPseudoState.outgoingTransitions.size == 1 &&
			lowlevelTransition.source == lowlevelPseudoState && lowlevelTransition.target == lowlevelTarget)
		val lowlevelTransitionAction = lowlevelTransition.action
		return createSequentialAction => [
			it.actions += lowlevelTransition.createRecursiveXStsOrthogonalRegionAndTransitionParentExitActionsWithOrthogonality
			if (lowlevelTransitionAction !== null) {
				it.actions += lowlevelTransitionAction.transformAction
			}
			it.actions += lowlevelTransition.createRecursiveXStsTransitionEntryActionsWithOrthogonality
		]
	}
	
	protected def dispatch createRecursiveXStsForwardNodeConnection(PseudoState lowlevelPseudoState,
			Transition lowlevelTransition, PseudoState lowlevelTarget) {
		// Single target elements: merges or joins
		checkArgument(lowlevelPseudoState.outgoingTransitions.size == 1 && lowlevelTransition.source == lowlevelPseudoState &&
			lowlevelTransition.target == lowlevelTarget && lowlevelTarget.incomingTransitions.size == 1)
		val lowlevelTransitionAction = lowlevelTransition.action
		return lowlevelTarget.transformForward => [
			// Needed if the transition from the junction is to higher
			it.actions.addAll(0, lowlevelTransition.createRecursiveXStsOrthogonalRegionAndTransitionParentExitActionsWithOrthogonality)
			if (lowlevelTransitionAction !== null) {
				it.actions.add(0, lowlevelTransitionAction.transformAction)
			}
			it.actions.addAll(0, lowlevelTransition.createRecursiveXStsOrthogonalRegionAndTransitionParentEntryActionsWithOrthogonality)
		]
	}
	
	protected def dispatch createRecursiveXStsForwardNodeConnection(ChoiceState lowlevelChoice,
			Transition lowlevelTransition, State lowlevelTarget) {
		checkArgument(lowlevelTransition.source == lowlevelChoice && lowlevelTransition.target == lowlevelTarget)
		val lowlevelTransitionAction = lowlevelTransition.action
		return createSequentialAction => [
			it.actions += lowlevelTransition.createRecursiveXStsOrthogonalRegionAndTransitionParentExitActionsWithOrthogonality
			if (lowlevelTransitionAction !== null) {
				it.actions += lowlevelTransitionAction.transformAction
			}
			it.actions += lowlevelTransition.createRecursiveXStsTransitionEntryActionsWithOrthogonality
		]
	}
	
	protected def dispatch createRecursiveXStsForwardNodeConnection(ForkState lowlevelFork,
			Transition lowlevelTransition, State lowlevelTarget) {
		checkArgument(lowlevelTransition.source == lowlevelFork && lowlevelTransition.target == lowlevelTarget)
		val lowlevelTransitionAction = lowlevelTransition.action
		return createSequentialAction => [
			it.actions += lowlevelTransition.createRecursiveXStsTransitionParentExitActions
			if (lowlevelTransitionAction !== null) {
				it.actions += lowlevelTransitionAction.transformAction
			}
			it.actions += lowlevelTransition.createRecursiveXStsTransitionEntryActions(false)
		]
		// The activation of the unentered regions still need to be activated by the caller
	}
	
	protected def dispatch createRecursiveXStsForwardNodeConnection(ChoiceState lowlevelChoice, 
			Transition lowlevelTransition, PseudoState lowlevelTarget) {
		checkArgument(lowlevelTransition.source == lowlevelChoice &&
			lowlevelTransition.target == lowlevelTarget && lowlevelTarget.incomingTransitions.size == 1)
		val lowlevelTransitionAction = lowlevelTransition.action
		return lowlevelTarget.transformForward => [
			it.actions.addAll(0, lowlevelTransition.createRecursiveXStsOrthogonalRegionAndTransitionParentExitActionsWithOrthogonality)
			if (lowlevelTransitionAction !== null) {
				it.actions.add(0, lowlevelTransitionAction.transformAction)
			}
			it.actions.addAll(0, lowlevelTransition.createRecursiveXStsOrthogonalRegionAndTransitionParentEntryActionsWithOrthogonality)
		]
	}
		
	protected def dispatch createRecursiveXStsForwardNodeConnection(ForkState lowlevelFork, 
			Transition lowlevelTransition, PseudoState lowlevelTarget) {
		checkArgument(lowlevelTransition.source == lowlevelFork &&
			lowlevelTransition.target == lowlevelTarget && lowlevelTarget.incomingTransitions.size == 1)
		val lowlevelTransitionAction = lowlevelTransition.action
		return lowlevelTarget.transformForward => [
			it.actions.addAll(0, lowlevelTransition.createRecursiveXStsTransitionParentExitActions)
			if (lowlevelTransitionAction !== null) {
				it.actions.add(0, lowlevelTransitionAction.transformAction)
			}
			it.actions.addAll(0, lowlevelTransition.createRecursiveXStsTransitionParentEntryActions)
		]
	}
	
	// Fork auxiliary
	
	protected def getTargetAncestor(ForkState lowlevelForkState) {
		var State lowlevelTargetAncestor
		for (lowlevelOutgoingTransition : lowlevelForkState.outgoingTransitions) {
			val lowlevelTargetAncestorCandidate = lowlevelOutgoingTransition.targetAncestor
			lowlevelTargetAncestor = if (lowlevelTargetAncestor === null || (lowlevelTargetAncestorCandidate !== null &&
					lowlevelTargetAncestor.parentRegionsRecursively.contains(lowlevelTargetAncestorCandidate.parentRegion))) {
				lowlevelTargetAncestorCandidate
			}
		}
		return lowlevelTargetAncestor
	}
	
	protected def Set<Region> getRecursiveLowlevelActivatedRegions(ForkState lowlevelForkState) {
		val enteredLowlevelRegions = newHashSet
		for (lowlevelOutgoingTransition : lowlevelForkState.outgoingTransitions) {
			enteredLowlevelRegions += lowlevelOutgoingTransition.getRecursiveLowlevelActivatedRegions
		}
		return enteredLowlevelRegions
	}
	
	protected def Set<Region> getRecursiveLowlevelActivatedRegions(Transition lowlevelTransition) {
		val lowlevelTargetAncestor = lowlevelTransition.targetAncestor  // Checking activated parent regions until this state
		val activatedLowlevelRegions = newHashSet
		val lowlevelSource = lowlevelTransition.source
		val lowlevelTarget = lowlevelTransition.target
		if (lowlevelTarget instanceof State) {
			val deactivatedLowlevelRegionFraction = lowlevelTarget.getParentRegionsRecursively(lowlevelTargetAncestor)
			deactivatedLowlevelRegionFraction += lowlevelTarget.getSubregionsRecursively
			activatedLowlevelRegions += deactivatedLowlevelRegionFraction
		}
		else if (lowlevelTarget instanceof ForkState) {
			// Important to denote the parent region of the junction activated
			activatedLowlevelRegions += lowlevelSource.parentRegion
			// Recursion through Junctions
			activatedLowlevelRegions += lowlevelTarget.getRecursiveLowlevelActivatedRegions
		}
		else if (lowlevelTarget instanceof ChoiceState) {
			val lowlevelOutgoingTransitions = lowlevelTarget.outgoingTransitions
			val firstOutgoingLowlevelTransition = lowlevelOutgoingTransitions.head
			val lowlevelParentRegion = firstOutgoingLowlevelTransition.target.parentRegion
			if (lowlevelOutgoingTransitions.map[it.target]
					.forall[it instanceof State && it.parentRegion == lowlevelParentRegion]) {
				// All branches are targeted to the same region
				activatedLowlevelRegions += lowlevelParentRegion
			}
			else if (lowlevelOutgoingTransitions.map[it.target]
					.forall[it instanceof ForkState]) {
				for (outgoingLowlevelTransition : lowlevelOutgoingTransitions) {
					activatedLowlevelRegions += outgoingLowlevelTransition.getRecursiveLowlevelActivatedRegions
				}
			}
			
		}
		return activatedLowlevelRegions
	}
	
	/** Basically a DFS. */
	protected def List<Action> createXStsUnenteredRegionEntryAction(State lowlevelState, Set<Region> enteredRegions) {
		val xStsRegionActivatingActions = <Action>newLinkedList
		for (lowlevelSubregion : lowlevelState.regions) {
			if (!enteredRegions.contains(lowlevelSubregion)) {
				xStsRegionActivatingActions += createSequentialAction => [
					// Region activations
					it.actions += lowlevelSubregion.createRecursiveXStsRegionAndSubregionActivatingAction
					// State entries
					for (lowlevelSubstate : lowlevelSubregion.stateNodes.filter(State)) {
						it.actions += lowlevelSubstate.createRecursiveXStsStateAndSubstateEntryActions
					}
				]
			}
			else {
				// Recursion
				for (lowlevelCompositeSubstate : lowlevelSubregion.stateNodes.filter(State).filter[it.composite]) {
					xStsRegionActivatingActions += lowlevelCompositeSubstate.createXStsUnenteredRegionEntryAction(enteredRegions)
				}
			}
		}
		return xStsRegionActivatingActions
	}
	
}