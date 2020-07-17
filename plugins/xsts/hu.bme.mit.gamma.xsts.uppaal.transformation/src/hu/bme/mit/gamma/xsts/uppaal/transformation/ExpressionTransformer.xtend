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
package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.expression.model.AddExpression
import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.DivExpression
import hu.bme.mit.gamma.expression.model.DivideExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression
import hu.bme.mit.gamma.expression.model.GreaterExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.InequalityExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.LessEqualExpression
import hu.bme.mit.gamma.expression.model.LessExpression
import hu.bme.mit.gamma.expression.model.ModExpression
import hu.bme.mit.gamma.expression.model.MultiplyExpression
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.SubtractExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.UnaryMinusExpression
import hu.bme.mit.gamma.expression.model.UnaryPlusExpression
import hu.bme.mit.gamma.expression.model.XorExpression

class ExpressionTransformer {
	
	protected final Traceability traceability
	
	new(Traceability traceability) {
		this.traceability = traceability
	}
	
	def dispatch void transform(Expression expression) {
		throw new IllegalArgumentException("Not supported expression: " + expression)
	}
	
	def dispatch void transform(IntegerLiteralExpression expression) {
	}
	
	def dispatch void transform(TrueExpression expression) {
	}
	
	def dispatch void transform(FalseExpression expression) {
	}
	
	def dispatch void transform(EnumerationLiteralExpression expression) {
	}
	
	def dispatch void transform(ReferenceExpression expression) {		
	}
	
	def dispatch void transform(NotExpression expression) {
	}
	
	def dispatch void transform(OrExpression expression) {
	}
	
	def dispatch void transform(XorExpression expression) {
	}
	
	def dispatch void transform(AndExpression expression) {
	}
	
	def dispatch void transform(EqualityExpression expression) {
	}
	
	def dispatch void transform(InequalityExpression expression) {
	}
	
	def dispatch void transform(GreaterExpression expression) {
	}
	
	def dispatch void transform(GreaterEqualExpression expression) {
	}
	
	def dispatch void transform(LessExpression expression) {
	}
	
	def dispatch void transform(LessEqualExpression expression) {
	}
	
	def dispatch void transform(AddExpression expression) {
	}
	
	def dispatch void transform(SubtractExpression expression) {
	}
	
	def dispatch void transform(MultiplyExpression expression) {
	}
	
	def dispatch void transform(DivideExpression expression) {
	}
	
	def dispatch void transform(DivExpression expression) {
	}
	
	def dispatch void transform(ModExpression expression) {
	}
	
	def dispatch void transform(UnaryPlusExpression expression) {
	}
	
	def dispatch void transform(UnaryMinusExpression expression) {
	}
	
	def dispatch void transform(IfThenElseExpression expression) {
	}
	
}