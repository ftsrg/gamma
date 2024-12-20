package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State

import static extension hu.bme.mit.gamma.ocra.transformation.NamingSerializer.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*


class OcraReferenceSerializer extends ThetaReferenceSerializer {
	// Singleton
	public static final OcraReferenceSerializer INSTANCE = new OcraReferenceSerializer
	protected new() {}
	//
	
	
	override getId(State state, Region parentRegion, ComponentInstanceReferenceExpression instance) {
//		return '''«state.getSingleTargetStateName(parentRegion, instance)»«FOR parent : state.ancestors BEFORE " & " SEPARATOR " & "»«parent.getSingleTargetStateName(parent.parentRegion, instance)»«ENDFOR»'''
		return '''«state.getSingleTargetStateName(parentRegion, instance)»''' // Enough due to __Inactive__ and __history__ literals
	}
	
	override getSingleTargetStateName(State state, Region parentRegion, ComponentInstanceReferenceExpression instance) {
		return '''«parentRegion.customizeName(instance)» = «state.customizeName»'''
	}
	
	override getId(Event event, Port port, ComponentInstanceReferenceExpression instance) {
		return event.customizePortName(port, instance)
	}
	
}