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

import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.DefaultExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.NullaryExpression
import hu.bme.mit.gamma.expression.model.RecordAccessExpression
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.StateReferenceExpression
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension com.google.common.collect.Iterables.getOnlyElement
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class ExpressionTransformer {
	// Auxiliary object
	protected final extension TypeTransformer typeTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	// Expression factory
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	// Trace needed for variable mappings
	protected final Trace trace
	protected final boolean functionInlining
	
	new(Trace trace) {
		this(trace, true)
	}
	
	new(Trace trace, boolean functionInlining) {
		this.trace = trace
		this.functionInlining = functionInlining
		this.typeTransformer = new TypeTransformer(trace)
	}
	
	// One expression is expected to be returned
	
	def Expression transformSimpleExpression(Expression expression) {
		return expression.transformExpression.onlyElement
	}
	
	// Multiple expressions can be returned
	
	def dispatch List<Expression> transformExpression(NullaryExpression expression) {
		return #[
			expression.clone
		]
	}
	
	def dispatch List<Expression> transformExpression(DefaultExpression expression) {
		return #[
			createTrueExpression
		]
	}
	
	def dispatch List<Expression> transformExpression(RecordAccessExpression expression) {
		return expression.transformReferenceExpression.filter(Expression).toList // "Cast" to List<Expression>
	}
	
	def dispatch List<Expression> transformExpression(ArrayAccessExpression expression) {
		return expression.transformReferenceExpression.filter(Expression).toList // "Cast" to List<Expression>
	}
	
	def dispatch List<Expression> transformExpression(UnaryExpression expression) {
		return #[
			create(expression.eClass) as UnaryExpression => [
				it.operand = expression.operand.transformSimpleExpression
			]
		]
	}
	
	def dispatch List<Expression> transformExpression(StateReferenceExpression expression) {
		val gammaRegion = expression.region
		val gammaState = expression.state
		return #[
			statechartModelFactory.createStateReferenceExpression => [
				it.region = trace.get(gammaRegion)
				it.state = trace.get(gammaState)
			]
		]
	}
	
	def dispatch List<Expression> transformExpression(IfThenElseExpression expression) {
		return #[
			createIfThenElseExpression => [
				it.condition = expression.condition.transformSimpleExpression
				it.then = expression.then.transformSimpleExpression
				it.^else = expression.^else.transformSimpleExpression
			]
		]
	}

	def dispatch List<Expression> transformExpression(DirectReferenceExpression expression) {
		return expression.transformReferenceExpression.filter(Expression).toList // "Cast" to List<Expression>
	}
	
	def dispatch List<Expression> transformExpression(EnumerationLiteralExpression expression) {
		val gammaEnumLiteral = expression.reference
		val index = gammaEnumLiteral.index
		val gammaEnumTypeDeclaration = gammaEnumLiteral.typeDeclaration
		checkState(trace.isMapped(gammaEnumTypeDeclaration))
		val lowlevelEnumTypeDeclaration = trace.get(gammaEnumTypeDeclaration)
		val lowlevelEnumTypeDefinition = lowlevelEnumTypeDeclaration.type as EnumerationTypeDefinition
		return #[
			createEnumerationLiteralExpression => [
				it.reference = lowlevelEnumTypeDefinition.literals.get(index)
			]
		]
	}
	
	def dispatch List<Expression> transformExpression(RecordLiteralExpression expression) {
		// Currently the field assignment position has to match the field declaration position
		val result = newArrayList
		for (assignment : expression.fieldAssignments) {
			result += assignment.value.transformExpression
		}
		return result
	}
	
	def dispatch List<Expression> transformExpression(ArrayLiteralExpression expression) {
		// Currently the field assignment position has to match the field declaration position
		val transformedExpressions = <List<Expression>>newArrayList
		for (operand : expression.operands) {
			transformedExpressions += operand.transformExpression
		}
		val result = <Expression>newArrayList
		val sizeOfTransformedExpressions = transformedExpressions.head.size
		// If sizeOfTransformedExpressions == 1: primitive types, no record
		// Else there is a wrapped record
		// Transforming { [1, 2],  [3, 4], [5, 6] } into { [1, 3, 5],  [2, 4, 6] }
		for (var i = 0; i < sizeOfTransformedExpressions; i++) {
			val arrayLiteral = createArrayLiteralExpression
			result += arrayLiteral
			for (transformedExpression : transformedExpressions) {
				arrayLiteral.operands += transformedExpression.get(i)
			}
		}
		return result
	}
	
	def dispatch List<Expression> transformExpression(EventParameterReferenceExpression expression) {
		return expression.transformReferenceExpression.filter(Expression).toList // "Cast" to List<Expression>
	}
	
	def dispatch List<Expression> transformExpression(BinaryExpression expression) {
		return #[
			create(expression.eClass) as BinaryExpression => [
				it.leftOperand = expression.leftOperand.transformSimpleExpression
				it.rightOperand = expression.rightOperand.transformSimpleExpression
			]
		]
	}
	
	def dispatch List<Expression> transformExpression(MultiaryExpression expression) {
		val multiaryExpression = create(expression.eClass) as MultiaryExpression
		for (containedExpression : expression.operands) {
			multiaryExpression.operands += containedExpression.transformSimpleExpression
		}
		return #[
			multiaryExpression
		]
	}
	
	// Key method: reference expression
	
	def List<ReferenceExpression> transformReferenceExpression(ReferenceExpression expression) {
		// a[0].b.c[1].d
		val fieldAccess = expression.fieldAccess // .b .c
		val indexes = expression.indexAccess // [0] and [1]
		// It is the callers responsibility to make sure the original expression contains all necessary indexes
		val lowlevelIndexes = indexes.map[it.transformSimpleExpression].toList
		
		val reference = expression.accessReference
		val lowlevelVariables = newArrayList
		
		// If original is not a full access, other potential fields are explored, that is,
		// fieldAccess can be an extensible field access 
		if (reference instanceof DirectReferenceExpression) {
			val declaration = reference.declaration as ValueDeclaration
			lowlevelVariables += trace.getAll(declaration -> fieldAccess)
		}
		else if (reference instanceof EventParameterReferenceExpression) {
			val port = reference.port
			val event = reference.event
			val parameter = reference.parameter
			lowlevelVariables += trace.getAllInParameters(port, event, parameter -> fieldAccess)
		}
		else if (reference instanceof FunctionAccessExpression) {
			// FunctionAccess?
		}
		
		// Simple references are returned if indexes are empty
		return lowlevelVariables.map[it.index(lowlevelIndexes)]
	}
	
	// Function access
	
	def dispatch List<Expression> transformExpression(FunctionAccessExpression expression) {
		val result = <Expression>newArrayList
		if (functionInlining) {
			if (trace.isMapped(expression)) {
				// By now, the function call must be inlined by ExpressionPreconditionTransformer
				for (returnVariable : trace.get(expression)) {
					result += returnVariable.createReferenceExpression
				}
			}
			else {
				throw new IllegalArgumentException(
					"Error transforming function access expression: element not found in trace!")
			}
		}
		else {
			throw new IllegalArgumentException("Currently only function inlining is possible!")
		}
		return result
	}
	
}