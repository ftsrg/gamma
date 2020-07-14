package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.property.model.StateFormula

abstract class PropertySerializer {
	
	protected extension PropertyExpressionSerializer serializer
	 
	new(PropertyExpressionSerializer serializer) {
		this.serializer = serializer
	}
	
	abstract def String serialize(StateFormula formula)
	
}