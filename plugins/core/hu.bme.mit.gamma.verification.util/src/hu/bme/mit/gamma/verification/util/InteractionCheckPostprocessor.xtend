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

import hu.bme.mit.gamma.expression.model.OpaqueExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.transformation.util.UnfoldedExecutionTraceBackAnnotator
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.Map.Entry
import java.util.regex.Pattern
import org.eclipse.xtend.lib.annotations.Data

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class InteractionCheckPostprocessor extends VerificationPostprocessor {
	//
	protected final List<
			Collection<? extends Interaction>> interactions = newArrayList
	//
	
	override execute(ExecutionTrace trace) {
		trace.saveTrace
		val component = trace.component
		
		val interactions = <Interaction>newArrayList
		
		val SEND_START = UnfoldedExecutionTraceBackAnnotator.INTERACTION_SENDING_BEGINNING
		val RECEIVE_START = UnfoldedExecutionTraceBackAnnotator.INTERACTION_RECEIVING_BEGINNING
		
		val steps = trace.allSteps
		for (step : steps) {
			var Entry<ComponentInstanceReferenceExpression, ? extends Object> sender = null
			var Entry<ComponentInstanceReferenceExpression, Transition> receiver = null
			
			val asserts = step.asserts
			val metadata = asserts.filter(OpaqueExpression)
			for (_metadata : metadata) {
				val string = _metadata.expression
				if (string.startsWith(SEND_START)) {
					// Sender may be a 'transition'
					sender = string.matchTransition(SEND_START, component)
					if (sender === null) {
						// Sender may be a 'state'
						sender = string.matchState(SEND_START, component)
					}
					if (sender === null) {
						throw new IllegalArgumentException("Not found pattern: " + string)
					}
				}
				else if (string.startsWith(RECEIVE_START)) {
					// Sender must be a 'transition'
					receiver = string.matchTransition(RECEIVE_START, component)
					if (receiver === null) {
						throw new IllegalArgumentException("Not found pattern: " + string)
					}
				}
			}
			
			if (sender !== null && receiver !== null) {
				val interaction = new Interaction(
					sender.key, sender.value, receiver.key, receiver.value)
				interactions += interaction
			}
		}
		
		this.interactions += interactions
		
		return interactions
	}
	
	protected def matchState(String string, String prefix, Component component) {
		val statechartInstances = component.allSimpleInstanceReferences
		
		val statePattern = Pattern.compile('''«prefix»state (.*) region (.*) of (.*)''')
		val stateMatcher = statePattern.matcher(string)
		if (stateMatcher.find) {
			// Sender is a 'state'
			val stateName = stateMatcher.group(1).trim
			val regionName = stateMatcher.group(2).trim
			val instanceName = stateMatcher.group(3).trim
			
			val instance = statechartInstances.findFirst[it.name == instanceName]
			val statechart = instance.lastInstance.getStatechart
			val state = statechart.allStates.findFirst[it.name == stateName &&
					it.parentRegion.name == regionName]
					
			return Map.entry(instance, state)
		}
		
		return null
	}
	
	protected def matchTransition(String string, String prefix, Component component) {
		val statechartInstances = component.allSimpleInstanceReferences
		
		val transitionPattern = Pattern.compile('''«prefix»(.*) of (.*)''')
		val transtionMatcher = transitionPattern.matcher(string)
		if (transtionMatcher.find) {
			// Sender is a 'transition'
			val transitionString = transtionMatcher.group(1).trim
			val instanceName = transtionMatcher.group(2).trim
			
			val instance = statechartInstances.findFirst[it.name == instanceName]
			val statechart = instance.lastInstance.getStatechart
			val transition = statechart.transitions.findFirst[it.serialize == transitionString]
					
			return Map.entry(instance, transition)
		}
		
		return null
	}
	
	//
	
	def getInteractions() {
		return interactions
	}
	
	def getAllInteractions() {
		return interactions.flatten.toList
	}
	
	//
	
	@Data
	static class Interaction {
		ComponentInstanceReferenceExpression senderInstance
		Object sender
		ComponentInstanceReferenceExpression receiverInstance
		Transition receiver
	}
	
}