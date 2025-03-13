/********************************************************************************
 * Copyright (c) 2022-2024 Contributors to the Gamma project
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
import java.util.List;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.LiteralExpression;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class LiteralExpressionCreator {
	// Singleton
	public static final LiteralExpressionCreator INSTANCE = new LiteralExpressionCreator();
	protected LiteralExpressionCreator() {}
	//
	
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	
	public LiteralExpression of(Declaration declaration, int value) {
		Type type = declaration.getType();
		return of(type, value);
	}
	
	public LiteralExpression of(Type type, int value) {
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(type);
		
		if (typeDefinition instanceof BooleanTypeDefinition booleanType) {
			return of(booleanType, value);
		}
		if (typeDefinition instanceof IntegerTypeDefinition integerType) {
			return of(integerType, value);
		}
		if (typeDefinition instanceof RationalTypeDefinition rationalType) {
			return of(rationalType, value);
		}
		if (typeDefinition instanceof DecimalTypeDefinition decimalType) {
			return of(decimalType, value);
		}
		if (typeDefinition instanceof EnumerationTypeDefinition enumerationType) {
			return of(enumerationType, value);
		}
		
		throw new IllegalArgumentException("Not known type: " + typeDefinition);
	}
	
	public LiteralExpression of(Declaration declaration, double value) {
		Type type = declaration.getType();
		return of(type, value);
	}
	
	public LiteralExpression of(Type type, double value) {
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(type);
		
		if (typeDefinition instanceof BooleanTypeDefinition booleanType) {
			return of(booleanType, (int) value);
		}
		if (typeDefinition instanceof IntegerTypeDefinition integerType) {
			return of(integerType, (int) value);
		}
		if (typeDefinition instanceof RationalTypeDefinition rationalType) {
			return of(rationalType, value);
		}
		if (typeDefinition instanceof DecimalTypeDefinition decimalType) {
			return of(decimalType, value);
		}
		if (typeDefinition instanceof EnumerationTypeDefinition enumerationType) {
			return of(enumerationType, (int) value);
		}
		
		throw new IllegalArgumentException("Not known type: " + typeDefinition);
	}
	
	public LiteralExpression of(BooleanTypeDefinition type, int value) {
		switch (value) {
			case 0:
				return factory.createFalseExpression();
			default:
				return factory.createTrueExpression();
		} 
	}
	
	public LiteralExpression of(IntegerTypeDefinition type, int value) {
		IntegerLiteralExpression integerLiteralExpression = factory.createIntegerLiteralExpression();
		integerLiteralExpression.setValue(
				BigInteger.valueOf(value));
		return integerLiteralExpression;
	}
	
	public LiteralExpression of(RationalTypeDefinition type, int value) {
		RationalLiteralExpression literalExpression = factory.createRationalLiteralExpression();
		literalExpression.setNumerator(BigInteger.valueOf(value));
		literalExpression.setDenominator(BigInteger.ONE);
		return literalExpression;
	}
	
	public LiteralExpression of(DecimalTypeDefinition type, int value) {
		DecimalLiteralExpression literalExpression = factory.createDecimalLiteralExpression();
		literalExpression.setValue(BigDecimal.valueOf(value));
		return literalExpression;
	}
	
	public LiteralExpression of(EnumerationTypeDefinition type, int value) {
		List<EnumerationLiteralDefinition> literals = type.getLiterals();
		EnumerationLiteralDefinition literal = literals.get(value);
		TypeDeclaration typeDeclaration = ecoreUtil.getContainerOfType(literal, TypeDeclaration.class);
		
		EnumerationLiteralExpression literalExpression = factory.createEnumerationLiteralExpression();
		TypeReference typeReference = factory.createTypeReference();
		typeReference.setReference(typeDeclaration);
		
		literalExpression.setTypeReference(typeReference);
		literalExpression.setReference(literal);
		
		return literalExpression;
	}
	
	public LiteralExpression of(RationalTypeDefinition type, double value) {
		DecimalLiteralExpression literalExpression = factory.createDecimalLiteralExpression();
		literalExpression.setValue(BigDecimal.valueOf(value));
		return literalExpression;
	}
	
	public LiteralExpression of(DecimalTypeDefinition type, double value) {
		DecimalLiteralExpression literalExpression = factory.createDecimalLiteralExpression();
		literalExpression.setValue(BigDecimal.valueOf(value));
		return literalExpression;
	}
	
}
