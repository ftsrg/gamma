/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.ComparisonExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.statechart.lowlevel.model.JoinState
import hu.bme.mit.gamma.statechart.lowlevel.model.MergeState
import hu.bme.mit.gamma.statechart.lowlevel.model.SchedulingOrder
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.statechart.lowlevel.model.Transition
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.transformation.util.VariableGroupRetriever
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import java.util.List
import java.util.Map

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*

class TransitionPreconditionCreator {

	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	// Model factories
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Auxiliary object
	protected final extension StateAssumptionCreator stateAssumptionCreator
	protected final extension ExpressionTransformer expressionTransformer
	
	protected final Trace trace
	protected final boolean addConflictGuard
	protected final boolean addPriorityGuard
	
	new(Trace trace) {
		this(trace, false, false)
	}
	
	new(Trace trace, boolean addConflictGuard, boolean addPriorityGuard) {
		this.trace = trace
		this.addConflictGuard = addConflictGuard
		this.addPriorityGuard = addPriorityGuard
		this.stateAssumptionCreator = new StateAssumptionCreator(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace)
	}
	
	/**
	 * Creates the precondition of an xSTS transition based on the low-level transition.
	 */
	def createXStsTransitionPrecondition(Transition lowlevelTransition) {
		val lowlevelSource = lowlevelTransition.source
		checkArgument(lowlevelSource instanceof State)
		val order = lowlevelTransition.statechart.schedulingOrder
		checkArgument(order == SchedulingOrder.TOP_DOWN || order == SchedulingOrder.BOTTOM_UP)
		
		val lowlevelPotentialConflictingTransitions =
		// Bottom-up or top down scheduling
		if (order == SchedulingOrder.BOTTOM_UP) {
			// Not that join transitions CANNOT leave states that are ancestors of each other
			// Such a model could cause trouble here, think of the join semantics
			lowlevelTransition.descendantTransitions
		}
		else {
			lowlevelTransition.ancestorTransitions 
			
		}
		
		val lowlevelHigherPriorityTransitions = lowlevelTransition.higherPriorityTransitions
		val xStsPriorityExpression = (addPriorityGuard) ?
				lowlevelHigherPriorityTransitions.createXStsTransitionConflictExclusion : null
		
		val xStsConflictExpression = (addConflictGuard) ?
				lowlevelPotentialConflictingTransitions.createXStsTransitionConflictExclusion : null
		
		val xStsEnablednessExpression = lowlevelTransition.isEnabledExpression
		// Caching: only the activeness must be cached if we want the guard evaluation to be flexible
		trace.getPrimaryIsActiveExpressions += xStsEnablednessExpression.operands.head // isActive is the first operand
		//
		
		val xStsPreconditionExpression = createAndExpression => [
			it.operands += xStsEnablednessExpression // Source state enabledness
			if (addPriorityGuard) {
				it.operands += xStsPriorityExpression // Priority resolution
			}
			if (addConflictGuard) {
				it.operands += xStsConflictExpression // Potential conflict resolution
			}
		]
		
		val xStsOperands = xStsPreconditionExpression.operands
		xStsOperands.removeIf[it instanceof TrueExpression]
		
		if (!xStsOperands.empty) {
			return xStsPreconditionExpression
		}
		return createTrueExpression
	}
	
	/**
	 * Creates an expression which is true iff NONE of the given lowlevel transition is enabled. 
	 */
	def createXStsTransitionConflictExclusion(Collection<Transition> lowlevelTransitions) {
		return lowlevelTransitions.map[it.isEnabledExpression]
				.connectViaNegations
	}
	
	// Dispatch isActive (source elements are active and guard is true) expression
	
	private def getIsEnabledExpression(Transition lowlevelTransition) {
		val andExpression = createAndExpression
		val xStsOperands = andExpression.operands
		// IsActive
		val lowlevelSourceNode = lowlevelTransition.source
		if (lowlevelSourceNode instanceof State) { // Theoretically constant true
			// e.g., local var a := region == Region.A
			// e.g., local var b := region == Region.A (extractable) && region2 == Region.B
			// Now only a single state assumption is here due to the introduction of history literals
			val singleXStsStateAssumption = lowlevelSourceNode.createSingleXStsStateAssumption
			// Caching
			trace.add(trace.getIsActiveExpressions,
				lowlevelTransition, singleXStsStateAssumption)
			//
			xStsOperands += singleXStsStateAssumption
		}
		// Guard
		val xStsGuardExpression = lowlevelTransition.getGuardExpression(trace.getGuards)
		if (xStsGuardExpression !== null) {
			xStsOperands += xStsGuardExpression
		}
		//
		checkArgument(!xStsOperands.empty)
		return andExpression
	}
	
	protected def getGuardExpression(Transition lowlevelTransition,
			Map<Transition, List<Expression>> cache /* So state and choice guards can be distinguished */) {
		val xSts = trace.XSts
		val guard = lowlevelTransition.guard
		if (guard !== null) {
			val xStsGuard = guard.transformExpression
			// Caching
			trace.add(cache, lowlevelTransition, xStsGuard)
			// Tracing timeout references
			val xStsTimeoutVariables = xSts.timeoutGroup.variables
			val timeoutReferences = xStsGuard.getSelfAndAllContentsOfType(DirectReferenceExpression)
					.filter[xStsTimeoutVariables.contains(it.declaration)].toList
			if (!timeoutReferences.empty) {
				val timeoutExpressions = timeoutReferences.map[it.getContainerOfType(ComparisonExpression)]
				trace.addTimeoutExpression(timeoutExpressions)
			}
			//
			
			return xStsGuard
		}
		return null
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
		throw new IllegalArgumentException("Merge states are not supported: " + lowlevelMergeState)
	}
	
}