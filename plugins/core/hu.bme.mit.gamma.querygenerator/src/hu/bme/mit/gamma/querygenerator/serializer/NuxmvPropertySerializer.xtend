/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.property.model.BinaryOperandLogicalPathFormula
import hu.bme.mit.gamma.property.model.BinaryOperandPathFormula
import hu.bme.mit.gamma.property.model.BinaryPathOperator
import hu.bme.mit.gamma.property.model.PathQuantifier
import hu.bme.mit.gamma.property.model.QuantifiedFormula
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula
import hu.bme.mit.gamma.property.model.UnaryPathOperator

class NuxmvPropertySerializer extends ThetaPropertySerializer {
	//
	public static final NuxmvPropertySerializer INSTANCE = new NuxmvPropertySerializer
	protected new() {
		super.serializer = new NuxmvPropertyExpressionSerializer(NuxmvReferenceSerializer.INSTANCE)
	}
	//
	
	protected override isValidFormula(StateFormula formula) {
		val quantifiedFormulas = newArrayList
		quantifiedFormulas += formula.getAllContentsOfType(QuantifiedFormula)
		
		if (quantifiedFormulas.empty) {
			return true // It is an LTL formula
		}
		
		if (formula instanceof QuantifiedFormula) {
			quantifiedFormulas += formula
		}
		for (quantifiedFormula : quantifiedFormulas) {
			val nestedFormula = quantifiedFormula.formula
			if (nestedFormula instanceof UnaryOperandPathFormula || 
					nestedFormula instanceof BinaryOperandPathFormula) {
				// Correct CTL operator
			}
			else {
				return false
			}
		}
		
		return true // All operators are valid (glued) CTL operators
	}
	
	//
	
	protected override dispatch String serializeFormula(BinaryOperandLogicalPathFormula formula) {
		val operator = formula.operator
		val leftOperand = formula.leftOperand.serializeFormula
		val rightOperand = formula.rightOperand.serializeFormula
		return switch (operator) {
			case AND: {
				'''((«leftOperand») & («rightOperand»))'''
			}
			case IMPLY: {
				'''((«leftOperand») -> («rightOperand»))'''
			}
			case OR: {
				'''((«leftOperand») | («rightOperand»))'''
			}
			case XOR: {
				'''((«leftOperand») xor («rightOperand»))'''
			}
			default: 
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	protected override dispatch String serializeFormula(BinaryOperandPathFormula formula) {
		val operator = formula.operator.transform
		val leftOperand = formula.leftOperand.serializeFormula
		val rightOperand = formula.rightOperand.serializeFormula
		
		return '''((«leftOperand») «operator» («rightOperand»))'''
	}
	
	//
	
	protected override String transform(UnaryPathOperator operator) {
		switch (operator) {
			case FUTURE: {
				return '''F'''
			}
			case GLOBAL: {
				return '''G'''
			}
			case NEXT: {
				return '''X'''
			}
			default: 
				/* nuXmv supports several other path operators, but only the above ones are supported for now.
				 * See the nuXmv manual for more information.
				 * Y ltl_expr -- previous state
				 * O ltl_expr -- once
				 * H ltl_expr -- historically
				 */ 
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	protected override transform(BinaryPathOperator operator) {
		switch (operator) {
			case UNTIL: {
				return '''U'''
			}
			case RELEASE: {
				return '''V'''
			}
			default: 
				/* nuXmv supports several other path operators, but only the above ones are supported for now.
				 * See the nuXmv manual for more information.
				 * ltl_expr S ltl_expr -- since
				 * ltl_expr T ltl_expr -- triggered
				 */
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	protected override String transform(PathQuantifier quantifier) {
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
	
}