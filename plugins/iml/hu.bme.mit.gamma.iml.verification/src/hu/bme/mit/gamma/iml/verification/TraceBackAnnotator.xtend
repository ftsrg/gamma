/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.iml.verification

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.querygenerator.ImlQueryGenerator
import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.SchedulingConstraintAnnotation
import hu.bme.mit.gamma.theta.verification.XstsBackAnnotator
import hu.bme.mit.gamma.trace.model.Cycle
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.Reset
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.verification.util.TraceBuilder
import java.util.NoSuchElementException
import java.util.Scanner
import java.util.logging.Logger
import org.eclipse.emf.ecore.EObject

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TraceBackAnnotator {
	//
	protected final String ENVIRONMENT = " <--"
	protected final String STATE = " -->"
	protected final String LOOP = " loop "
	//
	protected final Scanner traceScanner
	protected final StringBuilder initString = new StringBuilder
	protected Scanner initScanner
	boolean saveTrace = false
	boolean readSavedTrace = false
	//
	protected final ThetaQueryGenerator imlQueryGenerator
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
		val schedulingConstraintAnnotation = gammaPackage.annotations
				.filter(SchedulingConstraintAnnotation).head
		if (schedulingConstraintAnnotation !== null) {
			this.schedulingConstraint = schedulingConstraintAnnotation.schedulingConstraint
		}
		else {
			this.schedulingConstraint = null
		}
		synchronized (engineSynchronizationObject) { // Due to the VIATRA engine
			this.imlQueryGenerator = new ImlQueryGenerator(component)
		}
		this.xStsBackAnnotator = new XstsBackAnnotator(imlQueryGenerator, ImlArrayParser.INSTANCE)
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
		
		var EObject stepContainer = trace
		var step = stepContainer.addStep
		
		// Parsing
		var state = BackAnnotatorState.INFO
		var isInitialized = false
		try {
			while (traceScanner.hasNext) {
				// We have to have two passes for 1) the initial states and 2) first step's actions
				var currentScanner = (!readSavedTrace) ? traceScanner : initScanner
				var line = currentScanner.nextLine.trim
				
				if (saveTrace) {
					initString.append(line + System.lineSeparator)
				}
				
				// The trace starts with an INFO section, handled by the following code
				state = line.handleInfoLines(state)
				//
				
				if (state != BackAnnotatorState.INFO) {
					switch (line) {
						case state == BackAnnotatorState.INIT: {
							step.addReset
							isInitialized = true
							
							saveTrace = true // Saving the init state, for one more pass
							initString.append(line + System.lineSeparator)
							
							state = BackAnnotatorState.STATE_CHECK
						}
						case line.contains(ENVIRONMENT): {
							/// New step to be parsed: checking the previous step
							step.checkInEvents
							// Add schedule
							if (!step.containsType(Reset)) {
								step.addSchedulingIfNeeded
							}
							step.checkStates
							///
							
							// Creating a new step
							step = stepContainer.addStep
							
							/// Add static delay every turn (apart from first state)
							if (schedulingConstraint !== null) {
								step.addTimeElapse(schedulingConstraint)
							} // Or actual time delay (TODO later)
							
							state = BackAnnotatorState.ENVIRONMENT_CHECK
						}
						case line.contains(STATE): {
							if (saveTrace) {
								saveTrace = false // We are beyond the init state phase
								readSavedTrace = true // Time to reread the init actions
								initScanner = new Scanner(initString.toString)
							}
							else if (readSavedTrace) {
								readSavedTrace = false // We have reread the init actions
								// Progressing normally, with the main scanner
							}
							
							state = BackAnnotatorState.STATE_CHECK
						}
						case line.startsWith(LOOP): { // TODO
							val cycle = createCycle
							trace.cycle = cycle
							stepContainer = cycle
						}
						default: {
							// Parsing variables
							val handledLines = line.handleImandraLines(currentScanner)
							// There can be multiple lines with variable valuations in the trace
							for (handledLine : handledLines.split(System.lineSeparator).reject[it.nullOrEmpty]) {
								val split = handledLine.split(" = ", 2) // Only the first " = " is checked
								val id = split.get(0).trim
								val value = split.get(1).trim
								try {
									switch (state) {
										case STATE_CHECK : {
											val potentialStateString = '''«id» == «value»'''
											if (imlQueryGenerator.isSourceState(potentialStateString)) {
												potentialStateString.parseState(step)
											}
											else if (imlQueryGenerator.isDelay(id)) {
												step.addTimeElapse(Integer.valueOf(value))
											}
											else if (imlQueryGenerator.isSourceVariable(id)) {
												id.parseVariable(value, step)
											}
											else if (id.isSchedulingVariable) {
												id.addScheduling(value, step)
											}
											else if (imlQueryGenerator.isSourceOutEvent(id)) {
												id.parseOutEvent(value, step)
											}
											else if (imlQueryGenerator.isSourceOutEventParameter(id)) {
												id.parseOutEventParameter(value, step)
											}
											//
											// Synchronous in-event parameter: only if it is PERSISTENT
											else if (imlQueryGenerator.isSynchronousSourceInEventParameter(id)) {
												id.parseSynchronousInEventParameter(value, step)
											}
											//
											// We check the async queue in every state_check: if the message remains in the queue,
											// then it was not processed in the cycle, so we remove it from the trace.
											// Next time it is processed, in env_check, we will see that it is still in the queue,
											// but is removed by the end of the valid state; thus, we leave it in the trace (i.e., not remove it again here)
											else if (imlQueryGenerator.isAsynchronousSourceMessageQueue(id)) {
												id.handleStoredAsynchronousInEvents(value)
											}
											//
										}
										case ENVIRONMENT_CHECK: {
											// Synchronous in-event
											if (imlQueryGenerator.isSynchronousSourceInEvent(id)) {
												id.parseSynchronousInEvent(value, step)
											}
											// Synchronous in-event parameter
											else if (imlQueryGenerator.isSynchronousSourceInEventParameter(id)) {
												id.parseSynchronousInEventParameter(value, step)
											}
											// Asynchronous in-event
											else {
												val asyncQueueId = id // Note: we expect a SINGLE assignment to the queue
												if (imlQueryGenerator.isAsynchronousSourceMessageQueue(asyncQueueId)) {
													asyncQueueId.parseAsynchronousInEvent(value, step)
												}
												// Asynchronous in-event parameter
												else if (imlQueryGenerator.isAsynchronousSourceInEventParameter(asyncQueueId)) {
													asyncQueueId.parseAsynchronousInEventParameter(value, step)
												}
											}
										}
										default:
											throw new IllegalArgumentException("Not known state: " + state)
									}
								}
								catch (IndexOutOfBoundsException e) {
									// In the SMV mapping, the arrays are set to have a larger capacity by one
									// So out of indexing will result in the default value
									checkState(id.isArray(value))
								}
							}
						
						}
					}
				}
			}
			if (state == BackAnnotatorState.INFO || state == BackAnnotatorState.INIT) {
				// No counterexample, the scanner is empty
				return null
			}
			
			// Checking the last state
			step.checkInEvents // In events can be deleted here?
			if (!step.containsType(Reset)) {
				step.addSchedulingIfNeeded
			}
			step.checkStates
		} catch (NoSuchElementException e) {
			// If there are not enough lines, that means there are no environment actions
			if (!isInitialized) {
				step.actions += createReset
			}
			else {
				step.addSchedulingIfNeeded
			}
		}
		
		trace.removeInternalEventRaiseActs
		trace.removeTransientVariableReferences // They always have default values
		trace.addUnraisedEventNegations
		
		if (sortTrace) {
			trace.sortInstanceStates
		}
		
		return trace
	}
	
	//
	
	protected def handleInfoLines(String line, BackAnnotatorState state) {
		var newState = state
		if (state == BackAnnotatorState.INFO) {
			if (line.contains(STATE) || line.contains(ENVIRONMENT)) { // Comes in the other stream now?
				// We have reached the section of interest
				newState = BackAnnotatorState.INIT
			}
		}
		
		return newState
	}
	
	// TODO Delete if everything comes in a separate line in the final Imandra implementation
	protected def handleImandraLines(String line, Scanner scanner) {
		var newLine = line
		// Imandra returns the values of the fields between '{' and '}' and can have line breaks after the '='
		if (newLine.startsWith("{")) {
			newLine = line.substring(1)
		}
		while (!(newLine.endsWith(";") || newLine.endsWith("}"))) {
			val nextLine = scanner.nextLine
			if (saveTrace) {
				initString.append(nextLine + System.lineSeparator)
			}
			newLine = newLine + " " + nextLine
		}
		if (newLine.endsWith("}")) {
			newLine = newLine.substring(0, newLine.length - 1)
		}
		newLine = newLine.replaceAll(";", System.lineSeparator)
		
		return newLine
	}
	
	protected def addStep(EObject container) {
		val step = createStep
		switch (container) {
			ExecutionTrace: {
				container.steps += step
				return step
			}
			Cycle: {
				container.steps += step
				return step
			}
			default:
				throw new IllegalArgumentException("Not known object: " + container)
		}
	}
	
	//
	
	enum BackAnnotatorState {INFO, INIT, STATE_CHECK, ENVIRONMENT_CHECK}
	
}