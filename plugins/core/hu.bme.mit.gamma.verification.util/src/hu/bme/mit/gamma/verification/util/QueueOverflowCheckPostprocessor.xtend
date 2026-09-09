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

import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceQueueSizeReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.util.List

class QueueOverflowCheckPostprocessor extends VerificationPostprocessor {
	//
	protected final Component originalTopComponent
	//
	protected final List<ComponentInstanceQueueSizeReferenceExpression> queueSizeReferences = newArrayList
	//
	
	new(Component originalTopComponent) {
		this.originalTopComponent = originalTopComponent
	}
	
	override execute(Result result) {
		val res = result.result
		
		var ComponentInstanceQueueSizeReferenceExpression reference = null
		if (res == ThreeStateBoolean.FALSE) {
			// Knowing the structure of the property
			val property = result.property
			reference = property.selectQueueSizeReference
			
			val originalReference = reference.getOriginal(originalTopComponent)
			
			queueSizeReferences += originalReference
		}
		
		return reference
	}
	
	override execute(ExecutionTrace trace) {
		return null // Nothing to process at this point
	}
	
	//
	
	protected def selectQueueSizeReference(StateFormula property) {
		val references = property.selectQueueSizeReferences
		val reference = references.head
		
		return reference
	}
	
	protected def selectQueueSizeReferences(StateFormula property) {
		val references = property.getAllContentsOfType(ComponentInstanceQueueSizeReferenceExpression)
		return references
	}
	
	//
	
	def getQueueSizeReferences() {
		return queueSizeReferences
	}
	
}