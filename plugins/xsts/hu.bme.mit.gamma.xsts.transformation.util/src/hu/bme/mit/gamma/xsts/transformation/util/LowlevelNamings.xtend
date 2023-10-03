/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.expression.util.FieldHierarchy
import hu.bme.mit.gamma.statechart.interface_.Clock
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import java.util.List

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class LowlevelNamings {
	//
	protected static final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	//
	static def String getName(StatechartDefinition statechart) '''«statechart.name»'''
	static def String getStateName(State state) '''«state.name»'''
	static def String getRegionName(Region region) '''«region.name»'''
	static def String getInputName(Event event, Port port) '''«port.name»_«event.name»_In'''
	static def String getOutputName(Event event, Port port) '''«port.name»_«event.name»_Out'''
	static def String getInName(ParameterDeclaration parameterDeclaration, Port port) '''«parameterDeclaration.containingEvent.getInputName(port)»_«parameterDeclaration.name»'''
	static def String getOutName(ParameterDeclaration parameterDeclaration, Port port) '''«parameterDeclaration.containingEvent.getOutputName(port)»_«parameterDeclaration.name»'''
	static def String getComponentParameterName(ParameterDeclaration parameter) '''«parameter.name»'''
	static def String getName(VariableDeclaration variable) '''«variable.name»'''
	static def String getName(TimeoutDeclaration timeout) '''«timeout.name»'''
	static def String getName(Clock clock) '''«clock.name»'''
	static def String getName(TypeDeclaration type) '''«type.name»'''
	static def String getName(EnumerationLiteralDefinition literal) '''«literal.name»'''
	
	static def List<String> getInNames(ParameterDeclaration parameterDeclaration, Port port) {
		return parameterDeclaration.namePostfixes.map['''«parameterDeclaration.getInName(port)»«it»''']
	}
	static def List<String> getOutNames(ParameterDeclaration parameterDeclaration, Port port) {
		return parameterDeclaration.namePostfixes.map['''«parameterDeclaration.getOutName(port)»«it»''']
	}
	static def List<String> getComponentParameterNames(ParameterDeclaration parameter) {
		return parameter.namePostfixes.map['''«parameter.getComponentParameterName»«it»''']
	}
	static def List<String> getNames(VariableDeclaration variable) {
		return variable.namePostfixes.map['''«variable.getName»«it»''']
	}
	
	static def List<String> getNames(ConstantDeclaration variable) {
		return variable.namePostfixes.map['''«variable.getName»«it»''']
	}
	
	protected static def List<String> getNamePostfixes(ValueDeclaration variable) {
		val type = variable.typeDefinition
		val hierarchyList = type.fieldHierarchies
		return hierarchyList.names
	}
	
	protected static def List<String> getNames(List<FieldHierarchy> fields) {
		return fields.map[it.fields.map["_" + it.name].join]
	}
	
}