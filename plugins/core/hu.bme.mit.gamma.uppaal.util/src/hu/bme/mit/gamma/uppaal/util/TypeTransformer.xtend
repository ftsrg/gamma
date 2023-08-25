/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution) and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.util

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import uppaal.NTA
import uppaal.expressions.Expression
import uppaal.expressions.ExpressionsFactory
import uppaal.types.TypeDefinition
import uppaal.types.TypesFactory

class TypeTransformer {
	// NTA builder
	protected final NTA nta
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	protected final extension TypesFactory typFact = TypesFactory.eINSTANCE
	
	new(NTA nta) {
		this.nta = nta
	}
	
	// Type references, such as enums and typedefs for primitive types
	def transformTypeDeclaration(TypeDeclaration type) {
		return type.type.transformType
	}
	
	def dispatch TypeDefinition transformType(TypeReference type) {
		val referredType = type.reference
		return referredType.transformTypeDeclaration
	}
	
	def dispatch TypeDefinition transformType(EnumerationTypeDefinition type) {
		val literalSize = type.literals.size - 1
		val lowerBound = createLiteralExpression => [it.text = 0.toString]
		val upperBound = createLiteralExpression => [it.text = literalSize.toString]
		return createRange(lowerBound, upperBound)
	}
	
	def dispatch TypeDefinition transformType(ArrayTypeDefinition type) {
		val elementType = type.elementType
		return elementType.transformType // The variable creator has to add the indexes
	}
	
	def dispatch TypeDefinition transformType(IntegerTypeDefinition type) {
		return createTypeReference => [it.referredType = nta.int]
	}
	
	def dispatch TypeDefinition transformType(BooleanTypeDefinition type) {
		return createTypeReference => [it.referredType = nta.bool]
	}
	
	def TypeDefinition createRange(Expression lowerBound, Expression upperBound) {
		return createRangeTypeSpecification => [
			it.bounds = createIntegerBounds => [
				it.lowerBound = lowerBound
				it.upperBound = upperBound
			]
		]
	}
	
}