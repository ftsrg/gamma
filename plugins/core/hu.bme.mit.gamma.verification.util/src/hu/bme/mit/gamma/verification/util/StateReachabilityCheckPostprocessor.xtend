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

import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import java.util.Collection

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class StateReachabilityCheckPostprocessor extends VerificationPostprocessor {
	//
	protected final Collection<ComponentInstanceStateReferenceExpression> reachedStates = newArrayList
	//
	
	override execute(ExecutionTrace trace) {
		trace.saveTrace
		
		val steps = trace.steps
		for (step : steps) {
			val states = step.instanceStateConfigurations
			for (state : states) {
				if (!state.contained) {
					reachedStates += state
				}
			}
		}
		
		return reachedStates
	}
	
	//
	
	protected def isContained(ComponentInstanceStateReferenceExpression state) {
		val names = reachedStates.map[it.id] // Could be cached
		return names.contains(state.id)
	}
	
	def getId(ComponentInstanceStateReferenceExpression state) {
		return state.instance.name + "." + state.state.fullContainmentHierarchy
	}
	
	//
	
	def getReachedStates() {
		return reachedStates
	}
	
}