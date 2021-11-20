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

import hu.bme.mit.gamma.action.util.ActionUtil
import hu.bme.mit.gamma.activity.model.ActionDefinition
import hu.bme.mit.gamma.activity.model.ActionNode
import hu.bme.mit.gamma.activity.model.ActivityDeclaration
import hu.bme.mit.gamma.activity.model.ActivityDefinition
import hu.bme.mit.gamma.activity.model.ActivityModelFactory
import hu.bme.mit.gamma.activity.model.ActivityNode
import hu.bme.mit.gamma.activity.model.ControlFlow
import hu.bme.mit.gamma.activity.model.DataFlow
import hu.bme.mit.gamma.activity.model.DataNode
import hu.bme.mit.gamma.activity.model.DataNodeReference
import hu.bme.mit.gamma.activity.model.Definition
import hu.bme.mit.gamma.activity.model.Flow
import hu.bme.mit.gamma.activity.model.InlineActivityDeclaration
import hu.bme.mit.gamma.activity.model.InputPin
import hu.bme.mit.gamma.activity.model.InsideInputPinReference
import hu.bme.mit.gamma.activity.model.InsideOutputPinReference
import hu.bme.mit.gamma.activity.model.NamedActivityDeclaration
import hu.bme.mit.gamma.activity.model.NamedActivityDeclarationReference
import hu.bme.mit.gamma.activity.model.OutputPin
import hu.bme.mit.gamma.activity.model.OutsideInputPinReference
import hu.bme.mit.gamma.activity.model.OutsideOutputPinReference
import hu.bme.mit.gamma.activity.model.Pin
import hu.bme.mit.gamma.activity.model.PseudoActivityNode
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.TriggerNode
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ActivityToLowlevelTransformer {
	// Auxiliary objects
	protected final extension TypeTransformer typeTransformer
	protected final extension ActionTransformer actionTransformer
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension TriggerTransformer triggerTransformer
	protected final extension ValueDeclarationTransformer valueDeclarationTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ActionUtil actionUtil = ActionUtil.INSTANCE
	// Factory objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActivityModelFactory activityFactory = ActivityModelFactory.eINSTANCE
	protected final extension StatechartModelFactory factory = StatechartModelFactory.eINSTANCE
	// Trace
	protected final Trace trace
	protected final State state
	protected final String prefix
	
	new(Trace trace, State state) {
		this(trace, state, true, 10)
	}
	
	new(Trace trace, State state, boolean functionInlining, int maxRecursionDepth) {
		this.trace = trace
		this.state = state
		this.prefix = state.containingStatechart.name + "_" + state.name + "_"
		this.typeTransformer = new TypeTransformer(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace,
				functionInlining, maxRecursionDepth)
		this.triggerTransformer = new TriggerTransformer(this.trace, functionInlining, maxRecursionDepth)
		this.valueDeclarationTransformer = new ValueDeclarationTransformer(this.trace)
		this.actionTransformer = new ActionTransformer(this.trace, functionInlining, maxRecursionDepth)
	}
	
	def ActivityDeclaration execute(ActivityDeclaration activity) {		
		return activity.transform
	}
	
	def ActivityDeclaration transform(ActivityDeclaration activity) {
		val recordField = new Pair(state, activity)
		
		if (trace.isActivityDeclarationMapped(recordField)) {
			return trace.getActivityDeclaration(recordField)
		}
		
		val newActivity = if (activity instanceof NamedActivityDeclaration) {
			createNamedActivityDeclaration => [
				name = prefix + activity.name
			]
		} else {
			createInlineActivityDeclaration
		}
		
		trace.put(state, activity, newActivity)
		
		for (pin : activity.pins) {
			newActivity.pins += pin.transformPin
		}
		
		newActivity.definition = activity.definition.transformDefinition
		
		return newActivity
	}
	
	def dispatch transformDefinition(ActivityDefinition definition) {
		val recordField = new Pair(state, definition as Definition)
		
		if (trace.isDefinitionMapped(recordField)) {
			return trace.getDefinition(recordField)
		}
		
		val newDefinition = createActivityDefinition
		
		trace.put(state, definition, newDefinition)
		
		for (variableDeclaration : definition.variableDeclarations) {
			newDefinition.variableDeclarations += variableDeclaration.transform
		}
		
		for (activityNode : definition.activityNodes) {
			newDefinition.activityNodes += activityNode.transformNode
		}
		
		for (flow : definition.flows) {
			newDefinition.flows += flow.transformFlow
		}
		
		return newDefinition
	}
	
	def dispatch transformDefinition(ActionDefinition definition) {
		val recordField = new Pair(state, definition as Definition)
		
		if (trace.isDefinitionMapped(recordField)) {
			return trace.getDefinition(recordField)
		}
		
		val newDefinition = createActionDefinition
		
		trace.put(state, definition, newDefinition)
		
		newDefinition.action = definition.action.transformAction.wrap
		
		return newDefinition
	}
	
	def transformPin(Pin pin) {
		val recordField = new Pair(state, pin)
		
		if (trace.isPinMapped(recordField)) {
			return trace.getPin(recordField)
		}
		
		val newPin = pin.clone => [
			it.name = prefix + it.name
		]
		
		trace.put(state, pin, newPin)
		
		newPin.type = pin.type.transformType
		
		return newPin
	}
	
	def dispatch transformFlow(DataFlow flow) {
		val recordField = new Pair(state, flow as Flow)
		
		if (trace.isFlowMapped(recordField)) {
			return trace.getFlow(recordField)
		}
		
		val newFlow = createDataFlow
		
		trace.put(state, flow, newFlow)
		
		newFlow.dataSourceReference = flow.dataSourceReference.transformDataSourceReference
		newFlow.dataTargetReference = flow.dataTargetReference.transformDataTargetReference
		newFlow.guard = flow.guard?.transformExpression?.wrapIntoMultiaryExpression(createAndExpression)
		
		return newFlow
	}
	
	def dispatch transformDataSourceReference(DataNodeReference dataSourceReference) {		
		return createDataNodeReference => [
			dataNode = dataSourceReference.dataNode.transformNode as DataNode
		]
	}
	
	def dispatch transformDataSourceReference(InsideInputPinReference dataSourceReference) {		
		return createInsideInputPinReference => [
			inputPin = dataSourceReference.inputPin.transformPin as InputPin
		]
	}
	
	def dispatch transformDataSourceReference(OutsideOutputPinReference dataSourceReference) {		
		return createOutsideOutputPinReference => [
			outputPin = dataSourceReference.outputPin.transformPin as OutputPin
		]
	}
	
	def dispatch transformDataTargetReference(DataNodeReference dataTargetReference) {		
		return createDataNodeReference => [
			dataNode = dataTargetReference.dataNode.transformNode as DataNode
		]
	}
	
	def dispatch transformDataTargetReference(InsideOutputPinReference dataTargetReference) {		
		return createInsideOutputPinReference => [
			outputPin = dataTargetReference.outputPin.transformPin as OutputPin
		]
	}
	
	def dispatch transformDataTargetReference(OutsideInputPinReference dataTargetReference) {		
		return createOutsideInputPinReference => [
			inputPin = dataTargetReference.inputPin.transformPin as InputPin
		]
	}
	
	def dispatch transformFlow(ControlFlow flow) {
		val recordField = new Pair(state, flow as Flow)
		
		if (trace.isFlowMapped(recordField)) {
			return trace.getFlow(recordField)
		}
		
		val newFlow = createControlFlow
		
		trace.put(state, flow, newFlow)
		
		newFlow.sourceNode = flow.sourceNode.transformNode
		newFlow.targetNode = flow.targetNode.transformNode
		newFlow.guard = flow.guard?.transformExpression?.wrapIntoMultiaryExpression(createAndExpression)
		
		return newFlow
	}
	
	def dispatch transformNode(ActionNode node) {
		val recordField = new Pair(state, node as ActivityNode)
		
		if (trace.isActivityNodeMapped(recordField)) {
			return trace.getActivityNode(recordField)
		}
		
		val newNode = createActionNode => [
			name = prefix + node.name
		]
		
		trace.put(state, node, newNode)
		
		newNode.activityDeclarationReference = node.activityDeclarationReference?.transformActivityDeclarationReference
		
		return newNode
	}
	
	def dispatch transformActivityDeclarationReference(InlineActivityDeclaration declarationReference) {
		return declarationReference.transform as InlineActivityDeclaration
	}
	
	def dispatch transformActivityDeclarationReference(NamedActivityDeclarationReference declarationReference) {
		return createNamedActivityDeclarationReference => [
			namedActivityDeclaration = declarationReference.namedActivityDeclaration.transform as NamedActivityDeclaration
		]
	}
	
	def dispatch ActivityNode transformNode(TriggerNode node) {
		val recordField = new Pair(state, node as ActivityNode)
		
		if (trace.isActivityNodeMapped(recordField)) {
			return trace.getActivityNode(recordField)
		}
		
		val newNode = createTriggerNode => [
			it.name = prefix + node.name
			it.triggerExpression = node.trigger.transformTrigger
		]
		
		trace.put(state, node, newNode)
		
		return newNode
	}
	
	def dispatch ActivityNode transformNode(PseudoActivityNode node) {
		val recordField = new Pair(state, node as ActivityNode)
		
		if (trace.isActivityNodeMapped(recordField)) {
			return trace.getActivityNode(recordField)
		}
		
		val newNode = node.clone => [
			it.name = prefix + it.name
		]
		
		trace.put(state, node, newNode)
		
		return newNode
	}
	
}
