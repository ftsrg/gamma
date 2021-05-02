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
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.ActionOptimizer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Flows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.GlobalVariables
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Nodes
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.PlainVariables
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.ReferredEvents
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.ReferredVariables
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.TypeDeclarations
import hu.bme.mit.gamma.lowlevel.xsts.transformation.traceability.L2STrace
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.Package
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.AbstractMap.SimpleEntry
import java.util.Set
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformation
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformationStatements

import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*

class LowlevelActivityToXstsTransformer {
	extension BatchTransformation transformation
	extension BatchTransformationStatements statements

	final extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory

	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil actionFactory = XstsActionUtil.INSTANCE
	protected final extension ActionTransformer actionTransformer
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension VariableDeclarationTransformer variableDeclarationTransformer
	protected final extension VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	protected final extension ActionOptimizer actionOptimizer = ActionOptimizer.INSTANCE

	protected final extension XSTSModelFactory xStsModelFactory = XSTSModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE

	protected ViatraQueryEngine engine
	protected ViatraQueryEngine targetEngine
	protected final Package _package
	protected final XSTS xSts
	protected final Trace trace
	
	protected BatchTransformationRule<TypeDeclarations.Match, TypeDeclarations.Matcher> typeDeclarationsRule
	protected BatchTransformationRule<PlainVariables.Match, PlainVariables.Matcher> plainVariablesRule
	protected BatchTransformationRule<GlobalVariables.Match, GlobalVariables.Matcher> variableInitializationsRule
	protected BatchTransformationRule<Nodes.Match, Nodes.Matcher> nodesRule 
	protected BatchTransformationRule<Flows.Match, Flows.Matcher> flowsRule 

	protected boolean optimize
	protected Set<EventDeclaration> referredEvents
	protected Set<VariableDeclaration> referredVariables
	
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
	
	new(Package _package) {
		this(_package, false)
	}
	
	new(Package _package, boolean optimize) {
		this._package = _package

		this.engine = ViatraQueryEngine.on(new EMFScope(_package))
		this.xSts = createXSTS => [
			it.name = _package.name
			it.typeDeclarations += nodeStateEnumTypeDeclaration
			it.typeDeclarations += flowStateEnumTypeDeclaration
		]
		this.targetEngine = ViatraQueryEngine.on(new EMFScope(this.xSts))
		this.trace = new Trace(_package, xSts)
		this.actionTransformer = new ActionTransformer(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace)
		this.variableDeclarationTransformer = new VariableDeclarationTransformer(this.trace)
		this.transformation = BatchTransformation.forEngine(engine).build
		this.statements = transformation.transformationStatements
		this.optimize = optimize
		if (optimize) {
			this.referredEvents = ReferredEvents.Matcher.on(engine).allValuesOfevent
			this.referredVariables = ReferredVariables.Matcher.on(engine).allValuesOfvariable
		}
	}
		
	protected def getVariableInitializingAction() {
		if (xSts.variableInitializingTransition === null) {
			xSts.variableInitializingTransition = createSequentialAction.wrap
		}
		return xSts.variableInitializingTransition.action
	}
	
	protected def getConfigurationInitializingAction() {
		if (xSts.configurationInitializingTransition === null) {
			xSts.configurationInitializingTransition = createSequentialAction.wrap
		}
		return xSts.configurationInitializingTransition.action
	}
	
	protected def getEntryEventAction() {
		if (xSts.entryEventTransition === null) {
			xSts.entryEventTransition = createSequentialAction.wrap
		}
		return xSts.entryEventTransition.action
	}
	
	protected def getInEventAction() {
		if (xSts.inEventTransition === null) {
			xSts.inEventTransition = createSequentialAction.wrap
		}
		return xSts.inEventTransition.action
	}
	
	protected def getOutEventAction() {
		if (xSts.outEventTransition === null) {
			xSts.outEventTransition = createSequentialAction.wrap
		}
		return xSts.outEventTransition.action
	}
	
	def execute() {
		getTypeDeclarationsRule.fireAllCurrent
		getPlainVariablesRule.fireAllCurrent
		
		getNodesRule.fireAllCurrent
		getFlowsRule.fireAllCurrent
		
		getVariableInitializationsRule.fireAllCurrent
		
		variableInitializingAction as SequentialAction
		configurationInitializingAction as SequentialAction
		entryEventAction as SequentialAction
		inEventAction as SequentialAction
		outEventAction as SequentialAction

		return new SimpleEntry<XSTS, L2STrace>(xSts, trace.getTrace)
	}
	
	protected def getVariableInitializationsRule() {
		if (variableInitializationsRule === null) {
			variableInitializationsRule = createRule(GlobalVariables.instance).action [
				val lowlevelVariable = it.variable
				if (lowlevelVariable.notOptimizable) {
					val xStsVariable = trace.getXStsVariable(lowlevelVariable)
					// By now all variables must be traced because of such initializations: var a = b
					xStsVariable.expression = lowlevelVariable.initialValue.transformExpression
				}
			].build
		}
		return variableInitializationsRule
	}

	protected def getTypeDeclarationsRule() {
		if (typeDeclarationsRule === null) {
			typeDeclarationsRule = createRule(TypeDeclarations.instance).action [
				val lowlevelTypeDeclaration = it.typeDeclaration
				val xStsTypeDeclaration = lowlevelTypeDeclaration.clone
				xSts.typeDeclarations += xStsTypeDeclaration
				xSts.publicTypeDeclarations += xStsTypeDeclaration
				trace.put(lowlevelTypeDeclaration, xStsTypeDeclaration)
			].build
		}
		return typeDeclarationsRule
	}

	protected def getPlainVariablesRule() {
		if (plainVariablesRule === null) {
			plainVariablesRule = createRule(PlainVariables.instance).action [
				val lowlevelVariable = it.variable
				if (lowlevelVariable.notOptimizable) {
					val xStsVariable = lowlevelVariable.transformVariableDeclaration
					xSts.variableDeclarations += xStsVariable // Target model modification
					xSts.plainVariableGroup.variables += xStsVariable // Variable group modification
				}
			].build
		}
		return plainVariablesRule
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
	
	protected def isNotOptimizable(EventDeclaration lowlevelEvent) {
		return !optimize || referredEvents.contains(lowlevelEvent)
	}
	
	protected def isNotOptimizable(VariableDeclaration lowlevelVariable) {
		return !optimize || referredVariables.contains(lowlevelVariable)
	}
}
