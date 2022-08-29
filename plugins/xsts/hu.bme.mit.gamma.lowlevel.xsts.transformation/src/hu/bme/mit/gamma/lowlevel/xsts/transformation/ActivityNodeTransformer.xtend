package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.statechart.lowlevel.model.ActionNode
import hu.bme.mit.gamma.statechart.lowlevel.model.ActivityNode
import hu.bme.mit.gamma.statechart.lowlevel.model.CompositeNode
import hu.bme.mit.gamma.statechart.lowlevel.model.DecisionNode
import hu.bme.mit.gamma.statechart.lowlevel.model.FinalNode
import hu.bme.mit.gamma.statechart.lowlevel.model.InitialNode
import hu.bme.mit.gamma.statechart.lowlevel.model.MergeNode
import hu.bme.mit.gamma.statechart.lowlevel.model.TriggerNode
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import hu.bme.mit.gamma.xsts.model.Action

class ActivityNodeTransformer {
	protected final extension ActionTransformer actionTransformer
	protected final extension ExpressionTransformer expressionTransformer
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintModelfactory = ExpressionModelFactory.eINSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	// Engine
	protected final ViatraQueryEngine engine
	// Trace
	protected final Trace trace
	
	new(ViatraQueryEngine engine, Trace trace) {
		this(engine, trace, null)
	}
	
	new(ViatraQueryEngine engine, Trace trace, RegionActivator regionActivator) {
		this.engine = engine
		this.trace = trace
		
		this.actionTransformer = new ActionTransformer(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		this.variableDeclarationTransformer = new VariableDeclarationTransformer(this.trace)
		this.activityFlowTransformer = new ActivityFlowTransformer(this.trace)
	}
	
	protected final extension VariableDeclarationTransformer variableDeclarationTransformer
	protected final extension ActivityFlowTransformer activityFlowTransformer
	
	protected final extension ActivityLiterals activityLiterals = ActivityLiterals.INSTANCE 
			
	protected def runningPrecondition(ActivityNode node) {
		val nodeVariable = trace.getXStsVariable(node)

		val expression = createAndExpression => [
			it.operands += createEqualityExpression(
				nodeVariable, 
				createEnumerationLiteralExpression => [
					reference = runningNodeStateEnumLiteral
				]
			)
		]
		
		return expression
	}
	
	protected def createDoneAssignmentAction(ActivityNode node) {
		val nodeVariable = trace.getXStsVariable(node)
	
		return createAssignmentAction(
			nodeVariable, 
			createEnumerationLiteralExpression => [
				reference = doneNodeStateEnumLiteral
			]
		)
	}
	
	protected def createRunningAssignmentAction(ActivityNode node) {
		val nodeVariable = trace.getXStsVariable(node)

		return createAssignmentAction(
			nodeVariable, 
			createEnumerationLiteralExpression => [
				reference = runningNodeStateEnumLiteral
			]
		)
	}
	
	protected def dispatch createNodeTransitionAction(ActionNode node) {
		return createSequentialAction => [
			it.actions += node.runningPrecondition.createAssumeAction
			it.actions += node.action.transformAction
			it.actions += node.createDoneAssignmentAction
		]
	}
	
	protected def dispatch createNodeTransitionAction(CompositeNode node) {
		return createSequentialAction => [
			it.actions += node.runningPrecondition.createAssumeAction
			it.actions += node.createDoneAssignmentAction
		]
	}
	
	protected def dispatch createNodeTransitionAction(TriggerNode node) {
		return createSequentialAction => [
			val precondition = node.runningPrecondition
			precondition.operands += node.triggerExpression.transformExpression
			
			it.actions += precondition.createAssumeAction
			it.actions += node.createDoneAssignmentAction
		]
	}
	
	protected def dispatch createNodeTransitionAction(ActivityNode node) {
		return createSequentialAction => [
			it.actions += node.runningPrecondition.createAssumeAction
			it.actions += node.createDoneAssignmentAction
		]
	}
	
	protected dispatch def createActivityNodeFlowAction(ActivityNode node) {
		return createNonDeterministicAction => [
			it.actions += createParallelAction => [
				for (flow : node.incoming) {
					it.actions += flow.transformInwards
				}
			]
			it.actions += createParallelAction => [
				for (flow : node.outgoing) {
					it.actions += flow.transformOutwards
				}
			]
		]
	}
	
	protected dispatch def createActivityNodeFlowAction(DecisionNode node) {
		return createRapidFireActivityNodeFlowAction(node)
	}
	
	protected dispatch def createActivityNodeFlowAction(MergeNode node) {
		return createRapidFireActivityNodeFlowAction(node)
	}
	
	private def createRapidFireActivityNodeFlowAction(ActivityNode node) {
		return createNonDeterministicAction => [
			it.actions += createNonDeterministicAction => [
				for (flow : node.incoming) {
					it.actions += flow.transformInwards
				}
			]
			it.actions += createNonDeterministicAction => [
				for (flow : node.outgoing) {
					it.actions += flow.transformOutwards
				}
			]
		]
	}
	
	protected dispatch def createActivityNodeFlowAction(InitialNode node) {
		return createParallelAction => [
			for (flow : node.outgoing) {
				it.actions += flow.transformOutwards
			}
		]
	}
	
	protected dispatch def createActivityNodeFlowAction(FinalNode node) {
		return createParallelAction => [
			for (flow : node.incoming) {
				it.actions += flow.transformInwards
			}
		]
	}
	
	def transform(ActivityNode node) {	
		val action = createNonDeterministicAction => [
			it.actions += node.createActivityNodeFlowAction
			it.actions += node.createNodeTransitionAction
		]
		
		trace.put(node, action)
		
		return action
	}
	
}
