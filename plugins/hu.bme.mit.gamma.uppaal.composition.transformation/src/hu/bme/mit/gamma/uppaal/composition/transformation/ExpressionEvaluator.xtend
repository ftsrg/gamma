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

import hu.bme.mit.gamma.constraint.model.AddExpression
import hu.bme.mit.gamma.constraint.model.DivideExpression
import hu.bme.mit.gamma.constraint.model.Expression
import hu.bme.mit.gamma.constraint.model.IntegerLiteralExpression
import hu.bme.mit.gamma.constraint.model.MultiplyExpression
import hu.bme.mit.gamma.constraint.model.SubtractExpression

class ExpressionEvaluator {
	
	def dispatch int evaluate(Expression exp) {
		throw new IllegalArgumentException("Not transformable expression: " + exp)
	}
	
	def dispatch int evaluate(IntegerLiteralExpression exp) {
		return exp.value.intValue
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
	
}
