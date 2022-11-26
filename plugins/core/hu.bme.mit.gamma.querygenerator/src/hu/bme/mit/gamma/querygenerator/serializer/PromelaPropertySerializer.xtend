/********************************************************************************
 * Copyright (c) 2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.property.model.BinaryOperandPathFormula
import hu.bme.mit.gamma.property.model.BinaryPathOperator
import hu.bme.mit.gamma.property.model.QuantifiedFormula
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula
import hu.bme.mit.gamma.property.model.UnaryPathOperator
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static com.google.common.base.Preconditions.checkArgument
import static hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*

class PromelaPropertySerializer extends ThetaPropertySerializer {
	// Singleton
	public static final PromelaPropertySerializer INSTANCE = new PromelaPropertySerializer
	protected new() {
		super.serializer = new PromelaPropertyExpressionSerializer(PromelaReferenceSerializer.INSTANCE)
	}
	//
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	override serialize(StateFormula formula) {
		// A simple LTL
		val serializedFormula = formula.serializeFormula
		checkArgument(formula.isValidFormula, serializedFormula)
		return serializedFormula
	}
	
	override dispatch String serializeFormula(UnaryOperandPathFormula formula) {
		val operator = formula.operator
		val operand = formula.operand
		return '''«operator.transform» («operator.stableCondition»«operand.serializeFormula»)'''
	}
	
	dispatch def String serializeFormula(BinaryOperandPathFormula formula) {
		val operator = formula.operator
		val leftOperand = formula.leftOperand
		val rightOperand = formula.rightOperand
		return '''(«orNotStable»«leftOperand.serializeFormula») «operator.transform» («andStable»«rightOperand.serializeFormula»)'''
	}
	
	override protected isValidFormula(StateFormula stateFormula) {
		val list = stateFormula.getSelfAndAllContentsOfType(QuantifiedFormula)
		if (list.size > 1) {
			return false
		}
		if (stateFormula instanceof QuantifiedFormula) {
			val quantifiedFormula = stateFormula.formula
			if (quantifiedFormula instanceof UnaryOperandPathFormula) {
				val operator = quantifiedFormula.operator
				if (operator == UnaryPathOperator.NEXT) {
					return false
				}
			}
		}
		return true
	}
	
	protected def String transform(BinaryPathOperator operator) {
		switch (operator) {
			case UNTIL: {
				return '''U'''
			}
			default: 
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	protected def String getStableCondition(UnaryPathOperator operator) {
		switch (operator) {
			case FUTURE: {
				return andStable
			}
			case GLOBAL: {
				return orNotStable
			}
			default:
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	protected def String getOrNotStable() '''!«isStableVariableName» || '''
	protected def String getAndStable() '''«isStableVariableName» && '''
	
}