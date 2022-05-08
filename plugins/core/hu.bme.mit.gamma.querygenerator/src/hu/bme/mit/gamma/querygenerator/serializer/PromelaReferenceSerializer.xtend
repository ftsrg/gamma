package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State

import static extension hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class PromelaReferenceSerializer extends ThetaReferenceSerializer {
	// Singleton
	public static final PromelaReferenceSerializer INSTANCE = new PromelaReferenceSerializer
	protected new() {}
	
	override protected getSingleTargetStateName(State state, Region parentRegion, ComponentInstanceReferenceExpression instance) {
		return '''«parentRegion.customizeName(instance)» == «state.costumizeEnumLiteralName(parentRegion, instance)»'''
	}
}