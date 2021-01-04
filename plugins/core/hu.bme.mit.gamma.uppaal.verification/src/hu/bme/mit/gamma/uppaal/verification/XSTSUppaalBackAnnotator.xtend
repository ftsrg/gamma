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
package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.querygenerator.XSTSUppaalQueryGenerator
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.uppaal.util.XSTSNamings
import java.util.Scanner
import java.util.Set
import org.eclipse.emf.ecore.util.EcoreUtil

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class XSTSUppaalBackAnnotator extends AbstractUppaalBackAnnotator {
	
	protected final XSTSUppaalQueryGenerator xStsUppaalQueryGenerator
	
	new(Package gammaPackage, Scanner traceScanner) {
		this(gammaPackage, traceScanner, true)
	}
	
	new(Package gammaPackage, Scanner traceScanner, boolean sortTrace) {
		super(traceScanner, sortTrace)
		this.gammaPackage = gammaPackage
		this.component = gammaPackage.components.head
		this.xStsUppaalQueryGenerator = new XSTSUppaalQueryGenerator(gammaPackage)
	}
	
	override execute() throws EmptyTraceException {
		val trace = super.createTrace
		
		var Step step = null
		
		val raisedInEvents = newHashSet
		val activatedStates = newHashSet
		val raisedOutEvents = newHashSet
		
		var String line = null
		var state = BackAnnotatorState.INITIAL
		var localState = StableEnvironmentState.INITIAL
		while (traceScanner.hasNext) {
			line = traceScanner.nextLine
			// Variable line contains a single line from the trace
			switch (line) {
				case line.empty: {
					// No operation
				}
				case line.contains(ERROR_CONST):
					// If the condition is not well formed, an exception is thrown
					throw new IllegalArgumentException("Error in the trace: " + line)
				case line.contains(WARNING_CONST): {
					// No operation
				}
				case TRANSITIONS_CONST: {
					state = BackAnnotatorState.TRANSITIONS
				}
				case STATE_CONST_PREFIX: // There is a bug where State is written instead of State:
					state = BackAnnotatorState.STATE_LOCATIONS
				case STATE_CONST:
					state = BackAnnotatorState.STATE_LOCATIONS
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
							val locationName = split.last
							if (locationName.equals(XSTSNamings.stableLocationName)) {
								state = BackAnnotatorState.STATE_VARIABLES
								localState = StableEnvironmentState.STABLE
							}
							else if (locationName.equals(XSTSNamings.environmentFinishLocationName)) {
								state = BackAnnotatorState.STATE_VARIABLES
								localState = StableEnvironmentState.ENVIRONMENT
							}
							else if (locationName.equals(XSTSNamings.initialLocationName)) {
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
									val variable = split.head
									val value = split.last
									
									switch (localState) {
										case STABLE: {
											val index = Integer.parseInt(value)
											val potentialStateString = '''«variable» == «index»'''
											if (xStsUppaalQueryGenerator.isSourceState(potentialStateString)) {
												val instanceState = xStsUppaalQueryGenerator.getSourceState(potentialStateString)
												val controlState = instanceState.key
												val instance = instanceState.value
												if (index > 0) {
													step.addInstanceState(instance, controlState)
													activatedStates += controlState
												}
											}
											else if (xStsUppaalQueryGenerator.isSourceVariable(variable)) {
												val instanceVariable = xStsUppaalQueryGenerator.getSourceVariable(variable)
												step.addInstanceVariableState(instanceVariable.value, instanceVariable.key, value)
											}
											else if (xStsUppaalQueryGenerator.isSourceOutEvent(variable)) {
												val systemOutEvent = xStsUppaalQueryGenerator.getSourceOutEvent(variable)
												if (value.equals("1")) {
													val event = systemOutEvent.get(0) as Event
													val port = systemOutEvent.get(1) as Port
													val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
													step.addOutEvent(systemPort, event)
													// Denoting that this event has been actually raised
													raisedOutEvents += new Pair(systemPort, event)
												}
											}
											else if (xStsUppaalQueryGenerator.isSourceOutEventParamater(variable)) {
												val systemOutEvent = xStsUppaalQueryGenerator.getSourceOutEventParamater(variable)
												val event = systemOutEvent.get(0) as Event
												val port = systemOutEvent.get(1) as Port
												val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
												val parameter = systemOutEvent.get(2) as ParameterDeclaration
												step.addOutEventWithStringParameter(systemPort, event, parameter, value)
												// Will check in localState == StableEnvironmentState.ENVIRONMENT, if it is valid
											}
										}
										case ENVIRONMENT: {
											if (xStsUppaalQueryGenerator.isSourceInEvent(variable)) {
												val systemInEvent = xStsUppaalQueryGenerator.getSourceInEvent(variable)
												if (value.equals("1")) {
													val event = systemInEvent.get(0) as Event
													val port = systemInEvent.get(1) as Port
													val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
													step.addInEvent(systemPort, event)
													// Denoting that this event has been actually raised
													raisedInEvents += new Pair(systemPort, event)
												}
											}
											else if (xStsUppaalQueryGenerator.isSourceInEventParamater(variable)) {
												val systemInEvent = xStsUppaalQueryGenerator.getSourceInEventParamater(variable)
												val event = systemInEvent.get(0) as Event
												val port = systemInEvent.get(1) as Port
												val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
												val parameter = systemInEvent.get(2) as ParameterDeclaration
												step.addInEventWithParameter(systemPort, event, parameter, value)
												// Will check in localState == StableEnvironmentState.ENVIRONMENT, if it is valid
											}
										}
										default: {
											throw new IllegalStateException("Not known state")
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
									step.checkStates(raisedOutEvents, activatedStates)
									// Creating a new step
									trace.steps += step
									step = createStep
								}
							}
							if (localState == StableEnvironmentState.ENVIRONMENT) {
								// Deleting events that are not raised (parameter values are always present)
								step.checkInEvents(raisedInEvents)
								// Add schedule
								step.addComponentScheduling
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
		if (sortTrace) {
			trace.sortInstanceStates
		}
		return trace
	}
	
	protected def void checkStates(Step step, Set<Pair<Port, Event>> raisedOutEvents,
			Set<State> activatedStates) {
		val raiseEventActs = step.outEvents
		for (raiseEventAct : raiseEventActs) {
			if (!raisedOutEvents.contains(new Pair(raiseEventAct.port, raiseEventAct.event))) {
				EcoreUtil.delete(raiseEventAct)
			}
		}
		val instanceStates = step.instanceStateConfigurations
		for (instanceState : instanceStates) {
			// A state is active if all of its ancestor states are active
			val ancestorStates = instanceState.state.ancestors
			if (!activatedStates.containsAll(ancestorStates)) {
				EcoreUtil.delete(instanceState)
			}
		}
		raisedOutEvents.clear
		activatedStates.clear
	}
	
	protected def void checkInEvents(Step step, Set<Pair<Port, Event>> raisedInEvents) {
		val raiseEventActs = step.actions.filter(RaiseEventAct).toList
		for (raiseEventAct : raiseEventActs) {
			if (!raisedInEvents.contains(new Pair(raiseEventAct.port, raiseEventAct.event))) {
				EcoreUtil.delete(raiseEventAct)
			}
		}
		raisedInEvents.clear
	}
	
}

enum StableEnvironmentState {INITIAL, STABLE, ENVIRONMENT, OTHER}
