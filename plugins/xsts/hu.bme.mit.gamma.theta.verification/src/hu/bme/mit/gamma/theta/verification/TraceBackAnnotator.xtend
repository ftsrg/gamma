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
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.SchedulingConstraintAnnotation
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.verification.util.TraceBuilder
import java.util.NoSuchElementException
import java.util.Scanner
import java.util.Set
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.emf.ecore.util.EcoreUtil

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class TraceBackAnnotator {
	
	protected final String XSTS_TRACE = "(XstsStateSequence"
	protected final String XSTS_STATE = "(XstsState"
	protected final String EXPL_STATE = "(ExplState"
	
	protected final Scanner traceScanner
	protected final ThetaQueryGenerator thetaQueryGenerator
	
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
		this.component = gammaPackage.components.head
		this.thetaQueryGenerator = new ThetaQueryGenerator(gammaPackage)
		this.traceScanner = traceScanner
		this.sortTrace = sortTrace
		val schedulingConstraintAnnotation = gammaPackage.annotations
			.filter(SchedulingConstraintAnnotation).head
		if (schedulingConstraintAnnotation !== null) {
			this.schedulingConstraint = schedulingConstraintAnnotation.schedulingConstraint
		}
		else {
			this.schedulingConstraint = null
		}
	}
	
	def ExecutionTrace execute() {
		//
//		try (val thetaQueryGenerator = new ThetaQueryGenerator(gammaPackage,
//				true /* As ThetaVerification calls this on separate threads */)) {
		
		// Creating the trace component
		val trace = createExecutionTrace => [
			it.component = this.component
			it.import = this.gammaPackage
			it.name = this.component.name + "Trace"
		]
		val topComponentArguments = gammaPackage.topComponentArguments
		// Note that the top component does not contain parameter declarations anymore due to the preprocessing
		checkState(topComponentArguments.size == component.parameterDeclarations.size, 
			"The number of top component arguments and top component parameters are not equal: " +
				topComponentArguments.size + " - " + component.parameterDeclarations.size)
		logger.log(Level.INFO, "The number of top component arguments is " + topComponentArguments.size)
		trace.arguments += topComponentArguments.map[it.clone]
		var step = createStep
		trace.steps += step
		// Sets for raised in and out events and activated states
		val raisedOutEvents = newHashSet
		val raisedInEvents = newHashSet
		val activatedStates = newHashSet
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
						// Adding reset
						step.actions += createReset
						line = traceScanner.nextLine.trim
						state = BackAnnotatorState.STATE_CHECK
					}
					case line.startsWith(XSTS_STATE): {
						// Deleting unnecessary in and out events
						switch (state) {
							case STATE_CHECK: {
								step.checkStates(raisedOutEvents, activatedStates)
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
								step.checkInEvents(raisedInEvents)
								// Add schedule
								step.addComponentScheduling
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
				line = thetaQueryGenerator.unwrap(line)
				val split = line.split(" ")
				val id = split.get(0)
				val value = split.get(1)
				switch (state) {
					case STATE_CHECK: {
						val potentialStateString = '''«id» == «value»'''
						if (thetaQueryGenerator.isSourceState(potentialStateString)) {
							val instanceState = thetaQueryGenerator.getSourceState(potentialStateString)
							val controlState = instanceState.key
							val instance = instanceState.value
							step.addInstanceState(instance, controlState)
							activatedStates += controlState
						}
						else if (thetaQueryGenerator.isSourceVariable(id)) {
							val instanceVariable = thetaQueryGenerator.getSourceVariable(id)
							val instance = instanceVariable.value
							val variable = instanceVariable.key
							if (thetaQueryGenerator.isSourceRecordVariable(id)) {
								val field = thetaQueryGenerator.getSourceFieldHierarchy(id)
								step.addInstanceVariableState(instance, variable, field, value)
							}
							else {
								// Primitive variable
								step.addInstanceVariableState(instance, variable, value)
							}
						}
						else if (thetaQueryGenerator.isSourceOutEvent(id)) {
							val systemOutEvent = thetaQueryGenerator.getSourceOutEvent(id)
							if (value.equals("true")) {
								val event = systemOutEvent.get(0) as Event
								val port = systemOutEvent.get(1) as Port
								val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
								step.addOutEvent(systemPort, event)
								// Denoting that this event has been actually
								raisedOutEvents += new Pair(systemPort, event)
							}
						}
						else if (thetaQueryGenerator.isSourceOutEventParamater(id)) {
							val systemOutEvent = thetaQueryGenerator.getSourceOutEventParamater(id)
							val event = systemOutEvent.get(0) as Event
							val port = systemOutEvent.get(1) as Port
							val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
							val parameter = systemOutEvent.get(2) as ParameterDeclaration
							step.addOutEventWithStringParameter(systemPort, event, parameter, value)
						}
					}
					case ENVIRONMENT_CHECK: {
						// TODO delays
						if (thetaQueryGenerator.isSourceInEvent(id)) {
							val systemInEvent = thetaQueryGenerator.getSourceInEvent(id)
							if (value.equals("true")) {
								val event = systemInEvent.get(0) as Event
								val port = systemInEvent.get(1) as Port
								val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
								step.addInEvent(systemPort, event)
								// Denoting that this event has been actually
								raisedInEvents += new Pair(systemPort, event)
							}
						}
						else if (thetaQueryGenerator.isSourceInEventParamater(id)) {
							val systemInEvent = thetaQueryGenerator.getSourceInEventParamater(id)
							val event = systemInEvent.get(0) as Event
							val port = systemInEvent.get(1) as Port
							val systemPort = port.connectedTopComponentPort // Back-tracking to the system port
							val parameter = systemInEvent.get(2) as ParameterDeclaration
							step.addInEventWithParameter(systemPort, event, parameter, value)
						}
					}
					default:
						throw new IllegalArgumentException("Not known state: " + state)
				}
			}
			// Checking the last state (in events must NOT be deleted here though)
			step.checkStates(raisedOutEvents, activatedStates)
			// Sorting if needed
			if (sortTrace) {
				trace.sortInstanceStates
			}
		} catch (NoSuchElementException e) {
			// If there are not enough lines, that means there are no environment actions
			step.actions += createReset
		}
		return trace
//		}
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
	
	enum BackAnnotatorState {INIT, STATE_CHECK, ENVIRONMENT_CHECK}
	
}