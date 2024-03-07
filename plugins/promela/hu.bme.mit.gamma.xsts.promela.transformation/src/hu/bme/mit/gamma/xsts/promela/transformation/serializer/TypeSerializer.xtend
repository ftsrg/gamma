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
package hu.bme.mit.gamma.xsts.promela.transformation.serializer

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.transformation.util.MessageQueueUtil

import static extension hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*

class TypeSerializer {
	// Singleton
	public static final TypeSerializer INSTANCE = new TypeSerializer
	//
	
	protected final extension MessageQueueUtil messageQueueUtil = MessageQueueUtil.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
		
	// Type declaration
	
	def String serializeTypeDeclaration(TypeDeclaration typeDeclaration) '''
		mtype:«typeDeclaration.name» = «typeDeclaration.type.serializeType»
	'''
	
	// Type
	
	def dispatch String serializeType(Type type) {
		throw new IllegalArgumentException("Not known type: " + type)
	}
	
	def dispatch String serializeType(TypeReference type) '''mtype:«type.reference.name»'''
	
	def dispatch String serializeType(BooleanTypeDefinition type) '''bool'''
	
	def dispatch String serializeType(IntegerTypeDefinition type) '''int'''
	
	def dispatch String serializeType(EnumerationTypeDefinition type) '''{ «FOR literal : type.literals SEPARATOR ', '»«type.customizeEnumLiteralName(literal)»«ENDFOR» }'''
	
	def dispatch String serializeType(ArrayTypeDefinition type) '''«IF type.elementType instanceof ArrayTypeDefinition»«type
			.getContainerOfType(Declaration).name»0«ELSE»«type.elementType.serializeType»«ENDIF»'''
	
	// Multidimensional array declaration serialization
	
	def String serializeArrayTypeDeclaration(Type type) {
		return type.serializeArrayTypeDeclaration(0)
	}
	
	private def String serializeArrayTypeDeclaration(Type type, int index) {
		val typeDefinition = type as ArrayTypeDefinition
		val elementType = typeDefinition.elementType
		val declaration = typeDefinition.getContainerOfType(Declaration)
		return '''
			«IF elementType instanceof ArrayTypeDefinition»
				«elementType.serializeArrayTypeDeclaration(index + 1)»
				typedef «declaration.name»«index» { «declaration.name»«index+1» «arrayFieldName»[«typeDefinition.size.serialize»] }
			«ELSE»
				typedef «declaration.name»«index» { «elementType.serializeType» «arrayFieldName»[«typeDefinition.size.serialize»] }
			«ENDIF»
		'''
	}
	
}