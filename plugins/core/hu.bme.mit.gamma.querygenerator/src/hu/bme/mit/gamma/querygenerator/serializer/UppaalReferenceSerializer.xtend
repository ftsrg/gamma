package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.uppaal.util.Namings.*

class UppaalReferenceSerializer implements AbstractReferenceSerializer {
	// Singleton
	public static final UppaalReferenceSerializer INSTANCE = new UppaalReferenceSerializer
	protected new() {}
	//
	
	override getId(State state, Region parentRegion, ComponentInstanceReference instance) {
		val processName = parentRegion.getTemplateName(instance).processName
		val locationName = new StringBuilder
		locationName.append('''«processName».«state.locationName»''')
		if (parentRegion.subregion) {
			locationName.append(" && " + processName + ".isActive") 
		}
		return locationName.toString
	}
	
	override getId(VariableDeclaration variable, ComponentInstanceReference instance) {
		return getVariableName(variable, instance)
	}
	
	override getId(Event event, Port port, ComponentInstanceReference instance) {
		if (port.isInputEvent(event)) {
			return getToRaiseName(event, port, instance)
		}
		return getOutEventName(event, port, instance)
	}
	
	override getId(Event event, Port port, ParameterDeclaration parameter, ComponentInstanceReference instance) {
		if (port.isInputEvent(event)) {
			return getToRaiseValueOfName(event, port, parameter, instance)
		}
		return getOutValueOfName(event, port, parameter, instance)
	}
	
}