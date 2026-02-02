/********************************************************************************
 * Copyright (c) 2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.transformation.util.UnfoldingTraceability
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

abstract class StateCheckPostprocessor extends VerificationPostprocessor {
	//
	protected final Component originalTopComponent
	//
	protected final List<ComponentInstanceStateReferenceExpression> states = newArrayList
	//
	protected final extension UnfoldingTraceability traceability = UnfoldingTraceability.INSTANCE
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
			state = property.selectState
			
			val originalState = state.original
			
			states += originalState
		}
		
		return state
	}
	
	override execute(ExecutionTrace trace) {
		return null // Nothing to process at this point
	}
	
	//
	
	protected def selectState(StateFormula property) {
		val states = property.getAllContentsOfType(ComponentInstanceStateReferenceExpression)
		val state = states.head // Could be the second one, too
		
		return state
	}
	
	protected def getOriginal(ComponentInstanceStateReferenceExpression reference) {
		val instance = reference.instance
		val lastInstance = instance.lastInstance as SynchronousComponentInstance
		val state = reference.state
		
		val originalInstance = lastInstance.getOriginalSimpleInstanceReference(originalTopComponent)
		val originalState = originalInstance.getOriginalState(state)
		
		val stateReference = originalInstance.createStateReference(originalState)
		
		return stateReference
	}
	
	//
	
	def getStates() {
		return states
	}
	
}