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
import hu.bme.mit.gamma.property.model.PathQuantifier
import hu.bme.mit.gamma.property.model.QuantifiedFormula
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula

import static com.google.common.base.Preconditions.checkArgument
import static hu.bme.mit.gamma.xsts.iml.transformation.util.Namings.*

import static extension hu.bme.mit.gamma.property.derivedfeatures.PropertyModelDerivedFeatures.*

class ImlPropertySerializer extends ThetaPropertySerializer {
	//
	public static final ImlPropertySerializer INSTANCE = new ImlPropertySerializer
	protected new() {
		super.serializer = new ImlPropertyExpressionSerializer(ImlReferenceSerializer.INSTANCE)
	}
	//
	
	protected override isValidFormula(StateFormula formula) {
		return formula.invariant // EF and AG are supported
	}
	
	override serialize(Comment comment) '''(* «comment.comment» *)'''
	
	override serialize(StateFormula formula) {
		val serializedFormula = formula.serializeFormula
		checkArgument(formula.validFormula, serializedFormula)
		return serializedFormula
	}
	
	//
	
	
	protected override dispatch String serializeFormula(AtomicFormula formula) {
		return formula.expression.serialize
	}
	
	protected override dispatch String serializeFormula(QuantifiedFormula formula) {
		val quantifier = formula.quantifier // A or E
		val imandraCall = (quantifier == PathQuantifier.FORALL) ? "verify" : "instance"
		
		val inputId = "e"
		val recordId = ImlReferenceSerializer.recordIdentifier
		
		val pathFormula = formula.formula
		
		return '''«imandraCall»(fun «inputId» -> let «recordId» = «RUN_FUNCTION_IDENTIFIER» «INIT_FUNCTION_IDENTIFIER» «inputId» in
				«pathFormula.serializeFormula»)'''
	}
	
	protected override dispatch String serializeFormula(UnaryOperandPathFormula formula) {
		val operand = formula.operand // G or F
		return operand.serializeFormula
	}
	
}