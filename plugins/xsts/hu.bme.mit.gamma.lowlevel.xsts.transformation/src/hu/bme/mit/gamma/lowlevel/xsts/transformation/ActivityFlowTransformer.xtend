package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import hu.bme.mit.gamma.statechart.lowlevel.model.Succession

class ActivityFlowTransformer {
	
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	// Action utility
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	// Needed for the transformation of assignment actions
	protected final extension ActionTransformer actionTransformer
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension VariableDeclarationTransformer variableDeclarationTransformer
	protected final extension StateAssumptionCreator stateAssumptionCreator
	// Trace
	protected final Trace trace
	
	protected final extension ActivityLiterals activityLiterals = ActivityLiterals.INSTANCE 
	
	new(Trace trace) {
		this.trace = trace
		this.actionTransformer = new ActionTransformer(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		this.variableDeclarationTransformer = new VariableDeclarationTransformer(this.trace)
		this.stateAssumptionCreator = new StateAssumptionCreator(this.trace)
	}
	
	private def variable(Succession succession) {
		return trace.getXStsVariable(succession)		
	}
	
	private dispatch def sourceNodeVariable(Succession succession) {
		return trace.getXStsVariable(succession.sourceNode)
	}
	
	private dispatch def targetNodeVariable(Succession succession) {
		return trace.getXStsVariable(succession.targetNode)
	}
	
	private def inwardPrecondition(Succession succession) {
		val successionVariable = succession.variable
		val nodeVariable = succession.targetNodeVariable
		
		return createAndExpression => [
			it.operands += createEqualityExpression(successionVariable, createEnumerationLiteralExpression => [
					reference = fullFlowStateEnumLiteral
				]
			)
			it.operands += createEqualityExpression(nodeVariable, createEnumerationLiteralExpression => [
					reference = idleNodeStateEnumLiteral
				]
			)
		]
	}
	
	def transformInwards(Succession succession) {
		val flowVariable = succession.variable
		val nodeVariable = succession.targetNodeVariable
		
		return createSequentialAction => [
			it.actions += succession.inwardPrecondition.createAssumeAction
			it.actions += createAssignmentAction(flowVariable, createEnumerationLiteralExpression => [
					reference = emptyFlowStateEnumLiteral
				]
			)
			it.actions += createAssignmentAction(nodeVariable, createEnumerationLiteralExpression => [
					reference = runningNodeStateEnumLiteral
				]
			)
		]
	}
	
	private def outwardPrecondition(Succession succession) {
		val successionVariable = succession.variable
		val nodeVariable = succession.sourceNodeVariable
		
		return createAndExpression => [
			if (succession.guard !== null) {
				it.operands += succession.guard.transformExpression
			}
			it.operands += createEqualityExpression(successionVariable, createEnumerationLiteralExpression => [
					reference = emptyFlowStateEnumLiteral
				]
			)
			it.operands += createEqualityExpression(nodeVariable, createEnumerationLiteralExpression => [
					reference = doneNodeStateEnumLiteral
				]
			)
		]
	}
	
	def transformOutwards(Succession succession) {
		val successionVariable = succession.variable
		val nodeVariable = succession.sourceNodeVariable
		
		return createSequentialAction => [
			it.actions += succession.outwardPrecondition.createAssumeAction
			it.actions += createAssignmentAction(successionVariable, createEnumerationLiteralExpression => [
					reference = fullFlowStateEnumLiteral
				]
			)
			it.actions += createAssignmentAction(nodeVariable, createEnumerationLiteralExpression => [
					reference = idleNodeStateEnumLiteral
				]
			)
		]		
	}
	
}
