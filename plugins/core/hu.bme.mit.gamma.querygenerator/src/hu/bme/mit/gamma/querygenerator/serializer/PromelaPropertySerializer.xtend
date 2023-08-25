/********************************************************************************
 * Copyright (c) 2022-2023 Contributors to the Gamma project
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
import hu.bme.mit.gamma.property.model.PathFormula
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
	
	protected override dispatch String serializeFormula(UnaryOperandPathFormula formula) {
		val operator = formula.operator
		val operand = formula.operand
		return '''«operator.transform» («operator.stableCondition»«operand.serializeFormula»)'''
	}
	
	protected override dispatch serializeFormula(BinaryOperandPathFormula formula) {
		val operator = formula.operator
		val leftOperand = formula.leftOperand
		val rightOperand = formula.rightOperand
		return leftOperand.getStableCondition(operator, rightOperand)
	}
	
	protected override dispatch serializeFormula(BinaryOperandLogicalPathFormula formula) {
		val operator = formula.operator
		val leftOperand = formula.leftOperand.serializeFormula
		val rightOperand = formula.rightOperand.serializeFormula
		return switch (operator) {
			case AND: {
				'''(«leftOperand» && «rightOperand»)'''
			}
			case IMPLY: {
				'''(!(«leftOperand») || «rightOperand»)'''
			}
			case OR: {
				'''(«leftOperand» || «rightOperand»)'''
			}
			case XOR: {
				'''(!(«leftOperand») && «rightOperand») || («leftOperand») && !(«rightOperand»))'''
			}
			default: 
				throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	//
	
	protected override isValidFormula(StateFormula stateFormula) {
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
	
	//
	
	protected override String transform(BinaryPathOperator operator) {
		switch (operator) {
			case UNTIL: {
				return '''U'''
			}
			case RELEASE: {
				return '''V'''
			}
			case WEAK_UNTIL: {
				return '''W'''
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
	
	protected def String getStableCondition(PathFormula leftOperand, BinaryPathOperator operator, PathFormula rightOperand) {
		val leftSerializedOperand = leftOperand.serializeFormula
		val serializedOperator = operator.transform
		val rightSerializedOperand = rightOperand.serializeFormula
		switch (operator) {
			case UNTIL: {
				return '''(«orNotStable»«leftSerializedOperand») «serializedOperator» («andStable»«rightSerializedOperand»)'''
			}
			case WEAK_UNTIL: {
				return '''(«orNotStable»«leftSerializedOperand») «serializedOperator» («andStable»«rightSerializedOperand»)'''
			}
			case RELEASE: {
				return '''(«andStable»«leftSerializedOperand») «serializedOperator» («orNotStable»«rightSerializedOperand»)'''
			}
			default:
				throw new IllegalArgumentException("Not supported binary operator: " + operator)
		}
	}
	
	protected def String getOrNotStable() '''!«isStableVariableName» || '''
	protected def String getAndStable() '''«isStableVariableName» && '''
	
}