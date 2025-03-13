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
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.SchedulingConstraintAnnotation
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.verification.util.TraceBuilder
import java.util.NoSuchElementException
import java.util.Scanner
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TraceBackAnnotator {
	
	protected final String XSTS_TRACE = "(XstsStateSequence"
	protected final String XSTS_STATE = "(XstsState"
	protected final String EXPL_STATE = "(ExplState"
	
	protected final Scanner traceScanner
	protected final ThetaQueryGenerator thetaQueryGenerator
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
			this.thetaQueryGenerator = new ThetaQueryGenerator(component)
		}
		this.xStsBackAnnotator = new XstsBackAnnotator(thetaQueryGenerator, ThetaArrayParser.INSTANCE)
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
		var state = BackAnnotatorState.INIT
		try {
			while (traceScanner.hasNext) {
				var line = traceScanner.nextLine.trim // Trimming leading white spaces
				switch (line) {
					case line.startsWith(XSTS_TRACE): {
						// Skipping the first state
						var countedExplicitState = 0
						while (countedExplicitState < 2) {
							line = traceScanner.nextLine.trim
							if (line.startsWith(EXPL_STATE)) {
								countedExplicitState++
							}
						}
						// Needed to create a new step for reset if there are multiple in the trace
						if (trace.steps.size > 1) {
							if (!trace.steps.contains(step)) {
								trace.steps += step
							}
							// Must be done for last step like in line 259
							step.checkStates
							
							step = createStep
							trace.steps += step
						}
						// Adding reset
						step.actions += createReset
						line = traceScanner.nextLine.trim
						state = BackAnnotatorState.STATE_CHECK
					}
					case line.startsWith(XSTS_STATE): {
						// Deleting unnecessary in and out events
						switch (state) {
							case STATE_CHECK: {
								step.checkStates
								// Creating a new step
								step = createStep
								/// Add static delay every turn
								if (schedulingConstraint !== null) {
									step.addTimeElapse(schedulingConstraint)
								}
								///
								trace.steps += step
								// Setting the state
								state = BackAnnotatorState.ENVIRONMENT_CHECK
							}
							case ENVIRONMENT_CHECK: {
								step.checkInEvents
								// Add schedule
								step.addSchedulingIfNeeded
								// Setting the state
								state = BackAnnotatorState.STATE_CHECK
							}
							default:
								throw new IllegalArgumentException("Not know state: " + state)
						}
						// Skipping two lines
						line = traceScanner.nextLine
						line = traceScanner.nextLine.trim
					}
				}
				// We parse in every turn
				line = thetaQueryGenerator.unwrapAll(line)
				// From v.6.5.4, '(ExplState ' precedes actual values, which has to be removed
				if (line.startsWith(EXPL_STATE)) {
					line = line.substring(EXPL_STATE.length).trim
				}
				//
				val split = line.split(" ", 2) // Only the first " " is checked
				val id = split.get(0)
				val value = split.get(1)
				switch (state) {
					case STATE_CHECK: {
						val potentialStateString = '''«id» == «value»'''
						if (thetaQueryGenerator.isSourceState(potentialStateString)) {
							potentialStateString.parseState(step)
						}
						else if (thetaQueryGenerator.isDelay(id)) {
							step.addTimeElapse(Integer.valueOf(value))
						}
						else if (thetaQueryGenerator.isSourceVariable(id)) {
							id.parseVariable(value, step)
						}
						else if (id.isSchedulingVariable) {
							id.addScheduling(value, step)
						}
						else if (thetaQueryGenerator.isSourceOutEvent(id)) {
							id.parseOutEvent(value, step)
						}
						else if (thetaQueryGenerator.isSourceOutEventParameter(id)) {
							id.parseOutEventParameter(value, step)
						}
						// Checking if an asynchronous in-event is already stored in the queue
						else if (thetaQueryGenerator.isAsynchronousSourceMessageQueue(id)) {
							id.handleStoredAsynchronousInEvents(value)
						}
					}
					case ENVIRONMENT_CHECK: {
						// Synchronous in-event
						if (thetaQueryGenerator.isSynchronousSourceInEvent(id)) {
							id.parseSynchronousInEvent(value, step)
						}
						// Synchronous in-event parameter
						else if (thetaQueryGenerator.isSynchronousSourceInEventParameter(id)) {
							id.parseSynchronousInEventParameter(value, step)
						}
						// Asynchronous in-event
						else if (thetaQueryGenerator.isAsynchronousSourceMessageQueue(id)) {
							id.parseAsynchronousInEvent(value, step)
						}
						// Asynchronous in-event parameter
						else if (thetaQueryGenerator.isAsynchronousSourceInEventParameter(id)) {
							id.parseAsynchronousInEventParameter(value, step)
						}
					}
					default:
						throw new IllegalArgumentException("Not known state: " + state)
				}
			}
			// Checking the last state (in events must NOT be deleted here though)
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
	
	enum BackAnnotatorState {INIT, STATE_CHECK, ENVIRONMENT_CHECK}
	
}