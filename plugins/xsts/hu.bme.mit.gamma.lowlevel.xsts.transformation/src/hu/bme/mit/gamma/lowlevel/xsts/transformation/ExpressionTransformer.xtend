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

import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.NullaryExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.statechart.lowlevel.model.StateReferenceExpression
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class ExpressionTransformer {
	// Trace needed for variable references
	protected final Trace trace
	// Auxiliary objects
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	
	new() {
		this(new Trace(null, null)) // For ad-hoc expression transformations
	}
	
	new(Trace trace) {
		this.trace = trace
	}

	def dispatch Expression transformExpression(IfThenElseExpression expression) {
		return createIfThenElseExpression => [
			it.condition = expression.condition.transformExpression
			it.then = expression.then.transformExpression
			it.^else = expression.^else.transformExpression
		]
	}
	
	def dispatch Expression transformExpression(IntegerRangeLiteralExpression expression) {
		return createIntegerRangeLiteralExpression => [
			it.leftInclusive = expression.leftInclusive
			it.leftOperand = expression.leftOperand.transformExpression
			it.rightInclusive = expression.rightInclusive
			it.rightOperand = expression.rightOperand.transformExpression
		]
	}

	def dispatch Expression transformExpression(DirectReferenceExpression expression) {
		val declaration = expression.declaration
		if (declaration instanceof ParameterDeclaration) {
			// Loop iteration parameters
			return trace.getXStsParameter(declaration).createReferenceExpression
		}
		checkState(declaration instanceof VariableDeclaration, declaration)
		val variableDeclaration = declaration as VariableDeclaration
		if (variableDeclaration.final) {
			val initialValue = variableDeclaration.initialValue
			return initialValue.transformExpression
		}
		return trace.getXStsVariable(variableDeclaration).createReferenceExpression
	}
	
	def dispatch Expression transformExpression(ArrayAccessExpression expression) {
		val operand = expression.operand
		val index = expression.index
		return createArrayAccessExpression => [
			it.operand = operand.transformExpression
			it.index = index.transformExpression
		]
	}
	
	def dispatch Expression transformExpression(StateReferenceExpression expression) {
		val lowlevelRegion = expression.region
		val lowlevelState = expression.state
		val xStsVariable = trace.getXStsVariable(lowlevelRegion)
		val xStsLiteral = trace.getXStsEnumLiteral(lowlevelState)
		return xStsVariable.createEqualityExpression(
				xStsLiteral.createEnumerationLiteralExpression)
	}
	
	def dispatch Expression transformExpression(EnumerationLiteralExpression expression) {
		val lowlevelEnumLiteral = expression.reference
		val index = lowlevelEnumLiteral.index
		val lowlevelEnumTypeDeclaration = lowlevelEnumLiteral.getContainerOfType(TypeDeclaration)
		val xStsEnumTypeDeclaration = trace.getXStsTypeDeclaration(lowlevelEnumTypeDeclaration)
		val xStsEnumTypeDefinition = xStsEnumTypeDeclaration.type as EnumerationTypeDefinition
		return xStsEnumTypeDefinition.literals.get(index).createEnumerationLiteralExpression
	}
	
	// Clonable expressions
	
	def dispatch Expression transformExpression(NullaryExpression expression) {
		return expression.clone
	}
	
	def dispatch Expression transformExpression(UnaryExpression expression) {
		return expression.clone => [
			it.operand = expression.operand.transformExpression
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
	
	// Types
	
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