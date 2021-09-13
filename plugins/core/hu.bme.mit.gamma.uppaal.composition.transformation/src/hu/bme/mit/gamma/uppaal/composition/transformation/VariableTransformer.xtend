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
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import uppaal.NTA
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix
import uppaal.declarations.DeclarationsPackage
import uppaal.expressions.ExpressionsFactory
import uppaal.types.TypesPackage

class VariableTransformer {
	// NTA
	protected final NTA nta
	// NTA builder
	protected final extension NtaBuilder ntaBuilder
	protected final extension IModelManipulations manipulation
	// Gamma package
	protected final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
	// UPPAAL packages
	protected final extension DeclarationsPackage declPackage = DeclarationsPackage.eINSTANCE
	protected final extension TypesPackage typPackage = TypesPackage.eINSTANCE
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	// Trace
	extension final Trace traceModel
	
	new(NtaBuilder ntaBuilder, IModelManipulations manipulation, Trace traceModel) {
		this.nta = ntaBuilder.nta
		this.ntaBuilder = ntaBuilder
		this.manipulation = manipulation
		this.traceModel = traceModel
	}
	
	// Type references, such as enums and typedefs for primitive types
	def dispatch DataVariableDeclaration transformVariable(Declaration variable,
			TypeDeclaration type, DataVariablePrefix prefix, String name) {
		val declaredType = type.type
		return variable.transformVariable(declaredType, prefix, name)	
	}
	
	def dispatch DataVariableDeclaration transformVariable(Declaration variable,
			TypeReference type, DataVariablePrefix prefix, String name) {
		val referredType = type.reference
		return variable.transformVariable(referredType, prefix, name)	
	}
	
	def dispatch DataVariableDeclaration transformVariable(Declaration variable,
			EnumerationTypeDefinition type, DataVariablePrefix prefix, String name) {
		val uppaalVar = nta.globalDeclarations.createChild(declarations_Declaration, dataVariableDeclaration) as DataVariableDeclaration  => [
			it.prefix = prefix
		]
		val max = (type.literals.size - 1).toString
		uppaalVar.createRangedIntegerVariable(name, createLiteralExpression => [it.text = "0"],
			createLiteralExpression => [it.text = max])
		// Creating the trace
		addToTrace(variable, #{uppaalVar}, trace)
		return uppaalVar	
	}
	
	// Constant, variable and parameter declarations
	def dispatch DataVariableDeclaration transformVariable(Declaration variable, IntegerTypeDefinition type,
			DataVariablePrefix prefix, String name) {
		val uppaalVar = createVariable(nta.globalDeclarations, prefix, nta.int, name)
		addToTrace(variable, #{uppaalVar}, trace)	
		return uppaalVar	 
	}
	
	def dispatch DataVariableDeclaration transformVariable(Declaration variable, BooleanTypeDefinition type,
			DataVariablePrefix prefix, String name) {
		val uppaalVar = createVariable(nta.globalDeclarations, prefix, nta.bool, name)
		addToTrace(variable, #{uppaalVar}, trace)
		return uppaalVar
	}
	
	def dispatch DataVariableDeclaration transformVariable(Declaration variable, Type type,
			DataVariablePrefix prefix, String name) {
		throw new IllegalArgumentException("Not transformable variable type: " + type + "!")
	}
	
}