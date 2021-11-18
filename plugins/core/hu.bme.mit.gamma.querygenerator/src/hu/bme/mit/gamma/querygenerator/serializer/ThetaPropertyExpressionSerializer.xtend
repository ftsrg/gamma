package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.Expression

class ThetaPropertyExpressionSerializer extends PropertyExpressionSerializer {
	
	new(AbstractReferenceSerializer referenceSerializer) {
		super(referenceSerializer)
	}
	
	override String serialize(Expression expression) {
		if (expression instanceof EnumerationLiteralExpression) {
			val literal = expression.reference
			return literal.name
		}
		return super.serialize(expression)
	}
	
}