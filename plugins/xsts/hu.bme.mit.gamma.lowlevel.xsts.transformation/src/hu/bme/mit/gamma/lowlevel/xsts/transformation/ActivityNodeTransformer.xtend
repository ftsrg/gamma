package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.activity.model.ActivityNode
import hu.bme.mit.gamma.activity.model.ActionNode
import hu.bme.mit.gamma.activity.model.ActivityDefinition
import hu.bme.mit.gamma.activity.model.ActionDefinition

import static extension hu.bme.mit.gamma.activity.derivedfeatures.ActivityModelDerivedFeatures.*

class ActivityNodeTransformer {
	
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
	
	def createRunningAssumeAction(ActivityNode node) {
		val nodeVariable = trace.getXStsVariable(node)

		return createEqualityExpression(
			nodeVariable, 
			createEnumerationLiteralExpression => [
				reference = runningNodeStateEnumLiteral
			]
		).createAssumeAction
	}
	
	def createDoneAssignmentAction(ActivityNode node) {
		val nodeVariable = trace.getXStsVariable(node)
	
		return createAssignmentAction(
			nodeVariable, 
			createEnumerationLiteralExpression => [
				reference = doneNodeStateEnumLiteral
			]
		)
	}
	
	def createRunningAssignmentAction(ActivityNode node) {
		val nodeVariable = trace.getXStsVariable(node)

		return createAssignmentAction(
			nodeVariable, 
			createEnumerationLiteralExpression => [
				reference = runningNodeStateEnumLiteral
			]
		)
	}
	
	def dispatch transform(ActionNode node) {
		if (node.activityDeclarationReference !== null) {	
			val definition = node.activityDeclarationReference.definition
			if (definition instanceof ActionDefinition) {
				// action definition, running -> execute action -> done
				return createSequentialAction => [
					it.actions.add(node.createRunningAssumeAction)
					it.actions.add(definition.action.transformAction)
					it.actions.add(node.createDoneAssignmentAction)
				]
			}				
			if (definition instanceof ActivityDefinition) {
				// TODO: activity definition, running -> execute inner activity (set inner initial, wait for final done) -> done
				return createSequentialAction => [
					it.actions.add(node.createRunningAssumeAction)
					it.actions.add(node.createDoneAssignmentAction)
				]
			}
		} else {
			// Has no definition, simple running -> done
			return createSequentialAction => [
				it.actions.add(node.createRunningAssumeAction)
				it.actions.add(node.createDoneAssignmentAction)
			]
		}
	}
	
	def dispatch transform(ActivityNode node) {
		return createSequentialAction => [
			it.actions.add(node.createRunningAssumeAction)
			it.actions.add(node.createDoneAssignmentAction)
		]
	}
	
}
