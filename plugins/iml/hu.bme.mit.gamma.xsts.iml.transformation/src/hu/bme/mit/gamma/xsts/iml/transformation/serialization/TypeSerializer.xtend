/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.iml.transformation.serialization

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class TypeSerializer {
	// Singleton
	public static final TypeSerializer INSTANCE = new TypeSerializer
	//
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	//
	
	def dispatch String serializeType(Type type) {
		throw new IllegalArgumentException("Not known type: " + type)
	}
	
	def dispatch String serializeType(TypeReference type) '''«type.reference.serializeName».t''' // See module elements when serializing type declarations
	
	def dispatch String serializeType(BooleanTypeDefinition type) '''bool'''
	
	def dispatch String serializeType(IntegerTypeDefinition type) {
		// XSTS does not support native clocks, only annotations 
		val declaration = type.getContainerOfType(Declaration)
		if (declaration instanceof VariableDeclaration) {
			if (declaration.clock) {
				return 'int' // TODO
			}
		}
		// "Normal" usage
		return 'int'
	}
	
	def dispatch String serializeType(RationalTypeDefinition type) '''real'''
	
	def dispatch String serializeType(DecimalTypeDefinition type) '''real'''
	
	def dispatch String serializeType(EnumerationTypeDefinition type) '''«FOR literal : type.literals SEPARATOR ' | '»«literal.serializeName»«ENDFOR»'''
	
	def dispatch String serializeType(ArrayTypeDefinition type) '''((int, «type.elementType.serializeType») Map.t)'''
		
	//
	
}