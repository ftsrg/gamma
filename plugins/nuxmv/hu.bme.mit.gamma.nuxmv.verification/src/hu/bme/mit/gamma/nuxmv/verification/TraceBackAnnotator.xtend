/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.nuxmv.verification

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.querygenerator.NuxmvQueryGenerator
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
import hu.bme.mit.gamma.xsts.transformation.util.XstsNamings
import java.util.NoSuchElementException
import java.util.Scanner
import java.util.logging.Logger
import org.eclipse.emf.ecore.EObject

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TraceBackAnnotator {
	
	protected final String STATE = "-> State:"
	protected final String INPUT = "-> Input:"
	protected final String LOOP = "-- Loop starts here"
	protected final String DISCRETE_TRANSITION = "-- [ discrete transition"
	protected final String TIME_ELAPSE = "-- [ time elapse: "
	
	protected final Scanner traceScanner
	protected final ThetaQueryGenerator nuxmvQueryGenerator
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
			this.nuxmvQueryGenerator = new NuxmvQueryGenerator(component)
		}
		this.xStsBackAnnotator = new XstsBackAnnotator(nuxmvQueryGenerator, NuxmvArrayParser.INSTANCE)
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
		
		var needsScheduling = true // Relevant in the case of timed models
		
		// Parsing
		var state = BackAnnotatorState.INIT
		try {
			while (traceScanner.hasNext) {
				val isFirstState = (state == BackAnnotatorState.INIT)
				var line = traceScanner.nextLine.trim // Trimming leading white spaces
				switch (line) {
					case line.startsWith(INPUT),
					case line.startsWith(TIME_ELAPSE): {
						/// New step to be parsed: checking the previous step
						step.checkInEvents
						// Add schedule
						if (!step.containsType(Reset)) {
							if (needsScheduling) { // Check TIME_ELAPSE branch below
								step.addSchedulingIfNeeded
							}
							else {
								needsScheduling = true
							}
						}
						step.checkStates
						///
						
						// Creating a new step
						step = stepContainer.addStep
						
						/// Add static delay every turn (apart from first state)
						if (schedulingConstraint !== null) {
							step.addTimeElapse(schedulingConstraint)
						} // Or actual time delay
						else if (line.startsWith(TIME_ELAPSE)) {
							// -- [ time elapse: time = 0.0; delta = 2000.0 ] --
							val splitLine = line.split("delta = ")
							val last = splitLine.lastOrNull
							val delaySplit = last.split("\\.")
							val delayString = delaySplit.head
							val delay = Integer.parseInt(delayString)
							step.addTimeElapse(delay)
							// Schedule must not be added as the previous and next states are the same
							needsScheduling = false
						}
						///
						// Setting the state
						state = BackAnnotatorState.ENVIRONMENT_CHECK
					}
					case line.startsWith(STATE): {
						if (isFirstState) {
							step.actions += createReset
						}
						// Setting the state
						state = BackAnnotatorState.STATE_CHECK
					}
					case line.startsWith(LOOP): {
						val cycle = createCycle
						trace.cycle = cycle
						stepContainer = cycle
					}
					case line.startsWith(DISCRETE_TRANSITION): {
						// "-- [ discrete transition] --" nothing to do
					}
					default: {
						if (!isFirstState) {
							// We parse in every turn except the init
							val split = line.split(" = ", 2) // Only the first " = " is checked
							val id = split.get(0)
							val value = split.get(1)
							try {
								switch (state) {
									case STATE_CHECK: {
										val potentialStateString = '''«id» == «value»'''
										if (nuxmvQueryGenerator.isSourceState(potentialStateString)) {
											potentialStateString.parseState(step)
										}
										else if (nuxmvQueryGenerator.isDelay(id)) {
											step.addTimeElapse(Integer.valueOf(value))
										}
										else if (nuxmvQueryGenerator.isSourceVariable(id)) {
											id.parseVariable(value, step)
										}
										else if (id.isSchedulingVariable) {
											id.addScheduling(value, step)
										}
										else if (nuxmvQueryGenerator.isSourceOutEvent(id)) {
											id.parseOutEvent(value, step)
										}
										else if (nuxmvQueryGenerator.isSourceOutEventParameter(id)) {
											id.parseOutEventParameter(value, step)
										}
										//
										// Synchronous in-event parameter: only if it is PERSISTENT (cannot be IVAR)
										else if (nuxmvQueryGenerator.isSynchronousSourceInEventParameter(id)) {
											id.parseSynchronousInEventParameter(value, step)
										}
										//
										// We check the async queue in every state_check: if the message remains in the queue,
										// then it was not processed in the cycle, so we remove it from the trace.
										// Next time it is processed, in env_check, we will see that it is still in the queue,
										// but is removed by the end of the valid state; thus, we leave it in the trace (i.e., not remove it again here)
										else if (nuxmvQueryGenerator.isAsynchronousSourceMessageQueue(id)) {
											id.handleStoredAsynchronousInEvents(value)
										}
										//
									}
									case ENVIRONMENT_CHECK: {
										// Synchronous in-event
										if (nuxmvQueryGenerator.isSynchronousSourceInEvent(id)) {
											id.parseSynchronousInEvent(value, step)
										}
										// Synchronous in-event parameter
										else if (nuxmvQueryGenerator.isSynchronousSourceInEventParameter(id)) {
											id.parseSynchronousInEventParameter(value, step)
										}
										// Asynchronous in-event
										else {
											val asyncQueueId = id.backAnnotateFirstPrimedAsyncQueueId // Note: we expect a SINGLE assignment to the queue
											if (nuxmvQueryGenerator.isAsynchronousSourceMessageQueue(asyncQueueId)) {
												asyncQueueId.parseAsynchronousInEvent(value, step)
											}
											// Asynchronous in-event parameter
											else if (nuxmvQueryGenerator.isAsynchronousSourceInEventParameter(asyncQueueId)) {
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
			if (state == BackAnnotatorState.INIT) {
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
	
	//
	
	protected def backAnnotateFirstPrimedAsyncQueueId(String id) {
		var bracketIndex = id.indexOf("[")
		if (bracketIndex < 0) {
			bracketIndex = id.length
		}
		
		val bracketlessId = id.substring(0, bracketIndex)
		// Deleting "_inout_1" - index 1, because this is the first modification of the queue in the in-out transition
		val originalId = XstsNamings.getOriginalNameOfPrimedVariableNameInInoutTransition(bracketlessId, 1)
		
		return originalId
	}
	
	//
	
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
	
	enum BackAnnotatorState {INIT, STATE_CHECK, ENVIRONMENT_CHECK}
	
}