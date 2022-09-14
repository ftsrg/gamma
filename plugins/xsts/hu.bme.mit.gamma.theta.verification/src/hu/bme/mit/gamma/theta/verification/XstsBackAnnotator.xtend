/********************************************************************************
 * Copyright (c) 2021-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.util.IndexHierarchy
import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.verification.util.TraceBuilder
import java.util.Set

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class XstsBackAnnotator {
	
	protected final Component component
	protected final ThetaQueryGenerator xStsQueryGenerator
	protected final extension XstsArrayParser arrayParser
	
	//
	protected final Set<Pair<Port, Event>> storedAsynchronousInEvents = newHashSet
	
	// To check if certain elements are actually raised/reached
	protected final Set<Pair<Port, Event>> raisedInEvents = newHashSet
	protected final Set<Pair<Port, Event>> raisedOutEvents = newHashSet
	protected final Set<State> activatedStates = newHashSet
	
	protected final extension TraceBuilder traceBuilder = TraceBuilder.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	
	new(ThetaQueryGenerator thetaQueryGenerator, XstsArrayParser arrayParser) {
		this.xStsQueryGenerator = thetaQueryGenerator
		this.component = thetaQueryGenerator.component
		this.arrayParser = arrayParser
	}
	
	def void parseState(String potentialStateString, Step step) {
		val instanceState = xStsQueryGenerator.getSourceState(potentialStateString)
		val controlState = instanceState.key
		val instance = instanceState.value
		step.addInstanceState(instance, controlState)
		activatedStates += controlState
	}
	
	def void parseVariable(String id, String value, Step step) {
		val instanceVariable = xStsQueryGenerator.getSourceVariable(id)
		val instance = instanceVariable.value
		val variable = instanceVariable.key
		// Getting fields and indexes regardless of primitive or complex types
		// In the case of primitive types, these hierarchies will be empty
		val field = xStsQueryGenerator.getSourceVariableFieldHierarchy(id)
		val indexPairs = id.parseArray(value)
		// TODO handle one-capacity arrays
		for (indexPair : indexPairs) {
			val index = indexPair.key
			val parsedValue = indexPair.value
			step.addInstanceVariableState(instance, variable, field, index, parsedValue)
		}
	}
	
	def void parseOutEvent(String id, String value, Step step) {
		val systemOutEvent = xStsQueryGenerator.getSourceOutEvent(id)
		if (value == "true" || value == "1") { // For Theta and UPPAAL
			val event = systemOutEvent.get(0) as Event
			val port = systemOutEvent.get(1) as Port
			val systemPort = port.boundTopComponentPort // Back-tracking to the system port
			step.addOutEvent(systemPort, event)
			// Denoting that this event has been actually
			raisedOutEvents += systemPort -> event
		}
	}
	
	def void parseOutEventParameter(String id, String value, Step step) {
		val systemOutEvent = xStsQueryGenerator.getSourceOutEventParameter(id)
		val event = systemOutEvent.get(0) as Event
		val port = systemOutEvent.get(1) as Port
		val systemPort = port.boundTopComponentPort // Back-tracking to the system port
		val parameter = systemOutEvent.get(2) as ParameterDeclaration
		// Getting fields and indexes regardless of primitive or complex types
		val field = xStsQueryGenerator.getSourceOutEventParameterFieldHierarchy(id)
		val indexPairs = id.parseArray(value)
		//
		for (indexPair : indexPairs) {
			val index = indexPair.key
			val parsedValue = indexPair.value
			step.addOutEventWithStringParameter(systemPort, event, parameter,
					field, index, parsedValue)
		}
	}
	
	def void parseSynchronousInEvent(String id, String value, Step step) {
		val systemInEvent = xStsQueryGenerator.getSynchronousSourceInEvent(id)
		if (value == "true" || value == "1") { // For Theta and UPPAAL
			val event = systemInEvent.get(0) as Event
			val port = systemInEvent.get(1) as Port
			val systemPort = port.boundTopComponentPort // Back-tracking to the system port
			step.addInEvent(systemPort, event)
			// Denoting that this event has been actually raised
			raisedInEvents += systemPort -> event
		}
	}
	
	def void parseSynchronousInEventParameter(String id, String value, Step step) {
		val systemInEvent = xStsQueryGenerator.getSynchronousSourceInEventParameter(id)
		val event = systemInEvent.get(0) as Event
		val port = systemInEvent.get(1) as Port
		val systemPort = port.boundTopComponentPort // Back-tracking to the system port
		val parameter = systemInEvent.get(2) as ParameterDeclaration
		// Getting fields and indexes regardless of primitive or complex types
		val field = xStsQueryGenerator.getSynchronousSourceInEventParameterFieldHierarchy(id)
		val indexPairs = id.parseArray(value)
		//
		for (indexPair : indexPairs) {
			val index = indexPair.key
			val parsedValue = indexPair.value
			step.addInEventWithParameter(systemPort, event, parameter, field, index, parsedValue)
		}
	}
	
	protected def parseAsynchronousInEvent(String id, String value) {
		val messageQueue = xStsQueryGenerator.getAsynchronousSourceMessageQueue(id)
		
		val values = id.parseArray(value)
		var stringEventId = values.findFirst[it.key == new IndexHierarchy(0)]?.value
		// Note that 'id' might be a single value instead of an array due to optimization
		if (stringEventId === null) {
			stringEventId = values.findFirst[it.key == new IndexHierarchy]?.value
		}
		
		// If null - it is a default 0 value, nothing is raised
		if (stringEventId !== null) {
			val eventId = Integer.parseInt(stringEventId)
			if (eventId != 0) { // 0 is the "empty" cell
				val portEvent = messageQueue.getEvent(eventId)
				val port = portEvent.key
				val event = portEvent.value
				val systemPort = port.boundTopComponentPort // Back-tracking to the top port
				// Sometimes message queue can contain internal events
				if (component.contains(systemPort)) {
					return systemPort -> event
				}
			}
		}
	}
	
	def void parseAsynchronousInEvent(String id, String value, Step step) {
		val systemPortEvent = id.parseAsynchronousInEvent(value)
		if (systemPortEvent !== null) {
			val systemPort = systemPortEvent.key
			val event = systemPortEvent.value
			// Checking if this event has been raised in the previous cycle
			if (!storedAsynchronousInEvents.contains(systemPort -> event)) {
				step.addInEvent(systemPort, event)
				// Denoting that this event has been actually raised
				raisedInEvents += systemPort -> event
			}
		}
	}
	
	def void parseAsynchronousInEventParameter(String id, String value, Step step) {
		val systemInEvent = xStsQueryGenerator.getAsynchronousSourceInEventParameter(id)
		val event = systemInEvent.get(0) as Event
		val port = systemInEvent.get(1) as Port
		val systemPort = port.boundTopComponentPort // Back-tracking to the system port
		// Sometimes message queues can contain internal events too
		if (component.contains(systemPort)) {
			val parameter = systemInEvent.get(2) as ParameterDeclaration
			// Getting fields and indexes regardless of primitive or complex types
			val field = xStsQueryGenerator.getAsynchronousSourceInEventParameterFieldHierarchy(id)
			val indexPairs = id.parseArray(value)
			
			var firstElement = indexPairs.findFirst[it.key == new IndexHierarchy(0)]
			// Note that 'id' might be a single value instead of an array due to optimization
			if (firstElement === null) {
				firstElement = indexPairs.findFirst[it.key == new IndexHierarchy]
			}
			
			if (firstElement !== null) { // Default value, not necessary to add explicitly
				// The slave queue should be a single-size array - sometimes there are more elements?
				val index = firstElement.key
				index.removeFirstIfNotEmpty // If the slave queue is an array, we remove the first index
				// Or we do not do anything if it is a plain value due to array optimization
				val parsedValue = firstElement.value
				step.addInEventWithParameter(systemPort, event,
						parameter, field, index, parsedValue)
			}
		}
	}
	
	///
	
	def void handleStoredAsynchronousInEvents(String id, String value) {
		val systemPortEvent = id.parseAsynchronousInEvent(value)
		if (systemPortEvent !== null) {
			val systemPort = systemPortEvent.key
			val event = systemPortEvent.value
			// Denoting that this event is already in the queue, not a new one
			storedAsynchronousInEvents += systemPort -> event
		}
	}
	
	///
	
	def void checkStates(Step step) {
		val raiseEventActs = step.outEvents
		for (raiseEventAct : raiseEventActs) {
			if (!raisedOutEvents.contains(raiseEventAct.port -> raiseEventAct.event)) {
				raiseEventAct.delete
			}
		}
		val instanceStates = step.instanceStateConfigurations
		for (instanceState : instanceStates) {
			// A state is active if all of its ancestor states are active
			val ancestorStates = instanceState.state.ancestors
			if (!activatedStates.containsAll(ancestorStates)) {
				instanceState.delete
			}
		}
		raisedOutEvents.clear // Crucial
		activatedStates.clear // Crucial
	}
	
	def void checkInEvents(Step step) {
		val raiseEventActs = step.actions.filter(RaiseEventAct).toList
		for (raiseEventAct : raiseEventActs) {
			if (!raisedInEvents.contains(raiseEventAct.port -> raiseEventAct.event)) {
				raiseEventAct.delete
			}
		}
		raisedInEvents.clear // Crucial
		storedAsynchronousInEvents.clear // Crucial
	}
	
}