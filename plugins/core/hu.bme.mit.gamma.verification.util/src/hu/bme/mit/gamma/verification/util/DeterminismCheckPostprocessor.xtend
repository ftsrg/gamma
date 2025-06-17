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
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.transformation.util.UnfoldedExecutionTraceBackAnnotator
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.util.Collection
import java.util.regex.Pattern

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class DeterminismCheckPostprocessor extends VerificationPostprocessor {
	
	override execute(Collection<? extends Result> results) {
		return results.map[it.execute]
				.toList
	}
	
	def execute(Result result) {
		val trace = result.trace
		if (trace !== null) {
			return trace.execute
		}
	}
	
	def execute(Iterable<? extends ExecutionTrace> traces) {
		return traces.map[it.execute]
				.toList
	}
	
	// TODO unfolded traces or original traces? Probably both
	def execute(ExecutionTrace trace) {
		val steps = trace.steps
		val beforeLastStep = steps.beforeLastElement
		val lastStep = steps.lastElement
		
		val lastState = lastStep.asserts
		val beforeLastStepStates = beforeLastStep.instanceStateConfigurations
		
		// TODO for unfolded traces, too
		val stringBeginning = UnfoldedExecutionTraceBackAnnotator.TRAP_STATE_MESSAGE_BEGINNING
		val trapStateEntries = lastState.filter(OpaqueExpression)
				.filter[it.expression.startsWith(stringBeginning)]
		for (trapStateEntry : trapStateEntries) {
			// Parsing non-deterministic instance and region
			val string = trapStateEntry.expression
			val pattern = Pattern.compile('''«stringBeginning» region (.*) of (.*)''')
			val matcher = pattern.matcher(string)
			if (!matcher.find) {
				throw new IllegalArgumentException("Not found pattern: " + string)
			}
			
			val regionName = matcher.group(1)
			val instanceName = matcher.group(2)
			
			// Selecting next to last control location (state)
			val nondeterministicState = beforeLastStepStates.filter[
					it.instance.componentInstanceChain.map[it.name].join(".") == instanceName &&
					it.region.name == regionName]
					.onlyElement
					
			val state = nondeterministicState.state
			println('''Found nondeterministic state «state.name» in region «regionName» of «instanceName»''')
		}
		// TODO parse acts (input events) -> project them to statechart-level ports (timing will be cumbersome)
		// TODO identify outgoing transitions of interest based on 1) triggers and 2) guards (variables and input args)
		return new Object
	}
	
}