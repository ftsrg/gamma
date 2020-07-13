package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.property.model.StateFormula

interface PropertySerializer {
	
	def String serialize(StateFormula formula)
	
}