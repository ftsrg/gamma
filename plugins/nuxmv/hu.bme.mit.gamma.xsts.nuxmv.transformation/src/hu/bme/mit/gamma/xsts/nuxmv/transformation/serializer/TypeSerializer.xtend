/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.nuxmv.transformation.serializer

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class TypeSerializer {
	// Singleton
	public static final TypeSerializer INSTANCE = new TypeSerializer
	//
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
		
	// Type declaration
	
	def String serializeTypeDeclaration(TypeDeclaration typeDeclaration) '''
		«typeDeclaration.name» = «typeDeclaration.type.serializeType»
	'''
	
	// Type
	
	def dispatch String serializeType(Type type) {
		throw new IllegalArgumentException("Not known type: " + type)
	}
	
	def dispatch String serializeType(TypeReference type) '''«type.reference.type.serializeType»'''
	
	def dispatch String serializeType(BooleanTypeDefinition type) '''boolean'''
	
	def dispatch String serializeType(IntegerTypeDefinition type) {
		// XSTS does not support native clocks, only annotations 
		val declaration = type.getContainerOfType(Declaration)
		if (declaration instanceof VariableDeclaration) {
			if (declaration.clock) {
				return 'clock'
			}
		}
		// "Normal" usage
		return 'integer'
	}
	
	def dispatch String serializeType(RationalTypeDefinition type) '''real'''
	
	def dispatch String serializeType(DecimalTypeDefinition type) '''real'''
	
	def dispatch String serializeType(EnumerationTypeDefinition type) '''{ «FOR literal : type.literals SEPARATOR ', '»«literal.name»«ENDFOR» }'''
	
	// Arrays: both sides are inclusive
	// Note that WRITE, READ and CONSTARRAY are officially not supported with these kinds of (normal) arrays
	// In turn, integer arrays cannot contain enums/ranges :(
	def dispatch String serializeType(ArrayTypeDefinition type) '''array 0..«
		type.size.evaluate /*- 1 // To make it semantic-preserving - OOB indexing in SMV will return the highest index's value */» of «type.elementType.serializeType»'''
	
	// 

}