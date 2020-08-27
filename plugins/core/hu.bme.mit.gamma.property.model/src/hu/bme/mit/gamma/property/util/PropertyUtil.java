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
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.property.model.AtomicFormula;
import hu.bme.mit.gamma.property.model.BinaryLogicalOperator;
import hu.bme.mit.gamma.property.model.BinaryOperandLogicalPathFormula;
import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference;
import hu.bme.mit.gamma.property.model.PathFormula;
import hu.bme.mit.gamma.property.model.PathQuantifier;
import hu.bme.mit.gamma.property.model.PropertyModelFactory;
import hu.bme.mit.gamma.property.model.QuantifiedFormula;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula;
import hu.bme.mit.gamma.property.model.UnaryPathOperator;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.Port;

public class PropertyUtil extends ExpressionUtil {
	// Singleton
	public static final PropertyUtil INSTANCE = new PropertyUtil();
	protected PropertyUtil() {}
	//
	protected final PropertyModelFactory factory = PropertyModelFactory.eINSTANCE;
	
	public AtomicFormula createAtomicFormula(Expression expression) {
		AtomicFormula atomicFormula = factory.createAtomicFormula();
		atomicFormula.setExpression(expression);
		return atomicFormula;
	}
	
	public StateFormula createSimpleCTLFormula(PathQuantifier pathQuantifier,
			UnaryPathOperator unaryPathOperator, PathFormula formula) {
		QuantifiedFormula quantifiedFormula = factory.createQuantifiedFormula();
		quantifiedFormula.setQuantifier(pathQuantifier);
		UnaryOperandPathFormula pathFormula = factory.createUnaryOperandPathFormula();
		pathFormula.setOperator(unaryPathOperator);
		quantifiedFormula.setFormula(pathFormula);
		pathFormula.setOperand(formula);
		return quantifiedFormula;
	}
	
	public StateFormula createEF(PathFormula formula) {
		return createSimpleCTLFormula(PathQuantifier.EXISTS, UnaryPathOperator.FUTURE, formula);
	}
	
	public StateFormula createEG(PathFormula formula) {
		return createSimpleCTLFormula(PathQuantifier.EXISTS, UnaryPathOperator.GLOBAL, formula);
	}
	
	public StateFormula createAF(PathFormula formula) {
		return createSimpleCTLFormula(PathQuantifier.FORALL, UnaryPathOperator.FUTURE, formula);
	}
	
	public StateFormula createAG(PathFormula formula) {
		return createSimpleCTLFormula(PathQuantifier.FORALL, UnaryPathOperator.GLOBAL, formula);
	}
	
	public StateFormula createLeadsTo(PathFormula lhs, PathFormula rhs) {
		BinaryOperandLogicalPathFormula imply = factory.createBinaryOperandLogicalPathFormula();
		imply.setOperator(BinaryLogicalOperator.IMPLY);
		imply.setLeftOperand(lhs);
		StateFormula AF = createAF(rhs);
		imply.setRightOperand(AF);
		StateFormula AG = createAG(imply);
		return AG;
	}
	
	public ComponentInstanceEventReference createEventReference(ComponentInstanceReference instance,
			Port port, Event event) {
		ComponentInstanceEventReference reference = factory.createComponentInstanceEventReference();
		reference.setInstance(instance);
		reference.setPort(port);
		reference.setEvent(event);
		return reference;
	}
	
	public ComponentInstanceEventParameterReference createParameterReference(
			ComponentInstanceReference instance, Port port, Event event, ParameterDeclaration parameter) {
		ComponentInstanceEventParameterReference reference = factory.createComponentInstanceEventParameterReference();
		reference.setInstance(instance);
		reference.setPort(port);
		reference.setEvent(event);
		reference.setParameter(parameter);
		return reference;
	}
	
}
