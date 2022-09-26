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

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.PredicateHandler
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.ArrayList

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class HavocHandler {
	// Singleton
	public static final HavocHandler INSTANCE = new HavocHandler
	protected new() {}
	
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension PredicateHandler predicateHandler = PredicateHandler.INSTANCE
	
	def ArrayList<String> createSet(VariableDeclaration variable) {
		val type = variable.type
		return type.createSet(variable)
	}
	
	def dispatch ArrayList<String> createSet(TypeReference type, VariableDeclaration variable) {
		val typeDefinition = type.typeDefinition
		return typeDefinition.createSet(variable)
	}
	
	def dispatch createSet(BooleanTypeDefinition type, VariableDeclaration variable) {
		var list = newArrayList
		list.add("true")
		list.add("false")
		return list
	}
	
	def dispatch createSet(EnumerationTypeDefinition type, VariableDeclaration variable) {
		var list = newArrayList
		for (literal : type.literals) {
			list.add(type.typeDeclaration.name + literal.name)
		}
		return list
	}
	
	def dispatch createSet(IntegerTypeDefinition type, VariableDeclaration variable) {
		var list = newArrayList
		val root = variable.root
		
		val integerValues = root.calculateIntegerValues(variable)
		
		if (integerValues.empty) {
			// Sometimes input parameters are not referenced
			list.add("0")
			return list
		}
		
		for (i : integerValues)
			list.add(i.toString)
		
		return list
	}
}