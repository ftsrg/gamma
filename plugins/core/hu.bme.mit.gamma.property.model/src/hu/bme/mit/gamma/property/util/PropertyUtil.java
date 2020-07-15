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
package hu.bme.mit.gamma.property.util;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.property.model.AtomicFormula;
import hu.bme.mit.gamma.property.model.PathQuantifier;
import hu.bme.mit.gamma.property.model.PropertyModelFactory;
import hu.bme.mit.gamma.property.model.QuantifiedFormula;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula;
import hu.bme.mit.gamma.property.model.UnaryPathOperator;

public class PropertyUtil extends ExpressionUtil {
	// Singleton
	public static final PropertyUtil INSTANCE = new PropertyUtil();
	protected PropertyUtil() {}
	//
	protected PropertyModelFactory factory = PropertyModelFactory.eINSTANCE;
	
	public StateFormula createSimpleCTLFormula(PathQuantifier pathQuantifier,
			UnaryPathOperator unaryPathOperator, Expression expression) {
		QuantifiedFormula quantifiedFormula = factory.createQuantifiedFormula();
		quantifiedFormula.setQuantifier(pathQuantifier);
		UnaryOperandPathFormula pathFormula = factory.createUnaryOperandPathFormula();
		pathFormula.setOperator(unaryPathOperator);
		quantifiedFormula.setFormula(pathFormula);
		AtomicFormula atomicFormula = factory.createAtomicFormula();
		atomicFormula.setExpression(expression);
		pathFormula.setOperand(atomicFormula);
		return quantifiedFormula;
	}
	
	public StateFormula createEF(Expression expression) {
		return createSimpleCTLFormula(PathQuantifier.EXISTS, UnaryPathOperator.FUTURE, expression);
	}
	
	public StateFormula createEG(Expression expression) {
		return createSimpleCTLFormula(PathQuantifier.EXISTS, UnaryPathOperator.GLOBAL, expression);
	}
	
	public StateFormula createAF(Expression expression) {
		return createSimpleCTLFormula(PathQuantifier.FORALL, UnaryPathOperator.FUTURE, expression);
	}
	
	public StateFormula createAG(Expression expression) {
		return createSimpleCTLFormula(PathQuantifier.FORALL, UnaryPathOperator.GLOBAL, expression);
	}
	
	public StateFormula createLeadsTo(Expression lhs, Expression rhs) {
		return null;
	}
	
}
