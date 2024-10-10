/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
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
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.xsts.iml.transformation.util.MessageQueueHandler
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.transformation.util.MessageQueueUtil
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

class DeclarationSerializer {
	// Singleton
	public static final DeclarationSerializer INSTANCE = new DeclarationSerializer
	protected new() {}
	//
	protected final extension MessageQueueHandler queueHandler = MessageQueueHandler.INSTANCE
	protected final extension MessageQueueUtil queueUtil = MessageQueueUtil.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
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
	
}