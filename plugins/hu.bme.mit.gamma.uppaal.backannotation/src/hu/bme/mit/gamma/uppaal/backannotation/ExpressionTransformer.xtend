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
package hu.bme.mit.gamma.uppaal.backannotation

import uppaal.expressions.ArithmeticExpression
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.AssignmentOperator
import uppaal.expressions.BitShiftExpression
import uppaal.expressions.BitwiseExpression
import uppaal.expressions.CompareExpression
import uppaal.expressions.CompareOperator
import uppaal.expressions.Expression
import uppaal.expressions.FunctionCallExpression
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.IncrementDecrementExpression
import uppaal.expressions.LiteralExpression
import uppaal.expressions.LogicalExpression
import uppaal.expressions.LogicalOperator
import uppaal.expressions.MinusExpression
import uppaal.expressions.NegationExpression
import uppaal.expressions.PlusExpression
import uppaal.statements.EmptyStatement
import uppaal.statements.ExpressionStatement
import uppaal.statements.ReturnStatement
import uppaal.statements.Statement
import uppaal.declarations.Variable

class ExpressionTransformer {
	
	def dispatch String transform(Expression expression) {
		throw new IllegalArgumentException("Not know expression: " + expression)
	}
	
	def dispatch String transform(LiteralExpression expression) {
		return expression.text
	}
	
	def dispatch String transform(IdentifierExpression expression) {
		return expression.identifier.name
	}
	
	def dispatch String transform(AssignmentExpression expression) {
		return expression.firstExpr.transform + " " + expression.operator.transformAssignmentOperator + " " + expression.secondExpr.transform
	}
	
	private def transformAssignmentOperator(AssignmentOperator operator) {
		switch (operator) {
			case AssignmentOperator.BIT_AND_EQUAL: 
				return "&="
			case AssignmentOperator.BIT_LEFT_EQUAL: 
				return "<="
			case AssignmentOperator.BIT_RIGHT_EQUAL: 
				return ">="
			default: 
				return operator.literal
		}
	}
	
	def dispatch String negate(Expression expression) {
		return expression.transform
	}
	
	def dispatch String negate(LogicalExpression expression) {
		var LogicalOperator lOp
		switch (expression.operator) {
			case AND: 
				lOp = LogicalOperator.OR
			case OR: 
				lOp = LogicalOperator.AND
			default:
				throw new IllegalArgumentException("Not supported for operator: " + expression.operator)
		}		
		return expression.firstExpr.negate + " " + lOp.transformLogicalOperator + " " + expression.secondExpr.negate
	}
	
	def dispatch String negate(CompareExpression expression) {
		var CompareOperator cOp
		switch (expression.operator) {
			case EQUAL:
				cOp = CompareOperator.UNEQUAL
			case UNEQUAL:
				cOp = CompareOperator.EQUAL
			case GREATER:
				cOp = CompareOperator.LESS_OR_EQUAL
			case GREATER_OR_EQUAL:
				cOp = CompareOperator.LESS
			case LESS:
				cOp = CompareOperator.GREATER_OR_EQUAL
			case LESS_OR_EQUAL:
				cOp = CompareOperator.GREATER
			default:
				throw new IllegalArgumentException("Not supported for operator: " + expression.operator)
		}		
		return expression.firstExpr.negate + " " + cOp.transformCompareOperator + " " + expression.secondExpr.negate
	}
	
	def dispatch String negate(IdentifierExpression expression) {
		if (expression.identifier instanceof Variable)  {
			val variable = expression.identifier as Variable
			
			return "!" + expression.identifier.name
		}
		throw new IllegalArgumentException("The negation of the following variable is not supported: " + expression.identifier)
	}
	
	def dispatch String transform(NegationExpression expression) {
		return "!(" + expression.negatedExpression.transform + ")"
	}
	
	def dispatch String transform(PlusExpression expression) {
		return "+" +  expression.confirmedExpression.transform
	}
	
	def dispatch String transform(MinusExpression expression) {
		return "-" +  expression.invertedExpression.transform
	}
	
	def dispatch String transform(ArithmeticExpression expression) {
		return expression.firstExpr.transform + " " + expression.operator.literal + " " + expression.secondExpr.transform
	}
	
	def dispatch String transform(LogicalExpression expression) {
		return "(" + expression.firstExpr.transform + " " + expression.operator.transformLogicalOperator + " " + expression.secondExpr.transform + ")"
	}
	
	private def transformLogicalOperator(LogicalOperator operator) {
		switch (operator) {
			case LogicalOperator.AND: 
				return "&&"
			case LogicalOperator.OR: 
				return "||"
			default: 
				throw new IllegalArgumentException("The following operator is not supported: " + operator)
		}
	}
	
	def dispatch String transform(CompareExpression expression) {
		return expression.firstExpr.transform + " " + expression.operator.transformCompareOperator + " " + expression.secondExpr.transform
	}
	
	private def transformCompareOperator(CompareOperator operator) {
		switch (operator) {				
			case CompareOperator.LESS: 
				return "<;"
			case CompareOperator.LESS_OR_EQUAL: 
				return "<="
			case CompareOperator.GREATER: 
				return ">;"
			case CompareOperator.GREATER_OR_EQUAL_VALUE: 
				return ">="
			default: 
				return operator.literal
		}
	}
	
	def dispatch String transform(IncrementDecrementExpression expression) {
		if (expression.position.value == 0) {
			return expression.operator.literal + expression.expression.transform
		}
		else {
			return expression.expression.transform + expression.operator.literal
		}
	}
	
	def dispatch String transform(BitShiftExpression expression) {
		return expression.firstExpr.transform + " " + expression.operator.literal + " " + expression.secondExpr.transform
	}
	
	def dispatch String transform(BitwiseExpression expression) {
		return expression.firstExpr.transform + " " + expression.operator.literal + " " + expression.secondExpr.transform
	}
	
	def dispatch String transform(FunctionCallExpression expression) {
		return expression.function.name + "()"
	}
	
	def dispatch String transformStatement(Statement statement) {
		throw new IllegalArgumentException("The transformation of this statement is not supported: " + statement)
	}
	
	def dispatch String transformStatement(ExpressionStatement statement) {
		return statement.expression.transform
	}
	
	def dispatch String transformStatement(ReturnStatement statement) {
		return "return " + statement.returnExpression.transform
	}
	
	def dispatch String transformStatement(EmptyStatement statement) {
		return ""
	}
	
}
																				