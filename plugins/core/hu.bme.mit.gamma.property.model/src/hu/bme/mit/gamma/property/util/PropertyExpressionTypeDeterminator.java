package hu.bme.mit.gamma.property.util;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionType;
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator;
import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference;

public class PropertyExpressionTypeDeterminator extends ExpressionTypeDeterminator {
	// Singleton
	public static final PropertyExpressionTypeDeterminator INSTANCE = new PropertyExpressionTypeDeterminator();
	protected PropertyExpressionTypeDeterminator() {}
	//
	
	@Override
	public ExpressionType getType(final Expression expression) {
		if ((expression instanceof ComponentInstanceStateConfigurationReference) || 
			(expression instanceof ComponentInstanceEventReference)) {
			return ExpressionType.BOOLEAN;
		}
		if (expression instanceof ComponentInstanceVariableReference) {
			final VariableDeclaration variable = ((ComponentInstanceVariableReference) expression).getVariable();
			final Type declarationType = variable.getType();
			return this.transform(declarationType);
		}
		if (expression instanceof ComponentInstanceEventParameterReference) {
			final ParameterDeclaration parameter = ((ComponentInstanceEventParameterReference) expression).getParameter();
			final Type declarationType_1 = parameter.getType();
			return this.transform(declarationType_1);
		}
		return super.getType(expression);
	}	
	
	@Override
	public boolean isBoolean(final Expression expression) {
		final ExpressionType type = this.getType(expression);
		if (type == ExpressionType.BOOLEAN) {
			return true;
		}
		return super.isBoolean(expression);
	}
	
}
