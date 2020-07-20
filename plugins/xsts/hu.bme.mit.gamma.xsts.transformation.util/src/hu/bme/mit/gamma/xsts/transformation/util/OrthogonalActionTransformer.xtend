package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.OrthogonalAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XSTSActionUtil

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XSTSDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class OrthogonalActionTransformer {
	// Singleton
	public static final OrthogonalActionTransformer INSTANCE = new OrthogonalActionTransformer
	protected new() {}
	//
	
	protected extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected extension XSTSActionUtil xstsActionUtil = XSTSActionUtil.INSTANCE
	protected extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected extension XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE
	
	def void transform(XSTS xSts) {
		xSts.variableInitializingAction.transform
		xSts.configurationInitializingAction.transform
		xSts.entryEventAction.transform
		xSts.mergedAction.transform
		xSts.inEventAction.transform
		xSts.outEventAction.transform
	}
	
	def void transform(Action action) {
		val xSts = action.root
		val orthogonalActions = action.getSelfAndAllContentsOfType(OrthogonalAction)
		val orthogonalBranchActions = newArrayList
		for (orthogonalAction : orthogonalActions) {
			val newAction = createSequentialAction
			val setupAction = createSequentialAction
			val mainAction = createSequentialAction
			val commonizeAction = createSequentialAction
			newAction => [
				it.actions += setupAction
				it.actions += mainAction
				it.actions += commonizeAction
			]
			
			orthogonalBranchActions.clear
			orthogonalBranchActions += orthogonalAction.actions
			for (orthogonalBranch : orthogonalBranchActions) {
				val writtenVariables = orthogonalBranch.writtenVariables
				for (writtenVariable : writtenVariables) {
					val orthogonalVariable = writtenVariable.createOrthogonalVariable
					// _var_ := var
					setupAction.actions += orthogonalVariable.createAssignmentAction(writtenVariable)
					// Each written var is changed to _var_
					orthogonalVariable.change(writtenVariable, orthogonalBranch)
					mainAction.actions += orthogonalBranch
					// var := _var_
					commonizeAction.actions += writtenVariable.createAssignmentAction(orthogonalVariable)
				}
			}
			// If the orthogonal action is traced, this can cause trouble (the original action is not contained in a resource)
			newAction.change(orthogonalAction, xSts)
			newAction.replace(orthogonalAction)
		}
	}
	
	protected def createOrthogonalVariable(VariableDeclaration variable) {
		val xSts = variable.root as XSTS
		val orthogonalVariable = createVariableDeclaration => [
			it.type = variable.type.clone(true, true)
			it.name = variable.orthogonalName // If there are multiple ort variables with the same name, the model is faulty 
		]
		xSts.variableDeclarations += orthogonalVariable
		return orthogonalVariable
	}
	
}
	