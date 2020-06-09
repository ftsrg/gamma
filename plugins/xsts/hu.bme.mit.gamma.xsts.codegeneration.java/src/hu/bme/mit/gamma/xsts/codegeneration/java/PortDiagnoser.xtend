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
package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Interface
import java.util.Collection

class PortDiagnoser {
	
	def getEvents(Port port, EventDirection eventDirection) {
		val oppositeDirection = eventDirection.opposite
		val realizationMode = port.interfaceRealization.realizationMode
		if (realizationMode == RealizationMode.PROVIDED) {
			return port.interfaceRealization.interface.getEvents(eventDirection)
		}
		else if (realizationMode == RealizationMode.REQUIRED) {
			return port.interfaceRealization.interface.getEvents(oppositeDirection)
		}
		else {
			throw new IllegalArgumentException("Not known realization mode: " + realizationMode)
		}
	}
	
	def Collection<Event> getEvents(Interface _interface, EventDirection eventDirection) {
		val events = newHashSet
		val oppositeDirection = eventDirection.opposite
		for (eventDeclaration : _interface.events.filter[it.direction != oppositeDirection]) {
			events += eventDeclaration.event
		}
		for (parent : _interface.parents) {
			events += parent.getEvents(eventDirection)
		}
		return events
	}
	
	private def getOpposite(EventDirection eventDirection) {
		switch (eventDirection) {
			case IN:
				return EventDirection.OUT
			case OUT:
				return EventDirection.IN
			default:
				throw new IllegalArgumentException("Not known event direction: " + eventDirection)
		}
	}
	
}