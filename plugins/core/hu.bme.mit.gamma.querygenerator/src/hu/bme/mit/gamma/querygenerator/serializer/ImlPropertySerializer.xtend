/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
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
import hu.bme.mit.gamma.property.model.PathFormula
import hu.bme.mit.gamma.property.model.PathQuantifier
import hu.bme.mit.gamma.property.model.QuantifiedFormula
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.property.model.UnaryLogicalOperator
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula
import hu.bme.mit.gamma.property.model.UnaryPathOperator
import hu.bme.mit.gamma.xsts.iml.transformation.util.Namings

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.property.derivedfeatures.PropertyModelDerivedFeatures.*

class ImlPropertySerializer extends ThetaPropertySerializer {
	//
	public static final ImlPropertySerializer INSTANCE = new ImlPropertySerializer
	protected new() {
		super.serializer = new ImlPropertyExpressionSerializer(ImlReferenceSerializer.INSTANCE)
	}
	//
	
	protected override isValidFormula(StateFormula formula) {
		// Note that this translation supports LTL with FINITE traces
		return formula.ltl && !formula.containsBinaryPathOperators
		 // No CTL* (nesting of instance/verify) yet // No U, R or B yet
	}
	
	override serialize(Comment comment) '''(* «comment.comment» *)'''
	
	override serialize(StateFormula formula) {
		// LTL can be mapped in a special way: after A, only G and X can be contained, after E, only F and X
		val tailoredFormula = formula.tailorFormula
		//
		val serializedFormula = tailoredFormula.serializeFormula
		checkArgument(tailoredFormula.validFormula, serializedFormula)
		return serializedFormula
	}
	
	//
	
	protected override dispatch String serializeFormula(AtomicFormula formula) {
		return formula.expression.serialize
	}
	
	protected override dispatch String serializeFormula(QuantifiedFormula formula) {
		val quantifier = formula.quantifier // A or E
		val imandraCall = (quantifier == PathQuantifier.FORALL) ? "verify" : "instance"
		
		val pathFormula = formula.formula
		val pathFormulas = formula.relevantUnaryOperandPathFormulas
		return '''«imandraCall»(fun«FOR e : pathFormulas» «e.inputId»«ENDFOR» -> let «
				recordId» = «Namings.INIT_FUNCTION_IDENTIFIER» in «pathFormula.serializeFormula»)'''
	}
	
	protected override dispatch String serializeFormula(UnaryOperandPathFormula formula) {
		val operator = formula.operator // G, F or X
		val functionName = operator.functionName
		val operand = formula.operand
		return '''let «recordId» = «functionName» «recordId» «formula.inputId» in «operand.serializeFormula»'''
	}
	
	//
	
	protected override transform(UnaryLogicalOperator operator) {
		switch (operator) {
			case NOT: "not"
			default: throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	protected override transform(BinaryLogicalOperator operator) {
		switch (operator) {
			case AND: "&&"
			case IMPLY: "==>"
			case OR: "||"
			case XOR: "^"
			default: throw new IllegalArgumentException("Not supported operator: " + operator)
		}
	}
	
	//
	
	protected def tailorFormula(StateFormula formula) {
		if (formula instanceof QuantifiedFormula) {
			val clonedFormula = formula.clone // So no side-effect
			val pathFormulas = clonedFormula.relevantUnaryOperandPathFormulas
			val quantifier = clonedFormula.quantifier
			//
			if (quantifier == PathQuantifier.EXISTS) { // E
				val globals = pathFormulas.filter[it.operator == UnaryPathOperator.GLOBAL]
				if (globals.empty) { // G cannot be after E, but: G p === !F!p
					return formula
				}
				for (global : globals) {
					global.changeToDual
				}
				return clonedFormula
			}
			else { // A
				val futures = pathFormulas.filter[it.operator == UnaryPathOperator.FUTURE]
				if (futures.empty) { // F cannot be after A, but: F p === !G!p
					return formula
				}
				for (future : futures) {
					future.changeToDual
				}
				return clonedFormula
			}
		}
		return formula
	}
	
	//
	
	protected def getRelevantUnaryOperandPathFormulas(PathFormula formula) {
		// We consider levels of F, G and X operators in-between A and E quantifiers
		// to support multiple level of A/E nesting (CTL*)
		return formula.getAllContentsOfTypeBetweenTypes(QuantifiedFormula, UnaryOperandPathFormula)
	}
	
	protected def getRecordId() {
		return ImlReferenceSerializer.recordIdentifier
	}
	
	protected def getInputId() {
		return "e"
	}
	
	protected def getIndex(UnaryOperandPathFormula formula) {
		val unaryOperandPathFormulas = formula.relevantUnaryOperandPathFormulas
		return unaryOperandPathFormulas.indexOf(formula)
	}
	
	protected def getInputId(UnaryOperandPathFormula formula) {
		return inputId + formula.index
	}
	
	protected def getFunctionName(UnaryPathOperator operator) {
		switch (operator) {
			case FUTURE,
			case GLOBAL: return Namings.RUN_FUNCTION_IDENTIFIER
			case NEXT: return Namings.SINGLE_RUN_FUNCTION_IDENTIFIER
			default: throw new IllegalArgumentException("Not known operator: " + operator)
		}
	}
	
}