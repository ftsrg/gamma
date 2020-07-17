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
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.statechart.lowlevel.model.JoinState
import hu.bme.mit.gamma.statechart.lowlevel.model.MergeState
import hu.bme.mit.gamma.statechart.lowlevel.model.PseudoState
import hu.bme.mit.gamma.statechart.lowlevel.model.SchedulingOrder
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.statechart.lowlevel.model.Transition
import java.util.Collection
import java.util.List

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*

class TransitionPreconditionCreator {
	// Model factories
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Auxiliary object
	protected final extension StateAssumptionCreator stateAssumptionCreator
	protected final extension ExpressionTransformer expressionTransformer
	// Trace
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
		this.stateAssumptionCreator = new StateAssumptionCreator(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace)
	}
	
	/**
	 * Creates the precondition of an xSTS transition based on the low-level transition.
	 */
	def createXStsTransitionPrecondition(Transition lowlevelTransition) {
		val lowlevelSource = lowlevelTransition.source
		val order = lowlevelTransition.statechart.schedulingOrder
		checkArgument(order == SchedulingOrder.TOP_DOWN || order == SchedulingOrder.BOTTOM_UP)
		var Expression xStsTransitionConflictExpression = createTrueExpression
		if (lowlevelSource instanceof State) {
			// Conflict makes sense only in case of state sources
			val Collection<Transition> lowlevelPotentialConflictingTransitions =
			// Bottom-up or top down scheduling
			if (order == SchedulingOrder.BOTTOM_UP) {
				lowlevelTransition.lowlevelChildTransitions
			}
			else {
				// Top-down scheduling
				lowlevelTransition.lowlevelParentTransitions
			}
			xStsTransitionConflictExpression = lowlevelPotentialConflictingTransitions.createXStsTransitionConflictExclusion
		}
		val xStsTransitionActivenessExpression = lowlevelTransition.isActiveExpression
		val xStsTransitionPreconditionExpression = createAndExpression
		if (!(xStsTransitionConflictExpression instanceof TrueExpression)) {
			// True expression (if there are no parent transitions) is unnecessary in case of AndExpressions
			xStsTransitionPreconditionExpression.operands += xStsTransitionConflictExpression // Potential conflict resolution
		}
		if (!(xStsTransitionActivenessExpression instanceof TrueExpression)) {
			xStsTransitionPreconditionExpression.operands += xStsTransitionActivenessExpression // Source state activeness and Guard
		}
		if (xStsTransitionPreconditionExpression.operands.empty) {
			return createTrueExpression
		}
		else {
			return xStsTransitionPreconditionExpression
		}
	}
	
	/**
	 * Creates an expression which is true iff NONE of the given lowlevel transition is enabled. 
	 */
	private def createXStsTransitionConflictExclusion(Collection<Transition> lowlevelTransitions) {
		if (lowlevelTransitions.empty) {
			return createTrueExpression
		}
		return createAndExpression => [
			for (lowlevelTransition : lowlevelTransitions) {
				it.operands += createNotExpression => [
					it.operand = lowlevelTransition.isActiveExpression
				]
			}
		]
	}
	
	// Dispatch isActive (source elements are active and guard is true) expression
	
	private def getIsActiveExpression(Transition lowlevelTransition) {
		val andExpression = createAndExpression
		val lowlevelSourceNode = lowlevelTransition.source
		if (lowlevelSourceNode instanceof State) {
			andExpression.operands += lowlevelSourceNode.createRecursiveXStsStateAssumption
		}
		val guard = lowlevelTransition.guard
		if (guard !== null) {
			andExpression.operands += guard.transformExpression
		}
		if (andExpression.operands.empty) {
			return createTrueExpression
		}
		else {
			return andExpression
		}
	}
	
	// Precursory pseudo state preconditions
	
	def dispatch createSingleXStsTransitionPrecondition(JoinState lowlevelJoinState) {
		val lowlevelIncomingTransitions = lowlevelJoinState.incomingTransitions
		val andExpression = createAndExpression
		for (lowlevelIncomingTransition : lowlevelIncomingTransitions) {
			andExpression.operands += lowlevelIncomingTransition.createXStsTransitionPrecondition
		}
		andExpression.operands.removeIf[it instanceof TrueExpression]
		if (andExpression.operands.empty) {
			return createTrueExpression
		}
		return andExpression
	}
	
	def dispatch createSingleXStsTransitionPrecondition(MergeState lowlevelMergeState) {
		val lowlevelIncomingTransitions = lowlevelMergeState.incomingTransitions
		val orExpression = createOrExpression
		for (lowlevelIncomingTransition : lowlevelIncomingTransitions) {
			orExpression.operands += lowlevelIncomingTransition.createXStsTransitionPrecondition
		}
		return orExpression
	}
	
	//
	
	/**
	 * Returns the parent transitions of the given lowlevel transition, that is, the outgoing transitions of the
	 * ancestors of the source state of the given transition. 
	 */
	private def Collection<Transition> getLowlevelParentTransitions(Transition lowlevelTransition) {
		val lowlevelParentTransitions = newLinkedList
		lowlevelTransition.getLowlevelParentTransitions(lowlevelParentTransitions)
		return lowlevelParentTransitions
	}
	
	private def void getLowlevelParentTransitions(Transition lowlevelTransition,
			List<Transition> lowlevelParentTransitions) {
		val lowlevelSource = lowlevelTransition.source
		if (lowlevelSource.parentRegion.topRegion ||
				lowlevelSource instanceof PseudoState) {
			return
		}
		val lowlevelParentState = (lowlevelSource as State).parentState
		val untraversedOutgoingTransitions = newLinkedList
		untraversedOutgoingTransitions += lowlevelParentState.outgoingTransitions
		// Due to Merge/Join transitions where a source is the parent of another 
		untraversedOutgoingTransitions -= lowlevelParentTransitions
		for (lowlevelParentTransition : untraversedOutgoingTransitions) {
			lowlevelParentTransitions += lowlevelParentTransition
			lowlevelParentTransition.getLowlevelParentTransitions(lowlevelParentTransitions)
		}
	}
	
	/**
	 * Returns the child transitions of the given lowlevel transition, that is, the outgoing transitions of the
	 * descendants of the source state of the given transition. 
	 */
	private def Collection<Transition> getLowlevelChildTransitions(Transition lowlevelTransition) {
		val lowlevelChildTransitions = newLinkedList
		lowlevelTransition.getLowlevelChildTransitions(lowlevelChildTransitions)
		return lowlevelChildTransitions
	}
	
	private def void getLowlevelChildTransitions(Transition lowlevelTransition,
			List<Transition> lowlevelChildTransitions) {
		val lowlevelSource = lowlevelTransition.source
		if (lowlevelSource instanceof State) {
			if (!lowlevelSource.composite) {
				return
			}
			for (lowlevelChildRegion : lowlevelSource.regions) {
				for (lowlevelState : lowlevelChildRegion.stateNodes.filter(State)) {
					val untraversedOutgoingTransitions = newLinkedList
					untraversedOutgoingTransitions += lowlevelState.outgoingTransitions
					// Due to Merge/Join transitions where a source is the parent of another 
					untraversedOutgoingTransitions -= lowlevelChildTransitions
					for (lowlevelChildTransition : untraversedOutgoingTransitions) {
						lowlevelChildTransitions += lowlevelChildTransition
						lowlevelChildTransition.getLowlevelChildTransitions(lowlevelChildTransitions)
					}
				}
			}
		}
	}
	
}