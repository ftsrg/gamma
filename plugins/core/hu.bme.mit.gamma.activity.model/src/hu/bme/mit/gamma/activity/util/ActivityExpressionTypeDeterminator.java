package hu.bme.mit.gamma.activity.util;

import hu.bme.mit.gamma.activity.model.InputPinReference;
import hu.bme.mit.gamma.activity.model.OutputPinReference;
import hu.bme.mit.gamma.activity.model.Pin;
import hu.bme.mit.gamma.activity.model.PinReference;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.util.ExpressionType;
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator;

public class ActivityExpressionTypeDeterminator extends ExpressionTypeDeterminator {
	// Singleton
	public static final ActivityExpressionTypeDeterminator INSTANCE = new ActivityExpressionTypeDeterminator();
	protected ActivityExpressionTypeDeterminator() {}
	//
	
	@Override
	public ExpressionType getType(Expression expression) {
		if (expression instanceof PinReference) {
			return getType((PinReference)expression);
		}
		
		return super.getType(expression);
	}
	
	public ExpressionType getType(PinReference reference) {
		Pin pin;
		
		if (reference instanceof InputPinReference) {
			pin = ((InputPinReference)reference).getInputPin();
		} else  {
			pin = ((OutputPinReference)reference).getOutputPin();
		}
		
		return transform(pin.getType());
	}
}
