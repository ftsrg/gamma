/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.expression.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

import org.eclipse.emf.common.util.TreeIterator;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.AddExpression;
import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.DivideExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.EquivalenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.FalseExpression;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression;
import hu.bme.mit.gamma.expression.model.GreaterExpression;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.ImplyExpression;
import hu.bme.mit.gamma.expression.model.InequalityExpression;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.LessEqualExpression;
import hu.bme.mit.gamma.expression.model.LessExpression;
import hu.bme.mit.gamma.expression.model.MultiplyExpression;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.SubtractExpression;
import hu.bme.mit.gamma.expression.model.TrueExpression;
import hu.bme.mit.gamma.expression.model.XorExpression;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExpressionEvaluator {
	// Singleton
	public static final ExpressionEvaluator INSTANCE = new ExpressionEvaluator();
	protected ExpressionEvaluator() {}
	//

	protected final ArgumentInliner argumentInliner = ArgumentInliner.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	
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
			DirectReferenceExpression referenceExpression = (DirectReferenceExpression) expression;
			Declaration declaration = referenceExpression.getDeclaration();
			if (declaration instanceof ConstantDeclaration) {
				ConstantDeclaration constantDeclaration = (ConstantDeclaration) declaration;
				return evaluateInteger(constantDeclaration.getExpression());
			}
			if (declaration instanceof ParameterDeclaration) {
				ParameterDeclaration parameterDeclaration = (ParameterDeclaration) declaration;
				Expression argument = evaluateParameter(parameterDeclaration);
				return evaluateInteger(argument);
			}
			else {
				throw new IllegalArgumentException("Not transformable expression: " + expression.toString());
			}
		}
		if (expression instanceof IntegerLiteralExpression) {
			IntegerLiteralExpression integerLiteralExpression = (IntegerLiteralExpression) expression;
			return integerLiteralExpression.getValue().intValue();
		}
		if (expression instanceof EnumerationLiteralExpression) {
			EnumerationLiteralExpression enumerationLiteralExpression = (EnumerationLiteralExpression) expression;
			EnumerationLiteralDefinition enumLiteral = enumerationLiteralExpression.getReference();
			EnumerationTypeDefinition type = (EnumerationTypeDefinition) enumLiteral.eContainer();
			return type.getLiterals().indexOf(enumLiteral);
		}
		if (expression instanceof MultiplyExpression) {
			MultiplyExpression multiplyExpression = (MultiplyExpression) expression;
			return multiplyExpression.getOperands().stream().map(it -> evaluateInteger(it))
					.reduce(1, (p1, p2) -> p1 * p2);
		}
		if (expression instanceof DivideExpression) {
			DivideExpression divideExpression = (DivideExpression) expression;
			return evaluateInteger(divideExpression.getLeftOperand())
					/ evaluateInteger(divideExpression.getRightOperand());
		}
		if (expression instanceof AddExpression) {
			AddExpression addExpression = (AddExpression) expression;
			return addExpression.getOperands().stream().map(it -> evaluateInteger(it))
					.reduce(0, (p1, p2) -> p1 + p2);
		}
		if (expression instanceof SubtractExpression) {
			SubtractExpression subtractExpression = (SubtractExpression) expression;
			return evaluateInteger(subtractExpression.getLeftOperand())
					- evaluateInteger(subtractExpression.getRightOperand());
		}
		if (expression instanceof FunctionAccessExpression) {
			FunctionAccessExpression functionAccessExpression = (FunctionAccessExpression) expression;
			Expression inlinedLambaExpression = argumentInliner.createInlinedLambaExpression(functionAccessExpression);
			return evaluateInteger(inlinedLambaExpression);
		}
		if (expression instanceof IfThenElseExpression) {
			IfThenElseExpression ifThenElseExpression = (IfThenElseExpression) expression;
			Expression condition = ifThenElseExpression.getCondition();
			if (evaluateBoolean(condition)) {
				return evaluateInteger(
						ifThenElseExpression.getThen());
			}
			return evaluateInteger(
					ifThenElseExpression.getElse());
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
			AndExpression andExpression = (AndExpression) expression;
			IllegalArgumentException unevaluableException = null;
			for (Expression subExpression : andExpression.getOperands()) {
				try {
					if (!evaluateBoolean(subExpression)) {
						return false;
					}
				} catch (IllegalArgumentException e) {
					unevaluableException = e;
				}
			}
			// Checking equality expressions with references and different literals
			List<EqualityExpression> equalityExpressions =
					collectAllEqualityExpressions(andExpression);
			List<EqualityExpression> referenceEqualityExpressions =
					filterReferenceEqualityExpressions(equalityExpressions);
			if (hasEqualityToDifferentLiterals(referenceEqualityExpressions)) {
				return false;
			}
			//
			if (unevaluableException != null) {
				throw unevaluableException; // At least one was unevaluable
			}
			return true; // All subexpressions evaluated to true
		}
		if (expression instanceof OrExpression) {
			OrExpression orExpression = (OrExpression) expression;
			IllegalArgumentException unevaluableException = null;
			for (Expression subExpression : orExpression.getOperands()) {
				try {
					if (evaluateBoolean(subExpression)) {
						return true;
					}
				} catch (IllegalArgumentException e) {
					unevaluableException = e;
				}
			}
			if (unevaluableException != null) {
				throw unevaluableException; // At least one was unevaluable
			}
			return false; // All subexpressions evaluated to false
		}
		if (expression instanceof XorExpression) {
			int positiveCount = 0;
			XorExpression xorExpression = (XorExpression) expression;
			for (Expression subExpression : xorExpression.getOperands()) {
				if (evaluateBoolean(subExpression)) {
					++positiveCount;
				}
			}
			return positiveCount % 2 == 1;
		}
		if (expression instanceof NotExpression) {
			NotExpression notExpression = (NotExpression) expression;
			return !evaluateBoolean(notExpression.getOperand());
		}
		if (expression instanceof BinaryExpression) {
			BinaryExpression binaryExpression = (BinaryExpression) expression;
			Expression left = binaryExpression.getLeftOperand();
			Expression right = binaryExpression.getRightOperand();
			if (expression instanceof ImplyExpression) {
				return !evaluateBoolean(left) || evaluateBoolean(right);
			}
			if (expression instanceof EquivalenceExpression) {
				if (expression instanceof EqualityExpression) {
					// Handle enumeration literals as different ones can get the same integer value
					if (left instanceof EnumerationLiteralExpression &&
							right instanceof EnumerationLiteralExpression) {
						return ecoreUtil.helperEquals(left, right);
					}
					return evaluate(left) == evaluate(right);
				}
				if (expression instanceof InequalityExpression) {
					if (left instanceof EnumerationLiteralExpression &&
							right instanceof EnumerationLiteralExpression) {
						return !ecoreUtil.helperEquals(left, right);
					}
					return evaluate(left) != evaluate(right);
				}
			}
			if (expression instanceof LessExpression) {
				return evaluate(left) < evaluate(right);
			}
			if (expression instanceof LessEqualExpression) {
				return evaluate(left) <= evaluate(right);
			}
			if (expression instanceof GreaterExpression) {
				return evaluate(left) > evaluate(right);
			}
			if (expression instanceof GreaterEqualExpression) {
				return evaluate(left) >= evaluate(right);
			}
		}
		if (expression instanceof DirectReferenceExpression) {
			DirectReferenceExpression referenceExpression = (DirectReferenceExpression) expression;
			Declaration declaration = referenceExpression.getDeclaration();
			if (declaration instanceof ConstantDeclaration) {
				ConstantDeclaration constantDeclaration = (ConstantDeclaration) declaration;
				return evaluateBoolean(constantDeclaration.getExpression());
			}
			if (declaration instanceof ParameterDeclaration) {
				ParameterDeclaration parameterDeclaration = (ParameterDeclaration) declaration;
				Expression argument = evaluateParameter(parameterDeclaration);
				return evaluateBoolean(argument);
			}
			else {
				throw new IllegalArgumentException("Not transformable expression: " + expression);
			}
		}
		if (expression instanceof FunctionAccessExpression) {
			FunctionAccessExpression functionAccessExpression = (FunctionAccessExpression) expression;
			Expression inlinedLambaExpression = argumentInliner.createInlinedLambaExpression(functionAccessExpression);
			return evaluateBoolean(inlinedLambaExpression);
		}
		if (expression instanceof IfThenElseExpression) {
			IfThenElseExpression ifThenElseExpression = (IfThenElseExpression) expression;
			Expression condition = ifThenElseExpression.getCondition();
			if (evaluateBoolean(condition)) {
				return evaluateBoolean(
						ifThenElseExpression.getThen());
			}
			return evaluateBoolean(
					ifThenElseExpression.getElse());
		}
		throw new IllegalArgumentException("Not transformable expression: " + expression);
	}
	

	public boolean isDefinitelyTrueExpression(Expression expression) {
		try {
			return evaluateBoolean(expression);
		} catch (IllegalArgumentException e) {
			return false;
		}
	}

	public boolean isDefinitelyFalseExpression(Expression expression) {
		try {
			return !evaluateBoolean(expression);
		} catch (IllegalArgumentException e) {
			return false;
		}
	}
	
	// Auxiliary
	
	protected boolean hasEqualityToDifferentLiterals(List<EqualityExpression> expressions) {
		for (int i = 0; i < expressions.size() - 1; ++i) {
			try {
				EqualityExpression leftEqualityExpression = expressions.get(i);
				Expression leftReference = leftEqualityExpression.getLeftOperand();
				Expression leftValueExpression = leftEqualityExpression.getRightOperand();
				int leftValue = evaluate(leftValueExpression);
				for (int j = i + 1; j < expressions.size(); ++j) {
					try {
						EqualityExpression rightEqualityExpression = expressions.get(j);
						Expression rightReference = rightEqualityExpression.getLeftOperand();
						if (ecoreUtil.helperEquals(leftReference, rightReference)) {
							Expression rightValueExpression = rightEqualityExpression.getRightOperand();
							
							if (leftValueExpression instanceof EnumerationLiteralExpression &&
									rightValueExpression instanceof EnumerationLiteralExpression) {
								if (!ecoreUtil.helperEquals(leftValueExpression, rightValueExpression)) {
									return true;
								}
							}
							
							int rightValue = evaluate(rightValueExpression);
							if (leftValue != rightValue) {
								return true;
							}
						}
					} catch (IllegalArgumentException e) {
						// j is not evaluable
						expressions.remove(j);
						--j;
					}
				}
			} catch (IllegalArgumentException e) {
				// i is not evaluable
				expressions.remove(i);
				--i;
			}
		}
		return false;
	}
	
	protected List<EqualityExpression> collectAllEqualityExpressions(AndExpression expression) {
		List<EqualityExpression> equalityExpressions = new ArrayList<EqualityExpression>();
		for (Expression subexpression : expression.getOperands()) {
			if (subexpression instanceof EqualityExpression) {
				EqualityExpression equalityExpression = (EqualityExpression) subexpression;
				equalityExpressions.add(equalityExpression);
			}
			else if (subexpression instanceof AndExpression) {
				AndExpression andExpression = (AndExpression) subexpression;
				equalityExpressions.addAll(collectAllEqualityExpressions(andExpression));
			}
		}
		return equalityExpressions;
	}

	protected List<EqualityExpression> filterReferenceEqualityExpressions(
			Collection<EqualityExpression> expressions) {
		return expressions.stream().filter(
				it -> it.getLeftOperand() instanceof ReferenceExpression
				&& !(it.getRightOperand() instanceof ReferenceExpression))
			.collect(Collectors.toList());
	}
	
//	// Reverse
//	
//	public Expression of(Type type, int value) {
//		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(type);
//		if (typeDefinition instanceof BooleanTypeDefinition) {
//			return of((BooleanTypeDefinition) typeDefinition, value);
//		}
//		if (typeDefinition instanceof IntegerTypeDefinition) {
//			return of((IntegerTypeDefinition) typeDefinition, value);
//		}
//		if (typeDefinition instanceof EnumerationTypeDefinition) {
//			return of((EnumerationTypeDefinition) typeDefinition, value);
//		}
//		throw new IllegalArgumentException("Not known type: " + typeDefinition);
//	}
//	
//	public Expression of(BooleanTypeDefinition type, int value) {
//		switch (value) {
//			case 0:
//				return factory.createFalseExpression();
//			default:
//				return factory.createTrueExpression();
//		} 
//	}
//	
//	public Expression of(IntegerTypeDefinition type, int value) {
//		IntegerLiteralExpression integerLiteralExpression = factory.createIntegerLiteralExpression();
//		integerLiteralExpression.setValue(BigInteger.valueOf(value));
//		return integerLiteralExpression;
//	}
//	
//	public Expression of(EnumerationTypeDefinition type, int value) {
//		EnumerationLiteralDefinition literal = type.getLiterals().get(value);
//		return expressionUtil.createEnumerationLiteralExpression(literal);
//	}
	
}
