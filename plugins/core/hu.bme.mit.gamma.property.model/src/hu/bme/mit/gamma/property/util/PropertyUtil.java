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

import hu.bme.mit.gamma.expression.model.Comment;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.property.model.AtomicFormula;
import hu.bme.mit.gamma.property.model.BinaryLogicalOperator;
import hu.bme.mit.gamma.property.model.BinaryOperandLogicalPathFormula;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference;
import hu.bme.mit.gamma.property.model.PathFormula;
import hu.bme.mit.gamma.property.model.PathQuantifier;
import hu.bme.mit.gamma.property.model.PropertyModelFactory;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.QuantifiedFormula;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula;
import hu.bme.mit.gamma.property.model.UnaryPathOperator;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;

public class PropertyUtil extends StatechartUtil {
	// Singleton
	public static final PropertyUtil INSTANCE = new PropertyUtil();
	protected PropertyUtil() {}
	//
	protected final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	protected final PropertyModelFactory factory = PropertyModelFactory.eINSTANCE;
	
	// Wrap
	
	public PropertyPackage wrapFormula(Component component, StateFormula formula) {
		CommentableStateFormula commentableStateFormula = factory.createCommentableStateFormula();
		commentableStateFormula.setFormula(formula);
		return wrapFormula(component, commentableStateFormula);
	}
	
	public PropertyPackage wrapFormula(Component component, CommentableStateFormula formula) {
		PropertyPackage propertyPackage = factory.createPropertyPackage();
		Package _package = StatechartModelDerivedFeatures.getContainingPackage(component);
		propertyPackage.getImport().add(_package);
		propertyPackage.setComponent(component);
		propertyPackage.getFormulas().add(formula);
		return propertyPackage;
	}
	
	//
	
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
	
	// Comments
	
	public CommentableStateFormula createCommentableStateFormula(
			String commentString, StateFormula formula) {
		CommentableStateFormula commentableStateFormula = factory.createCommentableStateFormula();
		commentableStateFormula.setFormula(formula);
		Comment comment = expressionFactory.createComment();
		comment.setComment(commentString);
		commentableStateFormula.getComments().add(comment);
		return commentableStateFormula;
	}
	
	// Atomic expressions
	
	public ComponentInstanceStateConfigurationReference createStateReference(
			ComponentInstanceReference instance, State state) {
		ComponentInstanceStateConfigurationReference reference = factory.createComponentInstanceStateConfigurationReference();
		reference.setInstance(instance);
		reference.setRegion(StatechartModelDerivedFeatures.getParentRegion(state));
		reference.setState(state);
		return reference;
	}
	
	public ComponentInstanceVariableReference createVariableReference(ComponentInstanceReference instance,
			VariableDeclaration variable) {
		ComponentInstanceVariableReference reference = factory.createComponentInstanceVariableReference();
		reference.setInstance(instance);
		reference.setVariable(variable);
		return reference;
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
	
	// More complex
	
	public PropertyPackage createAtomicInstanceStateReachabilityProperty(
			Component topContainer,	ComponentInstance instance, State lastState) {
		StateFormula formula = createEF(
			createAtomicFormula(
				createStateReference(
					createInstanceReferenceChain(instance), lastState)
			)
		);
		return wrapFormula(topContainer, formula);
	}
	
	// Getter
	
	public PathFormula getEgLessFormula(StateFormula formula) {
		if (formula instanceof QuantifiedFormula) {
			QuantifiedFormula quantifiedFormula = (QuantifiedFormula) formula;
			PathQuantifier quantifier = quantifiedFormula.getQuantifier();
			if (quantifier == PathQuantifier.EXISTS) {
				PathFormula pathFormula = quantifiedFormula.getFormula();
				if (pathFormula instanceof UnaryOperandPathFormula) {
					UnaryOperandPathFormula unaryOperandPathFormula = (UnaryOperandPathFormula) pathFormula;
					UnaryPathOperator operator = unaryOperandPathFormula.getOperator();
					if (operator == UnaryPathOperator.FUTURE) {
						PathFormula egLessFormula = unaryOperandPathFormula.getOperand();
						return egLessFormula;
					}
				}
			}
		}
		return null;
	}
	
}
