package hu.bme.mit.gamma.xsts.util

import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

class XstsUtils {
	// Singleton
	public static final XstsUtils INSTANCE = new XstsUtils();
	protected new() {}
	//
	
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension XstsActionUtil actionFactory = XstsActionUtil.INSTANCE
		
	def SequentialAction getVariableInitializingAction(XSTS xSts) {
		if (xSts.variableInitializingTransition === null) {
			xSts.variableInitializingTransition = createSequentialAction.wrap
		}
		return xSts.variableInitializingTransition.action as SequentialAction
	}
	
	def SequentialAction getConfigurationInitializingAction(XSTS xSts) {
		if (xSts.configurationInitializingTransition === null) {
			xSts.configurationInitializingTransition = createSequentialAction.wrap
		}
		return xSts.configurationInitializingTransition.action as SequentialAction
	}
	
	def SequentialAction getEntryEventAction(XSTS xSts) {
		if (xSts.entryEventTransition === null) {
			xSts.entryEventTransition = createSequentialAction.wrap
		}
		return xSts.entryEventTransition.action as SequentialAction
	}
	
	def SequentialAction getInEventAction(XSTS xSts) {
		if (xSts.inEventTransition === null) {
			xSts.inEventTransition = createSequentialAction.wrap
		}
		return xSts.inEventTransition.action as SequentialAction
	}
	
	def SequentialAction getOutEventAction(XSTS xSts) {
		if (xSts.outEventTransition === null) {
			xSts.outEventTransition = createSequentialAction.wrap
		}
		return xSts.outEventTransition.action as SequentialAction
	}
	
	
	protected def eliminateNullActions(XSTS xSts) {
		if (xSts.variableInitializingTransition === null) {
			xSts.variableInitializingTransition = createEmptyAction.wrap
		}
		if (xSts.configurationInitializingTransition === null) {
			xSts.configurationInitializingTransition = createEmptyAction.wrap
		}
		if (xSts.entryEventTransition === null) {
			xSts.entryEventTransition = createEmptyAction.wrap
		}
		if (xSts.transitions.empty) {
			xSts.changeTransitions(createEmptyAction.wrap)
		}
		if (xSts.inEventTransition === null) {
			xSts.inEventTransition = createEmptyAction.wrap
		}
		if (xSts.outEventTransition === null) {
			xSts.outEventTransition = createEmptyAction.wrap
		}
	}
	
}
