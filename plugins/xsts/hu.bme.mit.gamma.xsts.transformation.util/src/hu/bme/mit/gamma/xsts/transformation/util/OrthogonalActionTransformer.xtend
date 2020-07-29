package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.EventGroup
import hu.bme.mit.gamma.xsts.model.EventParameterGroup
import hu.bme.mit.gamma.xsts.model.OrthogonalAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XSTSActionUtil
import java.util.Collection

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XSTSDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class OrthogonalActionTransformer {
	// Singleton
	public static final OrthogonalActionTransformer INSTANCE = new OrthogonalActionTransformer
	protected new() {}
	//
	
	protected extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected extension ExpressionUtil expressionActionUtil = ExpressionUtil.INSTANCE
	protected extension XSTSActionUtil xStsActionUtil = XSTSActionUtil.INSTANCE
	protected extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected extension XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE
	
	def void transform(XSTS xSts) {
		val eventVariables = xSts.variableGroups
			.filter[it.annotation instanceof EventGroup || it.annotation instanceof EventParameterGroup]
			.map[it.variables].flatten.toSet
		if (!eventVariables.empty) {
			xSts.variableInitializingAction.transform(eventVariables)
			xSts.configurationInitializingAction.transform(eventVariables)
			xSts.entryEventAction.transform(eventVariables)
			xSts.mergedAction.transform(eventVariables)
			xSts.inEventAction.transform(eventVariables)
			xSts.outEventAction.transform(eventVariables)
		}
	}
	
	def void transform(Action action, Collection<VariableDeclaration> consideredVariables) {
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
				writtenVariables.retainAll(consideredVariables) // Transforming only considered variables
				for (writtenVariable : writtenVariables) {
					val orthogonalVariable = writtenVariable.createOrthogonalVariable
					// _var_ := var
					setupAction.actions += orthogonalVariable.createAssignmentAction(writtenVariable)
					// Each written var is changed to _var_
					orthogonalVariable.change(writtenVariable, orthogonalBranch)
					mainAction.actions += orthogonalBranch
					// var := _var_
					commonizeAction.actions += writtenVariable.createAssignmentAction(orthogonalVariable)
					// _var_ := 0
					commonizeAction.actions += orthogonalVariable.createAssignmentAction(orthogonalVariable.initialValue)
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
	