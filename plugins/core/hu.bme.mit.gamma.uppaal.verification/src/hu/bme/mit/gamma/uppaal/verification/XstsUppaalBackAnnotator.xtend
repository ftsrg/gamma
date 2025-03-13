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

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.querygenerator.XstsUppaalQueryGenerator
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.SchedulingConstraintAnnotation
import hu.bme.mit.gamma.theta.verification.XstsBackAnnotator
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.uppaal.util.XstsNamings
import java.util.Scanner

import static com.google.common.base.Preconditions.checkState

class XstsUppaalBackAnnotator extends AbstractUppaalBackAnnotator {
	
	protected final XstsUppaalQueryGenerator xStsUppaalQueryGenerator
	protected final extension XstsBackAnnotator xStsBackAnnotator
	protected final Expression schedulingConstraint
	
	new(Package gammaPackage, Scanner traceScanner) {
		this(gammaPackage, traceScanner, true)
	}
	
	new(Package gammaPackage, Scanner traceScanner, boolean sortTrace) {
		super(gammaPackage, traceScanner, sortTrace)
		val schedulingConstraintAnnotation = gammaPackage.annotations
				.filter(SchedulingConstraintAnnotation).head
		if (schedulingConstraintAnnotation !== null) {
			this.schedulingConstraint = schedulingConstraintAnnotation.schedulingConstraint
		}
		else {
			this.schedulingConstraint = null
		}
		synchronized (engineSynchronizationObject) {
			this.xStsUppaalQueryGenerator = new XstsUppaalQueryGenerator(component)
		}
		this.xStsBackAnnotator = new XstsBackAnnotator(xStsUppaalQueryGenerator, UppaalArrayParser.INSTANCE)
	}
	
	override execute() throws EmptyTraceException {
		val trace = super.createTrace
		
		var Step step = null
		
		var String line = null
		var state = BackAnnotatorState.INFO
		var localState = StableEnvironmentState.INITIAL
		while (traceScanner.hasNext) {
			line = traceScanner.nextLine
			
			// The trace starts with an INFO section, handled by the following code
			state = line.handleInfoLines(state)
			//
			
			if (state != BackAnnotatorState.INFO) {
				switch (line) {
					case line.empty: {
						// No operation
					}
					case TRANSITIONS_CONST: {
						state = BackAnnotatorState.TRANSITIONS
					}
					case STATE_CONST_PREFIX, case STATE_CONST: { // There used to be a bug where 'State' was written instead of 'State:'
						state = BackAnnotatorState.STATE_LOCATIONS
					}
					case line.startsWith(DELAY_CONST): {
						// Parsing delays
						val delay = Integer.parseInt(line.substring(DELAY_CONST.length + 1))
						step.addTimeElapse(delay)
					}
					default: {
						switch (state) {
							case BackAnnotatorState.INITIAL: {
								// Creating a new step
								step = createStep
								step.addReset
							}
							case BackAnnotatorState.STATE_LOCATIONS: {
								val processLocationNames = newArrayList
								processLocationNames += line.split(" ").toList
								// Dropping the first " (" and last " )" elements
								processLocationNames.removeIf[it == "(" || it == ")"]
								checkState(processLocationNames.size == 1)
								val processLocationName = processLocationNames.head
								val split = processLocationName.split("\\.")
								val locationName = split.lastOrNull
								if (locationName == XstsNamings.stableLocationName) {
									state = BackAnnotatorState.STATE_VARIABLES
									localState = StableEnvironmentState.STABLE
								}
								else if (locationName == XstsNamings.environmentFinishLocationName) {
									state = BackAnnotatorState.STATE_VARIABLES
									localState = StableEnvironmentState.ENVIRONMENT
								}
								else if (locationName == XstsNamings.initialLocationName) {
									state = BackAnnotatorState.INITIAL
									localState = StableEnvironmentState.INITIAL
								}
								else {
									state = BackAnnotatorState.STATE_VARIABLES
									localState = StableEnvironmentState.OTHER
								}
								// Other locations are committed and not checked
							}
							case BackAnnotatorState.STATE_VARIABLES: {
								if (localState != StableEnvironmentState.OTHER) {
									val variableValues = line.split(" ")
									for (variableValue : variableValues) {
										val split = variableValue.split("=")
										val id = split.head
										val value = split.lastOrNull
										
										switch (localState) {
											case STABLE: {
												val index = Integer.parseInt(value)
												val potentialStateString = '''«id» == «index»'''
												if (xStsUppaalQueryGenerator.isSourceState(potentialStateString)) {
													if (index > 0) {
														potentialStateString.parseState(step)
													}
												}
												else if (xStsUppaalQueryGenerator.isDelay(id)) {
													step.addTimeElapse(Integer.valueOf(value))
												}
												else if (xStsUppaalQueryGenerator.isSourceVariable(id)) {
													id.parseVariable(value, step)
												}
												else if (id.isSchedulingVariable) {
													id.addScheduling(value, step)
												}
												else if (xStsUppaalQueryGenerator.isSourceOutEvent(id)) {
													id.parseOutEvent(value, step)
												}
												else if (xStsUppaalQueryGenerator.isSourceOutEventParameter(id)) {
													id.parseOutEventParameter(value, step)
													// Will check in localState == StableEnvironmentState.ENVIRONMENT, if it is valid
												}
												// Checking if an asynchronous in-event is already stored in the queue
												else if (xStsUppaalQueryGenerator.isAsynchronousSourceMessageQueue(id)) {
													id.handleStoredAsynchronousInEvents(value)
												}
											}
											case ENVIRONMENT: {
												if (xStsUppaalQueryGenerator.isSynchronousSourceInEvent(id)) {
													id.parseSynchronousInEvent(value, step)
												}
												else if (xStsUppaalQueryGenerator.isSynchronousSourceInEventParameter(id)) {
													id.parseSynchronousInEventParameter(value, step)
													// Will check in localState == StableEnvironmentState.ENVIRONMENT, if it is valid
												}
												// Asynchronous in-event
												else if (xStsUppaalQueryGenerator.isAsynchronousSourceMessageQueue(id)) {
													id.parseAsynchronousInEvent(value, step)
												}
												// Asynchronous in-event parameter
												else if (xStsUppaalQueryGenerator.isAsynchronousSourceInEventParameter(id)) {
													id.parseAsynchronousInEventParameter(value, step)
												}
											}
											default: {
												throw new IllegalStateException("Not known state: " + localState)
											}
										}
									}
								}
								if (localState == StableEnvironmentState.STABLE) {
									val schedule = step.actions.filter(ComponentSchedule).head
									val delay = step.actions.filter(TimeElapse).head
									if (delay !== null && schedule === null) {
										/* Delays happen in _StableLocation_ so the state before the delay is doubled.
										 * Leaving it like this would not cause a bug.
										 * Nevertheless, the trace is more compact this way. */
										step = createStep
										step.actions += delay
									}
									else {
										// Deleting states that are not inactive due to history
										step.checkStates
										// Creating a new step
										trace.steps += step
										step = createStep
									}
									/// Add static delay every turn
									if (schedulingConstraint !== null) {
										step.addTimeElapse(schedulingConstraint)
									}
									///
								}
								if (localState == StableEnvironmentState.ENVIRONMENT) {
									// Deleting events that are not raised (parameter values are always present)
									step.checkInEvents
									// Add schedule
									step.addSchedulingIfNeeded
								}
							}
							case BackAnnotatorState.TRANSITIONS: {
								// No operation
							}
							default: {
								throw new IllegalStateException("Not known state")
							}
						}
					}
				}
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
	
}

enum StableEnvironmentState {INITIAL, STABLE, ENVIRONMENT, OTHER}
