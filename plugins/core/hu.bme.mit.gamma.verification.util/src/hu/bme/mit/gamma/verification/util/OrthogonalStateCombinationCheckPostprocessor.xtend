/********************************************************************************
 * Copyright (c) 2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.util.Collection
import java.util.List

abstract class OrthogonalStateCombinationCheckPostprocessor extends VerificationPostprocessor {
	//
	protected final Component originalTopComponent
	//
	protected final List<Collection<? extends ComponentInstanceStateReferenceExpression>> stateCombinations = newArrayList
	//
	
	new(Component originalTopComponent) {
		this.originalTopComponent = originalTopComponent
	}
	
	override execute(Result result) {
		val res = result.result
		
		var ComponentInstanceStateReferenceExpression state = null
		if (res == ThreeStateBoolean.TRUE) {
			// Knowing the structure of the property
			val property = result.property
			val states = property.selectStates
			
			val originalStates = states.map[it.getOriginal(originalTopComponent)]
			
			states += originalStates
		}
		
		return state
	}
	
	override execute(ExecutionTrace trace) {
		return null // Nothing to process at this point
	}
	
	//
	
	def getOrthogonalStateCombinations() {
		return stateCombinations
	}
	
}