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
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.util.ActionUtil
import hu.bme.mit.gamma.activity.model.ActionNode
import hu.bme.mit.gamma.activity.model.CompositeNode
import hu.bme.mit.gamma.activity.model.ControlFlow
import hu.bme.mit.gamma.activity.model.DataFlow
import hu.bme.mit.gamma.activity.model.DecisionNode
import hu.bme.mit.gamma.activity.model.FinalNode
import hu.bme.mit.gamma.activity.model.ForkNode
import hu.bme.mit.gamma.activity.model.InitialNode
import hu.bme.mit.gamma.activity.model.JoinNode
import hu.bme.mit.gamma.activity.model.MergeNode
import hu.bme.mit.gamma.activity.model.Pin
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.ActivityComposition.ActivityDefinition
import hu.bme.mit.gamma.statechart.ActivityComposition.TriggerNode
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.lowlevel.model.ActivityNode
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static hu.bme.mit.gamma.xsts.transformation.util.LowlevelNamings.*

import static extension hu.bme.mit.gamma.activity.derivedfeatures.ActivityModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import hu.bme.mit.gamma.activity.model.InputPin
import hu.bme.mit.gamma.activity.model.OutputPin
import hu.bme.mit.gamma.activity.model.Flow
import hu.bme.mit.gamma.statechart.interface_.Component

class ActivityToLowlevelTransformer {
// Auxiliary objects
	protected final extension TypeTransformer typeTransformer
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ValueDeclarationTransformer valueDeclarationTransformer
	protected final extension ActionTransformer actionTransformer
	protected final extension TriggerTransformer triggerTransformer
	protected final extension PseudoStateTransformer pseudoStateTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ActionUtil actionUtil = ActionUtil.INSTANCE
	protected final extension EventAttributeTransformer eventAttributeTransformer = EventAttributeTransformer.INSTANCE
	protected final extension EventDeclarationTransformer eventDeclarationTransformer
	// Low-level statechart model factory
	protected final extension StatechartModelFactory factory = StatechartModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE
	// Trace object for storing the mappings
	protected final Trace trace

	new(Trace trace) {
		this(trace, true, 10)
	}

	new(Trace trace, boolean functionInlining, int maxRecursionDepth) {
		this.trace = trace
		this.typeTransformer = new TypeTransformer(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace, functionInlining, maxRecursionDepth)
		this.valueDeclarationTransformer = new ValueDeclarationTransformer(this.trace)
		this.actionTransformer = new ActionTransformer(this.trace, functionInlining, maxRecursionDepth)
		this.triggerTransformer = new TriggerTransformer(this.trace, functionInlining, maxRecursionDepth)
		this.pseudoStateTransformer = new PseudoStateTransformer(this.trace)
		this.eventDeclarationTransformer = new EventDeclarationTransformer(this.trace)
	}
		
	protected def transformComponent(ActivityDefinition activity) {
		if (trace.isMapped(activity)) {
			return trace.get(activity)
		}
		val lowlevelActivity = createActivityDefinition => [
			it.name = getName(activity)
		]
		trace.put(activity, lowlevelActivity) // Saving in trace
		
		
		// Constants
		val gammaPackage = activity.containingPackage
		for (constantDeclaration : gammaPackage.selfAndImports // During code generation, imported constants can be referenced
				.map[it.constantDeclarations].flatten) {
			lowlevelActivity.variableDeclarations += constantDeclaration.transform
		}
		// No parameter declarations mapping
		for (parameterDeclaration : activity.parameterDeclarations) {
			val lowlevelParameterDeclaration = parameterDeclaration.transformComponentParameter
			lowlevelActivity.variableDeclarations += lowlevelParameterDeclaration
			lowlevelActivity.parameterDeclarations += lowlevelParameterDeclaration
		}
		for (variableDeclaration : activity.variableDeclarations) {
			lowlevelActivity.variableDeclarations += variableDeclaration.transform
		}
		for (timeoutDeclaration : activity.timeoutDeclarations) {
			// Timeout declarations are transformed to integer variable declarations
			val lowlevelTimeoutDeclaration = timeoutDeclaration.transform
			lowlevelActivity.variableDeclarations += lowlevelTimeoutDeclaration
			lowlevelActivity.timeoutDeclarations += lowlevelTimeoutDeclaration
		}
		for (port : activity.ports) {
			// Both in and out events are transformed to a boolean VarDecl with additional parameters
			for (eventDeclaration : port.allEventDeclarations) {
				val lowlevelEventDeclarations = eventDeclaration.transform(port)
				if (port.isActivityControllerPort) {
					for (event : lowlevelEventDeclarations) {
						event.annotations += createActivityControllerEventAnnotation
					}
				}
				
				lowlevelActivity.eventDeclarations += lowlevelEventDeclarations
				if (eventDeclaration.direction == EventDirection.INTERNAL) {
					// Tracing
					lowlevelActivity.internalEventDeclarations += lowlevelEventDeclarations
				}
			}
		}
		
		for (activityNode : activity.activityNodes) {
			lowlevelActivity.activityNodes += activityNode.transformNode
		}
		
		for (flow : activity.flows) {
			lowlevelActivity.flows += flow.transformFlow
		}
		
		for (flow : activity.flows) {
			lowlevelActivity.finalizeDataBindings(flow)
		}
		
		return lowlevelActivity
	}
	
	def transformPin(Pin pin) {
		if (trace.isPinMapped(pin)) {
			return trace.getPin(pin)
		}
		
		val lowlevelVariable = createVariableDeclaration => [
			it.name = pin.name
		]
		
		trace.put(pin, lowlevelVariable)
		
		lowlevelVariable.type = pin.type.transformType
		
		return lowlevelVariable
	}
	
	def dispatch finalizeDataBindings(hu.bme.mit.gamma.statechart.lowlevel.model.ActivityDefinition lowlevelActivity, ControlFlow flow) {
		// NO-OP
	}
	
	def dispatch finalizeDataBindings(hu.bme.mit.gamma.statechart.lowlevel.model.ActivityDefinition lowlevelActivity, DataFlow flow) {		
		val sourceVariable = flow.sourcePin.transformPin
		val targetVariable = flow.targetPin.transformPin
		
		sourceVariable.change(targetVariable, lowlevelActivity)
		
		targetVariable.remove
	}
	
	def transformFlow(Flow flow) { 
		if (trace.isFlowMapped(flow)) {
			return trace.getFlow(flow)
		}
		
		val lowlevelFlow = createSuccession
		
		trace.put(flow, lowlevelFlow)
		
		lowlevelFlow.guard = flow.guard?.transformExpression?.wrapIntoMultiaryExpression(createAndExpression)
		lowlevelFlow.sourceNode = flow.sourceNode.transformNode
		lowlevelFlow.targetNode = flow.targetNode.transformNode
		
		return lowlevelFlow
	}
	
	def dispatch ActivityNode transformNode(CompositeNode node) {
		if (trace.isActivityNodeMapped(node)) {
			return trace.getActivityNode(node)
		}
		
		val lowlevelNode = createCompositeNode => [
			it.name = node.name
		]
		
		trace.putActivityNode(node, lowlevelNode)
		
		lowlevelNode.pins += node.pins.map [
			it.transformPin
		]
		lowlevelNode.incoming += node.incomingFlows.map[
			it.transformFlow
		]
		lowlevelNode.outgoing += node.outgoingFlows.map[
			it.transformFlow
		]
		
		return lowlevelNode
	}
	
	def dispatch ActivityNode transformNode(ActionNode node) {
		if (trace.isActivityNodeMapped(node)) {
			return trace.getActivityNode(node)
		}
		
		val lowlevelNode = createActionNode => [
			it.name = node.name
		]
		
		trace.putActivityNode(node, lowlevelNode)
		
		lowlevelNode.pins += node.pins.map [
			it.transformPin
		]
		lowlevelNode.action = node.action.transformAction.wrap
		lowlevelNode.incoming += node.incomingFlows.map[
			it.transformFlow
		]
		lowlevelNode.outgoing += node.outgoingFlows.map[
			it.transformFlow
		]
		
		return lowlevelNode
	}
	
	def dispatch ActivityNode transformNode(ForkNode node) {
		if (trace.isActivityNodeMapped(node)) {
			return trace.getActivityNode(node)
		}
		
		val lowlevelNode = createForkNode => [
			it.name = node.name
		]
		
		trace.putActivityNode(node, lowlevelNode)
		
		lowlevelNode.incoming += node.incomingFlows.map[
			it.transformFlow
		]
		lowlevelNode.outgoing += node.outgoingFlows.map[
			it.transformFlow
		]
		
		return lowlevelNode
	}
	
	def dispatch ActivityNode transformNode(JoinNode node) {
		if (trace.isActivityNodeMapped(node)) {
			return trace.getActivityNode(node)
		}
		
		val lowlevelNode = createJoinNode => [
			it.name = node.name
		]
		
		trace.putActivityNode(node, lowlevelNode)
		
		lowlevelNode.incoming += node.incomingFlows.map[
			it.transformFlow
		]
		lowlevelNode.outgoing += node.outgoingFlows.map[
			it.transformFlow
		]
		
		return lowlevelNode
	}
	
	def dispatch ActivityNode transformNode(DecisionNode node) {
		if (trace.isActivityNodeMapped(node)) {
			return trace.getActivityNode(node)
		}
		
		val lowlevelNode = createDecisionNode => [
			it.name = node.name
		]
		
		trace.putActivityNode(node, lowlevelNode)
		
		lowlevelNode.incoming += node.incomingFlows.map[
			it.transformFlow
		]
		lowlevelNode.outgoing += node.outgoingFlows.map[
			it.transformFlow
		]
		
		return lowlevelNode
	}
	
	def dispatch ActivityNode transformNode(MergeNode node) {
		if (trace.isActivityNodeMapped(node)) {
			return trace.getActivityNode(node)
		}
		
		val lowlevelNode = createMergeNode => [
			it.name = node.name
		]
		
		trace.putActivityNode(node, lowlevelNode)
		
		lowlevelNode.incoming += node.incomingFlows.map[
			it.transformFlow
		]
		lowlevelNode.outgoing += node.outgoingFlows.map[
			it.transformFlow
		]
		
		return lowlevelNode
	}
	
	def dispatch ActivityNode transformNode(InitialNode node) {
		if (trace.isActivityNodeMapped(node)) {
			return trace.getActivityNode(node)
		}
		
		val lowlevelNode = createInitialNode => [
			it.name = node.name
		]
		
		trace.putActivityNode(node, lowlevelNode)
		
		lowlevelNode.incoming += node.incomingFlows.map[
			it.transformFlow
		]
		lowlevelNode.outgoing += node.outgoingFlows.map[
			it.transformFlow
		]
		
		return lowlevelNode
	}
	
	def dispatch ActivityNode transformNode(FinalNode node) {
		if (trace.isActivityNodeMapped(node)) {
			return trace.getActivityNode(node)
		}
		
		val lowlevelNode = createFinalNode => [
			it.name = node.name
		]
		
		trace.putActivityNode(node, lowlevelNode)
		
		lowlevelNode.incoming += node.incomingFlows.map[
			it.transformFlow
		]
		lowlevelNode.outgoing += node.outgoingFlows.map[
			it.transformFlow
		]
		
		return lowlevelNode
	}
		
	def dispatch ActivityNode transformNode(TriggerNode node) {
		if (trace.isActivityNodeMapped(node)) {
			return trace.getActivityNode(node)
		}
		
		val lowlevelNode = createTriggerNode => [
			it.name = node.name
		]
		
		trace.putActivityNode(node, lowlevelNode)
		
		lowlevelNode.incoming += node.incomingFlows.map[
			it.transformFlow
		]
		lowlevelNode.outgoing += node.outgoingFlows.map[
			it.transformFlow
		]
				
		lowlevelNode.triggerExpression = node.trigger.transformTrigger
		
		return lowlevelNode
	}
	
	protected def VariableDeclaration transform(TimeoutDeclaration timeout) {
		val lowlevelTimeout = createVariableDeclaration => [
			it.name = getName(timeout)
			it.type = createIntegerTypeDefinition // Could be rational
			// Initial expression in EventReferenceTransformer
		]
		trace.put(timeout, lowlevelTimeout)
		return lowlevelTimeout
	}
	
}
