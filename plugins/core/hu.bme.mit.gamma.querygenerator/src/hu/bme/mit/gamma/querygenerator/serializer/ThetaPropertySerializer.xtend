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
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.Comment
import hu.bme.mit.gamma.property.model.AtomicFormula
import hu.bme.mit.gamma.property.model.PathQuantifier
import hu.bme.mit.gamma.property.model.QuantifiedFormula
import hu.bme.mit.gamma.property.model.StateFormula
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

	protected def dispatch String serializeFormula(AtomicFormula formula) {
		return formula.expression.serialize
	}
	
	protected def dispatch String serializeFormula(QuantifiedFormula formula) {
		val quantifier = formula.quantifier
		val pathFormula = formula.formula
		return '''«quantifier.transform»«pathFormula.serializeFormula»'''
	}
	
	protected def dispatch String serializeFormula(UnaryOperandPathFormula formula) {
		val operator = formula.operator
		val operand = formula.operand
		return '''«operator.transform» «operand.serializeFormula»'''
	}
	
	// Other CTL* formula expressions are not supported by UPPAAL
	
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
	
	override serialize(Comment comment) ''''''
	
}