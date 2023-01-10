/********************************************************************************
 * Copyright (c) 2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Statecharts
import hu.bme.mit.gamma.statechart.lowlevel.model.ChoiceState
import hu.bme.mit.gamma.statechart.lowlevel.model.CompositeElement
import hu.bme.mit.gamma.statechart.lowlevel.model.ForkState
import hu.bme.mit.gamma.statechart.lowlevel.model.GuardEvaluation
import hu.bme.mit.gamma.statechart.lowlevel.model.JoinState
import hu.bme.mit.gamma.statechart.lowlevel.model.MergeState
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.XTransition
import java.util.List
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*

class FlatTransitionMerger extends AbstractTransitionMerger {
	
	new(ViatraQueryEngine engine, Trace trace) {
		// Relies on conflict and priority encoding of TransitionPreconditionCreator
		// Right now, this is not yet set in the LowevelToXstsTransformer
		super(engine, trace)
	}
	
	override mergeTransitions() {
		val statecharts = Statecharts.Matcher.on(engine).allValuesOfstatechart
		checkState(statecharts.size == 1)
		val statechart = statecharts.head
		
		val xTransitions = statechart.XTransitions
		
		val primaryIsActiveExpressions = trace.getPrimaryIsActiveExpressions
		for (primaryIsActiveExpression : primaryIsActiveExpressions) {
			// Cloning: transitions can fire only if the source state configuration is not left!
			primaryIsActiveExpression.cloneIntoMultiaryExpression(createAndExpression)
			// The following lines extract the isActive expressions, so one must stay here
		}
		val isActiveExpressions = trace.getIsActiveExpressions
		val extractedIsActiveVariableActions = trace.extractExpressions(isActiveExpressions)
		// Extracting state references from the isActive expressions (if have not been extracted already)
		val stateReferenceExpressions = trace.getStateReferenceExpressions
		trace.keepExpressionsTransitivelyContainedBy(stateReferenceExpressions,
			extractedIsActiveVariableActions.map[it.variableDeclaration.expression])
		val extractedStateReferenceVariableActions = trace.extractExpressions(stateReferenceExpressions, true) // Might be empty
		
		// Order is important
		val extractedExpressions = newArrayList
		extractedExpressions += extractedStateReferenceVariableActions
		extractedExpressions += extractedIsActiveVariableActions
		
		// If we want to follow UML semantics, transition guard extraction is needed too (choice guards are not stored here)
		if (statechart.guardEvaluation == GuardEvaluation.BEGINNING_OF_STEP) {
			val xStsGuards = trace.getGuards
			extractedExpressions += trace.extractExpressions(xStsGuards)
		}
		
		// Handle here if we want BEGINNING_OF_STEP semantics in the case of choice guards too
		
		val xTransitionActions = <Action>newArrayList
		for (xTransition : xTransitions) {
			val xStsAction = xTransition.action
			val xStsSequentialAction = xStsAction as SequentialAction
			xTransitionActions += xStsSequentialAction.createIfAction
		}
		
		val xStsMergedAction = createSequentialAction => [
			it.actions += extractedExpressions
			it.actions += xTransitionActions
		]
		
		// Deleting single cross-reference local variables
		// Must be used after inserting the actions into a container due to the "change" call
		// This reduction cannot be used in general, as it would incorrect due to potential variable value changes
		extractedIsActiveVariableActions.map[it.variableDeclaration]
				.reduceCrossReferenceChain(xStsMergedAction)
		// No deletion here as later reduction will delete unreferenced variable actions
		
		xSts.changeTransitions(xStsMergedAction.wrap)
	}
	
	private def List<XTransition> getXTransitions(CompositeElement composite) {
		val xStsTransitions = newArrayList
		// According to semantics, we execute actions in the order of the regions
		for (lowlevelRegion : composite.regions) {
			val lowlevelStates = lowlevelRegion.stateNodes.filter(State)
			// Simple outgoing transitions
			for (lowlevelState : lowlevelStates) {
				for (lowlevelOutgoingTransition : lowlevelState.outgoingTransitions
						.filter[trace.isTraced(it)] /* Simple transitions */ ) {
					xStsTransitions += trace.getXStsTransition(lowlevelOutgoingTransition)
				}
				if (lowlevelState.isComposite) {
					// Recursion
					xStsTransitions += lowlevelState.XTransitions
				}
			}
			// Complex transitions
			for (lastJoinState : lowlevelRegion.stateNodes.filter(JoinState).filter[it.isLastJoinState]) {
				xStsTransitions += trace.getXStsTransition(lastJoinState)
			}
			for (lastMergeState : lowlevelRegion.stateNodes.filter(MergeState).filter[it.isLastMergeState]) {
				xStsTransitions += trace.getXStsTransition(lastMergeState)
			}
			for (lastForkState : lowlevelRegion.stateNodes.filter(ForkState).filter[it.isFirstForkState]) {
				xStsTransitions += trace.getXStsTransition(lastForkState)
			}
			for (lastChoiceState : lowlevelRegion.stateNodes.filter(ChoiceState).filter[it.isFirstChoiceState]) {
				xStsTransitions += trace.getXStsTransition(lastChoiceState)
			}
		}
		return xStsTransitions // No cloning due to the cached isActive and guard expressions
	}
	
}