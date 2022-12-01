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
package hu.bme.mit.gamma.codegeneration.java.util

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeReference

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class TypeSerializer {
	// Singleton
	public static final TypeSerializer INSTANCE = new TypeSerializer
	protected new() {}
	//
	
	def dispatch String serialize(Type type) {
		throw new IllegalArgumentException("Not supported expression: " + type)
	}
	
	def dispatch String serialize(TypeReference type) '''«IF type.reference.type.isPrimitive»«type.reference.type.serialize»«ELSE»«type.reference.name»«ENDIF»'''
	
	def dispatch String serialize(BooleanTypeDefinition type) '''boolean'''
	
	def dispatch String serialize(IntegerTypeDefinition type) '''int''' // Long cannot be passed as an Object then recast to int
	
	def dispatch String serialize(DecimalTypeDefinition type) '''double'''
	
	def dispatch String serialize(RationalTypeDefinition type) '''double'''
	
	def dispatch String serialize(ArrayTypeDefinition type) '''«type.elementType.serialize»[]'''
	
	def dispatch String serialize(EnumerationTypeDefinition type) '''«type.typeDeclaration.name»'''
	
	def dispatch String serialize(RecordTypeDefinition type) '''«type.typeDeclaration.name»'''

}
