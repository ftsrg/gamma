package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.activity.model.ControlFlow
import hu.bme.mit.gamma.activity.model.DataFlow
import hu.bme.mit.gamma.activity.model.Flow
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

import static extension hu.bme.mit.gamma.activity.derivedfeatures.ActivityModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*

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
	
	private def variable(Flow flow) {
		return trace.getXStsVariable(flow)		
	}
	
	private dispatch def sourceNodeVariable(ControlFlow flow) {
		return trace.getXStsVariable(flow.sourceNode)
	}
	
	private dispatch def sourceNodeVariable(DataFlow flow) {
		return trace.getXStsVariable(flow.sourceNode)
	}
	
	private dispatch def targetNodeVariable(ControlFlow flow) {
		return trace.getXStsVariable(flow.targetNode)
	}
	
	private dispatch def targetNodeVariable(DataFlow flow) {
		return trace.getXStsVariable(flow.targetNode)
	}
	
	private def inwardPrecondition(Flow flow) {
		val flowVariable = flow.variable
		val nodeVariable = flow.targetNodeVariable
		
		return createAndExpression => [
			it.operands += flow.activityInstance.state.createSingleXStsStateAssumption
			it.operands += createEqualityExpression(flowVariable, createEnumerationLiteralExpression => [
					reference = fullFlowStateEnumLiteral
				]
			)
			it.operands += createEqualityExpression(nodeVariable, createEnumerationLiteralExpression => [
					reference = idleNodeStateEnumLiteral
				]
			)
		]
	}
	
	def transformInwards(Flow flow) {
		val flowVariable = flow.variable
		val nodeVariable = flow.targetNodeVariable
		
		return createSequentialAction => [
			it.actions += flow.inwardPrecondition.createAssumeAction
			it.actions += createAssignmentAction(flowVariable, createEnumerationLiteralExpression => [
					reference = emptyFlowStateEnumLiteral
				]
			)
			it.actions += createAssignmentAction(nodeVariable, createEnumerationLiteralExpression => [
					reference = runningNodeStateEnumLiteral
				]
			)
				
			if (flow instanceof DataFlow) {
				val dataFlow = flow as DataFlow
				val dataFlowVariable = trace.getDataContainerXStsVariable(dataFlow)
				val targetDataContainer = dataFlow.targetDataContainer
				val targetDataContainerVariable = trace.getDataContainerXStsVariable(targetDataContainer)
				it.actions += createAssignmentAction(targetDataContainerVariable, dataFlowVariable)
			}
		]
	}
	
	private def outwardPrecondition(Flow flow) {
		val flowVariable = flow.variable
		val nodeVariable = flow.sourceNodeVariable
		
		return createAndExpression => [
			it.operands += flow.activityInstance.state.createSingleXStsStateAssumption
			if (flow.guard !== null) {
				it.operands += flow.guard.transformExpression
			}
			it.operands += createEqualityExpression(flowVariable, createEnumerationLiteralExpression => [
					reference = emptyFlowStateEnumLiteral
				]
			)
			it.operands += createEqualityExpression(nodeVariable, createEnumerationLiteralExpression => [
					reference = doneNodeStateEnumLiteral
				]
			)
		]
	}
	
	def transformOutwards(Flow flow) {
		val flowVariable = flow.variable
		val nodeVariable = flow.sourceNodeVariable
		
		return createSequentialAction => [
			it.actions += flow.outwardPrecondition.createAssumeAction
			it.actions += createAssignmentAction(flowVariable, createEnumerationLiteralExpression => [
					reference = fullFlowStateEnumLiteral
				]
			)
			it.actions += createAssignmentAction(nodeVariable, createEnumerationLiteralExpression => [
					reference = idleNodeStateEnumLiteral
				]
			)
				
			if (flow instanceof DataFlow) {
				val dataFlow = flow as DataFlow
				val dataFlowVariable = trace.getDataContainerXStsVariable(dataFlow)
				val sourceDataContainer = dataFlow.sourceDataContainer
				val sourceDataContainerVariable = trace.getDataContainerXStsVariable(sourceDataContainer)
				it.actions += createAssignmentAction(dataFlowVariable, sourceDataContainerVariable)
			}
		]		
	}
	
}
