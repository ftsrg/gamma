/********************************************************************************
 * Copyright (c) 2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.promela.transformation.util

import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.util.PredicateHandler
import java.math.BigInteger
import java.util.List

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class HavocHandler {
	// Singleton
	public static final HavocHandler INSTANCE = new HavocHandler
	protected new() {}
	
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension PredicateHandler predicateHandler = PredicateHandler.INSTANCE
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionModelFactory = ActionModelFactory.eINSTANCE
	
	// Entry point
	
	def createSet(VariableDeclaration variable) {
		val type = variable.type
		return type.createSet(variable)
	}
	
	//
	
	def dispatch List<Expression> createSet(TypeReference type, VariableDeclaration variable) {
		val typeDefinition = type.typeDefinition
		return typeDefinition.createSet(variable)
	}
	
	def dispatch List<Expression> createSet(BooleanTypeDefinition type, VariableDeclaration variable) {
		val list = <Expression>newArrayList
		
		list += expressionFactory.createFalseExpression
		list += expressionFactory.createTrueExpression
		
		return list
	}
	
	def dispatch List<Expression> createSet(EnumerationTypeDefinition type, VariableDeclaration variable) {
		val list = <Expression>newArrayList
		
		for (literal : type.literals) {
			val enumLiteralExpression = expressionFactory.createEnumerationLiteralExpression
			enumLiteralExpression.reference = literal
			list += enumLiteralExpression
		}
		
		return list
	}
	
	def dispatch List<Expression> createSet(IntegerTypeDefinition type, VariableDeclaration variable) {
		val list = <Expression>newArrayList
		
		val root = variable.root
		
		val integerValues = root.calculateIntegerValues(variable)
		
		// In theory, an else value is not needed as all 'interesting' positive and negative values are already present
		// from 1-hop distance - thus, it would be more robust to include an elseValue, but it poses too much burden
//		val elseValue = integerValues.contains(defaultValue) ? integerValues.max + 1 : defaultValue
		if (integerValues.empty) {
			val defaultValue = type.defaultExpression.evaluateInteger // 0
			integerValues += defaultValue // Adding another value for an "else" branch
		}
		
		for (integerValue : integerValues) {
			val integerLiteral = expressionFactory.createIntegerLiteralExpression
			integerLiteral.value = BigInteger.valueOf(integerValue.intValue)
			list += integerLiteral
		}
		return list
	}
}