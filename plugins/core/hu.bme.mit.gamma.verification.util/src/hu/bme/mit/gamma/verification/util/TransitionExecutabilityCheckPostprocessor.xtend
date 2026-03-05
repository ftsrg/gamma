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

import hu.bme.mit.gamma.expression.model.OpaqueExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.transformation.util.UnfoldedExecutionTraceBackAnnotator
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.Map.Entry
import java.util.regex.Pattern

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class TransitionExecutabilityCheckPostprocessor extends VerificationPostprocessor {
	//
	public static final String metadataBeginning = UnfoldedExecutionTraceBackAnnotator.EXECUTED_TRANSITION_MESSAGE_BEGINNING
	//
	protected final List<Collection<? extends
			Entry<ComponentInstanceReferenceExpression, Transition>>> executedTransitions = newArrayList
	//
	
	override execute(ExecutionTrace trace) {
		trace.saveTrace
		
		val executedTransitions = <Entry<ComponentInstanceReferenceExpression, Transition>>newArrayList
		
		val steps = trace.allSteps
		for (step : steps) {
			val asserts = step.asserts
			for (assertion : asserts.filter(OpaqueExpression)
						.filter[it.expression.startsWith(metadataBeginning)]) {
				val instanceTransition = trace.parseTransition(assertion)
				val instance = instanceTransition.key
				val transition = instanceTransition.value
				
				executedTransitions += instance.createTransitionReference(transition)
			}
		}
		
		this.executedTransitions += executedTransitions
		
		return executedTransitions
	}
	
	def parseTransition(ExecutionTrace trace, OpaqueExpression expression) {
		val string = expression.expression
		val pattern = Pattern.compile('''«metadataBeginning»(.*) of (.*)''')
		val matcher = pattern.matcher(string)
		if (!matcher.find) {
			throw new IllegalArgumentException("Not found pattern: " + string)
		}
		
		val instances = trace.steps.map[it.asserts].flatten
				.filter(ComponentInstanceElementReferenceExpression)
				.map[it.instance]
		
		val transitionString = matcher.group(1).trim
		val instanceName = matcher.group(2).trim
		
		val instance = instances.findFirst[it.name == instanceName].clone
		val statechart = instance.lastInstance.derivedType as StatechartDefinition
		val transition = statechart.transitions.findFirst[it.serialize == transitionString]
		
		return Map.entry(instance, transition)
	}
	
	//
	
	def getId(Entry<ComponentInstanceReferenceExpression, Transition> transitionInstance) {
		val instance = transitionInstance.key
		val transition = transitionInstance.value
		return instance.name + "." + transition.serialize
	}
	
	//
	
	def getExecutedTransitions() {
		return executedTransitions
	}
	
	def getAllExecutedTransitions() {
		return executedTransitions.flatten
	}
	
	def getUnexecutedTransitions() {
		val unexecutedTransitions = newLinkedHashSet
		
		val executedTransitionIds = allExecutedTransitions.map[it.id].toSet
		
		val instances = super.statechartInstanceReferences
		for (instance : instances) {
			val statechartInstance = instance.lastInstance
			val statechart = statechartInstance.getStatechart
			val transitions = statechart.transitions
			for (transition : transitions) {
				val transitionReference = instance.clone
						.createTransitionReference(transition)
				if (!executedTransitionIds.contains(transitionReference.id)) {
					unexecutedTransitions += transitionReference
				}
			}
		}
		
		return unexecutedTransitions
	}
	
	//
	
}