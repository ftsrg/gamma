package hu.bme.mit.gamma.scenario.util;

import hu.bme.mit.gamma.expression.model.Expression;

public class ExpressionSerializer extends hu.bme.mit.gamma.statechart.util.ExpressionSerializer {
	
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer();
	protected ExpressionSerializer() {}
	//

	@Override
	public String serialize(Expression expression) {
		return super.serialize(expression);
	}

	
}
