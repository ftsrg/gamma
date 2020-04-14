package hu.bme.mit.gamma.statechart.util;

import hu.bme.mit.gamma.expression.util.ExpressionEvaluator;
import hu.bme.mit.gamma.statechart.model.TimeSpecification;
import hu.bme.mit.gamma.statechart.model.TimeUnit;

public class StatechartUtil {

	private ExpressionEvaluator evaluator = new ExpressionEvaluator();
	
	public int evaluateMilliseconds(TimeSpecification time) {
		int value = evaluator.evaluateInteger(time.getValue());
		TimeUnit unit = time.getUnit();
		switch (unit) {
		case MILLISECOND:
			return value;
		case SECOND:
			return value * 1000;
		default:
			throw new IllegalArgumentException("Not known unit: " + unit);
		}
	}
	
}
