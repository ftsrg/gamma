/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.fei.xsap.transformation.serializer

import hu.bme.mit.gamma.fei.model.FaultExtensionInstructions
import hu.bme.mit.gamma.fei.model.FaultMode
import hu.bme.mit.gamma.querygenerator.serializer.NuxmvPropertyExpressionSerializer
import hu.bme.mit.gamma.querygenerator.serializer.NuxmvReferenceSerializer

class ModelSerializer {
	// Singleton
	public static ModelSerializer INSTANCE = new ModelSerializer
	protected new() {}
	//
	
	protected final extension FaultEffectSerializer faultEffectSerializer = FaultEffectSerializer.INSTANCE
	
	protected final extension NuxmvReferenceSerializer referenceSerializer = NuxmvReferenceSerializer.INSTANCE
	protected final extension NuxmvPropertyExpressionSerializer expressionSerializer =
			new NuxmvPropertyExpressionSerializer(referenceSerializer) // For probabilities
	
	//
	
	def String execute(FaultExtensionInstructions fei) '''
		FAULT EXTENSION «fei.name»
			EXTENSION OF MODULE main ««« Currently, we always target the unfolded (flat) main module 
			«FOR slice : fei.faultSlices»
				SLICE «slice.name» AFFECTS «FOR element : slice.affectedElements SEPARATOR ', '»«element.serializeId»«ENDFOR» WITH
					«FOR mode : slice.faultModes»
						MODE «mode.name»«IF mode.probability !== null»(«mode.probability.serialize»)«ENDIF» : «mode.serializeLocalDynamics» «mode.effect.serializeEffect»;
					«ENDFOR»
				««« TODO global dynamics
			«ENDFOR»
			««« TODO Common causes
	'''
	
	//
	
	protected def serializeLocalDynamics(FaultMode mode) {
		val dynamics = mode.localDynamics
		return dynamics.literal.toLowerCase.toFirstUpper // Permanent or Transient
	}
	
}