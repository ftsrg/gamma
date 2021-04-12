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
import java.util.Optional;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.AccessExpression;
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
import hu.bme.mit.gamma.expression.model.FieldDeclaration;
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
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.PredicateExpression;
import hu.bme.mit.gamma.expression.model.QuantifierExpression;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.RecordAccessExpression;
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression;
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
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

public class ExpressionTypeDeterminator2 {
	// Singleton
	public static final ExpressionTypeDeterminator2 INSTANCE = new ExpressionTypeDeterminator2();
	protected ExpressionTypeDeterminator2() {}
	
	protected final ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	protected final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;	
	
	public Type getType(Expression expression) {
		if (expression instanceof BooleanLiteralExpression) {
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
			return factory.createEnumerationTypeDefinition();
		}
		if (expression instanceof IntegerRangeLiteralExpression) {
			return factory.createIntegerRangeTypeDefinition();
		}
		if (expression instanceof RecordLiteralExpression) {
			return factory.createRecordTypeDefinition();
		}
		if (expression instanceof ArrayLiteralExpression) {
			return factory.createArrayTypeDefinition();
		}
		if (expression instanceof DirectReferenceExpression) {
			Type declarationType = ((DirectReferenceExpression) expression).getDeclaration().getType(); 
			return expressionUtil.findTypeDefinitionOfType(declarationType);
		}
		if (expression instanceof ElseExpression) {
			return factory.createBooleanTypeDefinition();
		}
		if (expression instanceof BooleanExpression) {
			Type declarationType = expressionUtil.getDeclaration(expression).getType();
			return expressionUtil.findTypeDefinitionOfType(declarationType);
		}
		if (expression instanceof PredicateExpression) {
			return factory.createBooleanTypeDefinition();
		}
		if (expression instanceof QuantifierExpression) {
			return factory.createBooleanTypeDefinition();
		}
		if (expression instanceof IfThenElseExpression) {
			return factory.createBooleanTypeDefinition();
		}
		if (expression instanceof OpaqueExpression) {
			// ?
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
			int depth = 0;
			List<FieldDeclaration> fields = new ArrayList<FieldDeclaration>();
			ReferenceExpression ref = (ArrayAccessExpression) expression;
			TypeDefinition type;
			while (true) {
				if (ref instanceof ArrayAccessExpression) {
					depth++;
					ref = (ReferenceExpression)((ArrayAccessExpression)ref).getOperand();
				} else if (ref instanceof RecordAccessExpression) {
					RecordAccessExpression recordAccessExpression = (RecordAccessExpression) ref;
					fields.add(0, recordAccessExpression.getFieldReference().getFieldDeclaration());
					ref = (ReferenceExpression) recordAccessExpression.getOperand();
				} else if (ref instanceof DirectReferenceExpression) {
					type = expressionUtil.findTypeDefinitionOfType(((DirectReferenceExpression)ref).getDeclaration().getType());
					break;
				} else {
					throw new IllegalArgumentException("Array access expression contains forbidden elements: " + ref.getClass());
				}
			}
			while (depth >= 0 || !fields.isEmpty()) {
				if (type instanceof ArrayTypeDefinition) {
					type = expressionUtil.findTypeDefinitionOfType(((ArrayTypeDefinition)type).getElementType());
					depth--;
				} else if (type instanceof RecordTypeDefinition) {
					type = expressionUtil.findTypeDefinitionOfType(((RecordTypeDefinition)type).getFieldDeclarations().stream().filter(e -> e.equals(fields.remove(0))).findFirst().get().getType());
				} else {
					throw new IllegalArgumentException("Type contains forbidden elements: " + type.getClass());
				}
			}
			return expressionUtil.findTypeDefinitionOfType(type);
		}
		if (expression instanceof FunctionAccessExpression) {
			Type declarationType = expressionUtil.getDeclaration(expression).getType();
			return expressionUtil.findTypeDefinitionOfType(declarationType);
		}
		if (expression instanceof RecordAccessExpression) {
			RecordAccessExpression recordAccessExpression = (RecordAccessExpression) expression;
			return getType(recordAccessExpression.getFieldReference());
		}
		if (expression instanceof SelectExpression) {
			SelectExpression selectExpression = (SelectExpression) expression;
			Declaration declaration = expressionUtil.getAccessedDeclaration(selectExpression);
			TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(declaration);
			if (typeDefinition instanceof ArrayTypeDefinition) {
				ArrayTypeDefinition arrayTypeDefinition = (ArrayTypeDefinition) typeDefinition;
				return arrayTypeDefinition.getElementType();
			}
			else if (typeDefinition instanceof IntegerRangeTypeDefinition) {
				return typeDefinition;
			}
			else if (typeDefinition instanceof EnumerationTypeDefinition) {
				return typeDefinition;
			}
			else {
				throw new IllegalArgumentException("The type of the operand  of the select expression is not an enumerable type: " + expressionUtil.getDeclaration(selectExpression));
			}
		}
		if (expression == null) {
			return factory.createVoidTypeDefinition();
		}
		// EventParameterReferences: they are contained in StatechartModelPackage (they cannot be imported)
		Optional<EObject> parameter = getParameter(expression);
		if (parameter.isPresent()) {
			ParameterDeclaration parameterDeclaration = (ParameterDeclaration) parameter.get();
			Type declarationType = parameterDeclaration.getType();
			return expressionUtil.findTypeDefinitionOfType(declarationType);
		}
		throw new IllegalArgumentException("Unknown type!");
	}
	
	protected Optional<EObject> getParameter(Expression expression) {
		return expression.eCrossReferences().stream().filter(it -> it instanceof ParameterDeclaration).findFirst();
	}
	
	// Extension methods
	
	// Arithmetics
	
	private Type getArithmeticType(Collection<Type> collection) {
		// Wrong types, not suitable for arithmetic operations
		if (collection.stream().anyMatch(it -> !isNumber(it))) {
			throw new IllegalArgumentException("Type is not suitable for arithmetic operations: " + collection);
		}
		// All types are numbers
		if (collection.stream().anyMatch(it -> it instanceof DecimalLiteralExpression)) {
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
	
	/*
	// Easy determination of boolean and number types
	
	public boolean isBoolean(Expression	expression) {
		if (expression instanceof DirectReferenceExpression) {
			DirectReferenceExpression referenceExpression = (DirectReferenceExpression) expression;
			Declaration declaration = referenceExpression.getDeclaration();
			Type declarationType = declaration.getType();
			return transform(declarationType) == ExpressionType.BOOLEAN;
		} else if (expression instanceof AccessExpression) {
			Declaration declaration = expressionUtil.getDeclaration(expression);
			Type declarationType = declaration.getType();
			return transform(declarationType) == ExpressionType.BOOLEAN;
		}
		return expression instanceof BooleanExpression || expression instanceof PredicateExpression ||
			expression instanceof ElseExpression;
	}
	
	private boolean isInteger(ExpressionType type) {
		return type == ExpressionType.INTEGER;
	}
	
	public boolean isInteger(Expression expression) {
		return isInteger(getType(expression));
	}
	*/
	
	private boolean isNumber(Type type) {
		return type instanceof DecimalTypeDefinition ||
				type instanceof IntegerTypeDefinition ||
				type instanceof RationalTypeDefinition;
	}
	
	
	public boolean isNumber(Expression expression) {
		if (expression instanceof DirectReferenceExpression) {
			DirectReferenceExpression referenceExpression = (DirectReferenceExpression) expression;
			Declaration declaration = referenceExpression.getDeclaration();
			Type declarationType = declaration.getType();
			return isNumber(declarationType);
		} else {
			return isNumber(getType(expression));
		}
	}
	
	// Type equal (in the case of complex types, only shallow comparison)
	
	public boolean equals(Type type, ExpressionType expressionType) {
		return type instanceof BooleanTypeDefinition && expressionType == ExpressionType.BOOLEAN ||
			type instanceof IntegerTypeDefinition && expressionType == ExpressionType.INTEGER ||
			type instanceof RationalTypeDefinition && expressionType == ExpressionType.RATIONAL ||
			type instanceof DecimalTypeDefinition && expressionType == ExpressionType.DECIMAL ||
			type instanceof EnumerationTypeDefinition && expressionType == ExpressionType.ENUMERATION ||
			type instanceof ArrayTypeDefinition  && expressionType == ExpressionType.ARRAY ||
			type instanceof IntegerRangeTypeDefinition && expressionType == ExpressionType.INTEGER_RANGE ||
			type instanceof RecordTypeDefinition && expressionType == ExpressionType.RECORD ||
			type instanceof VoidTypeDefinition && expressionType == ExpressionType.VOID ||
			type instanceof TypeReference && equals(((TypeReference) type).getReference().getType(), expressionType);
	}
	
	/*
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
		if (expression instanceof EnumerationLiteralExpression) {
			EnumerationLiteralExpression literal = (EnumerationLiteralExpression) expression;
			return (EnumerationTypeDefinition) literal.getReference().eContainer();
		}
		if (expression instanceof DirectReferenceExpression) {
			DirectReferenceExpression reference = (DirectReferenceExpression) expression;
			Type type = reference.getDeclaration().getType();
			return getEnumerationType(type);
		}
		Optional<EObject> parameter = getParameter(expression);
		if (parameter.isPresent()) {
			ParameterDeclaration parameterDeclaration = (ParameterDeclaration) parameter.get();
			Type type = parameterDeclaration.getType();
			return getEnumerationType(type);
		}
		throw new IllegalArgumentException("Not known expression: " + expression);
	}
	*/
}
