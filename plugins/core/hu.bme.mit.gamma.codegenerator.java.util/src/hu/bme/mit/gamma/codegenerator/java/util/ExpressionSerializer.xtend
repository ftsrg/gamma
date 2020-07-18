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
package hu.bme.mit.gamma.codegenerator.java.util

import hu.bme.mit.gamma.expression.model.AddExpression
import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression
import hu.bme.mit.gamma.expression.model.DivideExpression
import hu.bme.mit.gamma.expression.model.ElseExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression
import hu.bme.mit.gamma.expression.model.GreaterExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.ImplyExpression
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
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.UnaryMinusExpression
import hu.bme.mit.gamma.expression.model.UnaryPlusExpression
import hu.bme.mit.gamma.expression.model.XorExpression

class ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer
	protected new() {}
	//
	
	def dispatch String serialize(Expression expression) {
		throw new IllegalArgumentException("Not supported expression: " + expression)
	}
	
	def dispatch String serialize(ElseExpression expression) {
		// No operation, this cannot be transformed on this level
		throw new IllegalArgumentException("Cannot be transformed")
	}
	
	def dispatch String serialize(EnumerationLiteralExpression expression) {
		val definition = expression.reference
		val enumerationType = definition.eContainer as EnumerationTypeDefinition
		val typeDeclaration = enumerationType.eContainer as TypeDeclaration
		return typeDeclaration.name + "." + definition.name
	}
	
	def dispatch String serialize(IntegerLiteralExpression expression) {
		return expression.value.toString
	}
	
	def dispatch String serialize(DecimalLiteralExpression expression) {
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
		return '''(«FOR operand : expression.operands SEPARATOR " || "»«operand.serialize»«ENDFOR»)'''
	}
	
	def dispatch String serialize(XorExpression expression) {
		return '''(«FOR operand : expression.operands SEPARATOR " ^ "»«operand.serialize»«ENDFOR»)'''
	}
	
	def dispatch String serialize(AndExpression expression) {
		return '''(«FOR operand : expression.operands SEPARATOR " && "»«operand.serialize»«ENDFOR»)'''
	}
	
	def dispatch String serialize(ImplyExpression expression) {
		return '''(!«expression.leftOperand.serialize» || «expression.rightOperand.serialize»)'''
	}
	
	def dispatch String serialize(IfThenElseExpression expression) {
		return '''(«expression.condition.serialize» ? «expression.then.serialize» : «expression.^else.serialize»)'''
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
		return '''(«FOR operand : expression.operands SEPARATOR " + "»«operand.serialize»«ENDFOR»)'''
	}
	
	def dispatch String serialize(SubtractExpression expression) {
		return "(" + expression.leftOperand.serialize + " - " + expression.rightOperand.serialize + ")"
	}
	
	def dispatch String serialize(MultiplyExpression expression) {
		return '''(«FOR operand : expression.operands SEPARATOR " * "»«operand.serialize»«ENDFOR»)'''
	}
	
	def dispatch String serialize(DivideExpression expression) {
		return "(" + expression.leftOperand.serialize + " / " + expression.rightOperand.serialize + ")"
	}
	
	def dispatch String serialize(ModExpression expression) {
		return "(" + expression.leftOperand.serialize + " % " + expression.rightOperand.serialize + ")"
	}
	
	def dispatch String serialize(UnaryPlusExpression expression) {
		return "+" + expression.operand.serialize
	}
	
	def dispatch String serialize(UnaryMinusExpression expression) {
		return "-" + expression.operand.serialize
	}
	
}