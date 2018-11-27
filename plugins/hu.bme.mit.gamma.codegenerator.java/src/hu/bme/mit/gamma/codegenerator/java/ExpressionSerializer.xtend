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
package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.constraint.model.AddExpression
import hu.bme.mit.gamma.constraint.model.AndExpression
import hu.bme.mit.gamma.constraint.model.DivideExpression
import hu.bme.mit.gamma.constraint.model.EqualityExpression
import hu.bme.mit.gamma.constraint.model.Expression
import hu.bme.mit.gamma.constraint.model.FalseExpression
import hu.bme.mit.gamma.constraint.model.GreaterEqualExpression
import hu.bme.mit.gamma.constraint.model.GreaterExpression
import hu.bme.mit.gamma.constraint.model.InequalityExpression
import hu.bme.mit.gamma.constraint.model.IntegerLiteralExpression
import hu.bme.mit.gamma.constraint.model.LessEqualExpression
import hu.bme.mit.gamma.constraint.model.LessExpression
import hu.bme.mit.gamma.constraint.model.MultiplyExpression
import hu.bme.mit.gamma.constraint.model.NotExpression
import hu.bme.mit.gamma.constraint.model.OrExpression
import hu.bme.mit.gamma.constraint.model.ReferenceExpression
import hu.bme.mit.gamma.constraint.model.SubtractExpression
import hu.bme.mit.gamma.constraint.model.TrueExpression
import hu.bme.mit.gamma.constraint.model.UnaryMinusExpression
import hu.bme.mit.gamma.constraint.model.UnaryPlusExpression
import hu.bme.mit.gamma.constraint.model.ConstantDeclaration

class ExpressionSerializer {
	
	def dispatch String serialize(Expression expression) {
		throw new IllegalArgumentException("Not supported expression: " + expression)
	}
	
	def dispatch String serialize(IntegerLiteralExpression expression) {
		return expression.value.toString
	}
	
	def dispatch String serialize(TrueExpression expression) {
		return "true"
	}
	
	def dispatch String serialize(FalseExpression expression) {
		return "false"
	}
	
	def dispatch String serialize(ReferenceExpression expression) {		
		if (expression.declaration instanceof ConstantDeclaration) {
			val constant = expression.declaration as ConstantDeclaration
			return constant.expression.serialize	
		}
		return expression.declaration.name
	}
	
	def dispatch String serialize(NotExpression expression) {
		return "!" + expression.operand.serialize
	}
	
	def dispatch String serialize(OrExpression expression) {
		return '''(«FOR operand : expression.operands SEPARATOR " || "»«expression.serialize»«ENDFOR»)'''
	}	
	
	def dispatch String serialize(AndExpression expression) {
		return '''(«FOR operand : expression.operands SEPARATOR " && "»«expression.serialize»«ENDFOR»)'''
	}
	
	def dispatch String serialize(EqualityExpression expression) {
		return "(" + expression.leftOperand.serialize + " == " + expression.rightOperand.serialize + ")"
	}
	
	def dispatch String serialize(InequalityExpression expression) {
		return "(" + expression.leftOperand.serialize + " != " + expression.rightOperand.serialize + ")"
	}
	
	def dispatch String serialize(GreaterExpression expression) {
		return "(" + expression.leftOperand.serialize + " > " + expression.rightOperand.serialize + ")"
	}
	
	def dispatch String serialize(GreaterEqualExpression expression) {
		return "(" + expression.leftOperand.serialize + " >= " + expression.rightOperand.serialize + ")"
	}
	
	def dispatch String serialize(LessExpression expression) {
		return "(" + expression.leftOperand.serialize + " < " + expression.rightOperand.serialize + ")"
	}
	
	def dispatch String serialize(LessEqualExpression expression) {
		return "(" + expression.leftOperand.serialize + " <= " + expression.rightOperand.serialize + ")"
	}
	
	def dispatch String serialize(AddExpression expression) {
		return '''(«FOR operand : expression.operands SEPARATOR " + "»«expression.serialize»«ENDFOR»)'''
	}
	
	def dispatch String serialize(SubtractExpression expression) {
		return "(" + expression.leftOperand.serialize + " - " + expression.rightOperand.serialize + ")"
	}
	
	def dispatch String serialize(MultiplyExpression expression) {
		return '''(«FOR operand : expression.operands SEPARATOR " * "»«expression.serialize»«ENDFOR»)'''
	}
	
	def dispatch String serialize(DivideExpression expression) {
		return "(" + expression.leftOperand.serialize + " / " + expression.rightOperand.serialize + ")"
	}
	
	def dispatch String serialize(UnaryPlusExpression expression) {
		return "+" + expression.operand
	}
	
	def dispatch String serialize(UnaryMinusExpression expression) {
		return "-" + expression.operand
	}
	
}
