/********************************************************************************
 * Copyright (c) 2022-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.promela.verification

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.querygenerator.PromelaQueryGenerator
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.SchedulingConstraintAnnotation
import hu.bme.mit.gamma.theta.verification.XstsBackAnnotator
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.Schedule
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.verification.util.TraceBuilder
import java.util.NoSuchElementException
import java.util.Scanner
import java.util.logging.Logger
import java.util.regex.Pattern

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TraceBackAnnotator {
	
	protected final String INIT_START = "[flag = 1]"
	protected final String INIT_END = "flag = 1"
	protected final String INIT_ERROR = "flag = 0"
	protected final String ENV_START = "[flag = 2]"
	protected final String ENV_END = "flag = 2"
	protected final String TRANS_START = "[flag = 1]"
	protected final String TRANS_END = "flag = 1"
	protected final String TRACE_END = "#processes:"
	
	protected boolean traceEnd = false
	
	protected final Scanner traceScanner
	protected final PromelaQueryGenerator promelaQueryGenerator
	protected final extension XstsBackAnnotator xStsBackAnnotator
	protected static final Object engineSynchronizationObject = new Object // For the VIATRA engine in the query generator
	
	protected final Package gammaPackage
	protected final Component component
	protected final Expression schedulingConstraint
	
	protected final boolean sortTrace
	// Auxiliary objects
	protected final extension TraceModelFactory trFact = TraceModelFactory.eINSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension TraceBuilder traceBuilder = TraceBuilder.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	new(Package gammaPackage, Scanner traceScanner) {
		this(gammaPackage, traceScanner, true)
	}
	
	new(Package gammaPackage, Scanner traceScanner, boolean sortTrace) {
		this.gammaPackage = gammaPackage
		this.traceScanner = traceScanner
		this.sortTrace = sortTrace
		this.component = gammaPackage.firstComponent
		
		PromelaArrayParser.createMapping(gammaPackage.referencedTypedDeclarations)
		
		val schedulingConstraintAnnotation = gammaPackage.annotations
				.filter(SchedulingConstraintAnnotation).head
		if (schedulingConstraintAnnotation !== null) {
			this.schedulingConstraint = schedulingConstraintAnnotation.schedulingConstraint
		}
		else {
			this.schedulingConstraint = null
		}
		synchronized (engineSynchronizationObject) { // Due to the VIATRA engine
			this.promelaQueryGenerator = new PromelaQueryGenerator(component)
		}
		this.xStsBackAnnotator = new XstsBackAnnotator(promelaQueryGenerator, PromelaArrayParser.INSTANCE)
	}
	
	def ExecutionTrace synchronizeAndExecute() {
		synchronized (engineSynchronizationObject) {
			return execute
		}
	}
	
	def ExecutionTrace execute() {
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
			"The number of top component arguments and top component parameters are not equal: " +
				topComponentArguments.size + " - " + component.parameterDeclarations.size)
		trace.arguments += topComponentArguments.map[it.clone]
		var step = createStep
		trace.steps += step
		
		// Parsing
		var backAnnotatorState = BackAnnotatorState.INIT
		var modelState = ModelState.INIT
		var traceState = TraceState.NOT_REQUIRED
		var initError = false // error in INIT
		var lastElementArray = false
		var line = ""
		try {
			while (traceScanner.hasNext) {
				if (lastElementArray) {
					lastElementArray = false
				}
				else {
					line = traceScanner.nextLine.trim // Trimming leading white spaces
				}
				
				switch (modelState) {
					case INIT: {
						switch (line) {
							case line.endsWith(INIT_START): {
								// Adding reset
								step.actions += createReset
								backAnnotatorState = BackAnnotatorState.STATE_CHECK
								
								traceState = TraceState.REQUIRED
								line = traceScanner.nextLine.trim
							}
							case line.equals(INIT_END): {
								traceState = TraceState.NOT_REQUIRED
								modelState = ModelState.ENV
							}
							// error in INIT state
							case line.startsWith(TRACE_END): {
								// Adding reset
								step.actions += createReset
								backAnnotatorState = BackAnnotatorState.STATE_CHECK
								
								traceState = TraceState.REQUIRED
								initError = true
								traceEnd = true
								line = traceScanner.nextLine.trim
							}
							case line.equals(INIT_ERROR): {
								if (initError) {
									traceState = TraceState.NOT_REQUIRED
								}
							}
						}
					}
					case ENV: {
						switch (line) {
							case line.endsWith(ENV_START): {
								step.checkStates
								// Creating a new step
								step = createStep
								// Add static delay every turn
								if (schedulingConstraint !== null) {
									step.addTimeElapse(schedulingConstraint)
								}

								trace.steps += step
								// Setting the state
								backAnnotatorState = BackAnnotatorState.ENVIRONMENT_CHECK
								
								traceState = TraceState.REQUIRED
								line = traceScanner.nextLine.trim
							}
							case line.equals(ENV_END): {
								traceState = TraceState.NOT_REQUIRED
								modelState = ModelState.TRANS
							}
							case line.startsWith(TRACE_END): {
//								step.checkStates
//								// Creating a new step
//								step = createStep
//								// Add static delay every turn
//								if (schedulingConstraint !== null) {
//									step.addTimeElapse(schedulingConstraint)
//								}
//
//								trace.steps += step
//								// Setting the state
//								backAnnotatorState = BackAnnotatorState.ENVIRONMENT_CHECK
//								
								traceEnd = true
//								traceState = TraceState.REQUIRED
							}
						}
					}
					case TRANS: {
						switch (line) {
							case line.endsWith(TRANS_START): {
								step.checkInEvents
								// Add schedule
								step.addSchedulingIfNeeded
								// Setting the state
								backAnnotatorState = BackAnnotatorState.STATE_CHECK
								
								traceState = TraceState.REQUIRED
								line = traceScanner.nextLine.trim
							}
							case line.equals(TRANS_END): {
								traceState = TraceState.NOT_REQUIRED
								modelState = ModelState.ENV
							}
							case line.startsWith(TRACE_END): {
//								step.checkInEvents
//								// Add schedule
//								step.addComponentScheduling
//								// Setting the state
//								backAnnotatorState = BackAnnotatorState.STATE_CHECK
//								
								traceEnd = true
//								traceState = TraceState.REQUIRED
							}
						}
					}
					default:
						throw new IllegalArgumentException("Not known state: " + modelState)
				}
				
				// We parse in every turn (at the end of env and trans)
				if (traceState == TraceState.REQUIRED && line.checkLine) {
					
					var split = line.split(" = ")
					var id = split.get(0)
					var value = split.get(1)
					
					// Array
					if (id.endsWith("]")) {
						val arrayName = id.split(Pattern.quote("[")).get(0)
						line = traceScanner.nextLine.trim
						var arrayValue = id + " = " + value
						while (line.startsWith(arrayName)) {
							arrayValue += "|" + line
							line = traceScanner.nextLine.trim
						}
						// Elements of array in arrayValue
						id = arrayName
						value = arrayValue
						lastElementArray = true
					}
					backAnnotatorState.parse(id, value, step)
				}
			}
			// Checking the last state (in events must NOT be deleted here though)
			step.checkStates
			
			// Checking if Spin stopped in the middle due to finding an acceptance cycle
			if (step.actions.filter(Schedule).empty && step.asserts.empty) {
				val previousStep = step.previous as Step
				step.remove
				// Not correct as this is only the last step, but still, an indication for a cycle
				trace.cycle = createCycle => [it.steps += previousStep]
			}
		} catch (NoSuchElementException e) {
			// If there are not enough lines, that means there are no environment actions
			step.actions += createReset
		}
		
		trace.removeInternalEventRaiseActs
		trace.removeTransientVariableReferences // They always have default values
		trace.addUnraisedEventNegations
		
		if (sortTrace) {
			trace.sortInstanceStates
		}
		
		return trace
	}
	
	protected def parse(BackAnnotatorState backAnnotatorState, String id, String value, Step step) {
		switch (backAnnotatorState) {
			case STATE_CHECK: {
				val potentialStateString = '''«id» == «value»'''
				if (promelaQueryGenerator.isSourceState(potentialStateString)) {
					potentialStateString.parseState(step)
				}
				else if (promelaQueryGenerator.isDelay(id)) {
					step.addTimeElapse(Integer.valueOf(value))
				}
				else if (promelaQueryGenerator.isSourceVariable(id)) {
					id.parseVariable(value, step)
				}
				else if (id.isSchedulingVariable) {
					id.addScheduling(value, step)
				}
				else if (promelaQueryGenerator.isSourceOutEvent(id)) {
					id.parseOutEvent(value, step)
				}
				else if (promelaQueryGenerator.isSourceOutEventParameter(id)) {
					id.parseOutEventParameter(value, step)
				}
				// Checking if an asynchronous in-event is already stored in the queue
				else if (promelaQueryGenerator.isAsynchronousSourceMessageQueue(id)) {
					id.handleStoredAsynchronousInEvents(value)
				}
			}
			case ENVIRONMENT_CHECK: {
				// Synchronous in-event
				if (promelaQueryGenerator.isSynchronousSourceInEvent(id)) {
					id.parseSynchronousInEvent(value, step)
				}
				// Synchronous in-event parameter
				else if (promelaQueryGenerator.isSynchronousSourceInEventParameter(id)) {
					id.parseSynchronousInEventParameter(value, step)
				}
				// Asynchronous in-event
				else if (promelaQueryGenerator.isAsynchronousSourceMessageQueue(id)) {
					id.parseAsynchronousInEvent(value, step)
				}
				// Asynchronous in-event parameter
				else if (promelaQueryGenerator.isAsynchronousSourceInEventParameter(id)) {
					id.parseAsynchronousInEventParameter(value, step)
				}
			}
			default:
				throw new IllegalArgumentException("Not know state: " + backAnnotatorState)
		}
	}
	
	enum BackAnnotatorState { INIT, STATE_CHECK, ENVIRONMENT_CHECK }
	enum ModelState { INIT, TRANS, ENV }
	enum TraceState { REQUIRED, NOT_REQUIRED }
	
	// Filtering unnecessary lines
	protected def checkLine(String line) {
		return !(line.contains(":") ||
				(traceEnd && line.contains("proc  ")) ||
				line.startsWith("Never claim moves to") ||
				line.contains(" processes created") ||
				line.endsWith(" terminates") ||
				line.startsWith("msg_parallel_")
					// Addition
					|| line.startsWith("queue ")
				)
				
	}
}