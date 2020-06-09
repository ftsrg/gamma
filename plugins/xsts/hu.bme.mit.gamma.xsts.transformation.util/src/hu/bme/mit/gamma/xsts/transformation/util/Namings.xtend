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
package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Event

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition

class Namings {
	
	// To Low-level
	
	static def String getName(StatechartDefinition statechart) '''«statechart.name»'''
	static def String getStateName(State state) '''«state.name»'''
	static def String getRegionName(Region region) '''«region.name»'''
	static def String getInputName(Event event, Port port) '''«port.name»_«event.name»_In'''
	static def String getOutputName(Event event, Port port) '''«port.name»_«event.name»_Out'''
	static def String getInName(ParameterDeclaration parameterDeclaration, Port port) '''«parameterDeclaration.containingEvent.getInputName(port)»_«parameterDeclaration.name»'''
	static def String getOutName(ParameterDeclaration parameterDeclaration, Port port) '''«parameterDeclaration.containingEvent.getOutputName(port)»_«parameterDeclaration.name»'''
	static def String getComponentParameterName(ParameterDeclaration parameter) '''«parameter.name»'''
	static def String getName(TimeoutDeclaration timeout) '''«timeout.name»'''
	static def String getName(VariableDeclaration variable) '''«variable.name»'''
	static def String getName(TypeDeclaration type) '''«type.name»'''
	
	// To XSTS
	
	static def String getTypeName(String lowlevelName) '''«lowlevelName»'''
	static def String getVariableName(String lowlevelName) '''«lowlevelName»'''
	static def String getEventName(String lowlevelName) '''«lowlevelName»'''
	
	static def String getStateEnumLiteralName(String lowlevelName) '''«lowlevelName»'''
	static def String getRegionTypeName(String lowlevelName) '''«lowlevelName.toFirstUpper»'''
	static def String getRegionVariableName(String lowlevelName) '''«lowlevelName.toFirstLower»'''

	// XSTS customization
	
	static def String customizeName(VariableDeclaration variable, ComponentInstance instance) '''«getName(variable).variableName»_«instance.name»'''
	static def String customizeName(TimeoutDeclaration timeout, ComponentInstance instance) '''«getName(timeout).variableName»_«instance.name»'''
	static def String customizeRegionTypeName(TypeDeclaration type, Component component) '''«getName(type).typeName»_«component.name»'''
	static def String customizeInName(ParameterDeclaration parameterDeclaration, Port port, ComponentInstance instance) '''«parameterDeclaration.getInName(port).variableName»_«instance.name»'''
	static def String customizeOutName(ParameterDeclaration parameterDeclaration, Port port, ComponentInstance instance) '''«parameterDeclaration.getOutName(port).variableName»_«instance.name»'''
	static def String customizeInputName(Event event, Port port, ComponentInstance instance) '''«event.getInputName(port).eventName»_«instance.name»'''
	static def String customizeOutputName(Event event, Port port, ComponentInstance instance) '''«event.getOutputName(port).eventName»_«instance.name»'''
	// Regions
	static def String customizeName(State state) '''«state.stateName.stateEnumLiteralName»''' // They are enum literals
	static def String customizeName(Region region, ComponentInstance instance) '''«region.regionName.regionVariableName»_«instance.name»''' // For region variables
	
}