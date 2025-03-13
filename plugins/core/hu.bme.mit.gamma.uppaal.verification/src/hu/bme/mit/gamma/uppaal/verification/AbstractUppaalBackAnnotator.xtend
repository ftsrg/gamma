/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.verification.util.TraceBuilder
import java.util.Scanner
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

abstract class AbstractUppaalBackAnnotator {
	
	protected final String ERROR_CONST = "[error]"
	protected final String WARNING_CONST = "[warning]"
	
	protected final String STATE_CONST_PREFIX = "State"
	protected final String STATE_CONST = "State:"
	protected final String TRANSITIONS_CONST = "Transition:"
	protected final String DELAY_CONST = "Delay:"
	
	protected final Scanner traceScanner
	
	protected final Package gammaPackage
	protected final Component component
	protected static final Object engineSynchronizationObject = new Object // For the VIATRA engine in the query generator
	
	protected final boolean sortTrace
	
	protected final extension TraceModelFactory traceModelFactory = TraceModelFactory.eINSTANCE

	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension TraceBuilder traceBuilder = TraceBuilder.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	
	protected final StringBuilder resultText = new StringBuilder
	
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	new(Package gammaPackage, Scanner traceScanner, boolean sortTrace) {
		this.gammaPackage = gammaPackage
		this.component = gammaPackage.firstComponent
		this.traceScanner = traceScanner
		this.sortTrace = sortTrace
	}
	
	protected def createTrace() {
		// Creating the trace component
		val trace = createExecutionTrace => [
			it.component = this.component
			it.import = this.gammaPackage
			it.name = this.component.name + "Trace"
		]
		trace.addTimeUnitAnnotation
		val topComponentArguments = gammaPackage.topComponentArguments
		// Note that the top component does not contain parameter declarations anymore due to the preprocessing
		checkState(topComponentArguments.size == component.parameterDeclarations.size, 
			"The numbers of top component arguments and top component parameters are not equal: " +
				topComponentArguments.size + " - " + component.parameterDeclarations.size)
		trace.arguments += topComponentArguments.map[it.clone]
		return trace
	}
	
	protected def handleInfoLines(String line, BackAnnotatorState state) {
		var newState = state
		if (state == BackAnnotatorState.INFO) {
			if (line.contains(ERROR_CONST)) { // Comes in the other stream now?
				// If e.g., the condition is not well formed, an exception is thrown
				throw new IllegalArgumentException("Error in the trace: " + line)
			}
			else if (line.contains(WARNING_CONST)) { // Comes in the other stream now?
				logger.warning(line)
			}
			else if (line == STATE_CONST_PREFIX || line == STATE_CONST) {
				// We have reached the section of interest
				newState = BackAnnotatorState.INITIAL
			}
			else { // Saving the "info" lines
				resultText.append(line)
			}
		}
		
		return newState
	}
	
	def ExecutionTrace synchronizeAndExecute() {
		synchronized (engineSynchronizationObject) {
			return execute
		}
	}
	
	def ExecutionTrace execute() throws EmptyTraceException
	
	def getResultText() {
		return resultText.toString
	}
	
}

enum BackAnnotatorState {INFO, INITIAL, STATE_LOCATIONS, STATE_VARIABLES, TRANSITIONS, DELAY}

class EmptyTraceException extends Exception {}