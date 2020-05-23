package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.model.XSTS

abstract class ActionSerializer {
	
	protected final extension ExpressionSerializer expressionSerializer = new ExpressionSerializer
	protected final extension ExpressionUtil expressionUtil = new ExpressionUtil
	protected final extension GammaEcoreUtil ecoreUtil = new GammaEcoreUtil
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	
	abstract def CharSequence serializeInitializingAction(XSTS xSts)
	abstract def CharSequence serializeChangeState(XSTS xSts)
	
}