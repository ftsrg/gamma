/********************************************************************************
 * Copyright (c) 2025-2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import java.util.Collection
import java.util.Map
import java.util.Map.Entry

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class OutEventCheckPostprocessor extends VerificationPostprocessor {
	//
	protected final Collection<Collection<? extends Entry<Port, Event>>> raisedEvents = newLinkedHashSet
	//
	
	override execute(ExecutionTrace trace) {
		trace.saveTrace
		
		val raisedEvents = <Entry<Port, Event>>newArrayList
		
		val steps = trace.steps
		for (step : steps) {
			val outEvents = step.outEvents
			for (outEvent : outEvents) {
				val port = outEvent.port
				val event = outEvent.event
				raisedEvents += Map.entry(port, event)
			}
		}
		
		this.raisedEvents += raisedEvents
		
		return raisedEvents
	}
	
	//
	
	def getRaisedEvents() {
		return raisedEvents
	}
	
	def getAllRaisedEvents() {
		return raisedEvents.flatten.toSet
	}
	
	//
	
	def getUnraisedEvents() {
		val unraisedEvents = newLinkedHashSet
		
		val topComponent = topComponent
		unraisedEvents += topComponent.outputEvents2
		unraisedEvents -= getAllRaisedEvents
		
		return unraisedEvents
	}
	
}