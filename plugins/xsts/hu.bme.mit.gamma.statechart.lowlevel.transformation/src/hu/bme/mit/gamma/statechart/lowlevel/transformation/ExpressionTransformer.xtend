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
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.NullaryExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.model.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static com.google.common.base.Preconditions.checkState
import static hu.bme.mit.gamma.xsts.transformation.util.Namings.*

import static extension hu.bme.mit.gamma.expression.model.derivedfeatures.ExpressionModelDerivedFeatures.*

class ExpressionTransformer {
	// Auxiliary object
	protected final extension GammaEcoreUtil gammaEcoreUtil = new GammaEcoreUtil
	// Expression factory
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	// Trace needed for variable mappings
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
	}
	
	def dispatch Expression transformExpression(NullaryExpression expression) {
		return expression.clone(true, true)
	}
	
	def dispatch Expression transformExpression(UnaryExpression expression) {
		return create(expression.eClass) as UnaryExpression => [
			it.operand = expression.operand.transformExpression
		]
	}
	
	def dispatch Expression transformExpression(IfThenElseExpression expression) {
		return createIfThenElseExpression => [
			it.condition = expression.condition.transformExpression
			it.then = expression.then.transformExpression
			it.^else = expression.^else.transformExpression
		]
	}

	// Key method
	def dispatch Expression transformExpression(ReferenceExpression expression) {
		val declaration = expression.declaration
		if (declaration instanceof ConstantDeclaration) {
			// Constant type declarations have to be transformed as their right hand side is inlined
			val constantType = declaration.type
			if (constantType instanceof TypeReference) {
				val constantTypeDeclaration = constantType.reference
				val typeDefinition = constantTypeDeclaration.type
				if (!typeDefinition.isPrimitive) {
					if (!trace.isMapped(constantTypeDeclaration)) {
						val transformedTypeDeclaration = constantTypeDeclaration.transformTypeDeclaration
						val lowlevelPackage = trace.lowlevelPackage
						lowlevelPackage.typeDeclarations += transformedTypeDeclaration
					}
				}
			}
			return declaration.expression.transformExpression
		}
		checkState(declaration instanceof VariableDeclaration || 
			declaration instanceof ParameterDeclaration, declaration)
		val referenceExpression = createReferenceExpression
		if (declaration instanceof VariableDeclaration) {
			checkState(trace.isMapped(declaration), declaration)
			return referenceExpression => [
				it.declaration = trace.get(declaration)
			]
		}
		else if (declaration instanceof ParameterDeclaration) {
			checkState(trace.isMapped(declaration), declaration)
			return referenceExpression => [
				it.declaration = trace.get(declaration)
			]
		}
	}
	
	// Key method
	def dispatch Expression transformExpression(EventParameterReferenceExpression expression) {
		val port = expression.port
		val event = expression.event
		val parameter = expression.parameter
		return createReferenceExpression => [
			it.declaration = trace.get(port, event, parameter).get(EventDirection.IN)
		]
	}
	
	def dispatch Expression transformExpression(BinaryExpression expression) {
		return create(expression.eClass) as BinaryExpression => [
			it.leftOperand = expression.leftOperand.transformExpression
			it.rightOperand = expression.rightOperand.transformExpression
		]
	}
	
	def dispatch Expression transformExpression(MultiaryExpression expression) {
		val newExpression = create(expression.eClass) as MultiaryExpression
		for (containedExpression : expression.operands) {
			newExpression.operands += containedExpression.transformExpression
		}
		return newExpression
	}
	
	protected def dispatch Type transformType(Type type) {
		throw new IllegalArgumentException("Not known type: " + type)
	}

	protected def dispatch Type transformType(BooleanTypeDefinition type) {
		return type.clone(true, true)
	}

	protected def dispatch Type transformType(IntegerTypeDefinition type) {
		return type.clone(true, true)
	}

	protected def dispatch Type transformType(DecimalTypeDefinition type) {
		return type.clone(true, true)
	}
	
	protected def dispatch Type transformType(RationalTypeDefinition type) {
		return type.clone(true, true)
	}
	
	protected def dispatch Type transformType(EnumerationTypeDefinition type) {
		return type.clone(true, true)
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
		return createTypeReference => [
			it.reference = lowlevelTypeDeclaration
		]
	}
	
	protected def transformTypeDeclaration(TypeDeclaration typeDeclaration) {
		val newTypeDeclaration = constraintFactory.create(typeDeclaration.eClass) as TypeDeclaration => [
			it.name = getName(typeDeclaration)
			it.type = typeDeclaration.type.transformType
		]
		trace.put(typeDeclaration, newTypeDeclaration)
		return newTypeDeclaration
	}
	
	protected def VariableDeclaration transformVariable(VariableDeclaration variable) {
		return createVariableDeclaration => [
			it.name = variable.name
			it.type = variable.type.transformType
			it.expression = variable.expression?.transformExpression
		]
	}
	
}