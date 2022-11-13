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
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.statechart.interface_.InterfaceRealization
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*

class Namings {
	protected final static extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	public static final String arrayFieldName = "a"
	public static final String arrayFieldAccess = "." + arrayFieldName
	
	static def String customizeEnumLiteralName(EnumerationLiteralExpression expression) '''«expression.reference.typeDeclaration.name»«expression.reference.name»'''
	static def String customizeEnumLiteralName(EnumerationTypeDefinition type, EnumerationLiteralDefinition literal) '''«type.typeDeclaration.name»«literal.name»''' 
	static def String customizeEnumLiteralName(State state, Region parentRegion) '''«parentRegion.name.regionTypeName»_«parentRegion.containingComponent.FQNUpToComponent»«state.customizeName»'''
	
	static def createEnumMapping(Package gammaPackage) {
		val references = newArrayList
		// Explicit imports
		for (Package importedPackage : gammaPackage.getComponentImports) {
			references += importedPackage.getAllContentsOfType(TypeReference)
		}
		// Native references in the case the unfolded packages
		references += gammaPackage.getAllContentsOfType(TypeReference)
		// Events and parameters
		for (realization : gammaPackage.getAllContentsOfType(InterfaceRealization)) {
			references += realization.interface.getAllContentsOfType(TypeReference)
		}
		
		val typeDefinitions = newArrayList
		for (reference : references) {
			val type = reference.reference.typeDefinition
			if (type instanceof EnumerationTypeDefinition) {
				if (!(typeDefinitions.contains(type))) {
					typeDefinitions += type
				}
			}
		}
		
		val map = newHashMap
		for (type : typeDefinitions) {
			for (literal : type.literals) {
				map.put(type.customizeEnumLiteralName(literal), literal.name)
			}
		}
		return map
	}
}