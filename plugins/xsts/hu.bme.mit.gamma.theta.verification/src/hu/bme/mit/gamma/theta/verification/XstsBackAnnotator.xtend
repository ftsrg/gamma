package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.util.IndexHierarchy
import hu.bme.mit.gamma.querygenerator.ThetaQueryGenerator
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.verification.util.TraceBuilder
import java.util.Collection
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class XstsBackAnnotator {
	
	protected final Component component
	protected final ThetaQueryGenerator thetaQueryGenerator
	
	protected final extension TraceBuilder traceBuilder = TraceBuilder.INSTANCE
	
	new(ThetaQueryGenerator thetaQueryGenerator) {
		this.thetaQueryGenerator = thetaQueryGenerator
		this.component = thetaQueryGenerator.component
	}
	
	def handleState(String potentialStateString, Step step,
			Collection<? super State> activatedStates) {
		val instanceState = thetaQueryGenerator.getSourceState(potentialStateString)
		val controlState = instanceState.key
		val instance = instanceState.value
		step.addInstanceState(instance, controlState)
		activatedStates += controlState
	}
	
	def handleVariable(String id, String value, Step step) {
		val instanceVariable = thetaQueryGenerator.getSourceVariable(id)
		val instance = instanceVariable.value
		val variable = instanceVariable.key
		// Getting fields and indexes regardless of primitive or complex types
		// In the case of primitive types, these hierarchies will be empty
		val field = thetaQueryGenerator.getSourceVariableFieldHierarchy(id)
		val indexPairs = value.parseArray
		//
		for (indexPair : indexPairs) {
			val index = indexPair.key
			val parsedValue = indexPair.value
			step.addInstanceVariableState(instance, variable, field, index, parsedValue)
		}
	}
	
	def handleOutEvent(String id, String value, Step step,
			Collection<? super Pair<Port, Event>> raisedOutEvents) {
		val systemOutEvent = thetaQueryGenerator.getSourceOutEvent(id)
		if (value == "true" || value == "1") { // For Theta and UPPAAL
			val event = systemOutEvent.get(0) as Event
			val port = systemOutEvent.get(1) as Port
			val systemPort = port.boundTopComponentPort // Back-tracking to the system port
			step.addOutEvent(systemPort, event)
			// Denoting that this event has been actually
			raisedOutEvents += systemPort -> event
		}
	}
	
	def handleOutEventParameter(String id, String value, Step step) {
		val systemOutEvent = thetaQueryGenerator.getSourceOutEventParameter(id)
		val event = systemOutEvent.get(0) as Event
		val port = systemOutEvent.get(1) as Port
		val systemPort = port.boundTopComponentPort // Back-tracking to the system port
		val parameter = systemOutEvent.get(2) as ParameterDeclaration
		// Getting fields and indexes regardless of primitive or complex types
		val field = thetaQueryGenerator.getSourceOutEventParameterFieldHierarchy(id)
		val indexPairs = value.parseArray
		//
		for (indexPair : indexPairs) {
			val index = indexPair.key
			val parsedValue = indexPair.value
			step.addOutEventWithStringParameter(systemPort, event, parameter,
					field, index, parsedValue)
		}
	}
	
	def handleSynchronousInEvent(String id, String value, Step step,
			Collection<? super Pair<Port, Event>> raisedInEvents) {
		val systemInEvent = thetaQueryGenerator.getSynchronousSourceInEvent(id)
		if (value == "true" || value == "1") { // For Theta and UPPAAL
			val event = systemInEvent.get(0) as Event
			val port = systemInEvent.get(1) as Port
			val systemPort = port.boundTopComponentPort // Back-tracking to the system port
			step.addInEvent(systemPort, event)
			// Denoting that this event has been actually raised
			raisedInEvents += systemPort -> event
		}
	}
	
	def handleSynchronousInEventParameter(String id, String value, Step step) {
		val systemInEvent = thetaQueryGenerator.getSynchronousSourceInEventParameter(id)
		val event = systemInEvent.get(0) as Event
		val port = systemInEvent.get(1) as Port
		val systemPort = port.boundTopComponentPort // Back-tracking to the system port
		val parameter = systemInEvent.get(2) as ParameterDeclaration
		// Getting fields and indexes regardless of primitive or complex types
		val field = thetaQueryGenerator.getSynchronousSourceInEventParameterFieldHierarchy(id)
		val indexPairs = value.parseArray
		//
		for (indexPair : indexPairs) {
			val index = indexPair.key
			val parsedValue = indexPair.value
			step.addInEventWithParameter(systemPort, event, parameter, field, index, parsedValue)
		}
	}
	
	def handleAsynchronousInEvent(String id, String value, Step step,
			Collection<? super Pair<Port, Event>> raisedInEvents) {
		val messageQueue = thetaQueryGenerator.getAsynchronousSourceMessageQueue(id)
		val values = value.parseArray
		val stringEventId = values.findFirst[it.key == new IndexHierarchy(0)]?.value
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
					step.addInEvent(systemPort, event)
					// Denoting that this event has been actually
					raisedInEvents += systemPort -> event
				}
			}
		}
	}
	
	def handleAsynchronousInEventParameter(String id, String value, Step step) {
		val systemInEvent = thetaQueryGenerator.getAsynchronousSourceInEventParameter(id)
		val event = systemInEvent.get(0) as Event
		val port = systemInEvent.get(1) as Port
		val systemPort = port.boundTopComponentPort // Back-tracking to the system port
		// Sometimes message queues can contain internal events too
		if (component.contains(systemPort)) {
			val parameter = systemInEvent.get(2) as ParameterDeclaration
			// Getting fields and indexes regardless of primitive or complex types
			val field = thetaQueryGenerator.getAsynchronousSourceInEventParameterFieldHierarchy(id)
			val indexPairs = value.parseArray
			val firstElement = indexPairs.findFirst[it.key == new IndexHierarchy(0)]
			if (firstElement !== null) { // Default value, not necessary to add explicitly
				// The slave queue should be a single-size array - sometimes there are more elements?
				val index = firstElement.key
				index.removeFirst // As the slave queue is an array, we remove the first index
				//
				val parsedValue = firstElement.value
				step.addInEventWithParameter(systemPort, event,
						parameter, field, index, parsedValue)
			}
		}
	}
	
	// Not every index is retrieved - if an index is missing, its value is the default value
	protected def List<Pair<IndexHierarchy, String>> parseArray(String value) {
		// (array (0 10) (1 11) (default 0))
		val values = newArrayList
		if (value.isArray) {
			val unwrapped = thetaQueryGenerator.unwrap(value).substring("array ".length) // (0 10) (default 0)
			val splits = unwrapped.parseAlongParentheses // 0 10, default array
			for (split : splits) {
				val splitPair = split.split(" ") // 0, 10
				val index = splitPair.get(0) // 0
				if (!index.equals("default")) { // Not parsing default values
					val parsedIndex = Integer.parseInt(index) // 0
					val storedValue = splitPair.get(1) // 10
					val parsedValues = storedValue.parseArray
					for (parsedValue : parsedValues) {
						val indexHierarchy = parsedValue.key
						indexHierarchy.prepend(parsedIndex) // So the "parent index" will be retrieved earlier
						val stringValue = parsedValue.value
						values += indexHierarchy -> stringValue
					}
				}
			}
			return values
		}
		else {
			return #[new IndexHierarchy -> value]
		}
	}
	
	protected def parseAlongParentheses(String line) {
		val result = newArrayList
		var unclosedParanthesisCount = 0
		var firstParanthesisIndex = 0
		for (var i = 0; i < line.length; i++) {
			val character = line.charAt(i).toString
			if (character == "(") {
				unclosedParanthesisCount++
				if (unclosedParanthesisCount == 1) {
					firstParanthesisIndex = i
				}
			}
			else if (character == ")") {
				unclosedParanthesisCount--
				if (unclosedParanthesisCount == 0) {
					result += line.substring(firstParanthesisIndex + 1, i)
				}
			}
		}
		return result
	}
	
	protected def boolean isArray(String value) {
		return value.startsWith("(array ")
	}
	
}