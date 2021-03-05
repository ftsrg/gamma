/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.expression.model.AccessExpression
import hu.bme.mit.gamma.expression.model.AddExpression
import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.DivideExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.ImplyExpression
import hu.bme.mit.gamma.expression.model.InequalityExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.MultiplyExpression
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.SubtractExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.XorExpression
import hu.bme.mit.gamma.transformation.util.queries.ParameterizedInstancesWithParameters
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

import static com.google.common.base.Preconditions.checkState

// There is an expression evaluator in the Expression Model plugin, but that does not handle parameter declarations
class ExpressionEvaluator {
	// Engine on the Gamma resource 
	protected final ViatraQueryEngine engine
	
	new(ViatraQueryEngine engine) {
		this.engine = engine
	}
	
	def evaluateToInt(Expression exp) {
		try {
			return exp.evaluate
		} catch (IllegalArgumentException e) {
			return exp.evaluateBoolean
		}
	}
	
	def dispatch int evaluate(Expression exp) {
		throw new IllegalArgumentException("Not transformable expression: " + exp)
	}
	
	def dispatch int evaluate(DirectReferenceExpression exp) {
		val declaration = exp.declaration
		if (declaration instanceof ConstantDeclaration) {
			return declaration.expression.evaluate
		}
		else if (declaration instanceof ParameterDeclaration) {
			return declaration.parameterValue.evaluate
		}
		else {
			throw new IllegalArgumentException("Not transformable expression: " + exp)
		}
	}
	
	def dispatch int evaluate(AccessExpression exp) {
		//TODO
		throw new IllegalArgumentException("Access expressions are not yet transformed" + exp)
	}
	
	def dispatch int evaluate(IntegerLiteralExpression exp) {
		return exp.value.intValue
	}
	
	def dispatch int evaluate(EnumerationLiteralExpression exp) {
		val enum = exp.reference
		val type = enum.eContainer as EnumerationTypeDefinition
		return type.literals.indexOf(enum)
	}
	
	def dispatch int evaluate(MultiplyExpression exp) {
		return exp.operands.map[it.evaluate].reduce[p1, p2| p1 * p2]
	}
	
	def dispatch int evaluate(DivideExpression exp) {
		return exp.leftOperand.evaluate / exp.rightOperand.evaluate
	}
	
	def dispatch int evaluate(AddExpression exp) {
		return exp.operands.map[it.evaluate].reduce[p1, p2| p1 + p2]
	}
	
	def dispatch int evaluate(SubtractExpression exp) {
		return exp.leftOperand.evaluate - exp.rightOperand.evaluate
	}
	
	private def Expression getParameterValue(ParameterDeclaration parameter) {
		val matches = ParameterizedInstancesWithParameters.Matcher.on(engine).getAllMatches(null, null, parameter)
		checkState(matches.size == 1)
		val match = matches.head
		val index = match.type.parameterDeclarations.indexOf(parameter)
		val expression = match.instance.arguments.get(index)
		return expression
	}
	
	def dispatch boolean evaluateBoolean(TrueExpression expression) {
		return true
	}
	
	def dispatch boolean evaluateBoolean(FalseExpression expression) {
		return false
	}
	
	def dispatch boolean evaluateBoolean(AndExpression expression) {
		for (subExpression : expression.operands) {
			if (!subExpression.evaluateBoolean) {
				return false
			}
		}
		return true
	}
	
	def dispatch boolean evaluateBoolean(OrExpression expression) {
		for (subExpression : expression.operands) {
			if (subExpression.evaluateBoolean) {
				return true
			}
		}
		return false
	}
	
	def dispatch boolean evaluateBoolean(XorExpression expression) {
		var positiveCount = 0
		for (subExpression : expression.operands) {
			if (subExpression.evaluateBoolean) {
				positiveCount++
			}
		}
		return positiveCount % 2 == 1
	}
	
	def dispatch boolean evaluateBoolean(ImplyExpression expression) {
		return !expression.leftOperand.evaluateBoolean || expression.rightOperand.evaluateBoolean
	}
	
	def dispatch boolean evaluateBoolean(NotExpression expression) {
		return !expression.operand.evaluateBoolean
	}
	
	def dispatch boolean evaluateBoolean(EqualityExpression expression) {
		return expression.leftOperand.evaluateBoolean == expression.rightOperand.evaluateBoolean
	}
	
	def dispatch boolean evaluateBoolean(InequalityExpression expression) {
		return expression.leftOperand.evaluateBoolean != expression.rightOperand.evaluateBoolean
	}
	
	def dispatch boolean evaluateBoolean(DirectReferenceExpression exp) {
		val declaration = exp.declaration
		if (declaration instanceof ConstantDeclaration) {
			return declaration.expression.evaluateBoolean
		}
		else if (declaration instanceof ParameterDeclaration) {
			return declaration.parameterValue.evaluateBoolean
		}
		else {
			throw new IllegalArgumentException("Not transformable expression: " + exp)
		}
	}
	
	def dispatch boolean evaluateBoolean(AccessExpression exp) {
		//TODO
		throw new IllegalArgumentException("Access expressions are not yet transformed" + exp)
	}
	
}
