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
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Flows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Nodes
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory

import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*

class ActivityToXstsTransformer {
	final extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	// Auxiliary objects
	protected final extension XstsActionUtil actionFactory = XstsActionUtil.INSTANCE
	protected final extension ActionTransformer actionTransformer
	protected final extension ExpressionTransformer expressionTransformer
	// Factories
	protected final extension XSTSModelFactory xStsModelFactory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintModelFactory = ExpressionModelFactory.eINSTANCE

	protected final ViatraQueryEngine engine
	protected final XSTS xSts
	protected final Trace trace
	
	protected BatchTransformationRule<Nodes.Match, Nodes.Matcher> nodesRule 
	protected BatchTransformationRule<Flows.Match, Flows.Matcher> flowsRule 
	
	// NodeState
	val idleNodeStateEnumLiteral = createEnumerationLiteralDefinition => [
		name = Namings.IDLE_NODE_STATE_ENUM_LITERAL
	]
	val runningNodeStateEnumLiteral = createEnumerationLiteralDefinition => [
		name = Namings.RUNNING_NODE_STATE_ENUM_LITERAL
	]
	val nodeStateEnumType = createEnumerationTypeDefinition => [
		literals += idleNodeStateEnumLiteral
		literals += runningNodeStateEnumLiteral
	]
	val nodeStateEnumTypeDeclaration = createTypeDeclaration => [
		type = nodeStateEnumType
		name = "ActivityNodeState"
	]
	
	// FlowState
	val emptyFlowStateEnumLiteral = createEnumerationLiteralDefinition => [
		name = Namings.EMPTY_FLOW_STATE_ENUM_LITERAL
	]
	val fullFlowStateEnumLiteral = createEnumerationLiteralDefinition => [
		name = Namings.FULL_FLOW_STATE_ENUM_LITERAL
	]
	val flowStateEnumType = createEnumerationTypeDefinition => [
		literals += emptyFlowStateEnumLiteral
		literals += fullFlowStateEnumLiteral
	]
	val flowStateEnumTypeDeclaration = createTypeDeclaration => [
		type = flowStateEnumType
		name = "FlowState"
	]
	
	new(ViatraQueryEngine engine, XSTS xSts, Trace trace) {
		this.engine = engine
		this.xSts = xSts
		this.trace = trace
		this.actionTransformer = new ActionTransformer(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		
		xSts.typeDeclarations += nodeStateEnumTypeDeclaration
		xSts.typeDeclarations += flowStateEnumTypeDeclaration
	}

	protected def getNodesRule() {
		if (nodesRule === null) {
			nodesRule = createRule(Nodes.instance).action [
				it.activityNode.createActivityNodeMapping
			].build
		}
		return nodesRule
	}

	protected def createActivityNodeMapping(ActivityNode activityNode) {
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
	}

	protected def getFlowsRule() {
		if (flowsRule === null) {
			flowsRule = createRule(Flows.instance).action [
				it.flow.createFlowMapping
			].build
		}
		return flowsRule
	}

	protected dispatch def createFlowMapping(ControlFlow flow) {
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

	protected dispatch def createFlowMapping(DataFlow flow) {
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
}
