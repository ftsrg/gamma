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
import java.util.logging.Logger
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

import static com.google.common.base.Preconditions.checkArgument
import static hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

abstract class AbstractQueryGenerator {
		
	protected final Logger logger = Logger.getLogger("GammaLogger")
	protected ViatraQueryEngine engine
		
	def wrap(String id) {
		return "(" + id + ")"
	}
	
	def unwrap(String id) {
		return id.replaceAll("\\(", "").replaceAll("\\)", "")
	}
	
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
	
	private def String parseIdentifiers(String text) {
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
				val uppaalStateName = getTargetStateName(stateName)
				// The parentheses need to be \-d
				result = result.replaceAll(stateName, uppaalStateName)
			}
		}
		for (String variableName : variableNames) {
			if (result.contains(variableName)) {
				val uppaalVariableName = getTargetVariableName(variableName)
				result = result.replaceAll(variableName, uppaalVariableName)
			}
		}
		for (String systemOutEventName : systemOutEventNames) {
			if (result.contains(systemOutEventName)) {
				val uppaalVariableName = getTargetOutEventName(systemOutEventName)
				result = result.replaceAll(systemOutEventName, uppaalVariableName)
			}
		}
		for (String systemOutEventParameterName : systemOutEventParameterNames) {
			if (result.contains(systemOutEventParameterName)) {
				val uppaalVariableName = getTargetOutEventParameterName(systemOutEventParameterName)
				result = result.replaceAll(systemOutEventParameterName, uppaalVariableName)
			}
		}
		return result.wrap
	}
	
	def String parseRegularQuery(String text, TemporalOperator operator) {
		checkArgument(!operator.equals(TemporalOperator.LEADS_TO))
		var result = text.parseIdentifiers
		if (!operator.equals(TemporalOperator.MIGHT_ALWAYS) && !operator.equals(TemporalOperator.MUST_ALWAYS)) {
			// It is pointless to add isStable in the case of A[] and E[]
			result += " && isStable"
		}
		else {
			// Instead this is added
			result += " || !isStable"
		}
		return operator.operator + " " + result
	}
	
	def String parseLeadsToQuery(String first, String second) {
		var result = first.parseIdentifiers + " && isStable --> " + second.parseIdentifiers + " && isStable"
		return result
	}
	
	protected abstract def String getTargetStateName(String stateName);
	
	protected abstract def String getTargetVariableName(String variableName);
	
	protected abstract def String getTargetOutEventName(String portEventName);
	
	protected abstract def String getTargetOutEventParameterName(String portEventParameterName);
	
}