/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.activity.model.ActivityNode
import hu.bme.mit.gamma.activity.model.ControlFlow
import hu.bme.mit.gamma.activity.model.DataFlow
import hu.bme.mit.gamma.activity.model.Pin
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.DecisionNodes
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Flows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.InitialNodes
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.InputControlFlows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.InputDataFlows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Nodes
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.NormalActivityNodes
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.OutputControlFlows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.OutputDataFlows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Pins
import hu.bme.mit.gamma.statechart.lowlevel.model.Package
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformation
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformationStatements

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*

class LowlevelActivityToXstsTransformer {
	extension BatchTransformation transformation
	extension BatchTransformationStatements statements

	final extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory

	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil actionFactory = XstsActionUtil.INSTANCE
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ActivityNodeTransformer activityNodeTransformer
	protected final extension ActivityFlowTransformer activityFlowTransformer

	protected final extension XSTSModelFactory xStsModelFactory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE

	protected ViatraQueryEngine engine
	protected final Package _package
	protected final XSTS xSts
	protected Trace trace
	
	protected BatchTransformationRule<Nodes.Match, Nodes.Matcher> nodesRule 
	protected BatchTransformationRule<InitialNodes.Match, InitialNodes.Matcher> initialNodesRule 
	protected BatchTransformationRule<Flows.Match, Flows.Matcher> flowsRule 
	protected BatchTransformationRule<NormalActivityNodes.Match, NormalActivityNodes.Matcher> normalActivityNodesRule 
	protected BatchTransformationRule<DecisionNodes.Match, DecisionNodes.Matcher> decisionNodesRule
	protected BatchTransformationRule<Pins.Match, Pins.Matcher> pinsRule

	protected final extension ActivityLiterals activityLiterals = ActivityLiterals.INSTANCE
	protected final extension XstsUtils xstsUtils = XstsUtils.INSTANCE
	
	new(Package _package, ViatraQueryEngine engine, BatchTransformation transformation, BatchTransformationStatements statements, XSTS xsts, Trace trace) {
		this._package = _package
		this.engine = engine
		this.trace = trace
		this.xSts = xsts
		this.transformation = transformation
		this.statements = statements
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		this.activityNodeTransformer = new ActivityNodeTransformer(this.trace)
		this.activityFlowTransformer = new ActivityFlowTransformer(this.trace)
	}
	
	def execute() {		
		getPinsRule.fireAllCurrent
		getNodesRule.fireAllCurrent
		getFlowsRule.fireAllCurrent
		
		getNormalActivityNodesRule.fireAllCurrent
		getDecisionNodesRule.fireAllCurrent
	}

	private def getNodesRule() {
		if (nodesRule === null) {
			nodesRule = createRule(Nodes.instance).action [
				it.activityNode.createActivityNodeMapping
			].build
		}
		return nodesRule
	}

	private def createActivityNodeMapping(ActivityNode activityNode) {
		val xStsActivityNodeVariable = createVariableDeclaration => [
			name = activityNode.name.activityNodeVariableName
			type = createTypeReference => [
				reference = nodeStateEnumTypeDeclaration
			]
			expression = createEnumerationLiteralExpression => [
				reference = idleNodeStateEnumLiteral
			]
		]
		xSts.variableDeclarations += xStsActivityNodeVariable
		xSts.controlVariables += xStsActivityNodeVariable
		trace.put(activityNode, xStsActivityNodeVariable)
				
		xSts.transitions.add(activityNode.transform.createXStsTransition)
	}

	private def getFlowsRule() {
		if (flowsRule === null) {
			flowsRule = createRule(Flows.instance).action [
				it.flow.createFlowMapping
			].build
		}
		return flowsRule
	}

	private def getPinsRule() {
		if (pinsRule === null) {
			pinsRule = createRule(Pins.instance).action [
				it.pin.createPinMapping
			].build
		}
		return pinsRule
	}
	
	private def createPinMapping(Pin pin) {
		val pinType = pin.type
		val xStsPinVariable = createVariableDeclaration => [
			name = pin.pinVariableName
			type = pinType
			expression = pinType.initialValueOfType
		]
		xSts.variableDeclarations += xStsPinVariable
		
		trace.put(pin, xStsPinVariable)
	}

	private dispatch def createFlowMapping(ControlFlow flow) {
		val xStsFlowVariable = createVariableDeclaration => [
			name = flow.flowVariableName
			type = createTypeReference => [
				reference = flowStateEnumTypeDeclaration
			]
			expression = createEnumerationLiteralExpression => [
				reference = emptyFlowStateEnumLiteral
			]
		]
		xSts.variableDeclarations += xStsFlowVariable
		xSts.controlVariables += xStsFlowVariable
		trace.put(flow, xStsFlowVariable)
	}

	private dispatch def createFlowMapping(DataFlow flow) {
		val xStsFlowVariable = createVariableDeclaration => [
			name = flow.flowVariableName
			type = createTypeReference => [
				reference = flowStateEnumTypeDeclaration
			]
			expression = createEnumerationLiteralExpression => [
				reference = emptyFlowStateEnumLiteral
			]
		]
		xSts.variableDeclarations += xStsFlowVariable
		xSts.controlVariables += xStsFlowVariable
		trace.put(flow, xStsFlowVariable)
				
		val dataType = createIntegerTypeDefinition// DataFlowType.Matcher.on(engine).getOneArbitraryMatch(flow, null).get.type
		
		val xStsDataTokenVariable = createVariableDeclaration => [
			name = flow.flowDataTokenVariableName
			type = dataType
			expression = dataType.initialValueOfType
		]
		xSts.variableDeclarations += xStsDataTokenVariable
		trace.putDataTokenVariable(flow, xStsDataTokenVariable)
	}
	
	private def getNormalActivityNodesRule() {
		if (normalActivityNodesRule === null) {
			normalActivityNodesRule = createRule(NormalActivityNodes.instance).action [
				val inputFlows = InputControlFlows.Matcher.on(engine).getAllValuesOfflow(it.node) + InputDataFlows.Matcher.on(engine).getAllValuesOfflow(it.node)
				val inTransitionAction = createSequentialAction => [
					for (flow : inputFlows) {
						it.actions.add(0, flow.guard.transformGuard)
						it.actions.add(0, flow.inwardAssumeAction)
						it.actions.add(flow.transformInwards)
					}
				]
				if (inTransitionAction.actions.size != 0)  {
					xSts.transitions.add(inTransitionAction.createXStsTransition)
				}
				
				val outputFlows = OutputControlFlows.Matcher.on(engine).getAllValuesOfflow(it.node) + OutputDataFlows.Matcher.on(engine).getAllValuesOfflow(it.node)
				val outTransitionAction = createSequentialAction => [
					for (flow : outputFlows) {
						it.actions.add(0, flow.outwardAssumeAction)
						it.actions.add(flow.transformOutwards)
					}
				]
				if (outTransitionAction.actions.size != 0)  {
					xSts.transitions.add(outTransitionAction.createXStsTransition)
				}
			].build
		}
		return normalActivityNodesRule
	}
	
	private def getDecisionNodesRule() {
		if (decisionNodesRule === null) {
			decisionNodesRule = createRule(DecisionNodes.instance).action [
				val inputFlows = InputControlFlows.Matcher.on(engine).getAllValuesOfflow(it.node) + InputDataFlows.Matcher.on(engine).getAllValuesOfflow(it.node)
				val inTransitionAction = createNonDeterministicAction
				for (flow : inputFlows) {
					val flowAction = createSequentialAction => [
						it.actions.add(0, flow.guard.transformGuard)
						it.actions.add(0, flow.inwardAssumeAction)
						it.actions.add(flow.transformInwards)
					]
					inTransitionAction.actions += flowAction
				}
				if (inTransitionAction.actions.size != 0)  {
					xSts.transitions.add(inTransitionAction.createXStsTransition)
				}
				
				val outputFlows = OutputControlFlows.Matcher.on(engine).getAllValuesOfflow(it.node) + OutputDataFlows.Matcher.on(engine).getAllValuesOfflow(it.node)
				val outTransitionAction = createNonDeterministicAction
				for (flow : outputFlows) {
					val flowAction = createSequentialAction => [
						it.actions.add(0, flow.outwardAssumeAction)
						it.actions.add(flow.transformOutwards)
					]
					outTransitionAction.actions += flowAction
				}
				if (outTransitionAction.actions.size != 0)  {
					xSts.transitions.add(outTransitionAction.createXStsTransition)
				}
			].build
		}
		return decisionNodesRule
	}
	
	protected def createXStsTransition(Action xStsTransitionAction) {
		val xStsTransition = createXTransition => [
			it.action = xStsTransitionAction
			it.reads += xStsTransitionAction.readVariables
			it.writes += xStsTransitionAction.writtenVariables
		]
		return xStsTransition
	}
	
	def dispose() {
		if (transformation !== null) {
			transformation.ruleEngine.dispose
		}
		transformation = null
		trace = null
		return
	}
	
	def transformGuard(Expression guardExpression) {
		if (guardExpression === null) {
			return  createTrueExpression.createAssumeAction
		}
		return guardExpression.transformExpression.createAssumeAction
	}
	
}
