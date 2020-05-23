package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator
import hu.bme.mit.gamma.querygenerator.patterns.StatesToLocations
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.Region
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace
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
	
	protected override String getTargetStateName(SynchronousComponentInstance instance,
			Region parentRegion, State state) {
		val templateName = parentRegion.getTemplateName(instance)
		val processName = templateName.processName
		val locationNames = new StringBuilder("(")
		for (String locationName : StatesToLocations.Matcher.on(engine).getAllValuesOflocationName(null,
				state.name,
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
	
	override protected getTargetVariableName(VariableDeclaration variable,
			SynchronousComponentInstance instance) {
		return getVariableName(variable, instance)
	}
	
	override protected getTargetOutEventName(Event event, Port port,
			SynchronousComponentInstance instance) {
		return getOutEventName(event, port, instance)
	}
	
	override protected getTargetOutEventParameterName(Event event, Port port,
			ParameterDeclaration parameter, SynchronousComponentInstance instance) {
		return getOutValueOfName(event, port, parameter, instance)
	}
	
}