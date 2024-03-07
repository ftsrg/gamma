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
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator2
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.promela.transformation.util.ArrayHandler
import hu.bme.mit.gamma.xsts.promela.transformation.util.Configuration
import hu.bme.mit.gamma.xsts.promela.transformation.util.MessageQueueHandler
import hu.bme.mit.gamma.xsts.transformation.util.MessageQueueUtil
import hu.bme.mit.gamma.xsts.transformation.util.VariableGroupRetriever

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class DeclarationSerializer {
	// Singleton
	public static final DeclarationSerializer INSTANCE = new DeclarationSerializer
	protected new() {}
	//
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	protected final extension ArrayHandler arrayHandler = ArrayHandler.INSTANCE
	protected final extension MessageQueueUtil messageQueueUtil = MessageQueueUtil.INSTANCE
	protected final extension MessageQueueHandler messageQueueHandler = MessageQueueHandler.INSTANCE
	protected final extension VariableGroupRetriever groupRetriever = VariableGroupRetriever.INSTANCE
	
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	protected final extension ExpressionTypeDeterminator2 expressionTypeDeterminator = ExpressionTypeDeterminator2.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	//
	
	def String serializeDeclaration(XSTS xSts) '''
		«FOR type : xSts.getAllContentsOfType(ArrayTypeDefinition).allArrayTypeDefinition»
			«IF type.elementType instanceof ArrayTypeDefinition»«type.elementType.serializeArrayTypeDeclaration»«ENDIF»
		«ENDFOR»
		
		«FOR typeDeclaration : xSts.typeDeclarations»
			«typeDeclaration.serializeTypeDeclaration»
		«ENDFOR»
		
		«FOR variableDeclaration : xSts.variableDeclarations.filter[it.mustSerializeVariable] /* Native message queue handling*/»
			«variableDeclaration.serializeVariableDeclaration»
		«ENDFOR»
	'''
	
	// Variable
	
	protected def mustSerializeVariable(VariableDeclaration variableDeclaration) {
		if (Configuration.HANDLE_NATIVE_MESSAGE_QUEUES) {
			val xSts = variableDeclaration.containingXsts
			val sizeVariables = xSts.messageQueueSizeGroup.variables
			if (sizeVariables.contains(variableDeclaration)) {
				val declarationReferenceAnnotation = variableDeclaration.declarationReferenceAnnotation
				val messageQueue = declarationReferenceAnnotation.declarations.head
				if (messageQueue === null) {
					// Message queue has been removed due to optimization -> we need the size variable
					return true
				}
				else {
					return false
				}
			}
		}
		return true
	}
	
	protected def String serializeVariableDeclaration(VariableDeclaration variable) {
		// Promela does not support multidimensional arrays, so they need to be handled differently
		// It also does not support the use of array init blocks in processes
		val type = variable.type
		return '''
			«IF type instanceof ArrayTypeDefinition»
				«IF Configuration.HANDLE_NATIVE_MESSAGE_QUEUES && variable.queueVariable»
					«variable.serializeQueueVariable»
				«ELSEIF type.elementType instanceof ArrayTypeDefinition»
					«type.serializeType» «variable.serializeName»[«type.size.serialize»];
					«IF variable.expression !== null && variable.local»
						«variable.serializeArrayInit(variable.expression, type)»
					«ENDIF»
				«ELSE»
					«type.serializeType» «variable.serializeName»[«type.size.serialize»]«IF variable.expression !== null» = «variable.expression.serialize»«ENDIF»;
				«ENDIF»
			«ELSE»
				«type.serializeType» «variable.serializeName»«IF variable.expression !== null» = «variable.expression.serialize»«ENDIF»;
			«ENDIF»
		'''
	}
	
	def String serializeLocalVariableDeclaration(VariableDeclaration variable) {
		return '''local «variable.serializeVariableDeclaration»'''
	}
	
	protected def String serializeName(Declaration variable) {
		val name = variable.name
		return name
	}
	
}