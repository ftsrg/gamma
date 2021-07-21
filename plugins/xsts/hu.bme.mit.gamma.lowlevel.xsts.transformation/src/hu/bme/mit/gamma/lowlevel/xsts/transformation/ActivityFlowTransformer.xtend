package hu.bme.mit.gamma.lowlevel.xsts.transformation
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.activity.derivedfeatures.ActivityModelDerivedFeatures.*
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.activity.model.ControlFlow
import hu.bme.mit.gamma.activity.model.DataFlow

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
	// Trace
	protected final Trace trace
	
	protected final extension ActivityLiterals activityLiterals = ActivityLiterals.INSTANCE 
	
	new(Trace trace) {
		this.trace = trace
		this.actionTransformer = new ActionTransformer(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		this.variableDeclarationTransformer = new VariableDeclarationTransformer(this.trace)
	}
	
	private def createInwardAssumeAction(VariableDeclaration flowVariable, VariableDeclaration nodeVariable) {
		return createAssumeAction => [
			it.assumption = createAndExpression => [
				it.operands += createEqualityExpression(
					flowVariable, 
					createEnumerationLiteralExpression => [
						reference = fullFlowStateEnumLiteral
					]
				)
				it.operands += createEqualityExpression(
					nodeVariable, 
					createEnumerationLiteralExpression => [
						reference = idleNodeStateEnumLiteral
					]
				)
			]
		]
	}
	
	dispatch def inwardAssumeAction(ControlFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.targetNode)
		
		return createInwardAssumeAction(flowVariable, nodeVariable)
	}
	
	dispatch def inwardAssumeAction(DataFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.targetNode)
		
		return createInwardAssumeAction(flowVariable, nodeVariable)
	}
	
	private def createInwardTransformationAction(VariableDeclaration flowVariable, VariableDeclaration nodeVariable) {
		return createSequentialAction => [
			it.actions += createAssignmentAction(
				flowVariable, 
				createEnumerationLiteralExpression => [
					reference = emptyFlowStateEnumLiteral
				]
			)
			it.actions += createAssignmentAction(
				nodeVariable, 
				createEnumerationLiteralExpression => [
					reference = runningNodeStateEnumLiteral
				]
			)
		]
	}
	
	dispatch def transformInwards(ControlFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.targetNode)
		
		return createInwardTransformationAction(flowVariable, nodeVariable)
	}
	
	dispatch def transformInwards(DataFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.targetNode)
		
		return createInwardTransformationAction(flowVariable, nodeVariable)		
	}
	
	private def createOutwardAssumeAction(VariableDeclaration flowVariable, VariableDeclaration nodeVariable) {
		return createAssumeAction => [
			it.assumption = createAndExpression => [
				it.operands += createEqualityExpression(flowVariable, createEnumerationLiteralExpression => [
						reference = emptyFlowStateEnumLiteral
					]
				)
				it.operands += createEqualityExpression(nodeVariable, createEnumerationLiteralExpression => [
						reference = doneNodeStateEnumLiteral
					]
				)
			]
		]
	}
	
	dispatch def outwardAssumeAction(ControlFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.sourceNode)
		
		return createOutwardAssumeAction(flowVariable, nodeVariable)
	}
	
	dispatch def outwardAssumeAction(DataFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.sourceNode)
		
		return createOutwardAssumeAction(flowVariable, nodeVariable)
	}
	
	private def createOutwardTransformationAction(VariableDeclaration flowVariable, VariableDeclaration nodeVariable) {
		return createSequentialAction => [
			it.actions += createAssignmentAction(flowVariable, createEnumerationLiteralExpression => [
					reference = fullFlowStateEnumLiteral
				]
			)
			it.actions += createAssignmentAction(nodeVariable, createEnumerationLiteralExpression => [
					reference = idleNodeStateEnumLiteral
				]
			)
		]
	} 
	
	dispatch def transformOutwards(ControlFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.sourceNode)
		
		return createOutwardTransformationAction(flowVariable, nodeVariable)
	}
	
	dispatch def transformOutwards(DataFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.sourceNode)
		
		return createOutwardTransformationAction(flowVariable, nodeVariable)		
	}
	
}
