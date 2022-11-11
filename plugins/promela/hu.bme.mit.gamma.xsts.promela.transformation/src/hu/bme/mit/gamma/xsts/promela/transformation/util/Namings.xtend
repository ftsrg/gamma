/********************************************************************************
 * Copyright (c) 2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.promela.transformation.util

import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import java.util.List

import static hu.bme.mit.gamma.lowlevel.xsts.transformation.Namings.*

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*

class Namings {
	public static final String arrayFieldName = "a"
	public static final String arrayFieldAccess = "." + arrayFieldName
	
	static def String customizeEnumLiteralName(EnumerationLiteralExpression expression) '''«expression.reference.typeDeclaration.name»«expression.reference.name»'''
	static def String customizeEnumLiteralName(EnumerationTypeDefinition type, EnumerationLiteralDefinition literal) '''«type.typeDeclaration.name»«literal.name»'''
	static def String customizeEnumLiteralName(State state) '''«state.parentRegion.name.regionTypeName»_«state.parentRegion.containingComponent.FQNUpToComponent»«state.customizeName»''' 
	static def String customizeEnumLiteralName(Region region, String literal) '''«region.name.regionTypeName»_«region.containingComponent.FQNUpToComponent»«literal»'''
	static def String customizeEnumLiteralName(State state, Region parentRegion) '''«parentRegion.name.regionTypeName»_«parentRegion.containingComponent.FQNUpToComponent»«state.customizeName»'''
	
	static def createEnumMapping(List<Region> regions) {
		val map = newHashMap
		for (region : regions) {
			map.putAll(region.createEnumMapping)
		}
		return map
	}
	
	static def createEnumMapping(Region region) {
		val map = newHashMap

		// The __Inactive__ literal is needed
		map.put(region.customizeEnumLiteralName(INACTIVE_ENUM_LITERAL), INACTIVE_ENUM_LITERAL)

		// Enum literals are based on states
		for (state : region.states) {
			map.put(state.customizeEnumLiteralName(region), state.name.stateEnumLiteralName)
		}

		// History literals
		if (region.hasHistory) {
			for (state : region.states) {
				val name = state.name
				map.put(region.customizeEnumLiteralName(name.stateInactiveHistoryEnumLiteralName), name.stateInactiveHistoryEnumLiteralName)
			}
		}
		
		return map
	}
}