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
package hu.bme.mit.gamma.statechart.contract.tracegeneration

import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.traverser.LooplessPathRetriever
import hu.bme.mit.gamma.trace.model.Schedule
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class StatechartContractToTraceTransformer {
	
	final extension LooplessPathRetriever looplessPathRetriever = new LooplessPathRetriever
	final extension TransitionToStepTransformer transitionToStepTransformer = new TransitionToStepTransformer
	
	final extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	
	def execute(StatechartDefinition statechart) {
		return execute(statechart, false)
	}
	
	def execute(StatechartDefinition statechart, boolean addReset) {
		val paths = newArrayList
		for (topRegion : statechart.regions) {
			paths += topRegion.retrievePaths
		}
		val traces = newArrayList
		for (path : paths) {
			val trace = createExecutionTrace => [
				it.import = statechart.containingPackage
				it.component = statechart
				// Not adding arguments
			]
			traces += trace
			val steps = trace.steps
			for (transition : path.transitions) {
				steps += transition.execute
			}
			// Putting out-events after the scheduling step
			steps.mergeSteps
			// Adding reset in the first step if necessary
			if (addReset) {
				if (!steps.empty) {
					val firstStep = steps.head
					firstStep.actions.add(0, createReset)
				}
			}
		}
		return traces
	}
	
	private def mergeSteps(List<Step> steps) {
		for (var i = 0; i < steps.size; i++) {
			val lhs = steps.get(i)
			if (lhs.actions.filter(Schedule).empty) {
				val rhs = steps.get(i + 1)
				rhs.actions += lhs.actions
				rhs.outEvents += lhs.outEvents // Putting out-events after schedule is essential
				steps.remove(i)
				i--
			}
		}
	}
	
}