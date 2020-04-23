package hu.bme.mit.gamma.statechart.phase.transformation

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance

class Namings {
	
	static def getName(VariableDeclaration variable, ComponentInstance instance) {
		return variable.getName + "Of" + instance.name
	}
	
}