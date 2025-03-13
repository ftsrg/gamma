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
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.Comment
import hu.bme.mit.gamma.property.model.AtomicFormula
import hu.bme.mit.gamma.property.model.BinaryLogicalOperator
import hu.bme.mit.gamma.property.model.BinaryOperandLogicalPathFormula
import hu.bme.mit.gamma.property.model.BinaryOperandPathFormula
import hu.bme.mit.gamma.property.model.BinaryPathOperator
import hu.bme.mit.gamma.property.model.PathQuantifier
import hu.bme.mit.gamma.property.model.QuantifiedFormula
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.property.model.UnaryLogicalOperator
import hu.bme.mit.gamma.property.model.UnaryOperandLogicalPathFormula
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula
import hu.bme.mit.gamma.property.model.UnaryPathOperator

import static com.google.common.base.Preconditions.checkArgument

class ThetaPropertySerializer extends PropertySerializer {
	// Singleton
	public static final ThetaPropertySerializer INSTANCE = new ThetaPropertySerializer
	protected new() {
		super(new ThetaPropertyExpressionSerializer(ThetaReferenceSerializer.INSTANCE))
	}
	//
	
	override serialize(StateFormula formula) {
		// A simple CTL
		val serializedFormula = formula.serializeFormula
		checkArgument(formula.isValidFormula, serializedFormula)
		return serializedFormula
	}
	
	protected def isValidFormula(StateFormula formula) {
		if (formula instanceof QuantifiedFormula) {
			// A or E
			val quantifier = formula.quantifier
			val quantifiedFormula = formula.formula
			if (quantifiedFormula instanceof UnaryOperandPathFormula) {
				val operator = quantifiedFormula.operator
				val pathFormula = quantifiedFormula.operand
				if (quantifier == PathQuantifier.FORALL && operator == UnaryPathOperator.GLOBAL ||
						quantifier == PathQuantifier.EXISTS && operator == UnaryPathOperator.FUTURE) {
					// AG or EF
					if (pathFormula instanceof AtomicFormula) {
						return true
					}
				}
			}
		}
		return false
	}
	
	//

	protected def dispatch String serializeFormula(AtomicFormula formula) {
		return formula.expression.serialize
	}
	
	protected def dispatch String serializeFormula(QuantifiedFormula formula) {
		val quantifier = formula.quantifier
		val pathFormula = formula.formula
		return '''«quantifier.transform»«handleQuantifierOperatorSpace»«pathFormula.serializeFormula»'''
	}
	
	protected def dispatch String serializeFormula(UnaryOperandPathFormula formula) {
		val operator = formula.operator
		val operand = formula.operand
		return '''«operator.transform»(«operand.serializeFormula»)'''
	}
	
	protected def dispatch String serializeFormula(UnaryOperandLogicalPathFormula formula) {
		val operator = formula.operator
		val operand = formula.operand
		return '''«operator.transform»(«operand.serializeFormula»)'''
	}
	
	protected def dispatch String serializeFormula(BinaryOperandPathFormula formula) {
		val operator = formula.operator
		val leftOperand = formula.leftOperand
		val rightOperand = formula.rightOperand
		return '''((«leftOperand.serializeFormula») «operator.transform» («rightOperand.serializeFormula»))'''
	}
	
	protected def dispatch String serializeFormula(BinaryOperandLogicalPathFormula formula) {
		val operator = formula.operator
		val leftOperand = formula.leftOperand
		val rightOperand = formula.rightOperand
		return '''((«leftOperand.serializeFormula») «operator.transform» («rightOperand.serializeFormula»))'''
	}
	
	//
	
	protected def String transform(UnaryPathOperator operator) {
		switch (operator) {
			case FUTURE: {
				return '''<>'''
			}
			case GLOBAL: {
				return '''[]'''
			}
			default: 
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	protected def String transform(UnaryLogicalOperator operator) {
		throw new IllegalArgumentException("Not supported operator: " + operator)
	}
	
	protected def String transform(BinaryLogicalOperator operator) {
		throw new IllegalArgumentException("Not supported operator: " + operator)
	}
	
	protected def String transform(BinaryPathOperator operator) {
		throw new IllegalArgumentException("Not supported operator: " + operator)
	}
	
	protected def String transform(PathQuantifier quantifier) {
		switch (quantifier) {
			case FORALL: {
				return '''A'''
			}
			case EXISTS: {
				return '''E'''
			}
			default: 
				throw new IllegalArgumentException("Not supported quantifier: " + quantifier)
		}
	}
	
	// Set to CTL; subclasses can override it to support CTL *
	protected def handleQuantifierOperatorSpace() {
		return ""
	}
	
	override serialize(Comment comment) ''''''
	
}