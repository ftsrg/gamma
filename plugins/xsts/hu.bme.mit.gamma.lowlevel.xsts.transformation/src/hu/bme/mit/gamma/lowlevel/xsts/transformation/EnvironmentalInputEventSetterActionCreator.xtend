package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.List

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class EnvironmentalInputEventSetterActionCreator {
	
	protected final boolean useHavocActions
	
	protected final extension XstsActionUtil actionFactory = XstsActionUtil.INSTANCE
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	
	new(boolean useHavocActions) {
		this.useHavocActions = useHavocActions
	}
	
	def createInputEventSetterAction(VariableDeclaration xStsEventVariable,
			List<VariableDeclaration> xStsParameterVariables, boolean isResetable) {
		val block = createSequentialAction
		// In event variable
		val xStsInEventAssignment = 
		if (useHavocActions) {
			createHavocAction => [
				it.lhs = xStsEventVariable.createReferenceExpression
			]
		}
		else {
			createNonDeterministicAction => [
				// Event is raised
				it.actions += createAssignmentAction => [
					it.lhs = xStsEventVariable.createReferenceExpression
					it.rhs = createTrueExpression
				]
				// Event is not raised
				it.actions += createAssignmentAction => [
					it.lhs = xStsEventVariable.createReferenceExpression
					it.rhs = createFalseExpression
				]
			]
		}
		block.actions += xStsInEventAssignment
		// Parameter variables
		for (xStsParameterVariable : xStsParameterVariables) {
			if (isResetable) {
				// Synchronous composite components do not reset transient parameters!
				block.actions += createAssignmentAction => [
					it.lhs = xStsParameterVariable.createReferenceExpression
					it.rhs = xStsParameterVariable.defaultExpression
				]
			}
			val xStsInParameterAssignment = 
			if (useHavocActions) {
				createHavocAction => [
					it.lhs = xStsParameterVariable.createReferenceExpression
				]
			}
			else {
				val xStsAllPossibleParameterValues = newHashSet
				// TODO fill xStsAllPossibleParameterValues
				val xStsPossibleParameterValues = xStsAllPossibleParameterValues.removeDuplicatedExpressions
				createNonDeterministicAction => [
					for (xStsPossibleParameterValue : xStsPossibleParameterValues) {
						it.actions += createAssignmentAction => [
							it.lhs = xStsParameterVariable.createReferenceExpression
							it.rhs = xStsPossibleParameterValue
						]
					}
				]
			}
			// Setting the parameter value
			block.actions += createIfAction(
				// Only if the event is raised
				xStsEventVariable.createReferenceExpression,
				xStsInParameterAssignment
			)
		}
		return block
	}
	
}