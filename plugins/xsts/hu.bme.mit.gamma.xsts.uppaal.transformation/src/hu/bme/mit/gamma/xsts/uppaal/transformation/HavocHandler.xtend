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
package hu.bme.mit.gamma.xsts.uppaal.transformation

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.util.PredicateHandler
import java.util.logging.Logger
import org.eclipse.xtend.lib.annotations.Data
import uppaal.expressions.Expression
import uppaal.templates.Selection

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class HavocHandler {
	// Singleton
	public static final HavocHandler INSTANCE = new HavocHandler
	protected new() {
		val ntaName = Namings.name
		this.ntaBuilder = new NtaBuilder(ntaName) // Random NTA is created
	}
	//
	
	protected final NtaBuilder ntaBuilder
	
	protected final extension PredicateHandler predicateHandler = PredicateHandler.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	// Entry point
	
	def createSelection(VariableDeclaration variable) {
		val type = variable.type
		return type.createSelection(variable)
	}
	
	//
	
	def dispatch SelectionStruct createSelection(TypeReference type, VariableDeclaration variable) {
		val typeDefinition = type.typeDefinition
		return typeDefinition.createSelection(variable)
	}
	
	def dispatch SelectionStruct createSelection(BooleanTypeDefinition type, VariableDeclaration variable) {
		val name = Namings.name
		val selection = ntaBuilder.createBooleanSelection(name)
		
		return new SelectionStruct(selection, null)
	}
	
	def dispatch SelectionStruct createSelection(EnumerationTypeDefinition type, VariableDeclaration variable) {
		val literals = type.literals
		val upperLiteral = literals.size - 1
		
		val lowerBound = ntaBuilder.createLiteralExpression("0")
		val upperBound = ntaBuilder.createLiteralExpression(upperLiteral.toString)
		
		val name = Namings.name
		val selection = ntaBuilder.createIntegerSelection(name, lowerBound, upperBound)
		
		// Limiting the range to actually used literals + another one
		val referencableLiterals = literals.reject[it.unused] // Already contains "else" literal
		// See OptimizerAndVerificationHandler for unused marking
		
		if (referencableLiterals.size == literals.size) {
			// A  continuous range, no need for additional guards
			return new SelectionStruct(selection, null)
		}
		
		val indexes = referencableLiterals.map[it.index]
		val equalities = newArrayList // Filters the "interesting" values from the range
		for (integerValue : indexes) {
			equalities += ntaBuilder.createEqualityExpression(
				selection, ntaBuilder.createLiteralExpression(integerValue.toString))
		}
		
		val guard = ntaBuilder.wrapIntoOrExpression(equalities)
		
		return new SelectionStruct(selection, guard)
	}
	
	def dispatch SelectionStruct createSelection(IntegerTypeDefinition type, VariableDeclaration variable) {
		return variable.createSelectionOfIntegerValues
	}
	
	protected def SelectionStruct createSelectionOfIntegerValues(VariableDeclaration variable) {
		val root = variable.root
		
		logger.info("Calculating integer values for: " + variable.name)
		val integerValues = root.calculateIntegerValues(variable) // These are assumed values
		// Both "valid" and "invalid" integer values are returned for predicates
		logger.info("Finished calculating integer values for: " + variable.name)
		
		if (integerValues.empty) {
			// Sometimes input parameters are not referenced
			return new SelectionStruct(null, null)
		}
		
		val defaultValue = 0 // 0 for integers and enums alike
		val elseValue = integerValues.contains(defaultValue) ? integerValues.max + 1 : defaultValue
		integerValues += elseValue // Adding another value for an "else" branch
		
		val name = Namings.name
		val min = integerValues.min
		val max = integerValues.max
		val selection = ntaBuilder.createIntegerSelection(name,
			ntaBuilder.createLiteralExpression(min.toString),
			ntaBuilder.createLiteralExpression(max.toString)
		)
		
		logger.info("Retrieved integer values for " + variable.name + " havoc: " + integerValues)
		
		if (integerValues.size == max - min + 1) {
			// A  continuous range, no need for additional guards
			return new SelectionStruct(selection, null)
		}
		
		val equalities = newArrayList // Filters the "interesting" values from the range
		for (integerValue : integerValues) {
			equalities += ntaBuilder.createEqualityExpression(
				selection, ntaBuilder.createLiteralExpression(integerValue.toString))
		}
		
		val guard = ntaBuilder.wrapIntoOrExpression(equalities)
		
		return new SelectionStruct(selection, guard)
	}
	
	def dispatch SelectionStruct createSelection(ArrayTypeDefinition type, VariableDeclaration variable) {
		throw new IllegalArgumentException("Array havoc is not supported: " + type)
	}
	
	// Auxiliary structures
	
	@Data
	static class SelectionStruct {
		Selection selection
		Expression guard
	}
	
	static class Namings {
				
		static int id		
		def static String getName() '''_«id++»_«id.hashCode»'''
		
	}
	
}