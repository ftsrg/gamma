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
import hu.bme.mit.gamma.activity.model.InlineActivityDeclaration
import hu.bme.mit.gamma.activity.model.InputPin
import hu.bme.mit.gamma.activity.model.InsideInputPinReference
import hu.bme.mit.gamma.activity.model.InsideOutputPinReference
import hu.bme.mit.gamma.activity.model.NamedActivityDeclaration
import hu.bme.mit.gamma.activity.model.NamedActivityDeclarationReference
import hu.bme.mit.gamma.activity.model.OutputPin
import hu.bme.mit.gamma.activity.model.OutsideInputPinReference
import hu.bme.mit.gamma.activity.model.OutsideOutputPinReference
import hu.bme.mit.gamma.activity.model.PseudoActivityNode
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.util.GammaEcoreUtil

class ActivityToLowlevelTransformer {
	// Auxiliary objects
	protected final extension TypeTransformer typeTransformer
	protected final extension ActionTransformer actionTransformer
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ValueDeclarationTransformer valueDeclarationTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ActionUtil actionUtil = ActionUtil.INSTANCE
	// Factory objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActivityModelFactory activityFactory = ActivityModelFactory.eINSTANCE
	// Trace
	protected final Trace trace
	
	new(Trace trace) {
		this(trace, true, 10)
	}
	
	new(Trace trace, boolean functionInlining, int maxRecursionDepth) {
		this.trace = trace
		this.typeTransformer = new TypeTransformer(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace,
				functionInlining, maxRecursionDepth)
		this.valueDeclarationTransformer = new ValueDeclarationTransformer(this.trace)
		this.actionTransformer = new ActionTransformer(this.trace, functionInlining, maxRecursionDepth)
	}
	
	def ActivityDeclaration execute(ActivityDeclaration activity) {		
		return activity.transform
	}
	
	def ActivityDeclaration transform(ActivityDeclaration activity) {
		if (trace.isMapped(activity)) {
			return trace.get(activity)
		}
		
		val newActivity = if (activity instanceof NamedActivityDeclaration) {
			createNamedActivityDeclaration => [
				name = activity.name
			]
		} else {
			createInlineActivityDeclaration
		}
		
		trace.put(activity, newActivity)
		
		for (pin : activity.pins) {
			newActivity.pins += pin.transformPin
		}
		
		newActivity.definition = activity.definition.transformDefinition
		
		return newActivity
	}
	
	def dispatch transformDefinition(ActivityDefinition definition) {
		if (trace.isMapped(definition)) {
			return trace.get(definition)
		}
		
		val newDefinition = createActivityDefinition
		
		trace.put(definition, newDefinition)
		
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
		if (trace.isMapped(definition)) {
			return trace.get(definition)
		}
		
		val newDefinition = createActionDefinition
		
		trace.put(definition, newDefinition)
		
		newDefinition.action = definition.action.transformAction.wrap
		
		return newDefinition
	}
	
	def dispatch transformPin(OutputPin pin) {
		if (trace.isMapped(pin)) {
			return trace.get(pin)
		}
		
		val newPin = createOutputPin => [
			type = pin.type.transformType
		]
		
		trace.put(pin, newPin)
		
		return newPin
	}
	
	def dispatch transformPin(InputPin pin) {
		if (trace.isMapped(pin)) {
			return trace.get(pin)
		}
		
		val newPin = createInputPin => [
			type = pin.type.transformType
		]
		
		trace.put(pin, newPin)
		
		return newPin
	}
	
	def dispatch transformFlow(DataFlow flow) {
		if (trace.isMapped(flow)) {
			return trace.get(flow)
		}
		
		val newFlow = createDataFlow => [
			dataSourceReference = flow.dataSourceReference.transformDataSourceReference
			dataTargetReference = flow.dataTargetReference.transformDataTargetReference
		]
		
		trace.put(flow, newFlow)
		
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
		if (trace.isMapped(flow)) {
			return trace.get(flow)
		}
		
		val newFlow = createControlFlow => [
			sourceNode = flow.sourceNode.transformNode
			targetNode = flow.targetNode.transformNode
		]
		
		trace.put(flow, newFlow)
		
		return newFlow
	}
	
	def dispatch transformNode(ActionNode node) {
		if (trace.isMapped(node)) {
			return trace.get(node)
		}
		
		val newNode = createActionNode => [
			name = node.name
			activityDeclarationReference = node.activityDeclarationReference?.transformActivityDeclarationReference
		]
		
		trace.put(node, newNode)
		
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
	
	def dispatch ActivityNode transformNode(PseudoActivityNode node) {
		if (trace.isMapped(node)) {
			return trace.get(node)
		}
		
		val newNode = node.clone
		
		trace.put(node, newNode)
		
		return newNode
	}
	
}
