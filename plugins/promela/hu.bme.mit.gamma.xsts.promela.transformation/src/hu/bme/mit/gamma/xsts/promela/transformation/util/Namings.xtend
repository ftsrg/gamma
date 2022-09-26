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
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.XstsNamings.*

class Namings {
	public static final String arrayFieldName = "a"
	public static final String arrayFieldAccess = "." + arrayFieldName
	static def String costumizeEnumLiteralName(EnumerationLiteralExpression expression) '''«expression.reference.typeDeclaration.name»«expression.reference.name»'''
	static def String costumizeEnumLiteralName(EnumerationTypeDefinition type, EnumerationLiteralDefinition literal) '''«type.typeDeclaration.name»«literal.name»'''
	static def String costumizeEnumLiteralName(State state, Region parentRegion, ComponentInstanceReferenceExpression instance) '''«parentRegion.name.regionTypeName»_«instance.FQN»«state.customizeName»'''
	static def String costumizeEnumLiteralName(State state, Region parentRegion, SynchronousComponentInstance instance) '''«parentRegion.name.regionTypeName»_«instance.FQN»«state.customizeName»'''
}