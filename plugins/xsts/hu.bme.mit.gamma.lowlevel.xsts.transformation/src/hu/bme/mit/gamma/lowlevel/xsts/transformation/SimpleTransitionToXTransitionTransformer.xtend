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

import hu.bme.mit.gamma.statechart.lowlevel.model.EntryState
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.statechart.lowlevel.model.Transition
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*

class SimpleTransitionToXTransitionTransformer extends LowlevelTransitionToXTransitionTransformer {

	new(ViatraQueryEngine engine, Trace trace) {
		super(engine, trace)
	}
	
	/**
	 * Transforms state targeted simple transitions.
	 */
	def transform(Transition lowlevelSimpleTransition) {
		checkArgument(lowlevelSimpleTransition.source instanceof State &&
			lowlevelSimpleTransition.target instanceof State)
		// Precondition
		val xStsPrecondition = lowlevelSimpleTransition.createXStsTransitionPrecondition
		// Postcondition
		// No NonDeterministicAction as the merge transition method will merge the actions of
		// the transitions of a single region into a NonDeterministicAction
		val xStsTransitionAction = createSequentialAction => [
			// Active source state and guard
			it.actions += xStsPrecondition.createAssumeAction
			// To higher characteristics
			it.actions += lowlevelSimpleTransition.createRecursiveXStsTransitionExitActionsWithOrthogonality
			it.actions += lowlevelSimpleTransition.action.transformAction
			// To lower characteristics
			it.actions += lowlevelSimpleTransition.createRecursiveXStsTransitionEntryActionsWithOrthogonality
		]
		val xStsTransition = xStsTransitionAction.createXStsTransition
		trace.put(lowlevelSimpleTransition, xStsTransition, xStsPrecondition)
		return xStsTransition
	}
	
	/**
	 * Transforms entry node targeted simple transitions.
	 */
	def transform(Transition lowlevelSimpleTransition, State lowlevelTargetAncestor) {
		checkArgument(lowlevelSimpleTransition.isToLowerNode ||
				lowlevelSimpleTransition.isToHigherAndLowerNode)
		checkArgument(lowlevelSimpleTransition.source instanceof State)
		val lowlevelTarget = lowlevelSimpleTransition.target as EntryState
		val lowlevelTargetParentState = lowlevelTarget.parentState
		// Precondition
		val xStsPrecondition = lowlevelSimpleTransition.createXStsTransitionPrecondition
		// Postcondition
		val xStsTransitionAction = createSequentialAction => [
			// Active source state and guard
			it.actions += xStsPrecondition.createAssumeAction
			// To higher characteristics
			it.actions += lowlevelSimpleTransition.createRecursiveXStsTransitionExitActionsWithOrthogonality
			it.actions += lowlevelSimpleTransition.action.transformAction
			// To lower characteristics
			it.actions += lowlevelTarget.createRecursiveXStsStateAndSubstateActivatingActionWithOrthogonality // Note: must be before state entry actions
			it.actions += lowlevelTarget.createRecursiveXStsParentStateActivatingActionWithOrthogonality(lowlevelTargetAncestor) // Note: must be before state entry actions
			// Note: can NOT call createXStsTransitionEntryActions because of lowlevelTargetParentState
			it.actions += lowlevelTargetParentState.createRecursiveXStsParentStateEntryActionsWithOrthogonality(lowlevelTargetAncestor)
			it.actions += lowlevelTargetParentState.createRecursiveXStsStateAndSubstateEntryActionsWithOrthogonality
		]
		val xStsTransition = xStsTransitionAction.createXStsTransition
		trace.put(lowlevelSimpleTransition, xStsTransition, xStsPrecondition)
		return xStsTransition
	}
	
}