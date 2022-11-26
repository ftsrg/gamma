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
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Set

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*

class Namings {
	protected final static extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	public static final String arrayFieldName = "a"
	public static final String arrayFieldAccess = "." + arrayFieldName
	public static final String isStableVariableName = "isStable"
	
	static def String customizeEnumLiteralName(EnumerationLiteralExpression expression) '''«expression.reference.typeDeclaration.name»«expression.reference.name»'''
	static def String customizeEnumLiteralName(EnumerationTypeDefinition type, EnumerationLiteralDefinition literal) '''«type.typeDeclaration.name»«literal.name»''' 
	static def String customizeEnumLiteralName(State state, Region parentRegion) '''«parentRegion.name.regionTypeName»_«parentRegion.containingComponent.FQNUpToComponent»«state.customizeName»'''
	
	static def createEnumMapping(Set<TypeDeclaration> typeDeclarations) {
		val map = newHashMap
		
		for (typeDeclaration : typeDeclarations) {
			val type = typeDeclaration.typeDefinition
			if (type instanceof EnumerationTypeDefinition) {
				for (literal : type.literals) {
					map.put(type.customizeEnumLiteralName(literal), literal.name)
				}
			}
		}
		
		return map
	}
}