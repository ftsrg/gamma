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
package hu.bme.mit.gamma.property.util;

import java.util.ArrayList;
import java.util.List;

import hu.bme.mit.gamma.expression.model.Comment;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.property.model.AtomicFormula;
import hu.bme.mit.gamma.property.model.BinaryLogicalOperator;
import hu.bme.mit.gamma.property.model.BinaryOperandLogicalPathFormula;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PathFormula;
import hu.bme.mit.gamma.property.model.PathQuantifier;
import hu.bme.mit.gamma.property.model.PropertyModelFactory;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.QuantifiedFormula;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.property.model.UnaryOperandPathFormula;
import hu.bme.mit.gamma.property.model.UnaryPathOperator;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;

public class PropertyUtil extends StatechartUtil {
	// Singleton
	public static final PropertyUtil INSTANCE = new PropertyUtil();
	protected PropertyUtil() {}
	//
	protected final PropertyModelFactory propertyFactory = PropertyModelFactory.eINSTANCE;
	
	// Wrap
	
	public PropertyPackage wrapFormula(Component component, StateFormula formula) {
		CommentableStateFormula commentableStateFormula = propertyFactory.createCommentableStateFormula();
		commentableStateFormula.setFormula(formula);
		return wrapFormula(component, commentableStateFormula);
	}
	
	public PropertyPackage wrapFormula(Component component, CommentableStateFormula formula) {
		PropertyPackage propertyPackage = propertyFactory.createPropertyPackage();
		Package _package = StatechartModelDerivedFeatures.getContainingPackage(component);
		propertyPackage.getImports().add(_package);
		propertyPackage.setComponent(component);
		propertyPackage.getFormulas().add(formula);
		return propertyPackage;
	}
	
	// Wrapping - adding proxy wrapper instance references
	
	public void extendFormulasWithWrapperInstance(PropertyPackage propertyPackage) {
		Component component = propertyPackage.getComponent();
		List<CommentableStateFormula> formulas = propertyPackage.getFormulas();
		extendFormulasWithWrapperInstance(formulas, component);
	}
	
	protected void extendFormulasWithWrapperInstance(List<CommentableStateFormula> formulas, Component component) {
		for (CommentableStateFormula formula : formulas) {
			extendFormulasWithWrapperInstance(formula, component);
		}
	}

	protected void extendFormulasWithWrapperInstance(CommentableStateFormula commentableStateFormula, Component component) {
		StateFormula formula = commentableStateFormula.getFormula();
		List<ComponentInstanceElementReferenceExpression> stateExpressions =
				ecoreUtil.getAllContentsOfType(formula, ComponentInstanceElementReferenceExpression.class);
		for (ComponentInstanceElementReferenceExpression stateExpression : stateExpressions) {
			extendFormulasWithWrapperInstance(component, stateExpression);
		}
	}

	protected void extendFormulasWithWrapperInstance(Component component, ComponentInstanceElementReferenceExpression stateExpression) {
		ComponentInstanceReferenceExpression instanceReference = stateExpression.getInstance();
		ComponentInstance wrapperInstance = instantiateComponent(component);
		prependAndReplace(instanceReference, wrapperInstance);
	}
	
	public void removeFirstInstanceFromFormulas(PropertyPackage propertyPackage) {
		List<CommentableStateFormula> formulas = propertyPackage.getFormulas();
		removeFirstInstanceFromFormulas(formulas);
	}
	
	protected void removeFirstInstanceFromFormulas(List<CommentableStateFormula> formulas) {
		for (CommentableStateFormula commentableStateFormula : formulas) {
			removeFirstInstanceFromFormula(commentableStateFormula);
		}
	}

	protected void removeFirstInstanceFromFormula(CommentableStateFormula commentableStateFormula) {
		StateFormula formula = commentableStateFormula.getFormula();
		List<ComponentInstanceElementReferenceExpression> stateExpressions =
				ecoreUtil.getAllContentsOfType(formula, ComponentInstanceElementReferenceExpression.class);
		for (ComponentInstanceElementReferenceExpression stateExpression : stateExpressions) {
			removeFirstInstanceFromFormula(stateExpression);
		}
	}

	protected void removeFirstInstanceFromFormula(ComponentInstanceElementReferenceExpression stateExpression) {
		ComponentInstanceReferenceExpression instanceReference = stateExpression.getInstance();
		ComponentInstanceReferenceExpression child = instanceReference.getChild();
		ecoreUtil.replace(child, instanceReference);
	}
	
	//
	
	public ComponentInstanceElementReferenceExpression chainReferences(
			List<? extends Expression> operands) {
		List<Expression> expressions = new ArrayList<Expression>(operands);
		// If it is a variable reference, we expect the first "n" elements
		// to be ComponentInstanceReference
		List<ComponentInstanceReferenceExpression> instanceReferences =
				javaUtil.filterIntoList(expressions, ComponentInstanceReferenceExpression.class);
		ComponentInstanceReferenceExpression rootInstance =
				createInstanceReferenceChain(instanceReferences);
		
		// Last operand is the declaration reference
		Expression lastExpression = javaUtil.getLast(expressions);
		if (lastExpression instanceof DirectReferenceExpression) {
			Declaration declaration = getDeclaration(lastExpression);
			if (declaration instanceof VariableDeclaration) {
				VariableDeclaration variableDeclaration = (VariableDeclaration) declaration;
				ComponentInstanceVariableReferenceExpression variableReference =
						createVariableReference(rootInstance, variableDeclaration);
				return variableReference;
			}
			else {
				throw new IllegalArgumentException("Not known type: " + declaration);
			}
		}
		else {
			throw new IllegalArgumentException("Not known type: " + lastExpression);
		}
	}
	
	//
	
	public AtomicFormula createAtomicFormula(Expression expression) {
		AtomicFormula atomicFormula = propertyFactory.createAtomicFormula();
		atomicFormula.setExpression(expression);
		return atomicFormula;
	}
	
	public StateFormula createSimpleCtlFormula(PathQuantifier pathQuantifier,
			UnaryPathOperator unaryPathOperator, PathFormula formula) {
		QuantifiedFormula quantifiedFormula = propertyFactory.createQuantifiedFormula();
		quantifiedFormula.setQuantifier(pathQuantifier);
		UnaryOperandPathFormula pathFormula = propertyFactory.createUnaryOperandPathFormula();
		pathFormula.setOperator(unaryPathOperator);
		quantifiedFormula.setFormula(pathFormula);
		pathFormula.setOperand(formula);
		return quantifiedFormula;
	}
	
	public StateFormula createEF(PathFormula formula) {
		return createSimpleCtlFormula(PathQuantifier.EXISTS, UnaryPathOperator.FUTURE, formula);
	}
	
	public StateFormula createEG(PathFormula formula) {
		return createSimpleCtlFormula(PathQuantifier.EXISTS, UnaryPathOperator.GLOBAL, formula);
	}
	
	public StateFormula createAF(PathFormula formula) {
		return createSimpleCtlFormula(PathQuantifier.FORALL, UnaryPathOperator.FUTURE, formula);
	}
	
	public StateFormula createAG(PathFormula formula) {
		return createSimpleCtlFormula(PathQuantifier.FORALL, UnaryPathOperator.GLOBAL, formula);
	}
	
	public StateFormula createLeadsTo(PathFormula lhs, PathFormula rhs) {
		BinaryOperandLogicalPathFormula imply = propertyFactory.createBinaryOperandLogicalPathFormula();
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
		CommentableStateFormula commentableStateFormula = propertyFactory.createCommentableStateFormula();
		commentableStateFormula.setFormula(formula);
		Comment comment = factory.createComment();
		comment.setComment(commentString);
		commentableStateFormula.getComments().add(comment);
		return commentableStateFormula;
	}
	
	public CommentableStateFormula createCommentableStateFormula(StateFormula formula) {
		return createCommentableStateFormula("", formula);
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
