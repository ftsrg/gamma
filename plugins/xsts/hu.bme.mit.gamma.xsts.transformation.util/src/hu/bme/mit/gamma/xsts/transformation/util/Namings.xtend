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
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import java.util.List

import static extension hu.bme.mit.gamma.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.LowlevelNamings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*

class Namings {
	
	// To Low-level: in LowlevelNamings
	
	// To XSTS: in XstsNamings
	
	// XSTS customization
	
	static def String customizeName(TimeoutDeclaration timeout, ComponentInstance instance) '''«customizeName(timeout, instance.name)»'''
	static def String customizeName(TimeoutDeclaration timeout, ComponentInstanceReference instance) '''«customizeName(timeout, instance.FQN)»'''
	static def String customizeName(TimeoutDeclaration timeout, String instance) '''«getName(timeout).variableName»_«instance»'''
	
	static def String customizeInputName(Event event, Port port, ComponentInstance instance) '''«customizeInputName(event, port, instance.name)»'''
	static def String customizeInputName(Event event, Port port, ComponentInstanceReference instance) '''«customizeInputName(event, port, instance.FQN)»'''
	static def String customizeInputName(Event event, Port port, String instance) '''«event.getInputName(port).eventName»_«instance»'''
	
	static def String customizeOutputName(Event event, Port port, ComponentInstance instance) '''«customizeOutputName(event, port, instance.name)»'''
	static def String customizeOutputName(Event event, Port port, ComponentInstanceReference instance) '''«customizeOutputName(event, port, instance.FQN)»'''
	static def String customizeOutputName(Event event, Port port, String instance) '''«event.getOutputName(port).eventName»_«instance»'''
	
//	static def String customizeInName(ParameterDeclaration parameterDeclaration, Port port, ComponentInstance instance) '''«customizeInName(parameterDeclaration, port, instance.name)»'''
//	static def String customizeInName(ParameterDeclaration parameterDeclaration, Port port, ComponentInstanceReference instance) '''«customizeInName(parameterDeclaration, port, instance.FQN)»'''
//	static def String customizeInName(ParameterDeclaration parameterDeclaration, Port port, String instance) '''«parameterDeclaration.getInName(port).variableName»_«instance»'''
	
	static def List<String> customizeInNames(ParameterDeclaration parameterDeclaration, Port port, ComponentInstance instance) { customizeInNames(parameterDeclaration, port, instance.name) }
	static def List<String> customizeInNames(ParameterDeclaration parameterDeclaration, Port port, ComponentInstanceReference instance) { customizeInNames(parameterDeclaration, port, instance.FQN) }
	static def List<String> customizeInNames(ParameterDeclaration parameterDeclaration, Port port, String instance) { parameterDeclaration.getInNames(port).map[it.variableName + "_" + instance] }
	
//	static def String customizeOutName(ParameterDeclaration parameterDeclaration, Port port, ComponentInstance instance) '''«customizeOutName(parameterDeclaration, port, instance.name)»'''
//	static def String customizeOutName(ParameterDeclaration parameterDeclaration, Port port, ComponentInstanceReference instance) '''«customizeOutName(parameterDeclaration, port, instance.FQN)»'''
//	static def String customizeOutName(ParameterDeclaration parameterDeclaration, Port port, String instance) '''«parameterDeclaration.getOutName(port).variableName»_«instance»'''
	
	static def List<String> customizeOutNames(ParameterDeclaration parameterDeclaration, Port port, ComponentInstance instance) { customizeOutNames(parameterDeclaration, port, instance.name) }
	static def List<String> customizeOutNames(ParameterDeclaration parameterDeclaration, Port port, ComponentInstanceReference instance) { customizeOutNames(parameterDeclaration, port, instance.FQN) }
	static def List<String> customizeOutNames(ParameterDeclaration parameterDeclaration, Port port, String instance) { parameterDeclaration.getOutNames(port).map[it.variableName + "_" + instance] }
	
//	static def String customizeName(VariableDeclaration variable, ComponentInstance instance) '''«customizeName(variable, instance.name)»'''
//	static def String customizeName(VariableDeclaration variable, ComponentInstanceReference instance) '''«customizeName(variable, instance.FQN)»'''
//	static def String customizeName(VariableDeclaration variable, String instance) '''«getName(variable).variableName»_«instance»'''
	
	static def List<String> customizeNames(VariableDeclaration variable, ComponentInstance instance) { customizeNames(variable, instance.name) }
	static def List<String> customizeNames(VariableDeclaration variable, ComponentInstanceReference instance) { customizeNames(variable, instance.FQN) }
	static def List<String> customizeNames(VariableDeclaration variable, String instance) { getNames(variable).map[it.variableName + "_" + instance] }
	
	// Region customization
	
	static def String customizeRegionTypeName(TypeDeclaration type, Component component) '''«getName(type).typeName»_«component.name»'''
	
	static def String customizeName(State state) '''«state.stateName.stateEnumLiteralName»''' // They are enum literals
	
	static def String customizeName(Region region, ComponentInstance instance) '''«customizeName(region, instance.name)»''' // For region variables
	static def String customizeName(Region region, ComponentInstanceReference instance) '''«customizeName(region, instance.FQN)»''' // For region variables
	static def String customizeName(Region region, String instance) '''«region.regionName.regionVariableName»_«instance»''' // For region variables
	
	// Orthogonal variable renames
	static def String getOrthogonalName(VariableDeclaration variable) '''_«variable.name»_''' // Caller must make sure there is no name collision
	// XSTS instantiation
	static def String getCustomizedName(VariableDeclaration variable, ComponentInstance instance) '''«variable.name»_«instance.name»''' // Caller must make sure there is no name collision

}