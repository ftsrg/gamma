package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.RealizationMode
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import hu.bme.mit.gamma.statechart.model.interface_.Interface
import java.util.Collection
import java.util.Collections
import java.util.Set

class EventHandler {
	
	/** 
	 * Returns all events of the given ports that go in the given direction through the ports.
	 */
	def getSemanticEvents(Collection<? extends Port> ports, EventDirection direction) {
		val events =  newHashSet
		for (anInterface : ports.filter[it.interfaceRealization.realizationMode == RealizationMode.PROVIDED].map[it.interfaceRealization.interface]) {
			events.addAll(anInterface.getAllEvents(direction.oppositeDirection))
		}
		for (anInterface : ports.filter[it.interfaceRealization.realizationMode == RealizationMode.REQUIRED].map[it.interfaceRealization.interface]) {
			events.addAll(anInterface.getAllEvents(direction))
		}
		return events
	}
	
	/**
	 * Converts IN directions to OUT and vice versa.
	 */
	def getOppositeDirection(EventDirection direction) {
		switch (direction) {
			case EventDirection.IN:
				return EventDirection.OUT
			case EventDirection.OUT:
				return EventDirection.IN
			default:
				throw new IllegalArgumentException("Not known direction: " + direction)
		} 
	}
	
	/** 
	 * Returns all events of a given interface whose direction is not oppositeDirection.
	 * The parent interfaces are taken into considerations as well.
	 */ 
	 def Set<Event> getAllEvents(Interface anInterface, EventDirection oppositeDirection) {
		if (anInterface === null) {
			return Collections.EMPTY_SET
		}
		val eventSet = newHashSet
		for (parentInterface : anInterface.parents) {
			eventSet.addAll(parentInterface.getAllEvents(oppositeDirection))
		}
		for (event : anInterface.events.filter[it.direction != oppositeDirection].map[it.event]) {
			eventSet.add(event)
		}
		return eventSet
	}
	
}