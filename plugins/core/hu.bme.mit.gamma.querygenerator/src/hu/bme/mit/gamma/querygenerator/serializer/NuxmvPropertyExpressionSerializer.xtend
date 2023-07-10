package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.Expression

class NuxmvPropertyExpressionSerializer extends ThetaPropertyExpressionSerializer {
	
	new(AbstractReferenceSerializer referenceSerializer) {
		super(referenceSerializer)
	}
	
	override String serialize(Expression expression) {
		return super.serialize(expression)
	}
}