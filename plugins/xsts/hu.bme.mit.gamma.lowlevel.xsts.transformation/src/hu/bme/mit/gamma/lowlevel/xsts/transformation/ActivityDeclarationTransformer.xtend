package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory

class ActivityDeclarationTransformer {
	
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	// Action utility
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	// Needed for the transformation of assignment actions
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension VariableDeclarationTransformer variableDeclarationTransformer
	// Trace
	protected final Trace trace
	
	protected final extension ActivityLiterals activityLiterals = ActivityLiterals.INSTANCE 
	
	new(Trace trace) {
		this.trace = trace
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		this.variableDeclarationTransformer = new VariableDeclarationTransformer(this.trace)
	}
	
}
