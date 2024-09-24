/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.MessageQueue
import hu.bme.mit.gamma.statechart.interface_.Clock
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.LowlevelNamings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.QueueNamings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*

class Namings {
	
	protected final static extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final static extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	protected final static extension ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE
	//
	
	// To Low-level: in LowlevelNamings
	
	// To XSTS: in XstsNamings
	
	static def String getDelayVariableName() '''__Delay__'''
	static def String getInstanceEndcodingVariableName() '''__InstanceEncoding__'''
	
	// Types
	
	static def String customizeTypeName(TypeDeclaration type) '''«getName(type)»'''
	static def String customizeEnumLiteralName(EnumerationLiteralDefinition literal) '''«getName(literal).enumLiteralName»'''
	
	// Asynchronous message queue - XSTS customization
	
	static def String customizeMasterQueueName(MessageQueue queue, ComponentInstance instance) {
		val type = createIntegerTypeDefinition
		val names = type.createVariableDeclaration(
				'''«queue.getMasterQueueName(instance)»''').names
		checkState(names.size == 1)
		return names.head
	}
	
	static def List<String> customizeSlaveQueueName(ParameterDeclaration parameterDeclaration,
			Port port, ComponentInstance instance) {
		val type = parameterDeclaration.type.clone 
		val names = type.createVariableDeclaration(
				'''«parameterDeclaration.getSlaveQueueName(port, instance)»''').names
		return names
	}
	
	// XSTS customization
	
	static def String customizeName(TimeoutDeclaration timeout, ComponentInstance instance) '''«customizeName(timeout, instance.name)»'''
	static def String customizeName(TimeoutDeclaration timeout, ComponentInstanceReferenceExpression instance) '''«customizeName(timeout, instance.FQN)»'''
	static def String customizeName(TimeoutDeclaration timeout, String instance) '''«getName(timeout).variableName»_«instance»'''
	
	static def String customizeName(Clock clock, ComponentInstance instance) '''«customizeName(clock, instance.name)»'''
	static def String customizeName(Clock clock, ComponentInstanceReferenceExpression instance) '''«customizeName(clock, instance.FQN)»'''
	static def String customizeName(Clock clock, String instance) '''«getName(clock).variableName»_«instance»'''
	
	static def String customizeInputName(Event event, Port port, ComponentInstance instance) '''«customizeInputName(event, port, instance.name)»'''
	static def String customizeInputName(Event event, Port port, ComponentInstanceReferenceExpression instance) '''«customizeInputName(event, port, instance.FQN)»'''
	static def String customizeInputName(Event event, Port port, String instance) '''«event.getInputName(port).eventName»_«instance»'''
	
	static def String customizeOutputName(Event event, Port port, ComponentInstance instance) '''«customizeOutputName(event, port, instance.name)»'''
	static def String customizeOutputName(Event event, Port port, ComponentInstanceReferenceExpression instance) '''«customizeOutputName(event, port, instance.FQN)»'''
	static def String customizeOutputName(Event event, Port port, String instance) '''«event.getOutputName(port).eventName»_«instance»'''
	
	static def List<String> customizeInNames(ParameterDeclaration parameterDeclaration, Port port) { getInNames(parameterDeclaration, port).map[it.variableName].toList }
	static def List<String> customizeInNames(ParameterDeclaration parameterDeclaration, Port port, ComponentInstance instance) { customizeInNames(parameterDeclaration, port, instance.name) }
	static def List<String> customizeInNames(ParameterDeclaration parameterDeclaration, Port port, ComponentInstanceReferenceExpression instance) { customizeInNames(parameterDeclaration, port, instance.FQN) }
	static def List<String> customizeInNames(ParameterDeclaration parameterDeclaration, Port port, String instance) { parameterDeclaration.getInNames(port).map[it.variableName + "_" + instance] }
	
	static def List<String> customizeOutNames(ParameterDeclaration parameterDeclaration, Port port) { getOutNames(parameterDeclaration, port).map[it.variableName].toList }
	static def List<String> customizeOutNames(ParameterDeclaration parameterDeclaration, Port port, ComponentInstance instance) { customizeOutNames(parameterDeclaration, port, instance.name) }
	static def List<String> customizeOutNames(ParameterDeclaration parameterDeclaration, Port port, ComponentInstanceReferenceExpression instance) { customizeOutNames(parameterDeclaration, port, instance.FQN) }
	static def List<String> customizeOutNames(ParameterDeclaration parameterDeclaration, Port port, String instance) { parameterDeclaration.getOutNames(port).map[it.variableName + "_" + instance] }
	
	static def List<String> customizeNames(VariableDeclaration variable) { variable.names.map[it.variableName].toList }
	static def List<String> customizeNames(VariableDeclaration variable, ComponentInstance instance) { customizeNames(variable, instance.name) }
	static def List<String> customizeNames(VariableDeclaration variable, ComponentInstanceReferenceExpression instance) { customizeNames(variable, instance.FQN ) }
	static def List<String> customizeNames(VariableDeclaration variable, String instance) { getNames(variable).map[it.variableName + "_" + instance] }
	
	// Region customization
	
	static def String customizeRegionTypeName(Region region) '''«region.regionName.regionTypeName.customizeRegionTypeName(region.containingStatechart.name)»'''
	static def String customizeRegionTypeName(TypeDeclaration type, Component component) '''«getName(type).typeName.customizeRegionTypeName(component.name)»'''
	static def String customizeRegionTypeName(String typeName, String componentName) '''«typeName»_«componentName»'''
	
	static def String customizeName(State state) '''«state.stateName.stateEnumLiteralName»''' // They are enum literals
	
	static def String customizeName(Region region, ComponentInstance instance) '''«customizeName(region, instance.name)»''' // For region variables
	static def String customizeName(Region region, ComponentInstanceReferenceExpression instance) '''«customizeName(region, instance.FQN)»''' // For region variables
	static def String customizeName(Region region, String instance) '''«region.regionName.regionVariableName»_«instance»''' // For region variables
	
	// Orthogonal variable renames
	static def String getOrthogonalName(VariableDeclaration variable) '''_«variable.name»_''' // Caller must make sure there is no name collision
	// XSTS instantiation
	static def String getCustomizedName(VariableDeclaration variable, ComponentInstance instance) '''«variable.name»_«instance.name»''' // Caller must make sure there is no name collision

}