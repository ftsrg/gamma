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

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.DecimalTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.RationalTypeDefinition
import hu.bme.mit.gamma.expression.model.ScheduledClockVariableDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.SubrangeTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclarationAnnotation
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition
import hu.bme.mit.gamma.xsts.model.OnDemandControlVariableDeclarationAnnotation
import hu.bme.mit.gamma.xsts.model.PrimedVariable
import hu.bme.mit.gamma.xsts.model.StrictControlVariableDeclarationAnnotation
import hu.bme.mit.gamma.xsts.model.XSTS

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class DeclarationSerializer {
	// Singleton
	public static final DeclarationSerializer INSTANCE = new DeclarationSerializer
	protected new() {}
	// Auxiliary objects
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension SerializationValidator serializationValidator = SerializationValidator.INSTANCE
	
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
	
	def dispatch String serializeType(IntegerTypeDefinition type) '''«IF type.containingVariable.clock»clock«ELSE»integer«ENDIF»'''
	
	def dispatch String serializeType(RationalTypeDefinition type) '''rational'''
	
	def dispatch String serializeType(SubrangeTypeDefinition type) '''«type.lowerBound.serialize» : «type.upperBound.serialize»'''
	
	def dispatch String serializeType(EnumerationTypeDefinition type) '''{ «FOR literal : type.literals SEPARATOR ', '»«literal.serializeLiteral»«ENDFOR» }'''

	def dispatch String serializeType(ArrayTypeDefinition type) '''[integer] -> «type.elementType.serializeType»'''

	protected def String serializeLiteral(EnumerationLiteralDefinition literal) {
		literal.validateIdentifier // As these are the only element identifiers that come unchanged from the source model
		return '''«literal.name»'''
	}

	// Variable

	def String serializeVariableDeclaration(VariableDeclaration variable) '''«FOR annotation : variable.annotations»«annotation.serializeAnnotation» «ENDFOR»var «variable.name» : «variable.type.serializeType»«IF variable.expression !== null» = «variable.expression.serialize»«ENDIF»'''
	
	def String serializeLocalVariableDeclaration(VariableDeclaration variable) '''local «variable.serializeVariableDeclaration»'''
	
	// Annotation
	
	// Default - not handled annotations
	protected def dispatch serializeAnnotation(VariableDeclarationAnnotation annotation) ''''''
	
	protected def dispatch serializeAnnotation(StrictControlVariableDeclarationAnnotation annotation) '''ctrl'''
	
	protected def dispatch serializeAnnotation(OnDemandControlVariableDeclarationAnnotation annotation) '''ctrl'''
	
	/*
	 * PRED domain does not care about 'ctrl' annotations;
	 * EXPL domain in the first iteration considers only 'ctrl' variables - this can be useful;
	 * PRED_CART domain tracks 'ctrl' variables explicitly - this could be a potential disadvantage here.
	 * Maybe a new distinguished annotation should be introduced for clock variables in Theta.
	 */
	protected def dispatch serializeAnnotation(ScheduledClockVariableDeclarationAnnotation annotation) '''ctrl'''
	
}