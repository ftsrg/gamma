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
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.NullaryExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static com.google.common.base.Preconditions.checkState
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression

class ExpressionTransformer {
	// Trace needed for variable references
	protected final Trace trace
	// Auxiliary objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	
	new(Trace trace) {
		this.trace = trace
	}
	
	def dispatch Expression transformExpression(NullaryExpression expression) {
		return expression.clone
	}
	
	def dispatch Expression transformExpression(UnaryExpression expression) {
		return expression.clone => [
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
	def dispatch Expression transformExpression(DirectReferenceExpression expression) {
		checkState(expression.declaration instanceof VariableDeclaration)
		val declaration = expression.declaration as VariableDeclaration
		return expression.clone => [
			it.declaration = trace.getXStsVariable(declaration)
		]
	}
	
	// Key method
	def dispatch Expression transformExpression(EnumerationLiteralExpression expression) {
		val lowlevelEnumLiteral = expression.reference
		val index = lowlevelEnumLiteral.index
		val lowlevelEnumTypeDeclaration = lowlevelEnumLiteral.getContainerOfType(TypeDeclaration)
		val xStsEnumTypeDeclaration = trace.getXStsTypeDeclaration(lowlevelEnumTypeDeclaration)
		val xStsEnumTypeDefinition = xStsEnumTypeDeclaration.type as EnumerationTypeDefinition
		return createEnumerationLiteralExpression => [
			it.reference = xStsEnumTypeDefinition.literals.get(index)
		]
	}
	
	def dispatch Expression transformExpression(BinaryExpression expression) {
		return expression.clone => [
			it.leftOperand = expression.leftOperand.transformExpression
			it.rightOperand = expression.rightOperand.transformExpression
		]
	}
	
	def dispatch Expression transformExpression(MultiaryExpression expression) {
		val newExpression = expression.clone
		newExpression.operands.clear
		for (containedExpression : expression.operands) {
			newExpression.operands += containedExpression.transformExpression
		}
		return newExpression
	}
	
	def dispatch Type transformType(Type type) {
		return type.clone
	}
	
	def dispatch Type transformType(TypeReference type) {
		val lowlevelTypeDeclaration = type.reference
		checkState(trace.getXStsTypeDeclaration(lowlevelTypeDeclaration) !== null)
		val xStsTypeDeclaration = trace.getXStsTypeDeclaration(lowlevelTypeDeclaration)
		return createTypeReference => [
			it.reference = xStsTypeDeclaration
		]
	}
	
}