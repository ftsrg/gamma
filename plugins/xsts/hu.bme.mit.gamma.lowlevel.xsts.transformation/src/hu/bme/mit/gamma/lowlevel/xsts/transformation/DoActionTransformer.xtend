package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.activity.model.CallActivityAction
import hu.bme.mit.gamma.xsts.model.XSTS

class DoActionTransformer {
	
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	// Needed for the transformation of assignment actions
	protected final extension StateAssumptionCreator stateAssumptionCreator
	// Trace
	protected final Trace trace
	// EMF models
	protected final Package _package
	protected final XSTS xSts
	
	new(Trace trace, Package _package, XSTS xSts) {
		this.trace = trace
		this._package = _package
		this.xSts = xSts
		this.stateAssumptionCreator = new StateAssumptionCreator(this.trace)
	}
	
	def dispatch transformCallActivity(XSTS xsts, Action action) {
		throw new UnsupportedOperationException("Unsupported actions: " + action)
	}
	
	def dispatch transformCallActivity(XSTS xsts, CallActivityAction action) {

	}
	
}
