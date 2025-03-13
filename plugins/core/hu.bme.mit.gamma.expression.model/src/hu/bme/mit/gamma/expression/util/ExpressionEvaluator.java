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
package hu.bme.mit.gamma.expression.util;

import java.math.BigDecimal;
import java.math.BigInteger;
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
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.ConstantDeclaration;
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.DivideExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.EquivalenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.FalseExpression;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression;
import hu.bme.mit.gamma.expression.model.GreaterExpression;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.ImplyExpression;
import hu.bme.mit.gamma.expression.model.InequalityExpression;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.LessEqualExpression;
import hu.bme.mit.gamma.expression.model.LessExpression;
import hu.bme.mit.gamma.expression.model.MultiplyExpression;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.SubtractExpression;
import hu.bme.mit.gamma.expression.model.TrueExpression;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.UnaryMinusExpression;
import hu.bme.mit.gamma.expression.model.XorExpression;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExpressionEvaluator {
	// Singleton
	public static final ExpressionEvaluator INSTANCE = new ExpressionEvaluator();
	protected ExpressionEvaluator() {}
	//

	protected final ArgumentInliner argumentInliner = ArgumentInliner.INSTANCE;
	protected final ExpressionTypeDeterminator2 typeDeterminator = ExpressionTypeDeterminator2.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	//
	
	public Expression evaluateExpression(Expression expression) {
		TypeDefinition type = typeDeterminator.getTypeDefinition(expression);
		if (type instanceof BooleanTypeDefinition) {
			boolean value = evaluateBoolean(expression);
			return (value) ? factory.createTrueExpression() : factory.createFalseExpression();
		}
		if (type instanceof IntegerTypeDefinition) {
			int value = evaluateInteger(expression);
			IntegerLiteralExpression literal = factory.createIntegerLiteralExpression();
			BigInteger bigIntegerValue = BigInteger.valueOf(value);
			literal.setValue(bigIntegerValue);
			return literal;
		}
		if (type instanceof RationalTypeDefinition || type instanceof DecimalTypeDefinition) {
			double value = evaluateDecimal(expression);
			DecimalLiteralExpression literal = factory.createDecimalLiteralExpression();
			BigDecimal bigDecimalValue = BigDecimal.valueOf(value);
			literal.setValue(bigDecimalValue);
			return literal;
		}
		
		// None of the above
		return expression;
	}
	
	//
	
	public int evaluate(Expression expression) {
		try {
			return evaluateInteger(expression);
		} catch (IllegalArgumentException e) {
			return evaluateBoolean(expression) ? 1 : 0;
		}
	}
	
	public double evaluateDouble(Expression expression) {
		try {
			return (double) evaluate(expression);
		} catch (IllegalArgumentException e) {
			return evaluateDecimal(expression);
		}
	}
	
	// Integers (and enums)
	public int evaluateInteger(Expression expression) {
		if (expression instanceof DirectReferenceExpression referenceExpression) {
			Declaration declaration = referenceExpression.getDeclaration();
			if (declaration instanceof ConstantDeclaration constantDeclaration) {
				return evaluateInteger(constantDeclaration.getExpression());
			}
			if (declaration instanceof ParameterDeclaration parameterDeclaration) {
				Expression argument = evaluateParameter(parameterDeclaration);
				return evaluateInteger(argument);
			}
			else {
				throw new IllegalArgumentException("Not evaluable expression: " + expression.toString());
			}
		}
		if (expression instanceof IntegerLiteralExpression integerLiteralExpression) {
			return integerLiteralExpression.getValue().intValue();
		}
		if (expression instanceof EnumerationLiteralExpression enumerationLiteralExpression) {
			EnumerationLiteralDefinition enumLiteral = enumerationLiteralExpression.getReference();
			EnumerationTypeDefinition type = (EnumerationTypeDefinition) enumLiteral.eContainer();
			List<EnumerationLiteralDefinition> literals = type.getLiterals();
			return literals.indexOf(enumLiteral);
		}
		if (expression instanceof ArrayAccessExpression arrayAccessExpression) {
			Expression index = arrayAccessExpression.getIndex();
			Expression operand = arrayAccessExpression.getOperand();
			if (operand instanceof ArrayLiteralExpression) {
				ArrayLiteralExpression arrayLiteralExpression = (ArrayLiteralExpression) operand;
				List<Expression> operands = arrayLiteralExpression.getOperands();
				return evaluateInteger(
						operands.get(
								evaluateInteger(index)));
			}
		}
		if (expression instanceof MultiplyExpression multiplyExpression) {
			List<Expression> operands = multiplyExpression.getOperands();
			List<Integer> evaluatedOperands = new ArrayList<Integer>();
			IllegalArgumentException potentialException = null;
			//
			for (Expression multiplicationOperand : operands) {
				try {
					int evaluatedOperand = evaluateInteger(multiplicationOperand);
					if (evaluatedOperand == 0) {
						return 0;
					}
					else {
						evaluatedOperands.add(evaluatedOperand);
					}
				} catch (IllegalArgumentException e) {
					potentialException = e;
				}
			}
			//
			if (potentialException != null) {
				throw potentialException;
			}
			return evaluatedOperands.stream().reduce(1, (p1, p2) -> p1 * p2);
		}
		if (expression instanceof DivideExpression divideExpression) {
			int evaluatedNumerator = evaluateInteger(divideExpression.getLeftOperand());
			if (evaluatedNumerator == 0) {
				return 0;
			}
			//
			return evaluatedNumerator / evaluateInteger(divideExpression.getRightOperand());
		}
		if (expression instanceof AddExpression addExpression) {
			List<Expression> operands = addExpression.getOperands();
			// Potential optimization
			List<Expression> negativeOperandPairs = getNegativeExpressionPairs(operands);
			//
			List<Expression> evaluableOperands = new ArrayList<Expression>(operands);
			evaluableOperands.removeAll(negativeOperandPairs);
			//
			return evaluableOperands.stream().map(it -> evaluateInteger(it))
					.reduce(0, (p1, p2) -> p1 + p2);
		}
		if (expression instanceof SubtractExpression subtractExpression) {
			Expression leftOperand = subtractExpression.getLeftOperand();
			Expression rightOperand = subtractExpression.getRightOperand();
			
			if (ecoreUtil.helperEquals(leftOperand, rightOperand)) {
				return 0;
			}
			//
			return evaluateInteger(leftOperand) - evaluateInteger(rightOperand);
		}
		if (expression instanceof FunctionAccessExpression functionAccessExpression) {
			Expression inlinedLambaExpression = argumentInliner.createInlinedLambaExpression(functionAccessExpression);
			return evaluateInteger(inlinedLambaExpression);
		}
		if (expression instanceof IfThenElseExpression ifThenElseExpression) {
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
	
	public List<Integer> evaluateRange(IntegerRangeLiteralExpression expression) {
		// Generating a list of integer to iterate over
		ArrayList<Integer> range = new ArrayList<Integer>();
		
		Expression lhs = expression.getLeftOperand();
		Expression rhs = expression.getRightOperand();
		
		// if the expression is left inclusive we leave the lhs as is, if exclusive we have to increase the lhs by 1
		// similarly if the expression is right inclusive we have to increase the rhs by 1, if exlusive we can leave as is
		for (int i = (evaluate(lhs) + (expression.isLeftInclusive() ? 0 : 1)); i < (evaluate(rhs) + (expression.isRightInclusive() ? 1 : 0)); i++) {
			range.add(i);
		}
		
		return range;
	}

	// Decimal and rational
	public double evaluateDecimal(Expression expression) {
		if (expression instanceof DirectReferenceExpression referenceExpression) {
			Declaration declaration = referenceExpression.getDeclaration();
			if (declaration instanceof ConstantDeclaration constantDeclaration) {
				return evaluateDecimal(constantDeclaration.getExpression());
			}
			if (declaration instanceof ParameterDeclaration parameterDeclaration) {
				final Expression argument = evaluateParameter(parameterDeclaration);
				return evaluateDecimal(argument);
			}
			else {
				throw new IllegalArgumentException("Not transformable expression: " + expression.toString());
			}
		}
		if (expression instanceof IntegerLiteralExpression integerLiteralExpression) {
			return integerLiteralExpression.getValue().doubleValue();
		}
		if (expression instanceof DecimalLiteralExpression decimalLiteralExpression) {
			return decimalLiteralExpression.getValue().doubleValue();
		}
		if (expression instanceof RationalLiteralExpression rationalLiteralExpression) {
			return rationalLiteralExpression.getNumerator().doubleValue() /
					rationalLiteralExpression.getDenominator().doubleValue();
		}
		if (expression instanceof EnumerationLiteralExpression literalExpression) {
			EnumerationLiteralDefinition enumLiteral = literalExpression.getReference();
			EnumerationTypeDefinition type = (EnumerationTypeDefinition) enumLiteral.eContainer();
			List<EnumerationLiteralDefinition> literals = type.getLiterals();
			return (double) literals.indexOf(enumLiteral);
		}
		if (expression instanceof ArrayAccessExpression arrayAccessExpression) {
			Expression index = arrayAccessExpression.getIndex();
			Expression operand = arrayAccessExpression.getOperand();
			if (operand instanceof ArrayLiteralExpression) {
				ArrayLiteralExpression arrayLiteralExpression = (ArrayLiteralExpression) operand;
				List<Expression> operands = arrayLiteralExpression.getOperands();
				return evaluateDecimal(
						operands.get(
								evaluateInteger(index)));
			}
		}
		if (expression instanceof MultiplyExpression multiplyExpression) {
			List<Expression> operands = multiplyExpression.getOperands();
			List<Double> evaluatedOperands = new ArrayList<Double>();
			IllegalArgumentException potentialException = null;
			//
			for (Expression multiplicationOperand : operands) {
				try {
					double evaluatedOperand = evaluateDecimal(multiplicationOperand);
					if (evaluatedOperand == 0.0) {
						return 0.0;
					}
					else {
						evaluatedOperands.add(evaluatedOperand);
					}
				} catch (IllegalArgumentException e) {
					potentialException = e;
				}
			}
			//
			if (potentialException != null) {
				throw potentialException;
			}
			return evaluatedOperands.stream().reduce(1.0, (p1, p2) -> p1 * p2);
		}
		if (expression instanceof DivideExpression divideExpression) {
			double evaluatedNumerator = evaluateDecimal(divideExpression.getLeftOperand());
			if (evaluatedNumerator == 0.0) {
				return 0.0;
			}
			//
			return evaluatedNumerator / evaluateDecimal(divideExpression.getRightOperand());
		}
		if (expression instanceof AddExpression addExpression) {
			List<Expression> operands = addExpression.getOperands();
			// Potential optimization
			List<Expression> negativeOperandPairs = getNegativeExpressionPairs(operands);
			//
			List<Expression> evaluableOperands = new ArrayList<Expression>(operands);
			evaluableOperands.removeAll(negativeOperandPairs);
			//
			return evaluableOperands.stream().map(it -> evaluateDecimal(it))
					.reduce(0.0, (p1, p2) -> p1 + p2);
		}
		if (expression instanceof SubtractExpression subtractExpression) {
			// Potential optimization trick
			Expression leftOperand = subtractExpression.getLeftOperand();
			Expression rightOperand = subtractExpression.getRightOperand();
			
			if (ecoreUtil.helperEquals(leftOperand, rightOperand)) {
				return 0.0;
			}
			//
			
			return evaluateDecimal(leftOperand) - evaluateDecimal(rightOperand);
		}
		throw new IllegalArgumentException("Not transformable expression: " + expression);
	} 
	
	// Booleans
	public boolean evaluateBoolean(Expression expression) {
		if (expression instanceof TrueExpression) {
			return true;
		}
		if (expression instanceof FalseExpression) {
			return false;
		}
		if (expression instanceof ArrayAccessExpression arrayAccessExpression) {
			Expression index = arrayAccessExpression.getIndex();
			Expression operand = arrayAccessExpression.getOperand();
			if (operand instanceof ArrayLiteralExpression arrayLiteralExpression) {
				List<Expression> operands = arrayLiteralExpression.getOperands();
				return evaluateBoolean(
						operands.get(
								evaluateInteger(index)));
			}
		}
		if (expression instanceof AndExpression andExpression) {
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
		if (expression instanceof OrExpression orExpression) {
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
		if (expression instanceof NotExpression notExpression) {
			return !evaluateBoolean(notExpression.getOperand());
		}
		if (expression instanceof BinaryExpression binaryExpression) {
			Expression left = binaryExpression.getLeftOperand();
			Expression right = binaryExpression.getRightOperand();
			//
			boolean leftEqualsRight = ecoreUtil.helperEquals(left, right); // For optimization
			//
			if (expression instanceof ImplyExpression) {
				return !evaluateBoolean(left) || evaluateBoolean(right);
			}
			if (expression instanceof EquivalenceExpression) {
				if (expression instanceof EqualityExpression) {
					// Handle enumeration literals as different ones can get the same integer value
					if (left instanceof EnumerationLiteralExpression &&
							right instanceof EnumerationLiteralExpression) {
						return leftEqualsRight;
					}
					return evaluate(left) == evaluate(right);
				}
				if (expression instanceof InequalityExpression) {
					if (left instanceof EnumerationLiteralExpression &&
							right instanceof EnumerationLiteralExpression) {
						return !leftEqualsRight;
					}
					return evaluate(left) != evaluate(right);
				}
			}
			if (expression instanceof LessExpression) {
				// Potential optimization trick
				if (leftEqualsRight) {
					return false;
				}
				//
				return evaluate(left) < evaluate(right);
			}
			if (expression instanceof LessEqualExpression) {
				// Potential optimization trick
				if (leftEqualsRight) {
					return true;
				}
				//
				return evaluate(left) <= evaluate(right);
			}
			if (expression instanceof GreaterExpression) {
				// Potential optimization trick
				if (leftEqualsRight) {
					return false;
				}
				//
				return evaluate(left) > evaluate(right);
			}
			if (expression instanceof GreaterEqualExpression) {
				// Potential optimization trick
				if (leftEqualsRight) {
					return true;
				}
				//
				return evaluate(left) >= evaluate(right);
			}
		}
		if (expression instanceof DirectReferenceExpression referenceExpression) {
			Declaration declaration = referenceExpression.getDeclaration();
			if (declaration instanceof ConstantDeclaration constantDeclaration) {
				return evaluateBoolean(constantDeclaration.getExpression());
			}
			if (declaration instanceof ParameterDeclaration parameterDeclaration) {
				Expression argument = evaluateParameter(parameterDeclaration);
				return evaluateBoolean(argument);
			}
			else {
				throw new IllegalArgumentException("Not transformable expression: " + expression);
			}
		}
		if (expression instanceof FunctionAccessExpression functionAccessExpression) {
			Expression inlinedLambaExpression = argumentInliner.createInlinedLambaExpression(functionAccessExpression);
			return evaluateBoolean(inlinedLambaExpression);
		}
		if (expression instanceof IfThenElseExpression ifThenElseExpression) {
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
	
	protected List<Expression> getNegativeExpressionPairs(List<Expression> expressions) {
		List<Expression> negativeExpressionPairs = new ArrayList<Expression>(); // a, -a, (b + 1), -(b + 1), ...
		
		for (int i = 0; i < expressions.size() - 1; i++) {
			Expression left = expressions.get(i);
			if (!negativeExpressionPairs.contains(left)) { // Left cannot be already "removed"
				boolean found = false;
				for (int j = i + 1; j < expressions.size() && !found; j++) {
					Expression right = expressions.get(j);
					if (!negativeExpressionPairs.contains(right)) { // Right cannot be already "removed"
						if (areNegativesOfEachOther(left, right)) {
							found = true;
							negativeExpressionPairs.add(left);
							negativeExpressionPairs.add(right);
						}
					}
				}
			}
		}
		
		return negativeExpressionPairs;
	}
	
	protected boolean areNegativesOfEachOther(Expression lhs, Expression rhs) {
		if (lhs instanceof UnaryMinusExpression negative) {
			Expression lhsNegativeOperand = negative.getOperand();
			return ecoreUtil.helperEquals(lhsNegativeOperand, rhs);
		}
		else if (rhs instanceof UnaryMinusExpression negative) {
			Expression rhsNegativeOperand = negative.getOperand();
			return ecoreUtil.helperEquals(lhs, rhsNegativeOperand);
		}
		
		return false;
	}
	
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
		return expressions.stream().filter(it -> 
				it.getLeftOperand() instanceof ReferenceExpression &&
					!(it.getRightOperand() instanceof ReferenceExpression))
			.collect(Collectors.toList());
	}
	
}
