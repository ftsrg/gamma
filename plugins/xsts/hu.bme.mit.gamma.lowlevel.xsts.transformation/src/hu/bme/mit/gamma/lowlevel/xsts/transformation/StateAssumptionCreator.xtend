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
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*

class StateAssumptionCreator {
	// Model factories
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected final extension XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	// Trace needed for variable references
	protected final Trace trace
		
	new(Trace trace) {
		this.trace = trace
	}
	
	/**
	 * Based on the given low-level state (and implicitly its parent region), an equality expression is created
	 * defining that the xSTS parent region variable is set to the xSTS enum literal associated to the given low-level state,
	 * e.g., main_region (region variable) == Init (state enum literal).
	 */
	protected def createSingleXStsStateAssumption(State lowlevelState) {
		val lowlevelRegion = lowlevelState.parentRegion
		val xStsParentRegionVariable = trace.getXStsVariable(lowlevelRegion)
		val xStsEnumLiteral = trace.getXStsEnumLiteral(lowlevelState)
		val xStsStateReference = xStsParentRegionVariable.createEqualityExpression(
				xStsEnumLiteral.createEnumerationLiteralExpression)
		// Caching
		trace.add(trace.getStateReferenceExpressions, lowlevelState, xStsStateReference)
		//
		return xStsStateReference
	}
	
	/**
	 * Based on the given low-level state (and implicitly its parent region), an equality expression is created
	 * defining that the xSTS parent region variable is set to the xSTS enum literal associated to the given low-level state,
	 * and recursively all parent region variables are set to the corresponding parent state, e.g., main_region (region variable)
	 * == Init (state enum literal) && subregion (region variable) == SubregionInit (state enum literal).
	 */
//	protected def Expression createRecursiveXStsStateAssumption(State lowlevelState) {
//		val xStsActualStateAssumption = lowlevelState.createSingleXStsStateAssumption
//		if (lowlevelState.parentRegion.topRegion) {
//			return xStsActualStateAssumption
//		}
//		// Not a top region state, the parents need to be addressed too
//		val lowlevelParentState = lowlevelState.parentState
//		val xStsParentStateAssumptions = lowlevelParentState.createRecursiveXStsStateAssumption
//		val xStsCompositeStateAssumption = createAndExpression => [
//			it.operands += xStsParentStateAssumptions
//			it.operands += xStsActualStateAssumption
//		]
//		return xStsCompositeStateAssumption
//	}
	
	
	
	/// Inactive history enum literal related methods
	
	protected def createSingleXStsInactiveStateExpression(Region lowlevelRegion) { // Currently unused
		val xStsInactiveHistoryEnumLiterals = trace.getXStsInactiveHistoryEnumLiterals(lowlevelRegion)
		val xStsRegionVariable = trace.getXStsVariable(lowlevelRegion)
		
		val xStsInactivityPossibilities = newArrayList
		for (xStsInactiveHistoryEnumLiteral : xStsInactiveHistoryEnumLiterals) {
			xStsInactivityPossibilities += xStsRegionVariable.createEqualityExpression(
					xStsInactiveHistoryEnumLiteral.createEnumerationLiteralExpression)
		}
		
		return xStsInactivityPossibilities.wrapIntoOrExpression
	}
	
//	protected def createSingleXStsInactiveStateAction(Region lowlevelRegion) {
//		val xStsParentRegionVariable = trace.getXStsVariable(lowlevelRegion)
//		val xStsExpression = lowlevelRegion.createSingleXStsInactiveActiveStateExpression
//		
//		return xStsParentRegionVariable.createAssignmentAction(xStsExpression)
//	}
	
	protected def createSingleXStsInactiveHistoryStateAssumption(State lowlevelState) {
		val lowlevelRegion = lowlevelState.parentRegion
		val xStsParentRegionVariable = trace.getXStsVariable(lowlevelRegion)
		val xStsEnumLiteral = trace.getXStsInactiveHistoryEnumLiteral(lowlevelState)
		val xStsStateReference = xStsParentRegionVariable.createEqualityExpression(
				xStsEnumLiteral.createEnumerationLiteralExpression)
				
		return xStsStateReference
	}
	
	// Activation
	protected def createSingleXStsInactiveActiveStateExpression(Region lowlevelRegion) {
		val ifThenElses = newArrayList
		val lowlevelStates = lowlevelRegion.states
		for (lowlevelState : lowlevelStates) {
			val singleXStsInactiveHistoryStateAssumption = lowlevelState.createSingleXStsInactiveHistoryStateAssumption
			val singleXStsStateLiteral = trace.getXStsEnumLiteral(lowlevelState)
					.createEnumerationLiteralExpression
			ifThenElses += singleXStsInactiveHistoryStateAssumption.createIfThenElseExpression(
					singleXStsStateLiteral, null)
		}
		// Else: _Inactive_ - if everything else is set correctly, this code is not necessary
//		val last = ifThenElses.last
//		if (last !== null) {
//			last.^else = trace.getXStsInactiveEnumLiteral(lowlevelRegion)
//					.createEnumerationLiteralExpression
//		}
		
		return ifThenElses.weave
	}
	
	protected def createSingleXStsInactiveActiveStateAction(Region lowlevelRegion) {
		val xStsParentRegionVariable = trace.getXStsVariable(lowlevelRegion)
		val xStsExpression = lowlevelRegion.createSingleXStsInactiveActiveStateExpression
		
		return xStsParentRegionVariable.createAssignmentAction(xStsExpression)
	}
	
	// Deactivation
	protected def createSingleXStsActiveInactiveStateExpression(Region lowlevelRegion) {
		val ifThenElses = newArrayList
		val lowlevelStates = lowlevelRegion.states
		for (lowlevelState : lowlevelStates) {
			val singleXStsStateAssumption = lowlevelState.createSingleXStsStateAssumption
			val singleXStsInactiveStateLiteral = trace.getXStsInactiveHistoryEnumLiteral(lowlevelState)
					.createEnumerationLiteralExpression
			ifThenElses += singleXStsStateAssumption.createIfThenElseExpression(
					singleXStsInactiveStateLiteral, null)
		}
		// Else: _Inactive_ - if everything else is set correctly, this code is not necessary
//		val last = ifThenElses.last
//		if (last !== null) {
//			last.^else = trace.getXStsInactiveEnumLiteral(lowlevelRegion)
//					.createEnumerationLiteralExpression
//		}
		return ifThenElses.weave
	}
	
	protected def createSingleXStsActiveInactiveStateAction(Region lowlevelRegion) {
		val xStsParentRegionVariable = trace.getXStsVariable(lowlevelRegion)
		val xStsExpression = lowlevelRegion.createSingleXStsActiveInactiveStateExpression
		
		return xStsParentRegionVariable.createAssignmentAction(xStsExpression)
	}
	
	///
	
	def createRegionAction() {
		val lowlevelStatechart = trace.statechart
		val orthogonalRegionSchedulingOrder = lowlevelStatechart.orthogonalRegionSchedulingOrder
		switch (orthogonalRegionSchedulingOrder) {
			case SEQUENTIAL: {
				return createSequentialAction
			}
			case UNORDERED: {
				return createUnorderedAction
			}
			case PARALLEL: {
				return createParallelAction
			}
			default: {
				throw new IllegalArgumentException("Not known region scheduling order: " +
						orthogonalRegionSchedulingOrder)
			}
		}
	}
	
}