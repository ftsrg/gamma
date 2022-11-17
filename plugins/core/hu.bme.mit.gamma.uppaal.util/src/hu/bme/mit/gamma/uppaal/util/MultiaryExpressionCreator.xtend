/********************************************************************************
 * Copyright (c) 2020-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution) and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.util

import java.util.Collection
import uppaal.expressions.ArithmeticOperator
import uppaal.expressions.Expression
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.LogicalOperator

import static com.google.common.base.Preconditions.checkArgument

class MultiaryExpressionCreator {
	// Singleton
	public static final MultiaryExpressionCreator INSTANCE =  new MultiaryExpressionCreator
	protected new() {}
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
		
	def createLogicalExpression(LogicalOperator operator,
			Collection<? extends Expression> expressions) {
			if (expressions.empty) {
				println('AS')
			}
		checkArgument(!expressions.empty)
		if (expressions.size == 1) {
			return expressions.head
		}
		var logicalExpression = createLogicalExpression => [
			it.operator = operator
		]
		var i = 0
		for (expression : expressions) {
			if (i == 0) {
				logicalExpression.firstExpr = expression
			}
			else if (i == 1) {
				logicalExpression.secondExpr = expression
			}
			else {
				val oldExpression = logicalExpression
				logicalExpression = createLogicalExpression => [
					it.operator = operator
					it.firstExpr = oldExpression
					it.secondExpr = expression
				]
			}
			i++
		}
		return logicalExpression
	}
	
	def createArithmeticExpression(ArithmeticOperator operator,
			Collection<? extends Expression> expressions) {
		checkArgument(!expressions.empty)
		if (expressions.size == 1) {
			return expressions.head
		}
		var logicalExpression = createArithmeticExpression => [
			it.operator = operator
		]
		var i = 0
		for (expression : expressions) {
			if (i == 0) {
				logicalExpression.firstExpr = expression
			}
			else if (i == 1) {
				logicalExpression.secondExpr = expression
			}
			else {
				val oldExpression = logicalExpression
				logicalExpression = createArithmeticExpression => [
					it.operator = operator
					it.firstExpr = oldExpression
					it.secondExpr = expression
				]
			}
			i++
		}
		return logicalExpression
	}
	
}