/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
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
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
import hu.bme.mit.gamma.expression.model.FieldReferenceExpression;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.IfThenElseExpression;
import hu.bme.mit.gamma.expression.model.InfinityExpression;
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
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.UnaryExpression;
import hu.bme.mit.gamma.expression.model.UnaryMinusExpression;
import hu.bme.mit.gamma.expression.model.UnaryPlusExpression;
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExpressionTypeDeterminator2 {
	// Singleton
	public static final ExpressionTypeDeterminator2 INSTANCE = new ExpressionTypeDeterminator2();
	protected ExpressionTypeDeterminator2() {}
	//
	
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	//
	
	public Type getType(Expression expression) {
		if (expression instanceof BooleanExpression) { // BooleanLiteralExpression is a BooleanExpression
			return factory.createBooleanTypeDefinition();
		}
		if (expression instanceof InfinityExpression) {
			// Not the cleanest solution, but good for an initial iteration
			return factory.createIntegerTypeDefinition();
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
			EnumerationLiteralExpression enumerationLiteralExpression = (EnumerationLiteralExpression) expression;
			TypeReference typeReference = ecoreUtil.clone(enumerationLiteralExpression.getTypeReference());
			return typeReference;
		}
		if (expression instanceof IntegerRangeLiteralExpression) {
			return factory.createIntegerRangeTypeDefinition();
		}
		if (expression instanceof RecordLiteralExpression) {
			TypeReference typeReference = factory.createTypeReference();
			RecordLiteralExpression recordLiteralExpression = (RecordLiteralExpression) expression;
			typeReference.setReference(recordLiteralExpression.getTypeDeclaration());
			return typeReference;
		}
		if (expression instanceof ArrayLiteralExpression) {
			ArrayLiteralExpression arrayLiteralExpression = (ArrayLiteralExpression) expression;
			List<Expression> operands = arrayLiteralExpression.getOperands();
			if (operands.isEmpty()) {
				// Maybe this should be changed to VoidTypeDefinition, as empty array literals could be useful
				throw new IllegalArgumentException();
			}
			Expression firstOperand = operands.get(0);
			ArrayTypeDefinition arrayTypeDefinition = factory.createArrayTypeDefinition();
			arrayTypeDefinition.setElementType(getType(firstOperand));
			IntegerLiteralExpression size = factory.createIntegerLiteralExpression();
			size.setValue(BigInteger.valueOf(operands.size()));
			arrayTypeDefinition.setSize(size);
			return arrayTypeDefinition;
		}
		if (expression instanceof DirectReferenceExpression) {
			DirectReferenceExpression referenceExpression = (DirectReferenceExpression) expression;
			Declaration declaration = referenceExpression.getDeclaration();
			Type type = declaration.getType();
			return ecoreUtil.clone(type);
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
			IfThenElseExpression ifThenElseExpression = (IfThenElseExpression) expression;
			return getType(ifThenElseExpression.getThen());
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
			ArrayAccessExpression arrayAccessExpression = (ArrayAccessExpression) expression;
			Expression operand = arrayAccessExpression.getOperand();
			Type type = getTypeDefinition(operand);
			if (type instanceof ArrayTypeDefinition) {
				ArrayTypeDefinition arrayTypeDefinition = (ArrayTypeDefinition) type;
				Type elementType = arrayTypeDefinition.getElementType();
				return ecoreUtil.clone(elementType);
			}
			else {
				throw new IllegalArgumentException("Not known type: " + type);
			}
		}
		if (expression instanceof FunctionAccessExpression) {
			FunctionAccessExpression functionAccessExpression = (FunctionAccessExpression) expression;
			Expression operand = functionAccessExpression.getOperand();
			return getType(operand);
		}
		if (expression instanceof FieldReferenceExpression) {
			FieldReferenceExpression fieldReferenceExpression = (FieldReferenceExpression) expression;
			FieldDeclaration fieldDeclaration = fieldReferenceExpression.getFieldDeclaration();
			Type type = fieldDeclaration.getType();
			return ecoreUtil.clone(type);
		}
		if (expression instanceof RecordAccessExpression) {
			RecordAccessExpression recordAccessExpression = (RecordAccessExpression) expression;
			FieldReferenceExpression fieldReference = recordAccessExpression.getFieldReference();
			return getType(fieldReference);
		}
		if (expression instanceof SelectExpression) {
			SelectExpression selectExpression = (SelectExpression) expression;
			Expression operand = selectExpression.getOperand();
			Type operandType = getType(operand);
			TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(operandType);
			if (typeDefinition instanceof ArrayTypeDefinition) {
				ArrayTypeDefinition arrayTypeDefinition = (ArrayTypeDefinition) typeDefinition;
				Type elementType = arrayTypeDefinition.getElementType();
				return ecoreUtil.clone(elementType);
			}
			else if (typeDefinition instanceof IntegerRangeTypeDefinition) {
				return factory.createIntegerTypeDefinition();
			}
			else if (typeDefinition instanceof EnumerationTypeDefinition) {
				return operandType;
			}
			else {
				throw new IllegalArgumentException(
					"The type of the operand of the select expression is not an enumerable type: " + typeDefinition);
			}
		}
		// Some expressions are expected to return an empty value, for example:
		// return; - in a procedure declaration
		if (expression == null) {
			return factory.createVoidTypeDefinition();
		}
		throw new IllegalArgumentException("Unknown type: " + expression);
	}
	
	public TypeDefinition getTypeDefinition(Expression expression) {
		return ExpressionModelDerivedFeatures.getTypeDefinition(
				getType(expression));
	}
	
	// TypeReference handling auxiliary methods
	
	private Type getAliaslessTypeTree(Type type) {
		if (type instanceof TypeReference) {
			TypeDefinition typeDefinition = null;
			try {
				typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(type);
			} catch (IllegalArgumentException e) {
				return null; // // Might be the result of inconsistent Xtext type reference (reference is null)
			}
			// Valid type reference, we can move on
			if (ExpressionModelDerivedFeatures.isPrimitive(typeDefinition)) {
				return ecoreUtil.clone(typeDefinition); // We do no distinguish between aliases and primitive types
			}
			if (ExpressionModelDerivedFeatures.isArray(typeDefinition)) {
				return getAliaslessTypeTree(typeDefinition); // We do no distinguish between aliases and arrays
			}
			// Enum or record
			TypeReference finalTypeReference = ExpressionModelDerivedFeatures.getFinalTypeReference(
					(TypeReference) type);
			TypeReference clonedFinalTypeReference = ecoreUtil.clone(finalTypeReference);
			TypeDeclaration typeDeclaration = finalTypeReference.getReference();
			// Optimization possibility
			Type declaredTypeDefinition = typeDeclaration.getType();
			if (declaredTypeDefinition instanceof EnumerationTypeDefinition) {
				return clonedFinalTypeReference; // Optimization: enums do not have to be cloned
			}
			// Record
			TypeDeclaration clonedTypeDeclaration = ecoreUtil.clone(typeDeclaration);
			clonedFinalTypeReference.setReference(clonedTypeDeclaration);
			Type clonedType = clonedTypeDeclaration.getType();
			clonedTypeDeclaration.setType(getAliaslessTypeTree(clonedType));
			return clonedFinalTypeReference;
		}
		Type clonedType = ecoreUtil.clone(type); // type instanceof TypeDefinition
		List<TypeReference> typeReferences = ecoreUtil.getAllContentsOfType(clonedType, TypeReference.class);
		for (TypeReference reference : typeReferences) {
			// The method must return a cloned type along every path!
			Type clonedFinalTypeReference = getAliaslessTypeTree(reference);
			ecoreUtil.replace(clonedFinalTypeReference, reference);
		}
		return clonedType;
	}
	
	// Equals
	
	public boolean equalsType(Expression expressionOne, Expression expressionTwo) {
		Type typeOne = getType(expressionOne);
		Type typeTwo = getType(expressionTwo);
		return equals(typeOne, typeTwo);
	}
	
	public boolean equalsType(Type typeOne, Expression expression) {
		Type typeTwo = getType(expression);
		return equals(typeOne, typeTwo);
	}
	
	public boolean equals(Type typeOne, Type typeTwo) {
		Type typeOneRemovedReferences = getAliaslessTypeTree(typeOne);
		Type typeTwoRemovedReferences = getAliaslessTypeTree(typeTwo);
		return ecoreUtil.helperEquals(typeOneRemovedReferences, typeTwoRemovedReferences);
	}
	
	// Extension methods
	
	// Arithmetics
	
	private Type getArithmeticType(Collection<Type> collection) {
		// Wrong types, not suitable for arithmetic operations
		if (collection.stream().anyMatch(it -> !isNumber(it))) {
			throw new IllegalArgumentException("Type is not suitable for arithmetic operations: " + collection);
		}
		// All types are numbers
		if (collection.stream().anyMatch(it ->
				ExpressionModelDerivedFeatures.getTypeDefinition(it) instanceof DecimalTypeDefinition)) {
			return factory.createDecimalTypeDefinition();
		}
		if (collection.stream().anyMatch(it ->
				ExpressionModelDerivedFeatures.getTypeDefinition(it) instanceof RationalLiteralExpression)) {
			return factory.createRationalTypeDefinition();
		}
		return factory.createIntegerTypeDefinition();
	}
	
	// Unary
	
	// Unary plus and minus
	
	private <T extends ArithmeticExpression & UnaryExpression> Type getArithmeticUnaryType(T expression) {
		Type type = getType(expression.getOperand());
		if (isNumber(type)) {
			return type;
		}
		throw new IllegalArgumentException("Type is not suitable type for expression: " +
				print(type) + " expression: " + expression);
	}
	
	// Binary
	
	// Subtract and divide
	
	private <T extends ArithmeticExpression & BinaryExpression> Type getArithmeticBinaryType(T expression) {
		List<Type> types = new ArrayList<Type>();
		types.add(getType(expression.getLeftOperand()));
		types.add(getType(expression.getRightOperand()));		
		return getArithmeticType(types);
	}
	
	// Modulo and div
	
	private <T extends ArithmeticExpression & BinaryExpression> Type getArithmeticBinaryIntegerType(T expression) {
		Type type = getArithmeticBinaryType(expression);
		if (type instanceof IntegerTypeDefinition) {
			return type;
		}
		throw new IllegalArgumentException("Type is not a suitable type for expression: " +
				print(type) + " expression: " + expression);
	}
	
	// Multiary
	
	// Add and multiply
	
	private <T extends ArithmeticExpression & MultiaryExpression> Type getArithmeticMultiaryType(T expression) {
		Collection<Type> types = expression.getOperands().stream()
				.map(it -> getType(it)).collect(Collectors.toSet());
		return getArithmeticType(types);
	}
	
	// Type is number
	
	private boolean isNumber(Type type) {
		try {
			TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(type);
			return typeDefinition instanceof DecimalTypeDefinition ||
				typeDefinition instanceof IntegerTypeDefinition ||
				typeDefinition instanceof RationalTypeDefinition;
		} catch (IllegalArgumentException e) {
			return false; // Might be the result of inconsistent Xtext type reference (reference is null)
		}
	}
	
	public boolean isNumber(Expression expression) {
		try {
			return expression != null && isNumber(getType(expression));
		} catch (IllegalArgumentException e) {
			return false; // e.g., if getType(expression) throws an exception
		}
	}
	
	// Type is boolean
	
	public boolean isBoolean(Expression expression) {
		try {
			return expression != null && getTypeDefinition(expression) instanceof BooleanTypeDefinition;
		} catch (IllegalArgumentException e) {
			return false; // e.g., if getTypeDefinition(expression) throws an exception
		}
	}
	
	// Type is integer
	
	public boolean isInteger(Expression expression) {
		try {
			return expression != null && getTypeDefinition(expression) instanceof IntegerTypeDefinition;
		} catch (IllegalArgumentException e) {
			return false; // e.g., if getTypeDefinition(expression) throws an exception
		}
	}
	
	public boolean isInteger(Type type) {
		try {
			return type != null &&
				ExpressionModelDerivedFeatures.getTypeDefinition(type) instanceof IntegerTypeDefinition;
		} catch (IllegalArgumentException e) {
			return false; // e.g., if getType(expression) throws an exception
		}
	}
	
	// Type pretty printer
	
	public String print(Expression expression) {
		Type type = getType(expression);
		return print(type);
	}
	
	public String print(Type type) {
		if (type instanceof IntegerTypeDefinition) {
			return "Integer";
		}
		if (type instanceof IntegerRangeTypeDefinition) {
			return "Integer range";
		}
		if (type instanceof DecimalTypeDefinition) {
			return "Decimal";
		}
		if (type instanceof BooleanTypeDefinition) {
			return "Boolean";
		}
		if (type instanceof RationalTypeDefinition) {
			return "Rational";
		}
		if (type instanceof ArrayTypeDefinition) {
			ArrayTypeDefinition arrayType = (ArrayTypeDefinition) type;
			Type elementType = arrayType.getElementType();
			return "Array, type of elements: " + print(elementType);
		}
		if (type instanceof RecordTypeDefinition) {
			RecordTypeDefinition recordTypeDefinition = (RecordTypeDefinition) type;
			List<FieldDeclaration> fields = recordTypeDefinition.getFieldDeclarations();
			String fieldsNames = fields.stream()
					.map(it -> it.getName())
					.reduce((lhs, rhs) -> lhs + ", " + rhs).orElse("");
			return "Record, with fields: " + fieldsNames;
		}
		if (type instanceof EnumerationTypeDefinition) {
			EnumerationTypeDefinition enumerationTypeDefinition = (EnumerationTypeDefinition) type;
			String literalNames = enumerationTypeDefinition.getLiterals().stream()
					.map(it -> it.getName())
					.reduce((lhs, rhs) -> lhs + ", " + rhs).orElse("");
			return "Enumeration, with literals: " + literalNames;
		}
		if (type instanceof VoidTypeDefinition) {
			return "Void";
		}
		if (type instanceof TypeReference) {
			TypeReference typeReference = (TypeReference) type;
			TypeDeclaration reference = typeReference.getReference();
			Type referenceType = reference.getType();
			return reference.getName() + ": " + print(referenceType);
		}
		return "Unknown type: " + type; // During parsing, there can be null typeDefinitions
	}
		
}