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
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.ActionOptimizer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.DecisionNodes
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Flows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.GlobalVariables
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.InputControlFlows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Nodes
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.NormalActivityNodes
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.OutputControlFlows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.PlainVariables
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.ReferredEvents
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.ReferredVariables
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.TypeDeclarations
import hu.bme.mit.gamma.lowlevel.xsts.transformation.traceability.L2STrace
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.Package
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
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

import static extension hu.bme.mit.gamma.activity.derivedfeatures.ActivityModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.InputDataFlows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.OutputDataFlows
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.DataFlowType
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.InitialNodes
import hu.bme.mit.gamma.activity.model.DataNodeReference
import hu.bme.mit.gamma.activity.model.Pin
import hu.bme.mit.gamma.activity.model.ActionNode
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition

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
	protected Trace trace
	
	protected BatchTransformationRule<TypeDeclarations.Match, TypeDeclarations.Matcher> typeDeclarationsRule
	protected BatchTransformationRule<PlainVariables.Match, PlainVariables.Matcher> plainVariablesRule
	protected BatchTransformationRule<GlobalVariables.Match, GlobalVariables.Matcher> variableInitializationsRule
	protected BatchTransformationRule<Nodes.Match, Nodes.Matcher> nodesRule 
	protected BatchTransformationRule<InitialNodes.Match, InitialNodes.Matcher> initialNodesRule 
	protected BatchTransformationRule<Flows.Match, Flows.Matcher> flowsRule 
	protected BatchTransformationRule<NormalActivityNodes.Match, NormalActivityNodes.Matcher> normalActivityNodesRule 
	protected BatchTransformationRule<DecisionNodes.Match, DecisionNodes.Matcher> decisionNodesRule

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
		
	private def getVariableInitializingAction() {
		if (xSts.variableInitializingTransition === null) {
			xSts.variableInitializingTransition = createSequentialAction.wrap
		}
		return xSts.variableInitializingTransition.action
	}
	
	private def getConfigurationInitializingAction() {
		if (xSts.configurationInitializingTransition === null) {
			xSts.configurationInitializingTransition = createSequentialAction.wrap
		}
		return xSts.configurationInitializingTransition.action
	}
	
	private def getEntryEventAction() {
		if (xSts.entryEventTransition === null) {
			xSts.entryEventTransition = createSequentialAction.wrap
		}
		return xSts.entryEventTransition.action
	}
	
	private def getInEventAction() {
		if (xSts.inEventTransition === null) {
			xSts.inEventTransition = createSequentialAction.wrap
		}
		return xSts.inEventTransition.action
	}
	
	private def getOutEventAction() {
		if (xSts.outEventTransition === null) {
			xSts.outEventTransition = createSequentialAction.wrap
		}
		return xSts.outEventTransition.action
	}
	
	def execute() {
		getTypeDeclarationsRule.fireAllCurrent
		getPlainVariablesRule.fireAllCurrent
		
		getVariableInitializationsRule.fireAllCurrent
		initializeVariableInitializingAction
		
		getNodesRule.fireAllCurrent
		getFlowsRule.fireAllCurrent
				
		variableInitializingAction as SequentialAction
		configurationInitializingAction as SequentialAction
		entryEventAction as SequentialAction
		inEventAction as SequentialAction
		outEventAction as SequentialAction
		
		getNormalActivityNodesRule.fireAllCurrent
		getDecisionNodesRule.fireAllCurrent

		getInitialNodesRule.fireAllCurrent

		return new SimpleEntry<XSTS, L2STrace>(xSts, trace.getTrace)
	}
	
	private def getVariableInitializationsRule() {
		if (variableInitializationsRule === null) {
			variableInitializationsRule = createRule(GlobalVariables.instance).action [
				val lowlevelVariable = it.variable
				val xStsVariable = trace.getXStsVariable(lowlevelVariable)
				xStsVariable.expression = lowlevelVariable.initialValue.transformExpression
			].build
		}
		return variableInitializationsRule
	}

	private def getTypeDeclarationsRule() {
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

	private def getPlainVariablesRule() {
		if (plainVariablesRule === null) {
			plainVariablesRule = createRule(PlainVariables.instance).action [
				val lowlevelVariable = it.variable
				val xStsVariable = lowlevelVariable.transformVariableDeclaration
				xSts.variableDeclarations += xStsVariable // Target model modification
			].build
		}
		return plainVariablesRule
	}
	
	private def initializeVariableInitializingAction() {
		val xStsVariables = newLinkedList

		for (activity : _package.activities) {
			for (lowlevelVariable : activity.transitiveVariableDeclarations) {
				xStsVariables += trace.getXStsVariable(lowlevelVariable)
			}
		}

		for (xStsVariable : xStsVariables) {
			// variableInitializingAction as it must be set before setting the configuration
			variableInitializingAction as SequentialAction => [
				it.actions += createAssignmentAction => [
					it.lhs = createDirectReferenceExpression => [it.declaration = xStsVariable]
					it.rhs = xStsVariable.initialValue
				]
			]
		}
	}

	private def getNodesRule() {
		if (nodesRule === null) {
			nodesRule = createRule(Nodes.instance).action [
				it.activityNode.createActivityNodeMapping
			].build
		}
		return nodesRule
	}

	private def getInitialNodesRule() {
		if (initialNodesRule === null) {
			initialNodesRule = createRule(InitialNodes.instance).action [
				val nodeVariable = trace.getXStsVariable(it.activityNode)
				
				(entryEventAction as SequentialAction).actions += createAssignmentAction(nodeVariable, createEnumerationLiteralExpression => [
						reference = runningNodeStateEnumLiteral
					]
				)
			].build
		}
		return initialNodesRule
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
				
		if (activityNode instanceof ActionNode) {
			for (Pin pin : activityNode.activityDeclarationReference.getPins) {
				val pinType = pin.type
				val xStsPinVariable = createVariableDeclaration => [
					name = pin.pinVariableName
					type = pinType
					expression = pinType.initialValueOfType
				]
				xSts.variableDeclarations += xStsPinVariable
				trace.put(pin, xStsPinVariable)
			}
		}
	}

	private def getFlowsRule() {
		if (flowsRule === null) {
			flowsRule = createRule(Flows.instance).action [
				it.flow.createFlowMapping
			].build
		}
		return flowsRule
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
						it.actions.add(0, flow.guard.transformGuard)
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
						it.actions.add(0, flow.guard.transformGuard)
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
	
	private def createInwardAssumeAction(VariableDeclaration flowVariable, VariableDeclaration nodeVariable) {
		return createAssumeAction => [
			it.assumption = createAndExpression => [
				it.operands += createEqualityExpression(flowVariable, createEnumerationLiteralExpression => [
						reference = fullFlowStateEnumLiteral
					]
				)
				it.operands += createEqualityExpression(nodeVariable, createEnumerationLiteralExpression => [
						reference = idleNodeStateEnumLiteral
					]
				)
			]
		]
	}
	
	private dispatch def inwardAssumeAction(ControlFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.targetNode)
		
		return createInwardAssumeAction(flowVariable, nodeVariable)
	}
	
	private dispatch def inwardAssumeAction(DataFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.targetNode)
		
		return createInwardAssumeAction(flowVariable, nodeVariable)
	}
	
	private def createInwardTransformationAction(VariableDeclaration flowVariable, VariableDeclaration nodeVariable) {
		return createSequentialAction => [
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
	
	private dispatch def transformInwards(ControlFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.targetNode)
		
		return createInwardTransformationAction(flowVariable, nodeVariable)
	}
	
	private dispatch def transformInwards(DataFlow flow) {
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
						reference = runningNodeStateEnumLiteral
					]
				)
			]
		]
	}
	
	private dispatch def outwardAssumeAction(ControlFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.sourceNode)
		
		return createOutwardAssumeAction(flowVariable, nodeVariable)
	}
	
	private dispatch def outwardAssumeAction(DataFlow flow) {
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
	
	private dispatch def transformOutwards(ControlFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.sourceNode)
		
		return createOutwardTransformationAction(flowVariable, nodeVariable)
	}
	
	private dispatch def transformOutwards(DataFlow flow) {
		val flowVariable = trace.getXStsVariable(flow)
		val nodeVariable = trace.getXStsVariable(flow.sourceNode)
		
		return createOutwardTransformationAction(flowVariable, nodeVariable)		
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
		targetEngine = null
		trace = null
		return
	}
	
	private def transformGuard(Expression guardExpression) {
		if (guardExpression === null) {
			return  createTrueExpression.createAssumeAction
		}
		return guardExpression.transformExpression.createAssumeAction
	}
	
}
