package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator
import hu.bme.mit.gamma.querygenerator.patterns.InstanceStates
import hu.bme.mit.gamma.querygenerator.patterns.InstanceVariables
import hu.bme.mit.gamma.querygenerator.patterns.StatesToLocations
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.Region
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.transformation.util.queries.TopSyncSystemOutEvents
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace
import java.util.List
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.uppaal.util.Namings.*

class QueryGenerator {
	
	protected final Logger logger = Logger.getLogger("GammaLogger")
	protected final ViatraQueryEngine engine
	
	new(G2UTrace trace) {
		val traceabilitySet = trace.eResource.resourceSet
		checkArgument(traceabilitySet !== null)
		this.engine = ViatraQueryEngine.on(new EMFScope(traceabilitySet))
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
	
	/** Returns the chain of regions from the given lowest region to the top region. 
	 */
	def String getFullRegionPathName(Region lowestRegion) {
		if (!(lowestRegion.eContainer instanceof State)) {
			return lowestRegion.name
		}
		val fullParentRegionPathName = getFullRegionPathName(lowestRegion.eContainer.eContainer as Region)
		return fullParentRegionPathName + "." + lowestRegion.name // Only regions are in path - states could be added too
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
				val uppaalStateName = getUppaalStateName(stateName)
				// The parentheses need to be \-d
				result = result.replaceAll(stateName, uppaalStateName)
			}
		}
		for (String variableName : variableNames) {
			if (result.contains(variableName)) {
				val uppaalVariableName = getUppaalVariableName(variableName)
				result = result.replaceAll(variableName, uppaalVariableName)
			}
		}
		for (String systemOutEventName : systemOutEventNames) {
			if (result.contains(systemOutEventName)) {
				val uppaalVariableName = getUppaalOutEventName(systemOutEventName)
				result = result.replaceAll(systemOutEventName, uppaalVariableName)
			}
		}
		for (String systemOutEventParameterName : systemOutEventParameterNames) {
			if (result.contains(systemOutEventParameterName)) {
				val uppaalVariableName = getUppaalOutEventParameterName(systemOutEventParameterName)
				result = result.replaceAll(systemOutEventParameterName, uppaalVariableName)
			}
		}
		result = "(" + result + ")"
		return result
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
	
	def String getUppaalStateName(String stateName) {
		logger.log(Level.INFO, stateName)
		val splittedStateName = stateName.unwrap.split("\\.")
		for (InstanceStates.Match match : InstanceStates.Matcher.on(engine).getAllMatches(null, splittedStateName.get(0),
				null, splittedStateName.get(splittedStateName.length - 2) /* parent region */,
				null, splittedStateName.get(splittedStateName.length - 1) /* state */)) {
			val parentRegion = match.parentRegion
			val templateName = parentRegion.getTemplateName(match.instance)
			val processName = templateName.processName
			val locationNames = new StringBuilder("(")
			for (String locationName : StatesToLocations.Matcher.on(engine).getAllValuesOflocationName(null,
					match.state.name,
					templateName /*Must define templateName too as there are states with the same (same statechart types)*/)) {
				val templateLocationName = processName +  "." + locationName
				if (locationNames.length == 1) {
					// First append
					locationNames.append(templateLocationName)
				}
				else {
					locationNames.append(" || " + templateLocationName)
				}
			}
			locationNames.append(")")
			if (parentRegion.subregion) {
				locationNames.append(" && " + processName + ".isActive") 
			}
			return locationNames.toString
		}
		throw new IllegalArgumentException("Not known state!")
	}
	
	def String getUppaalVariableName(String variableName) {		
		val splittedStateName = variableName.unwrap.split("\\.")
		return getVariableName(splittedStateName.get(1), splittedStateName.get(0))
	}
	
	def String getUppaalOutEventName(String portEventName) {
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).allMatches) {
			val name = getSystemOutEventName(eventsMatch.systemPort, eventsMatch.event)
			if (name.equals(portEventName)) {
				return getOutEventName(eventsMatch.event, eventsMatch.port, eventsMatch.instance)
			}
		}
		throw new IllegalArgumentException("Not known system event: " + portEventName)
	}
	
	def String getUppaalOutEventParameterName(String portEventParameterName) {
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).allMatches) {
			val systemPort = eventsMatch.systemPort
			val event = eventsMatch.event
			for (ParameterDeclaration parameter : event.parameterDeclarations) {
				if (portEventParameterName.equals(getSystemOutEventParameterName(systemPort, event, parameter))) {
					return getOutValueOfName(event, eventsMatch.port, parameter, eventsMatch.instance)
				}
			}
		}
		throw new IllegalArgumentException("Not known system event: " + portEventParameterName)
	}
	
	def wrap(String id) {
		return "(" + id + ")"
	}
	
	def unwrap(String id) {
		return id.replaceAll("\\(", "").replaceAll("\\)", "")
	}
	
}