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

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.fei.model.FaultEvent
import hu.bme.mit.gamma.fei.model.FaultModeState
import hu.bme.mit.gamma.fei.model.FaultModeStateReference
import hu.bme.mit.gamma.fei.model.FaultTransition
import hu.bme.mit.gamma.fei.model.FaultTransitionTrigger
import hu.bme.mit.gamma.fei.model.GlobalDynamics
import hu.bme.mit.gamma.querygenerator.serializer.NuxmvPropertyExpressionSerializer
import hu.bme.mit.gamma.querygenerator.serializer.NuxmvReferenceSerializer

class GlobalDynamicsSerializer {
	// Singleton
	public static GlobalDynamicsSerializer INSTANCE = new GlobalDynamicsSerializer
	protected new() {}
	//
	protected final extension NuxmvPropertyExpressionSerializer expressionSerializer =
			new NuxmvPropertyExpressionSerializer(NuxmvReferenceSerializer.INSTANCE)
	//
	
	def serializeGlobalDynamics(GlobalDynamics globalDynamics) '''
		«IF globalDynamics !== null»
			GLOBAL DYNAMICS
				«FOR transition : globalDynamics.transitions»
					«transition.serializeFaultTransition»
				«ENDFOR»
		«ENDIF»
	'''
	
	//
	
	protected def serializeFaultTransition(FaultTransition transition) '''
		TRANS «transition.source.serializeFaultModeStateReference» -[
			«transition.trigger.serializeFaultTransitionTrigger»«transition.guard.serializeFaultTransitionGuard»]->
				«transition.target.serializeFaultModeStateReference»;
	'''
	
	protected def serializeFaultModeStateReference(FaultModeStateReference reference) '''
		«reference.faultMode.name».«reference.state.serializeFaultModeState»'''
	
	protected def serializeFaultTransitionTrigger(FaultTransitionTrigger trigger) '''
		«IF trigger !== null»«trigger.faultMode.name».«trigger.event.serializeFaultEvent»«ENDIF»'''
	
	protected def serializeFaultTransitionGuard(Expression expression) '''
		«IF expression !== null» when «expression.serialize»«ENDIF»'''
	
	//
	
	protected def serializeFaultModeState(FaultModeState state) {
		return switch (state) {
			case FAULTY: "fault"
			case NOMINAL: "nominal"
			default:
				throw new IllegalArgumentException("Not known state: " + state)
		}
	}
	
	protected def serializeFaultEvent(FaultEvent event) {
		return switch (event) {
			case FAILURE: "failure"
			case SELF_FIX: "self_fixed"
			default:
				throw new IllegalArgumentException("Not known event: " + event)
		}
	}
	
}