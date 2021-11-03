package hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer

import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.AssignmentActions
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.NotReadVariables
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class TransientVariableRemover {
	// Singleton
	public static final TransientVariableRemover INSTANCE =  new TransientVariableRemover
	protected new() {}
	//
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	def void removeTransientVariables(XSTS xSts) {
		val engine = ViatraQueryEngine.on(new EMFScope(xSts))
		
		val unreadXStsVariableMatcher = NotReadVariables.Matcher.on(engine)
		val unreadTransientXStsVariables = unreadXStsVariableMatcher.allValuesOfvariable
				.filter[it.transient || it.local]
		val xStsAssignmentMatcher = AssignmentActions.Matcher.on(engine)
		for (unreadTransientXStsVariable : unreadTransientXStsVariables) {
			val xStsAssignments = xStsAssignmentMatcher.getAllValuesOfaction(
					null, unreadTransientXStsVariable)
			for (xStsAssignment : xStsAssignments) {
				xStsAssignment.remove
			}
			// Deleting the potential containing VariableDeclarationAction too
			unreadTransientXStsVariable.deleteDeclaration
		}
	}
	
}