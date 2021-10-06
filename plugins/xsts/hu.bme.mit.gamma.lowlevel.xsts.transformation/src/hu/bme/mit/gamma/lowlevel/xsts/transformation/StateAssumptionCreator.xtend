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
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.statechart.lowlevel.model.State

import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*

class StateAssumptionCreator {
	// Model factories
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
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
	protected def Expression createRecursiveXStsStateAssumption(State lowlevelState) {
		val xStsActualStateAssumption = lowlevelState.createSingleXStsStateAssumption
		if (lowlevelState.parentRegion.topRegion) {
			return xStsActualStateAssumption
		}
		// Not a top region state, the parents need to be addressed too
		val lowlevelParentState = lowlevelState.parentState
		val xStsParentStateAssumptions = lowlevelParentState.createRecursiveXStsStateAssumption
		val xStsCompositeStateAssumption = createAndExpression => [
			it.operands += xStsParentStateAssumptions
			it.operands += xStsActualStateAssumption
		]
		return xStsCompositeStateAssumption
	}
	
}