package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

abstract class AbstractTransitionMerger {
	// VIATRA engines
	protected final ViatraQueryEngine engine
	// Trace object for handling the tracing
	protected final Trace trace
	//
	protected final XSTS xSts
	
	protected final extension PseudoStateHandler pseudoStateHandler
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected final extension XstsActionUtil actionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	
	new(ViatraQueryEngine engine, Trace trace) {
		this.engine = engine
		this.trace = trace
		this.xSts = trace.XSts
		this.pseudoStateHandler = new PseudoStateHandler(this.engine)
	}
	
	abstract def void mergeTransitions()
	
}