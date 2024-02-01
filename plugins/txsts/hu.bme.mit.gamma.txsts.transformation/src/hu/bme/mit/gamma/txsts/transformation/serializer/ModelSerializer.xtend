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
package hu.bme.mit.gamma.txsts.transformation.serializer

import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.transformation.serializer.ActionSerializer

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class ModelSerializer extends ActionSerializer{
	// Singleton
	public static final ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	
	protected final extension DeclarationSerializer declarationSerializer = DeclarationSerializer.INSTANCE
	
	def String serializeTxsts(XSTS xSts) {
		return xSts.serializeTxsts(false)
	}
	
	def String serializeTxsts(XSTS xSts, boolean serializePrimedVariables) '''
		«xSts.serializeDeclarations(serializePrimedVariables)»
		
		trans «FOR transition : xSts.transitions SEPARATOR " or "»{
			__delay;
			«transition.action.serialize»
		}«ENDFOR»
		init {
			«xSts.initializingAction.serialize»
		}
		env {
			«xSts.environmentalAction.serialize»
		}
	'''

}