package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.querygenerator.patterns.InstanceStates
import hu.bme.mit.gamma.querygenerator.patterns.InstanceVariables
import hu.bme.mit.gamma.querygenerator.patterns.StatesToLocations
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.Region
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopSyncSystemOutEvents
import java.util.ArrayList
import java.util.List
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.uppaal.util.Namings.*

class QueryGenerator {
	
	protected final Logger logger = Logger.getLogger("GammaLogger")
	protected final ViatraQueryEngine engine
	
	new (ResourceSet traceabilitySet) {
		this.engine = ViatraQueryEngine.on(new EMFScope(traceabilitySet))
	}
	
	
	def List<String> getStateNames() {
		val stateNames = new ArrayList<String>()
		for (InstanceStates.Match statesMatch : InstanceStates.Matcher.on(engine).getAllMatches()) {
			val entry = statesMatch.getInstanceName() + "." + getFullRegionPathName(statesMatch.getParentRegion()) + "." + statesMatch.getStateName()
			if (!statesMatch.getState().getName().startsWith("LocalReaction")) {
				stateNames.add(entry)				
			}
		}
		return stateNames
	}
	
	def List<String> getVariableNames() {
		val variableNames = new ArrayList<String>()
		for (InstanceVariables.Match variableMatch : InstanceVariables.Matcher.on(engine).getAllMatches()) {
			val entry = variableMatch.getInstance().getName() + "." + variableMatch.getVariable().getName()
			variableNames.add(entry)
		}
		return variableNames
	}
	
	def String getSystemOutEventName(Port systemPort, Event event) {
		return systemPort.getName() + "." + event.getName()
	}
	
	def List<String> getSystemOutEventNames() {
		val eventNames = new ArrayList<String>()
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches()) {
			val entry = getSystemOutEventName(eventsMatch.getSystemPort(), eventsMatch.getEvent())
			eventNames.add(entry)
		}
		return eventNames
	}
	
	def String getSystemOutEventParameterName(Port systemPort, Event event, ParameterDeclaration parameter) {
		return getSystemOutEventName(systemPort, event) + "::" + parameter.getName()
	}
	
	def List<String> getSystemOutEventParameterNames() {
		val parameterNames = new ArrayList<String>()
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches()) {
			val event = eventsMatch.getEvent()
			for (ParameterDeclaration parameter : event.getParameterDeclarations()) {
				val systemPort = eventsMatch.getSystemPort()
				val entry = getSystemOutEventParameterName(systemPort, event, parameter)
				parameterNames.add(entry)
			}
		}
		return parameterNames
	}
	
	/** Returns the chain of regions from the given lowest region to the top region. 
	 */
	def String getFullRegionPathName(Region lowestRegion) {
		if (!(lowestRegion.eContainer() instanceof State)) {
			return lowestRegion.getName()
		}
		val fullParentRegionPathName = getFullRegionPathName(lowestRegion.eContainer().eContainer() as Region)
		return fullParentRegionPathName + "." + lowestRegion.getName() // Only regions are in path - states could be added too
	}
	
	def String parseRegular(String text, TemporalOperator operator) {
		var result = text
		if (text.contains("deadlock")) {
			return text
		}
		val stateNames = this.getStateNames()
		val variableNames = this.getVariableNames()
		val systemOutEventNames = this.getSystemOutEventNames()
		val systemOutEventParameterNames = this.getSystemOutEventParameterNames()
		for (String stateName : stateNames) {
			if (result.contains("(" + stateName + ")")) {
				val uppaalStateName = getUppaalStateName(stateName)
				// The parentheses need to be \-d
				result = result.replaceAll("\\(" + stateName + "\\)", "\\(" + uppaalStateName + "\\)")
			}
			// Checking the negations
			if (result.contains("(!" + stateName + ")")) {
				val uppaalStateName = getUppaalStateName(stateName)
				// The parentheses need to be \-d
				result = result.replaceAll("\\(!" + stateName + "\\)", "\\(!" + uppaalStateName + "\\)")
			}
		}
		for (String variableName : variableNames) {
			if (result.contains("(" + variableName + ")")) {
				val uppaalVariableName = getUppaalVariableName(variableName)
				result = result.replaceAll("\\(" + variableName + "\\)", "\\(" + uppaalVariableName + "\\)")
			}
			// Checking the negations
			if (result.contains("(!" + variableName + ")")) {
				val uppaalVariableName = getUppaalVariableName(variableName)
				result = result.replaceAll("\\(!" + variableName + "\\)", "\\(!" + uppaalVariableName + "\\)")
			}
		}
		for (String systemOutEventName : systemOutEventNames) {
			if (result.contains("(" + systemOutEventName + ")")) {
				val uppaalVariableName = getUppaalOutEventName(systemOutEventName)
				result = result.replaceAll("\\(" + systemOutEventName + "\\)", "\\(" + uppaalVariableName + "\\)")
			}
			// Checking the negations
			if (result.contains("(!" + systemOutEventName + ")")) {
				val uppaalVariableName = getUppaalOutEventName(systemOutEventName)
				result = result.replaceAll("\\(!" + systemOutEventName + "\\)", "\\(!" + uppaalVariableName + "\\)")
			}
		}
		for (String systemOutEventParameterName : systemOutEventParameterNames) {
			if (result.contains("(" + systemOutEventParameterName + ")")) {
				val uppaalVariableName = getUppaalOutEventParameterName(systemOutEventParameterName)
				result = result.replaceAll("\\(" + systemOutEventParameterName + "\\)", "\\(" + uppaalVariableName + "\\)")
			}
			// Checking the negations
			if (result.contains("(!" + systemOutEventParameterName + ")")) {
				val uppaalVariableName = getUppaalOutEventParameterName(systemOutEventParameterName)
				result = result.replaceAll("\\(!" + systemOutEventParameterName + "\\)", "\\(!" + uppaalVariableName + "\\)")
			}
		}
		result = "(" + result + ")"
		if (!operator.equals(TemporalOperator.MIGHT_ALWAYS) && !operator.equals(TemporalOperator.MUST_ALWAYS)) {
			// It is pointless to add isStable in the case of A[] and E[]
			result += " && isStable"
		}
		else {
			// Instead this is added
			result += " || !isStable"
		}
		return result
	}
	
	def String getUppaalStateName(String stateName) {
		logger.log(Level.INFO, stateName)
		val splittedStateName = stateName.split("\\.")
		for (InstanceStates.Match match : InstanceStates.Matcher.on(engine).getAllMatches(null, splittedStateName.get(0),
				null, splittedStateName.get(splittedStateName.length - 2) /* parent region */,
				null, splittedStateName.get(splittedStateName.length - 1) /* state */)) {
			val parentRegion = match.getParentRegion()
			val templateName = parentRegion.getTemplateName(match.instance)
			val processName = "P_" + templateName
			val locationNames = new StringBuilder("(")
			for (String locationName : StatesToLocations.Matcher.on(engine).getAllValuesOflocationName(null,
					match.getState().getName(),
					templateName /*Must define templateName too as there are states with the same (same statechart types)*/)) {
				val templateLocationName = processName +  "." + locationName
				if (locationNames.length() == 1) {
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
			return locationNames.toString()
		}
		throw new IllegalArgumentException("Not known state!")
	}
	
	def String getUppaalVariableName(String variableName) {		
		val splittedStateName = variableName.split("\\.")
		return splittedStateName.get(1) + "Of" + splittedStateName.get(0)
	}
	
	def String getUppaalOutEventName(String portEventName) {
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches()) {
			val name = getSystemOutEventName(eventsMatch.getSystemPort(), eventsMatch.getEvent())
			if (name.equals(portEventName)) {
				return getOutEventName(eventsMatch.getEvent(), eventsMatch.getPort(), eventsMatch.getInstance())
			}
		}
		throw new IllegalArgumentException("Not known system event: " + portEventName)
	}
	
	def String getUppaalOutEventParameterName(String portEventParameterName) {
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches()) {
			val systemPort = eventsMatch.getSystemPort()
			val event = eventsMatch.getEvent()
			for (ParameterDeclaration parameter : event.getParameterDeclarations()) {
				if (portEventParameterName.equals(getSystemOutEventParameterName(systemPort, event, parameter))) {
					return getValueOfName(event, eventsMatch.getPort(), eventsMatch.getInstance())
				}
			}
		}
		throw new IllegalArgumentException("Not known system event: " + portEventParameterName)
	}
	
}