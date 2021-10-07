/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.expression.util;

import java.math.BigInteger;

import org.eclipse.emf.common.util.TreeIterator;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.AddExpression;
import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.DivideExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.FalseExpression;
import hu.bme.mit.gamma.expression.model.ImplyExpression;
import hu.bme.mit.gamma.expression.model.InequalityExpression;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.MultiplyExpression;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.SubtractExpression;
import hu.bme.mit.gamma.expression.model.TrueExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.XorExpression;

public class ExpressionEvaluator {
	// Singleton
	public static final ExpressionEvaluator INSTANCE = new ExpressionEvaluator();
	protected ExpressionEvaluator() {}
	//

	protected final ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	protected final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	
	public int evaluate(Expression expression) {
		try {
			return evaluateInteger(expression);
		} catch (IllegalArgumentException e) {
			return evaluateBoolean(expression) ? 1 : 0;
		}
	}

	// Integers (and enums)
	public int evaluateInteger(Expression expression) {
		if (expression instanceof DirectReferenceExpression) {
			final DirectReferenceExpression referenceExpression = (DirectReferenceExpression) expression;
			Declaration declaration = referenceExpression.getDeclaration();
			if (declaration instanceof ConstantDeclaration) {
				final ConstantDeclaration constantDeclaration = (ConstantDeclaration) declaration;
				return evaluateInteger(constantDeclaration.getExpression());
			}
			if (declaration instanceof ParameterDeclaration) {
				final ParameterDeclaration parameterDeclaration = (ParameterDeclaration) declaration;
				final Expression argument = evaluateParameter(parameterDeclaration);
				return evaluateInteger(argument);
			}
			else {
				throw new IllegalArgumentException("Not transformable expression: " + expression.toString());
			}
		}
		if (expression instanceof IntegerLiteralExpression) {
			final IntegerLiteralExpression integerLiteralExpression = (IntegerLiteralExpression) expression;
			return integerLiteralExpression.getValue().intValue();
		}
		if (expression instanceof EnumerationLiteralExpression) {
			EnumerationLiteralDefinition enumLiteral = ((EnumerationLiteralExpression) expression).getReference();
			EnumerationTypeDefinition type = (EnumerationTypeDefinition) enumLiteral.eContainer();
			return type.getLiterals().indexOf(enumLiteral);
		}
		if (expression instanceof MultiplyExpression) {
			final MultiplyExpression multiplyExpression = (MultiplyExpression) expression;
			return multiplyExpression.getOperands().stream().map(it -> evaluateInteger(it)).reduce(1,
					(p1, p2) -> p1 * p2);
		}
		if (expression instanceof DivideExpression) {
			final DivideExpression divideExpression = (DivideExpression) expression;
			return evaluateInteger(divideExpression.getLeftOperand())
					/ evaluateInteger(divideExpression.getRightOperand());
		}
		if (expression instanceof AddExpression) {
			final AddExpression addExpression = (AddExpression) expression;
			return addExpression.getOperands().stream().map(it -> evaluateInteger(it)).reduce(0, (p1, p2) -> p1 + p2);
		}
		if (expression instanceof SubtractExpression) {
			final SubtractExpression subtractExpression = (SubtractExpression) expression;
			return evaluateInteger(subtractExpression.getLeftOperand())
					- evaluateInteger(subtractExpression.getRightOperand());
		}
		throw new IllegalArgumentException("Not transformable expression: " + expression);
	}

	public Expression evaluateParameter(ParameterDeclaration parameter) {
		EObject component = parameter.eContainer(); // Component
		EObject root = EcoreUtil.getRootContainer(parameter); // Package
		TreeIterator<Object> contents = EcoreUtil.getAllContents(root, true);
		while (contents.hasNext()) {
			Object content = contents.next();
			if (content instanceof ArgumentedElement) {
				ArgumentedElement element = (ArgumentedElement) content;
				if (element.eCrossReferences().contains(component)) { // If the component is referenced
					int index = ExpressionModelDerivedFeatures.getIndex(parameter);
					Expression expression = element.getArguments().get(index);
					return expression;
				}
			}
		}
		throw new IllegalArgumentException("Not found expression for parameter: " + parameter);
	}
	
	// Booleans
	public boolean evaluateBoolean(Expression expression) {
		if (expression instanceof TrueExpression) {
			return true;
		}
		if (expression instanceof FalseExpression) {
			return false;
		}
		if (expression instanceof AndExpression) {
			final AndExpression andExpression = (AndExpression) expression;
			for (Expression subExpression : andExpression.getOperands()) {
				if (!evaluateBoolean(subExpression)) {
					return false;
				}
			}
			return true;
		}
		if (expression instanceof OrExpression) {
			final OrExpression orExpression = (OrExpression) expression;
			for (Expression subExpression : orExpression.getOperands()) {
				if (evaluateBoolean(subExpression)) {
					return true;
				}
			}
			return false;
		}
		if (expression instanceof XorExpression) {
			int positiveCount = 0;
			final XorExpression xorExpression = (XorExpression) expression;
			for (Expression subExpression : xorExpression.getOperands()) {
				if (evaluateBoolean(subExpression)) {
					++positiveCount;
				}
			}
			return positiveCount % 2 == 1;
		}
		if (expression instanceof ImplyExpression) {
			final ImplyExpression implyExpression = (ImplyExpression) expression;
			return !evaluateBoolean(implyExpression.getLeftOperand())
					|| evaluateBoolean(implyExpression.getRightOperand());
		}
		if (expression instanceof NotExpression) {
			final NotExpression notExpression = (NotExpression) expression;
			return !evaluateBoolean(notExpression.getOperand());
		}
		if (expression instanceof EqualityExpression) {
			final EqualityExpression equalityExpression = (EqualityExpression) expression;
			// Evaluate to handle integer operands
			return evaluate(equalityExpression.getLeftOperand()) == evaluate(
					equalityExpression.getRightOperand());
		}
		if (expression instanceof InequalityExpression) {
			final InequalityExpression inequalityExpression = (InequalityExpression) expression;
			return evaluate(inequalityExpression.getLeftOperand()) != evaluate(
					inequalityExpression.getRightOperand());
		}
		if (expression instanceof DirectReferenceExpression) {
			final DirectReferenceExpression referenceExpression = (DirectReferenceExpression) expression;
			Declaration declaration = referenceExpression.getDeclaration();
			if (declaration instanceof ConstantDeclaration) {
				final ConstantDeclaration constantDeclaration = (ConstantDeclaration) declaration;
				return evaluateBoolean(constantDeclaration.getExpression());
			}
			if (declaration instanceof ParameterDeclaration) {
				final ParameterDeclaration parameterDeclaration = (ParameterDeclaration) declaration;
				final Expression argument = evaluateParameter(parameterDeclaration);
				return evaluateBoolean(argument);
			}
			else {
				throw new IllegalArgumentException("Not transformable expression: " + expression);
			}
		}
		throw new IllegalArgumentException("Not transformable expression: " + expression);
	}
	
	// Reverse
	
	public Expression of(Type type, int value) {
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(type);
		if (typeDefinition instanceof BooleanTypeDefinition) {
			return of((BooleanTypeDefinition) typeDefinition, value);
		}
		if (typeDefinition instanceof IntegerTypeDefinition) {
			return of((IntegerTypeDefinition) typeDefinition, value);
		}
		if (typeDefinition instanceof EnumerationTypeDefinition) {
			return of((EnumerationTypeDefinition) typeDefinition, value);
		}
		throw new IllegalArgumentException("Not known type: " + typeDefinition);
	}
	
	public Expression of(BooleanTypeDefinition type, int value) {
		switch (value) {
			case 0:
				return factory.createFalseExpression();
			default:
				return factory.createTrueExpression();
		} 
	}
	
	public Expression of(IntegerTypeDefinition type, int value) {
		IntegerLiteralExpression integerLiteralExpression = factory.createIntegerLiteralExpression();
		integerLiteralExpression.setValue(BigInteger.valueOf(value));
		return integerLiteralExpression;
	}
	
	public Expression of(EnumerationTypeDefinition type, int value) {
		EnumerationLiteralDefinition literal = type.getLiterals().get(value);
		return expressionUtil.createEnumerationLiteralExpression(literal);
	}
	
}
