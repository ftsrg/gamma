package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class ThetaReferenceSerializer implements AbstractReferenceSerializer {
	// Singleton
	public static final ThetaReferenceSerializer INSTANCE = new ThetaReferenceSerializer
	protected new() {}
	//
	
	override getId(State state, Region parentRegion, SynchronousComponentInstance instance) {
		return '''«state.getSingleTargetStateName(parentRegion, instance)»«FOR parent : state.ancestors BEFORE " && " SEPARATOR " && "»«parent.getSingleTargetStateName(parent.parentRegion, instance)»«ENDFOR»'''
	}
	
	def protected getSingleTargetStateName(State state, Region parentRegion, SynchronousComponentInstance instance) {
		return '''«parentRegion.customizeName(instance)» == «state.customizeName»'''
	}
	
	override getId(VariableDeclaration variable, SynchronousComponentInstance instance) {
		return variable.customizeName(instance)
	}
	
	override getId(Event event, Port port, SynchronousComponentInstance instance) {
		if (port.isInputEvent(event)) {
			event.customizeInputName(port, instance)
		}
		return event.customizeOutputName(port, instance)
	}
	
	override getId(Event event, Port port, ParameterDeclaration parameter, SynchronousComponentInstance instance) {
		if (port.isInputEvent(event)) {
			parameter.customizeInName(port, instance)
		}
		return parameter.customizeOutName(port, instance)
	}
	
}