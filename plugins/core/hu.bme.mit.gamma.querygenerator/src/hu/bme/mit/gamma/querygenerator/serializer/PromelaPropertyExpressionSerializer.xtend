package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.xsts.promela.transformation.util.Namings

class PromelaPropertyExpressionSerializer extends ThetaPropertyExpressionSerializer {
	
	new(AbstractReferenceSerializer referenceSerializer) {
		super(referenceSerializer)
	}
	
	override String serialize(Expression expression) {
		if (expression instanceof EnumerationLiteralExpression) {
			return Namings.costumizeEnumLiteralName(expression)
		}
		return super.serialize(expression)
	}
}