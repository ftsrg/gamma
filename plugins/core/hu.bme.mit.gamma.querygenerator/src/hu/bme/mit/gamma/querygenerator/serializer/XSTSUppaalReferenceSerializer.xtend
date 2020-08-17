package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class XSTSUppaalReferenceSerializer extends ThetaReferenceSerializer {
	// Singleton
	public static final XSTSUppaalReferenceSerializer INSTANCE = new XSTSUppaalReferenceSerializer
	protected new() {}
	//
	
	override getId(State state, Region parentRegion, ComponentInstanceReference instance) {
		return '''«state.getSingleTargetStateName(parentRegion, instance)»«FOR parent : state.ancestors BEFORE " && " SEPARATOR " && "»«parent.getSingleTargetStateName(parent.parentRegion, instance)»«ENDFOR»'''
	}
	
	override protected getSingleTargetStateName(State state, Region parentRegion, ComponentInstanceReference instance) {
		return '''«parentRegion.customizeName(instance)» == «parentRegion.stateNodes.filter(State).toList.indexOf(state) + 1 /* + 1 for __Inactive__ */»'''
	}
	
}