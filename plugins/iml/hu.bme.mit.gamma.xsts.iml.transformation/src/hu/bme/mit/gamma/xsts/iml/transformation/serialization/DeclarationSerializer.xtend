/********************************************************************************
 * Copyright (c) 2024-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.iml.transformation.serialization

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FunctionDeclaration
import hu.bme.mit.gamma.expression.model.LambdaDeclaration
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.VoidTypeDefinition
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.iml.transformation.util.MessageQueueHandler
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.ProcedureDeclaration
import hu.bme.mit.gamma.xsts.transformation.util.MessageQueueUtil
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.iml.transformation.util.Namings.*

class DeclarationSerializer {
	// Singleton
	public static final DeclarationSerializer INSTANCE = new DeclarationSerializer
	protected new() {}
	//
	protected final extension MessageQueueHandler queueHandler = MessageQueueHandler.INSTANCE
	protected final extension MessageQueueUtil queueUtil = MessageQueueUtil.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension ActionSerializer actionSerializer = new ActionSerializer
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE
	//
	
	def serializeFieldDeclaration(Declaration declaration) {
		//
		if (declaration.queueVariable) {
			return declaration.serializeQueueVariable
		}
		if (declaration.queueSizeVariable && declaration.hasQueueOfQueueSizeVariable) {
			// IML lists contain their size natively
			return ''''''
			// If the queue is null, we cannot remove the size variable as other parts depend on this
		}
		//
		return '''«declaration.serializeName» : «declaration.type.serializeType»;'''
	}
			
	def serializeEnvFieldDeclaration(HavocAction havoc) '''«
			havoc.serializeFieldName» : «havoc.lhs.declaration.type.serializeType»;'''
	
	// Type declaration: enumeration types are serialized using modules to ease 'literal -> type' linking
	
	def serializeTypeDeclaration(TypeDeclaration declaration) '''
		module «declaration.serializeName» = struct type t = «declaration.type.serializeType» end
	'''
	// type nonrec «declaration.serializeName» = «declaration.type.serializeType»
	
	def serializeFunctionDeclaration(FunctionDeclaration function) '''
		«IF function instanceof ProcedureDeclaration»
			type nonrec «function.customizeLocalVariablesTypeName» = {
				«FOR localVariable : function.localVariables»
					«localVariable.serializeFieldDeclaration»
				«ENDFOR»
				«function.createReturnVariable.serializeFieldDeclaration»
			}
		«ENDIF»
		
		let «IF function.recursive»rec «ENDIF»«function.name» («GLOBAL_RECORD_IDENTIFIER» : «GLOBAL_RECORD_TYPE_NAME») «
				FOR parameter : function.parameterDeclarations SEPARATOR ' '»(«parameter.serializeParameterDeclaration»)«ENDFOR» =
			«function.serializeFunctionDeclarationBody»
	'''
	
	protected def serializeParameterDeclaration(Declaration declaration)'''«declaration.serializeName» : «declaration.type.serializeType»'''
 	
	protected def dispatch serializeFunctionDeclarationBody(LambdaDeclaration function) '''«function.expression.serialize»'''
	
	protected def dispatch serializeFunctionDeclarationBody(ProcedureDeclaration function) '''
		«(function.localVariables + #[function.createReturnVariable])
					.initVariablesIfNotEmpty(LOCAL_RECORD_IDENTIFIER)»
		«function.body.serializeActionIntermediate»«functionReturnValues»
	'''
	
	//
	
	private def createReturnVariable(FunctionDeclaration function) {
		val functionType = function.type
		val type = (functionType instanceof VoidTypeDefinition) ? 
				createBooleanTypeDefinition :
				functionType.clone
		return type.createVariableDeclaration(FUNCTION_RETURN_VALUE_NAME)
	}
	
}