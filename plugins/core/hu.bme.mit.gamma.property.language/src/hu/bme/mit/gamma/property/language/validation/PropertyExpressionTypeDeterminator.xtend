package hu.bme.mit.gamma.property.language.validation

import hu.bme.mit.gamma.expression.language.validation.ExpressionTypeDeterminator
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference
import hu.bme.mit.gamma.expression.model.BooleanLiteralExpression
import hu.bme.mit.gamma.expression.language.validation.ExpressionType
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference

class PropertyExpressionTypeDeterminator extends ExpressionTypeDeterminator {
	// Singleton
	public static final PropertyExpressionTypeDeterminator INSTANCE = new PropertyExpressionTypeDeterminator
	protected new() {}
	//
	
	override getType(Expression expression) {
		if (expression instanceof ComponentInstanceStateConfigurationReference ||
				expression instanceof ComponentInstanceEventReference) {
			return ExpressionType.BOOLEAN;
		}
		if (expression instanceof ComponentInstanceVariableReference) {
			val variable = expression.variable
			val declarationType = variable.type
			return declarationType.transform
		}
		if (expression instanceof ComponentInstanceEventParameterReference) {
			val parameter = expression.parameter
			val declarationType = parameter.type
			return declarationType.transform
		}
		return super.getType(expression)
	}
	
	override isBoolean(Expression expression) {
		return expression instanceof ComponentInstanceStateConfigurationReference ||
			expression instanceof ComponentInstanceEventReference ||
			super.isBoolean(expression)
	}
	
}