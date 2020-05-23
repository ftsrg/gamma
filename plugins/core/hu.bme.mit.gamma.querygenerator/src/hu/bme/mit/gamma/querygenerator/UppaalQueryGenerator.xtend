package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator
import hu.bme.mit.gamma.querygenerator.patterns.InstanceStates
import hu.bme.mit.gamma.querygenerator.patterns.StatesToLocations
import hu.bme.mit.gamma.transformation.util.queries.TopSyncSystemOutEvents
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace
import java.util.logging.Level
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.uppaal.util.Namings.*

class UppaalQueryGenerator extends AbstractQueryGenerator {
	
	new(G2UTrace trace) {
		val traceabilitySet = trace.eResource.resourceSet
		checkArgument(traceabilitySet !== null)
		this.engine = ViatraQueryEngine.on(new EMFScope(traceabilitySet))
	}
	
	override String parseRegularQuery(String text, TemporalOperator operator) {
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
	
	override String parseLeadsToQuery(String first, String second) {
		var result = first.parseIdentifiers + " && isStable --> " + second.parseIdentifiers + " && isStable"
		return result
	}
	
	protected override String getTargetStateName(String stateName) {
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
	
	protected override String getTargetVariableName(String variableName) {
		val splittedStateName = variableName.unwrap.split("\\.")
		return getVariableName(splittedStateName.get(1), splittedStateName.get(0))
	}
	
	protected override String getTargetOutEventName(String portEventName) {
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).allMatches) {
			val name = getSystemOutEventName(eventsMatch.systemPort, eventsMatch.event)
			if (name.equals(portEventName)) {
				return getOutEventName(eventsMatch.event, eventsMatch.port, eventsMatch.instance)
			}
		}
		throw new IllegalArgumentException("Not known system event: " + portEventName)
	}
	
	protected override String getTargetOutEventParameterName(String portEventParameterName) {
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).allMatches) {
			val systemPort = eventsMatch.systemPort
			val event = eventsMatch.event
			for (ParameterDeclaration parameter : event.parameterDeclarations) {
				if (portEventParameterName.equals(getSystemOutEventParameterName(systemPort, event, parameter))) {
					return getOutValueOfName(event, eventsMatch.port, parameter, eventsMatch.instance)
				}
			}
		}
		throw new IllegalArgumentException("Not known system parameter event: " + portEventParameterName)
	}
	
}