/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.testgeneration.c

import hu.bme.mit.gamma.expression.model.BooleanLiteralExpression
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression

class TypeSerializer {
	
	def String serialize(Expression expression) {
		throw new IllegalArgumentException("Not supported expression: " + expression)
	}
	
	def dispatch String serialize(IntegerLiteralExpression expression, String name) {
		return '''uint32_t'''
	}
	
		def dispatch String serialize(BooleanLiteralExpression type, String name) {
		return '''bool'''
	}

	def dispatch String serialize(DecimalLiteralExpression type, String name) {
		return '''float'''
	}

	def dispatch String serialize(RationalLiteralExpression type, String name) {
		return '''float'''
	}
	
	
}