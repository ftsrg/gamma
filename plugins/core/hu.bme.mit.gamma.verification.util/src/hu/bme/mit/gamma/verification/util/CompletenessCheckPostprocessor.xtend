/********************************************************************************
 * Copyright (c) 2025-2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class CompletenessCheckPostprocessor extends StateCheckPostprocessor {
	//
	protected final List<PortEventReference> portEvents = newArrayList
	//
	
	new(Component originalTopComponent) {
		super(originalTopComponent)
	}
	
	override execute(Result result) {
		val res = result.result
		
		var ComponentInstanceStateReferenceExpression state = null
		var PortEventReference portEvent = null
		if (res == ThreeStateBoolean.TRUE) {
			// Knowing the structure of the property
			val property = result.property
			val stateAndEvent = property.selectStateAndEvent
			
			state = stateAndEvent.key
			val originalState = state.getOriginal(originalTopComponent)
			states += originalState
			
			portEvent = stateAndEvent.value
			portEvents += portEvent
		}
		
		return state
	}
	
	protected def selectStateAndEvent(StateFormula property) {  // G (state a -> G(!outoing_transition1_id && ...))
		val variableInstance = property.getFirstOfAllContentsOfType(ComponentInstanceVariableReferenceExpression)
		val instance = variableInstance.instance.clone
		val variable = variableInstance.variableDeclaration
		
		val statechart = variable.containingStatechart
		val transition = statechart.transitions.findFirst[
				it.effects.filter(AssignmentStatement).exists[it.lhs.declaration === variable]]
		val state = transition.sourceState as State
		val eventTrigger = transition.trigger as EventTrigger
		val portEvent = eventTrigger.eventReference.clone as PortEventReference
		
		return instance.createStateReference(state) -> portEvent
	}
	
	//
	
	def getUnhandledEvents() {
		val unhandledEvents = newLinkedHashMap
		
		for (var i = 0; i < states.size; i++) {
			val state = states.get(i)
			val portEvent = portEvents.get(i)
			
			unhandledEvents += state -> portEvent
		}
		
		return unhandledEvents
	}
	
}