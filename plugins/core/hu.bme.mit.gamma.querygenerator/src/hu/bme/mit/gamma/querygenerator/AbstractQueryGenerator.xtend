package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator
import hu.bme.mit.gamma.querygenerator.patterns.InstanceStates
import hu.bme.mit.gamma.querygenerator.patterns.InstanceVariables
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.Region
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.transformation.util.queries.TopSyncSystemOutEvents
import java.util.List
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

import static com.google.common.base.Preconditions.checkArgument
import static hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

abstract class AbstractQueryGenerator {
		
	protected ViatraQueryEngine engine
		
	def wrap(String id) {
		return "(" + id + ")"
	}
	
	def unwrap(String id) {
		return id.replaceAll("\\(", "").replaceAll("\\)", "")
	}
	
	// Gamma identifiers
	
	def List<String> getStateNames() {
		val stateNames = newArrayList
		for (InstanceStates.Match statesMatch : InstanceStates.Matcher.on(engine).allMatches) {
			val stateName = statesMatch.state.name
			val entry = getStateName(statesMatch.instance, statesMatch.parentRegion, statesMatch.state)
			if (!stateName.startsWith("LocalReaction")) {
				stateNames.add(entry)				
			}
		}
		return stateNames
	}
	
	def getStateName(SynchronousComponentInstance instance, Region parentRegion, State state) {
		return (instance.name + "." + getFullRegionPathName(parentRegion) + "." + state.name).wrap
	}
	
	def List<String> getVariableNames() {
		val variableNames = newArrayList
		for (InstanceVariables.Match variableMatch : InstanceVariables.Matcher.on(engine).allMatches) {
			val entry = variableMatch.instance.getVariableName(variableMatch.variable)
			variableNames.add(entry)
		}
		return variableNames
	}
	
	def getVariableName(SynchronousComponentInstance instance, VariableDeclaration variable) {
		return (instance.name + "." + variable.name).wrap
	}
	
	def List<String> getSystemOutEventNames() {
		val eventNames = newArrayList
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).allMatches) {
			val entry = getSystemOutEventName(eventsMatch.systemPort, eventsMatch.event)
			eventNames.add(entry)
		}
		return eventNames
	}
	
	def String getSystemOutEventName(Port systemPort, Event event) {
		return (systemPort.name + "." + event.name).wrap
	}
	
	def List<String> getSystemOutEventParameterNames() {
		val parameterNames = newArrayList
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).allMatches) {
			val event = eventsMatch.event
			for (ParameterDeclaration parameter : event.parameterDeclarations) {
				val systemPort = eventsMatch.systemPort
				val entry = getSystemOutEventParameterName(systemPort, event, parameter)
				parameterNames.add(entry)
			}
		}
		return parameterNames
	}
	
	def String getSystemOutEventParameterName(Port systemPort, Event event, ParameterDeclaration parameter) {
		return (getSystemOutEventName(systemPort, event).unwrap + "::" + parameter.name).wrap
	}
	
	// Parsing identifiers
	
	protected def String parseIdentifiers(String text) {
		var result = text
		if (text.contains("deadlock")) {
			return text
		}
		val stateNames = this.getStateNames
		val variableNames = this.getVariableNames
		val systemOutEventNames = this.getSystemOutEventNames
		val systemOutEventParameterNames = this.getSystemOutEventParameterNames
		for (String stateName : stateNames) {
			if (result.contains(stateName)) {
				val targetStateName = getTargetStateName(stateName)
				// The parentheses need to be \-d
				result = result.replaceAll(stateName, targetStateName)
			}
		}
		for (String variableName : variableNames) {
			if (result.contains(variableName)) {
				val targetVariableName = getTargetVariableName(variableName)
				result = result.replaceAll(variableName, targetVariableName)
			}
		}
		for (String systemOutEventName : systemOutEventNames) {
			if (result.contains(systemOutEventName)) {
				val targetVariableName = getTargetOutEventName(systemOutEventName)
				result = result.replaceAll(systemOutEventName, targetVariableName)
			}
		}
		for (String systemOutEventParameterName : systemOutEventParameterNames) {
			if (result.contains(systemOutEventParameterName)) {
				val targetVariableName = getTargetOutEventParameterName(systemOutEventParameterName)
				result = result.replaceAll(systemOutEventParameterName, targetVariableName)
			}
		}
		return result.wrap
	}
	
	def abstract String parseRegularQuery(String text, TemporalOperator operator)
	
	def abstract String parseLeadsToQuery(String first, String second)
	
	// Getting target identifiers
	
	protected def String getTargetStateName(String stateName) {
		val splittedStateName = stateName.unwrap.split("\\.")
		val matches = InstanceStates.Matcher.on(engine).getAllMatches(null, splittedStateName.get(0),
				null, splittedStateName.get(splittedStateName.length - 2) /* parent region */,
				null, splittedStateName.get(splittedStateName.length - 1) /* state */)
		checkArgument(matches.size == 1, "Not known state: " + stateName)
		val match = matches.head
		return getTargetStateName(match.state, match.parentRegion, match.instance)
	}
	
	protected def String getTargetVariableName(String variableName) {
		for (InstanceVariables.Match instancesMatch : InstanceVariables.Matcher.on(engine).allMatches) {
			val name = getVariableName(instancesMatch.instance, instancesMatch.variable)
			if (variableName.equals(name)) {
				return getTargetVariableName(instancesMatch.variable, instancesMatch.instance)
			}
		}
		throw new IllegalArgumentException("Not known variable: " + variableName)
	}
	
	protected def String getTargetOutEventName(String portEventName) {
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).allMatches) {
			val name = getSystemOutEventName(eventsMatch.systemPort, eventsMatch.event)
			if (name.equals(portEventName)) {
				return getTargetOutEventName(eventsMatch.event, eventsMatch.port, eventsMatch.instance)
			}
		}
		throw new IllegalArgumentException("Not known system event: " + portEventName)
	}
	
	protected def String getTargetOutEventParameterName(String portEventParameterName) {
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).allMatches) {
			val systemPort = eventsMatch.systemPort
			val event = eventsMatch.event
			for (ParameterDeclaration parameter : event.parameterDeclarations) {
				if (portEventParameterName.equals(getSystemOutEventParameterName(systemPort, event, parameter))) {
					return getTargetOutEventParameterName(event, eventsMatch.port, parameter, eventsMatch.instance)
				}
			}
		}
		throw new IllegalArgumentException("Not known system parameter event: " + portEventParameterName)
	}
	
	protected abstract def String getTargetStateName(State state, Region parentRegion,
		SynchronousComponentInstance instance)
	
	protected abstract def String getTargetVariableName(VariableDeclaration variable,
		SynchronousComponentInstance instance)
	
	protected abstract def String getTargetOutEventName(Event event, Port port,
		SynchronousComponentInstance instance)
	
	protected abstract def String getTargetOutEventParameterName(Event event, Port port,
		ParameterDeclaration parameter,SynchronousComponentInstance instance)
	
}