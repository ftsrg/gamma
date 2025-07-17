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

import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.statechart.util.ElementSerializer
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.util.Collection
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

abstract class VerificationPostprocessor {
	//
	protected final List<ExecutionTrace> traces = newArrayList
	//
	protected final extension ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE
	protected final extension ElementSerializer elementSerializer = ElementSerializer.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	//
	
	def Collection<? extends Object> execute(Collection<? extends Result> results) {
		return results.map[it.execute]
				.toList
	}
	
	def Object execute(Result result) {
		val trace = result.trace
		if (trace !== null) {
			return trace.execute
		}
		return null
	}
	
	def Collection<? extends Object> execute(Iterable<? extends ExecutionTrace> traces) {
		return traces.map[it.execute]
				.toList
	}
	
	def Object execute(ExecutionTrace trace)
	
	//
	
	protected def saveTrace(ExecutionTrace trace) {
		traces += trace
	}
	
	def getTraces() {
		return traces
	}
	
	def getStatechartInstanceReferences() {
		val allComponents = traces.map[it.component].toSet
		val components = (allComponents.allHelperEquals) ?
				#{ allComponents.head } : allComponents
		
		val instanceReferences = components
				.map[it.allSimpleInstanceReferences]
				.flatten
				.toList
		
		return instanceReferences
	}
	
}