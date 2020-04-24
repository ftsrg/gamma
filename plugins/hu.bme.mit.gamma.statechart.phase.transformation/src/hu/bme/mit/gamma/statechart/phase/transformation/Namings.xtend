package hu.bme.mit.gamma.statechart.phase.transformation

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.StateNode
import hu.bme.mit.gamma.statechart.model.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance

class Namings {
	
	static def getName(Declaration variable, ComponentInstance instance) {
		return variable.getName + "Of" + instance.name
	}
	
	static def getName(TimeoutDeclaration variable, ComponentInstance instance) {
		return variable.getName + "Of" + instance.name
	}
	
	static def getName(StateNode variable, ComponentInstance instance) {
		return variable.getName + "Of" + instance.name
	}
	
	static def getName(Port port, ComponentInstance instance) {
		return port.getName + "Of" + instance.name
	}
	
}