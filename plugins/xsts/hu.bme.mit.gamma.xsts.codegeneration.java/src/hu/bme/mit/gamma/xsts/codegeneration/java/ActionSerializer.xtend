package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.xsts.model.model.XSTS
import hu.bme.mit.gamma.expression.util.ExpressionUtil

abstract class ActionSerializer {
	
	extension protected ExpressionSerializer expressionSerializer = new ExpressionSerializer
	extension protected ExpressionUtil expressionUtil = new ExpressionUtil
	
	abstract def CharSequence serializeInitializingAction(XSTS xSts)
	abstract def CharSequence serializeChangeState(XSTS xSts)
	
}