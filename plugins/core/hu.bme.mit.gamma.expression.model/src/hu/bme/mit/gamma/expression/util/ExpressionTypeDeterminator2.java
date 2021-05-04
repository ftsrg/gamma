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
package hu.bme.mit.gamma.expression.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.AddExpression;
import hu.bme.mit.gamma.expression.model.ArithmeticExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.BooleanExpression;
import hu.bme.mit.gamma.expression.model.BooleanLiteralExpression;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.DivExpression;
import hu.bme.mit.gamma.expression.model.DivideExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerRangeTypeDefinition;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.ModExpression;
import hu.bme.mit.gamma.expression.model.MultiaryExpression;
import hu.bme.mit.gamma.expression.model.MultiplyExpression;
import hu.bme.mit.gamma.expression.model.OpaqueExpression;
import hu.bme.mit.gamma.expression.model.PredicateExpression;
import hu.bme.mit.gamma.expression.model.QuantifierExpression;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.SelectExpression;
import hu.bme.mit.gamma.expression.model.SubtractExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.UnaryExpression;
import hu.bme.mit.gamma.expression.model.UnaryMinusExpression;
import hu.bme.mit.gamma.expression.model.UnaryPlusExpression;
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExpressionTypeDeterminator2 {
	public static final ExpressionTypeDeterminator2 INSTANCE = new ExpressionTypeDeterminator2();
	protected ExpressionTypeDeterminator2() {}
	
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	protected final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	
	public Type getType(Expression expression) {
		if (expression instanceof BooleanLiteralExpression || expression instanceof BooleanExpression) {
			return factory.createBooleanTypeDefinition();
		}
		if (expression instanceof IntegerLiteralExpression) {
			return factory.createIntegerTypeDefinition();
		}
		if (expression instanceof RationalLiteralExpression) {
			return factory.createRationalTypeDefinition();
		}
		if (expression instanceof DecimalLiteralExpression) {
			return factory.createDecimalTypeDefinition();
		}
		if (expression instanceof EnumerationLiteralExpression) {
			TypeReference typeReference = factory.createTypeReference();
			typeReference.setReference(ExpressionModelDerivedFeatures.getTypeDeclaration(((EnumerationLiteralExpression) expression).getReference()));
			return typeReference;
		}
		if (expression instanceof IntegerRangeLiteralExpression) {
			return factory.createIntegerRangeTypeDefinition();
		}
		if (expression instanceof RecordLiteralExpression) {
			TypeReference typeReference = factory.createTypeReference();
			typeReference.setReference(((RecordLiteralExpression) expression).getTypeDeclaration());
			return typeReference;
		}
		if (expression instanceof ArrayLiteralExpression) {
			List<Expression> operands = ((ArrayLiteralExpression) expression).getOperands();
			if (operands.isEmpty()) {
				throw new IllegalArgumentException();
			}
			Expression firstOperand = operands.get(0);
			ArrayTypeDefinition arrayTypeDefinition = factory.createArrayTypeDefinition();
			arrayTypeDefinition.setElementType(getTypeDefinition(firstOperand));
			return arrayTypeDefinition;
		}
		if (expression instanceof DirectReferenceExpression) {
			DirectReferenceExpression referenceExpression = (DirectReferenceExpression) expression;
			Declaration declaration = referenceExpression.getDeclaration();
			Type type = declaration.getType();
			return removeTypeReferences(type);
		}
		if (expression instanceof ElseExpression) {
			return factory.createBooleanTypeDefinition();
		}
		if (expression instanceof PredicateExpression) {
			return factory.createBooleanTypeDefinition();
		}
		if (expression instanceof QuantifierExpression) {
			return factory.createBooleanTypeDefinition();
		}
		if (expression instanceof IfThenElseExpression) {
			return getType(((IfThenElseExpression) expression).getThen());
		}
		if (expression instanceof OpaqueExpression) {
			return factory.createVoidTypeDefinition();
		}
		if (expression instanceof UnaryPlusExpression) {
			return getArithmeticUnaryType((UnaryPlusExpression) expression);
		}
		if (expression instanceof UnaryMinusExpression) {
			return getArithmeticUnaryType((UnaryMinusExpression) expression);
		}
		if (expression instanceof SubtractExpression) {
			return getArithmeticBinaryType((SubtractExpression) expression);
		}
		if (expression instanceof DivideExpression) {
			return getArithmeticBinaryType((DivideExpression) expression);
		}
		if (expression instanceof ModExpression) {
			return getArithmeticBinaryIntegerType((ModExpression) expression);
		}
		if (expression instanceof DivExpression) {
			return getArithmeticBinaryIntegerType((DivExpression) expression);
		}
		if (expression instanceof AddExpression) {
			return getArithmeticMultiaryType((AddExpression) expression);
		}
		if (expression instanceof MultiplyExpression) {
			return getArithmeticMultiaryType((MultiplyExpression) expression);
		}
		if (expression instanceof ArrayAccessExpression) {
			Expression tmpExpression = ((ArrayAccessExpression) expression).getOperand();
			Type declarationType = expressionUtil.getDeclaration(tmpExpression).getType();
			if (declarationType instanceof ArrayTypeDefinition) {
				return ((ArrayTypeDefinition) declarationType).getElementType();
			}
		}
		if (expression instanceof FunctionAccessExpression) {
			Type declarationType = expressionUtil.getDeclaration(expression).getType();
			return ExpressionModelDerivedFeatures.getTypeDefinition(declarationType);
		}
		if (expression instanceof RecordAccessExpression) {
			RecordAccessExpression recordAccessExpression = (RecordAccessExpression) expression;
			return getType(recordAccessExpression.getFieldReference());
		}
		if (expression instanceof SelectExpression) {
			Expression tmpExpression = ((SelectExpression) expression).getOperand();
			Type declarationType = expressionUtil.getDeclaration(tmpExpression).getType();
			TypeDefinition typeDefinition = removeTypeReferences(declarationType);
			if (typeDefinition instanceof ArrayTypeDefinition) {
				ArrayTypeDefinition arrayTypeDefinition = (ArrayTypeDefinition) typeDefinition;
				return removeTypeReferences(arrayTypeDefinition.getElementType());
			}
			else if (typeDefinition instanceof IntegerRangeTypeDefinition) {
				return factory.createIntegerTypeDefinition();
			}
			else if (typeDefinition instanceof EnumerationTypeDefinition) {
				return typeDefinition;
			}
			else {
				throw new IllegalArgumentException("The type of the operand of the select expression is not an enumerable type: " + expressionUtil.getDeclaration(expression));
			}
		}
		throw new IllegalArgumentException("Unknown type!");
	}
	
	// Equals, TypeReference
	
	public TypeDefinition removeTypeReferences(Type type) {
		Type clone = ecoreUtil.clone(type);
		for (TypeReference reference : ecoreUtil.getAllContentsOfType(clone, TypeReference.class)) {
			TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(reference);
			ecoreUtil.replace(reference, typeDefinition);
		}
		return ExpressionModelDerivedFeatures.getTypeDefinition(clone);
	}
	
	public TypeDefinition getTypeDefinition(Expression expression) {
	    return removeTypeReferences(getType(expression));
	}
	
	public boolean equals (Expression expressionOne, Expression expressionTwo) {
		Type typeOne = getType(expressionOne);
		Type typeTwo = getType(expressionTwo);
		return equals(typeOne, typeTwo);
	}
	
	public boolean equals(Type typeOne, Expression expression) {
		Type typeTwo = getType(expression);
		return equals(typeOne, typeTwo);
	}
	
	public boolean equals(Type typeOne, Type typeTwo) {
		if (typeOne instanceof TypeReference) {
			typeOne = removeTypeReferences(typeOne);
		}
		if (typeTwo instanceof TypeReference) {
			typeTwo = removeTypeReferences(typeTwo);
		}
		return typeOne instanceof BooleanTypeDefinition && typeTwo instanceof BooleanTypeDefinition ||
				typeOne instanceof IntegerTypeDefinition && typeTwo instanceof IntegerTypeDefinition ||
				typeOne instanceof RationalTypeDefinition && typeTwo instanceof RationalTypeDefinition ||
				typeOne instanceof DecimalTypeDefinition && typeTwo instanceof DecimalTypeDefinition ||
				typeOne instanceof EnumerationTypeDefinition && typeTwo instanceof EnumerationTypeDefinition ||
				typeOne instanceof ArrayTypeDefinition && typeTwo instanceof ArrayTypeDefinition ||
				typeOne instanceof IntegerRangeTypeDefinition && typeTwo instanceof IntegerRangeTypeDefinition ||
				typeOne instanceof RecordTypeDefinition && typeTwo instanceof RecordTypeDefinition ||
				typeOne instanceof VoidTypeDefinition && typeTwo instanceof VoidTypeDefinition;
	}
	
	
	// Extension methods
	
	// Arithmetics
	
	private Type getArithmeticType(Collection<Type> collection) {
		// Wrong types, not suitable for arithmetic operations
		if (collection.stream().anyMatch(it -> !isNumber(it))) {
			throw new IllegalArgumentException("Type is not suitable for arithmetic operations: " + collection);
		}
		// All types are numbers
		if (collection.stream().anyMatch(it -> it instanceof DecimalTypeDefinition)) {
			return factory.createDecimalTypeDefinition();
		}
		if (collection.stream().anyMatch(it -> it instanceof RationalLiteralExpression)) {
			return factory.createRationalTypeDefinition();
		}
		return factory.createIntegerTypeDefinition();
	}
	
	// Unary
	
	/**
	 * Unary plus and minus.
	 */
	private <T extends ArithmeticExpression & UnaryExpression> Type getArithmeticUnaryType(T expression) {
		Type type = getType(expression.getOperand());
		if (isNumber(type)) {
			return type;
		}
		throw new IllegalArgumentException("Type is not suitable type for expression: " + type + System.lineSeparator() + expression);
	}
	
	// Binary
	
	/**
	 * Subtract and divide.
	 */
	private <T extends ArithmeticExpression & BinaryExpression> Type getArithmeticBinaryType(T expression) {
		List<Type> types = new ArrayList<Type>();
		types.add(getType(expression.getLeftOperand()));
		types.add(getType(expression.getRightOperand()));		
		return getArithmeticType(types);
	}
	
	/**
	 * Modulo and div.
	 */
	private <T extends ArithmeticExpression & BinaryExpression> Type getArithmeticBinaryIntegerType(T expression) {
		Type type = getArithmeticBinaryType(expression);
		if (type instanceof IntegerTypeDefinition) {
			return type;
		}
		throw new IllegalArgumentException("Type is not suitable type for expression: " + type + System.lineSeparator() + expression);
	}
	
	// Multiary
	
	/**
	 * Add and multiply.
	 */
	private <T extends ArithmeticExpression & MultiaryExpression> Type getArithmeticMultiaryType(T expression) {
		Collection<Type> types = expression.getOperands().stream().map(it -> getType(it)).collect(Collectors.toSet());
		return getArithmeticType(types);
	}
	
	// Type is number.
	
	private boolean isNumber(Type type) {
		return type instanceof DecimalTypeDefinition ||
				type instanceof IntegerTypeDefinition ||
				type instanceof RationalTypeDefinition;
	}
	
	
	public boolean isNumber(Expression expression) {
		return isNumber(getType(expression));
	}
	
	// Type is boolean.
	
	public boolean isBoolean(Expression expression) {
		if (getType(expression) instanceof BooleanTypeDefinition) {
			return true;
		}
		else {
			return false;
		}
	}

	// Type is integer.
	
	public boolean isInteger(Expression expression) {
		if (getType(expression) instanceof IntegerTypeDefinition) {
			return true;
		}
		else {
			return false;
		}
	}
	
	// Enumerations
	
	public EnumerationTypeDefinition getEnumerationType(Type type) {
		EnumerationTypeDefinition enumType = null;
		if (type instanceof EnumerationTypeDefinition) {
			enumType = (EnumerationTypeDefinition) type;
		}
		else if (type instanceof TypeReference){
			final TypeReference typeReference = (TypeReference) type;
			final Type referencedType = typeReference.getReference().getType();
			if (referencedType instanceof EnumerationTypeDefinition) {
				enumType = (EnumerationTypeDefinition) referencedType;
			}
		}
		return enumType;
	}
	
	public EnumerationTypeDefinition getEnumerationType(Expression expression) {
		Type type = getType(expression);
		return getEnumerationType(type);
	}
}
