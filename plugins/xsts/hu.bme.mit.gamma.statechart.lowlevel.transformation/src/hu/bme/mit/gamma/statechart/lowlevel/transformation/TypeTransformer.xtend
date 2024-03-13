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
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static hu.bme.mit.gamma.xsts.transformation.util.LowlevelNamings.*

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class TypeTransformer {
	
	// Auxiliary object
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	
	// Expression factory
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Trace needed for variable mappings
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
	}
	
	protected def dispatch Type transformType(Type type) {
		throw new IllegalArgumentException("Not known type: " + type)
	}

	protected def dispatch Type transformType(BooleanTypeDefinition type) {
		return type.clone
	}

	protected def dispatch Type transformType(IntegerTypeDefinition type) {
		return type.clone
	}

	protected def dispatch Type transformType(DecimalTypeDefinition type) {
		return type.clone
	}
	
	protected def dispatch Type transformType(RationalTypeDefinition type) {
		return type.clone
	}
	
	protected def dispatch Type transformType(EnumerationTypeDefinition type) {
		return type.clone
	}
	
	protected def dispatch Type transformType(ArrayTypeDefinition type) {
		// ExpressionModelDerivedFeatures.getNativeTypes creates the correct types, cloning is enough
		return type.clone
	}
	
	protected def dispatch Type transformType(RecordTypeDefinition type) {
		// Due to the transformation and usage of ExpressionModelDerivedFeatures.getNativeTypes,
		// this situation must never occur
		throw new IllegalArgumentException("Record types cannot be transformed like this: " + type)
	}
	
	protected def dispatch Type transformType(TypeReference type) {
		val typeDeclaration = type.reference
		val typeDefinition = typeDeclaration.type
		// Inlining primitive types
		if (typeDefinition.isPrimitive) {
			return typeDefinition.transformType
		}
		val lowlevelTypeDeclaration = if (trace.isMapped(typeDeclaration)) {
			trace.get(typeDeclaration)
		}
		else {
			// Transforming type declaration
			val transformedTypeDeclaration = typeDeclaration.transformTypeDeclaration
			val lowlevelPackage = trace.lowlevelPackage
			lowlevelPackage.typeDeclarations += transformedTypeDeclaration
			transformedTypeDeclaration
		}
		return lowlevelTypeDeclaration.createTypeReference
	}
	
	protected def transformTypeDeclaration(TypeDeclaration typeDeclaration) {
		val newTypeDeclaration = constraintFactory.createTypeDeclaration => [
			it.name = getName(typeDeclaration)
			it.type = typeDeclaration.type.transformType
		]
		trace.put(typeDeclaration, newTypeDeclaration)
		return newTypeDeclaration
	}
	
}