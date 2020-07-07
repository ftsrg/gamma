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
package hu.bme.mit.gamma.expression.derivedfeatures;

import java.math.BigDecimal;
import java.math.BigInteger;

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition;
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression;
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ParametricElement;
import hu.bme.mit.gamma.expression.model.RationalLiteralExpression;
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExpressionModelDerivedFeatures {
	
	protected static ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	protected static GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected static ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;

	public static boolean isPrimitive(Type type) {
		if (type instanceof BooleanTypeDefinition || type instanceof IntegerTypeDefinition ||
				type instanceof DecimalTypeDefinition || type instanceof RationalTypeDefinition) {
			return true;
		}
		return false;
	}
	
	public static TypeDefinition getTypeDefinition(Type type) {
		if (type instanceof TypeDefinition) {
			return (TypeDefinition) type;
		}
		if (type instanceof TypeReference) {
			TypeReference typeReference = (TypeReference) type;
			return (TypeDefinition) typeReference.getReference().getType();
		}
		throw new IllegalArgumentException("Not known type: " + type);
	}
	
	public static Expression getDefaultExpression(Type type) {
		TypeDefinition typeDefinition = getTypeDefinition(type);
		if (typeDefinition instanceof BooleanTypeDefinition) {
			return factory.createFalseExpression();
		}
		if (typeDefinition instanceof IntegerTypeDefinition) {
			IntegerLiteralExpression literal = factory.createIntegerLiteralExpression();
			literal.setValue(BigInteger.ZERO);
			return literal;
		}
		if (typeDefinition instanceof DecimalTypeDefinition) {
			DecimalLiteralExpression literal = factory.createDecimalLiteralExpression();
			literal.setValue(BigDecimal.ZERO);
			return literal;
		}
		if (typeDefinition instanceof RationalTypeDefinition) {
			RationalLiteralExpression literal = factory.createRationalLiteralExpression();
			literal.setNumerator(BigInteger.ZERO);
			literal.setDenominator(BigInteger.ONE);
			return literal;
		}
		if (typeDefinition instanceof EnumerationTypeDefinition) {
			EnumerationTypeDefinition enumType = (EnumerationTypeDefinition) typeDefinition;
			EnumerationLiteralExpression literal = factory.createEnumerationLiteralExpression();
			literal.setReference(enumType.getLiterals().get(0));
			return literal;
		}
		throw new IllegalArgumentException("Not known type: " + type);
	}
	
	public static int getIndex(ParameterDeclaration parameter) {
		ParametricElement container = (ParametricElement) parameter.eContainer();
		return container.getParameterDeclarations().indexOf(parameter);
	}
	
}
