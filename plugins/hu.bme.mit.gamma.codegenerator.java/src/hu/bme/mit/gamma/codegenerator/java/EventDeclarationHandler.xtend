package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.statechart.model.interface_.EventDeclaration
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import hu.bme.mit.gamma.statechart.model.interface_.Interface
import java.util.Collection
import java.util.Collections
import java.util.HashSet
import java.util.Set

class EventDeclarationHandler {
	
	protected final extension TypeTransformer typeTransformer
	
	new(Trace trace) {
		this.typeTransformer = new TypeTransformer(trace)
	}
	
	/**
	 * Returns the parameter type and name of the given event declaration, e.g., long value.
	 */
	def generateParameter(EventDeclaration eventDeclaration) '''
		«IF eventDeclaration.event.parameterDeclarations.size > 0»
			«eventDeclaration.event.parameterDeclarations.eventParameterType» «eventDeclaration.event.parameterDeclarations.eventParameterValue»«ENDIF»'''
		
	/**
	 * Returns the parameter name of the given event declaration, e.g., value.
	 */
	def generateParameterValue(EventDeclaration eventDeclaration) '''
		«IF eventDeclaration.event.parameterDeclarations.size > 0»
			«eventDeclaration.event.parameterDeclarations.eventParameterValue»«ENDIF»'''
			
		
	/**
	 * Returns the Java type of the Yakindu type given in a singleton Collection as a string.
	 */
	protected def String getEventParameterType(Collection<? extends ParameterDeclaration> parameters) {
		if (!parameters.empty) {
			if (parameters.size > 1) {
				throw new IllegalArgumentException("More than one parameter: " + parameters)
			}
			return parameters.head.type.transformType
		}
		return ""
	}
	
	/**
	 * Returns the parameter name of an event, or an empty string if the event has no parameter (type is null).
	 */
	protected def getEventParameterValue(Object type) {
		if (type !== null) {
			return "value"
		}
		return ""
	}
	
	/** 
	 * Returns all events of a given interface whose direction is not oppositeDirection.
	 * The parent interfaces are taken into considerations as well.
	 */ 
	 protected def Set<Event> getAllEvents(Interface anInterface, EventDirection oppositeDirection) {
		if (anInterface === null) {
			return Collections.EMPTY_SET
		}
		val eventSet = new HashSet<Event>
		for (parentInterface : anInterface.parents) {
			eventSet.addAll(parentInterface.getAllEvents(oppositeDirection))
		}
		for (event : anInterface.events.filter[it.direction != oppositeDirection].map[it.event]) {
			eventSet.add(event)
		}
		return eventSet
	}
	
	/**
	 * Returns EventDirection.IN in case of EventDirection.OUT directions and vice versa.
	 */
	protected def getOppositeDirection(EventDirection direction) {
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
	 * Returns a "value" sting, if the given port refers to a typed event, "null" otherwise. Can be used, if the we want to create a message.
	 */
	protected def valueOrNull(org.yakindu.base.types.Event event) {
		if (event.type !== null) {
			return event.type.eventParameterValue
		}
		return "null"
	}
	
	/**
	 * Returns a "value" sting, if the given port refers to a typed event, "null" otherwise. Can be used, if the we want to create a message.
	 */
	protected def valueOrNull(Event event) {
		if (!event.parameterDeclarations.empty) {
			return event.parameterDeclarations.head.eventParameterValue
		}
		return "null"
	}
			
}