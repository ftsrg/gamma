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
package hu.bme.mit.gamma.xsts.promela.transformation.serializer

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator2
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.promela.transformation.util.ArrayHandler

import static extension hu.bme.mit.gamma.xsts.promela.transformation.util.Namings.*

class DeclarationSerializer {
	// Singleton
	public static final DeclarationSerializer INSTANCE = new DeclarationSerializer

	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension ArrayHandler arrayHandler = ArrayHandler.INSTANCE
	
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	protected final extension ExpressionTypeDeterminator2 expressionTypeDeterminator = ExpressionTypeDeterminator2.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	protected new() {}
	
	def String serializeDeclaration(XSTS xSts) '''
		«FOR type : xSts.getAllContentsOfType(ArrayTypeDefinition).allArrayTypeDefinition»
			«IF type.elementType instanceof ArrayTypeDefinition»«type.elementType.serializeArrayTypeDefinition(0)»«ENDIF»
		«ENDFOR»
		
		«FOR typeDeclaration : xSts.typeDeclarations»
			«typeDeclaration.serializeTypeDeclaration»
		«ENDFOR»
		
		«FOR variableDeclaration : xSts.variableDeclarations»
			«variableDeclaration.serializeVariableDeclaration»
		«ENDFOR»
	'''
	
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
	
	def dispatch String serializeType(ArrayTypeDefinition type) '''«IF type.elementType instanceof ArrayTypeDefinition»«type.getContainerOfType(Declaration).name»0«ELSE»«type.elementType.serializeType»«ENDIF»'''
	
	// Array serialization
	
	def String serializeArrayTypeDefinition(Type type, Integer index) {
		val typeDefinition = type as ArrayTypeDefinition
		val elementType = typeDefinition.elementType
		val declaration = typeDefinition.getContainerOfType(Declaration)
		return '''
		«IF elementType instanceof ArrayTypeDefinition»
			«elementType.serializeArrayTypeDefinition(index+1)»
			typedef «declaration.name»«index» { «declaration.name»«index+1» «arrayFieldName»[«typeDefinition.size.serialize»] }
		«ELSE»
			typedef «declaration.name»«index» { «elementType.serializeType» «arrayFieldName»[«typeDefinition.size.serialize»] }
		«ENDIF»
		'''
	}
	
	// Variable
	
	protected def String serializeVariableDeclaration(VariableDeclaration variable) {
		//Proomela does not support multidimensional arrays, so they need to be handled differently.
		//It also does not support the use of array init blocks in processes.
		val type = variable.type
		return '''
		«IF type instanceof ArrayTypeDefinition»
			«IF type.elementType instanceof ArrayTypeDefinition»
				«type.serializeType» «variable.name»[«type.size.serialize»];
			«ELSE»
				«type.serializeType» «variable.name»[«type.size.serialize»]«IF variable.expression !== null» = «variable.expression.serialize»«ENDIF»;
			«ENDIF»
		«ELSE»
			«type.serializeType» «variable.name»«IF variable.expression !== null» = «variable.expression.serialize»«ENDIF»;
		«ENDIF»
		'''
	}
	
	def String serializeLocalVariableDeclaration(VariableDeclaration variable) {
		//Proomela does not support multidimensional arrays, so they need to be handled differently.
		//It also does not support the use of array init blocks in processes.
		val type = variable.type
		return '''
		«IF type instanceof ArrayTypeDefinition»
			«IF type.elementType instanceof ArrayTypeDefinition»
				local «type.serializeType» «variable.name»[«type.size.serialize»];
				«IF variable.expression !== null»
				«variable.serializeArrayInit(variable.expression, type)»
				«ENDIF»
			«ELSE»
				local «type.serializeType» «variable.name»[«type.size.serialize»]«IF variable.expression !== null» = «variable.expression.serialize»«ENDIF»;
			«ENDIF»
		«ELSE»
			local «type.serializeType» «variable.name»«IF variable.expression !== null» = «variable.expression.serialize»«ENDIF»;
		«ENDIF»
		'''
	}
}