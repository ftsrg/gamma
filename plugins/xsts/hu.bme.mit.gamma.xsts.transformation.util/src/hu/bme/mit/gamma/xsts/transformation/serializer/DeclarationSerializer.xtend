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
package hu.bme.mit.gamma.xsts.transformation.serializer

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition
import hu.bme.mit.gamma.expression.model.SubrangeTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition
import hu.bme.mit.gamma.xsts.model.PrimedVariable
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition

class DeclarationSerializer {
	// Singleton
	public static final DeclarationSerializer INSTANCE = new DeclarationSerializer
	protected new() {}
	// Auxiliary objects
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	
	// xSts
	
	def String serializeDeclarations(XSTS xSts, boolean serializePrimedVariables) '''
		«FOR typeDeclaration : xSts.typeDeclarations»
			«typeDeclaration.serializeTypeDeclaration»
		«ENDFOR»
		«FOR variableDeclaration : xSts.variableDeclarations
					.filter[serializePrimedVariables || !(it instanceof PrimedVariable)]»
			«variableDeclaration.serializeVariableDeclaration»
		«ENDFOR»
	''' 
	
	// Type declaration
	
	def String serializeTypeDeclaration(TypeDeclaration typeDeclaration) '''
		type «typeDeclaration.name» : «typeDeclaration.type.serializeType»
	'''
	
	// Type
	
	def dispatch String serializeType(Type type) {
		throw new IllegalArgumentException("Not known type: " + type)
	}
	
	def dispatch String serializeType(TypeReference type) '''«type.reference.name»'''
	
	def dispatch String serializeType(VoidTypeDefinition type) '''void'''
	
	def dispatch String serializeType(BooleanTypeDefinition type) '''boolean'''
	
	def dispatch String serializeType(DecimalTypeDefinition type) '''decimal'''
	
	def dispatch String serializeType(IntegerTypeDefinition type) '''integer'''
	
	def dispatch String serializeType(RationalTypeDefinition type) '''rational'''
	
	def dispatch String serializeType(SubrangeTypeDefinition type) '''«type.lowerBound.serialize» : «type.upperBound.serialize»'''
	
	def dispatch String serializeType(EnumerationTypeDefinition type) '''{ «FOR literal : type.literals SEPARATOR ', '»«literal.name»«ENDFOR»}'''

	def dispatch String serializeType(ArrayTypeDefinition type) '''array «type.elementType.serializeType» [«type.size.serialize»]'''

	// Variable

	def String serializeVariableDeclaration(VariableDeclaration variable) '''«variable.serializeModifier»var «variable.name» : «variable.type.serializeType»«IF variable.expression !== null» = «variable.expression.serialize»«ENDIF»'''
	
	def String serializeLocalVariableDeclaration(VariableDeclaration variable) '''local «variable.serializeVariableDeclaration»'''
	
	private def serializeModifier(VariableDeclaration variable) {
		val container = variable.eContainer
		if (container instanceof XSTS) {
			val xSts = container as XSTS
			if (xSts.controlVariables.contains(variable)) {
				return "ctrl "
			}
	//		if (xSts.clockVariables.contains(variable)) {
	//			return "clk "
	//		}
		}
		return ""
	}
	
}