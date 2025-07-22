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

import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import java.util.Map
import java.util.Map.Entry

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TransitionPairExecutabilityCheckPostprocessor extends VerificationPostprocessor {
	//
	protected final extension TransitionExecutabilityCheckPostprocessor postprocessor = new TransitionExecutabilityCheckPostprocessor
	//
	
	override execute(ExecutionTrace trace) {
		trace.saveTrace
		
		return postprocessor.execute(trace)
	}
	
	//
	
	def getId(Entry<Entry<ComponentInstanceReferenceExpression, Transition>,
				Entry<ComponentInstanceReferenceExpression, Transition>> transitionInstancePair) {
		val first = transitionInstancePair.key
		val operator = "->"
		val second = transitionInstancePair.value
		return '''«first.id» «operator» «second.id»'''
	}
	
	def getExecutedTransitionPairs() {
		val executedTransitionPairs = newLinkedList
		for (executedTransition : executedTransitions) {
			val beforeLast = executedTransition.beforeLastElement // In
			val last = executedTransition.lastElement // Out
			
			val pair = Map.entry(beforeLast, last)
			executedTransitionPairs += pair
			// TODO we could parse not just the last two, but previous executions, too (if any)
		}
		
		return executedTransitionPairs
	}
	
	def getUnexecutedTransitionPairs() {
		val unexecutedTransitionPairs = newLinkedHashSet
		
		val executedTransitionPairIds = executedTransitionPairs.map[it.id].toSet
		
		val instances = super.statechartInstanceReferences
		for (instance : instances) {
			val statechartInstance = instance.lastInstance
			val statechart = statechartInstance.getStatechart
			val nodes = statechart.allStateNodes
			for (node : nodes) {
				for (incoming : node.incomingTransitions) {
					for (outgoing : node.outgoingTransitions) {
						val first = Map.entry(instance, incoming)
						val second = Map.entry(instance, outgoing)
						val pair = Map.entry(first, second)
						
						if (!executedTransitionPairIds.contains(pair.id)) {
							unexecutedTransitionPairs += pair
						}
					}
				}
			}
		}
		
		return unexecutedTransitionPairs
	}

}