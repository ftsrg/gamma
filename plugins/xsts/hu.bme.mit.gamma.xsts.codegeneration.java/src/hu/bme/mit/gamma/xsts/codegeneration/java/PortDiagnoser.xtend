package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.RealizationMode
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import hu.bme.mit.gamma.statechart.model.interface_.Interface
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