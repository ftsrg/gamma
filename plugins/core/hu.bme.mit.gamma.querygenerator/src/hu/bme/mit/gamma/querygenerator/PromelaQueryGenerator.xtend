package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance

import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*

class PromelaQueryGenerator extends ThetaQueryGenerator {
	
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	
	new(Component component) {
		super(component)
	}
	
	override protected getSingleTargetStateName(State state, Region parentRegion, SynchronousComponentInstance instance) {
		return '''«parentRegion.customizeName(instance)» == «state.costumizeEnumLiteralName(parentRegion, instance)»'''
	}
}