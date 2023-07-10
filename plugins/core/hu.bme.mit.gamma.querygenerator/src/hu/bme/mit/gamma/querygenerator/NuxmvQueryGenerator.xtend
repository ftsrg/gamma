package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.statechart.interface_.Component

class NuxmvQueryGenerator extends ThetaQueryGenerator {
		//
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	//
	new(Component component) {
		super(component)
	}
	
}