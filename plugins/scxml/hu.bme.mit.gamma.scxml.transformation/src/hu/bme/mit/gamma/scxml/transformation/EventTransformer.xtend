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
package hu.bme.mit.gamma.scxml.transformation

import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Interface

import static hu.bme.mit.gamma.scxml.transformation.Namings.*

class EventTransformer extends AtomicElementTransformer {
	new(StatechartTraceability traceability) {
		super(traceability)
	}
	
	def getOrTransformInternalEvent(Interface gammaInterface, String eventName) {
		if (traceability.containsInternalEvent(gammaInterface -> eventName)) {
			return traceability.getInternalEvent(gammaInterface -> eventName)
		}
		else {
			return transformInternalEvent(gammaInterface, eventName)
		}
	}
	
	protected def transformInternalEvent(Interface gammaInterface, String eventName) {
		val gammaEvent = transformEvent(gammaInterface, EventDirection.INTERNAL, eventName)
		gammaEvent.name = getInternalEventName(eventName)
		traceability.putInternalEvent(gammaInterface -> eventName, gammaEvent)
		return gammaEvent
	}
	
	def getOrTransformInEvent(Interface gammaInterface, String eventName) {
		if (traceability.containsInEvent(gammaInterface -> eventName)) {
			return traceability.getInEvent(gammaInterface -> eventName)
		}
		else {
			return transformInEvent(gammaInterface, eventName)
		}
	}
	
	protected def transformInEvent(Interface gammaInterface, String eventName) {
		val gammaEvent = transformEvent(gammaInterface, EventDirection.IN, eventName)
		gammaEvent.name = getInEventName(eventName)
		traceability.putInEvent(gammaInterface -> eventName, gammaEvent)
		return gammaEvent
	}
	
	def getOrTransformOutEvent(Interface gammaInterface, String eventName) {
		if (traceability.containsOutEvent(gammaInterface -> eventName)) {
			return traceability.getOutEvent(gammaInterface -> eventName)
		}
		else {
			return transformOutEvent(gammaInterface, eventName)
		}
	}
	
	protected def transformOutEvent(Interface gammaInterface, String eventName) {
		val gammaEvent = transformEvent(gammaInterface, EventDirection.OUT, eventName)
		gammaEvent.name = getOutEventName(eventName)
		traceability.putOutEvent(gammaInterface -> eventName, gammaEvent)
		return gammaEvent
	}
	
	// This method assumes that the transformation of the interface
	// of the respective event has already happened when we transform the event.
	private def transformEvent(Interface gammaInterface, EventDirection direction, String eventName) {
		val gammaEvent = createEvent
		val gammaEventDeclaration = createEventDeclaration
		gammaEventDeclaration.event = gammaEvent
		gammaEventDeclaration.direction = direction
		
		gammaInterface.events += gammaEventDeclaration
		return gammaEvent
	}
	
}