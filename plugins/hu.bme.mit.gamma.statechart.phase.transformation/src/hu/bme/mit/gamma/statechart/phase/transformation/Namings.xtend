package hu.bme.mit.gamma.statechart.phase.transformation

import hu.bme.mit.gamma.expression.model.NamedElement
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance

class Namings {
	
	static def getName(NamedElement element, ComponentInstance instance) {
		return element.getName + "Of" + instance.name
	}
	
}