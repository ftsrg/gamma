/********************************************************************************
 * Copyright (c) 2023-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State

import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class NuxmvReferenceSerializer extends ThetaReferenceSerializer {
	// Singleton
	public static final NuxmvReferenceSerializer INSTANCE = new NuxmvReferenceSerializer
	protected new() {}
	//
	
	override getId(State state, Region parentRegion, ComponentInstanceReferenceExpression instance) {
//		return '''«state.getSingleTargetStateName(parentRegion, instance)»«FOR parent : state.ancestors BEFORE " & " SEPARATOR " & "»«parent.getSingleTargetStateName(parent.parentRegion, instance)»«ENDFOR»'''
		return '''«state.getSingleTargetStateName(parentRegion, instance)»''' // Enough due to __Inactive__ and __history__ literals
	}
	
	override getSingleTargetStateName(State state, Region parentRegion, ComponentInstanceReferenceExpression instance) {
		return '''«parentRegion.customizeName(instance)» = «state.XStsId»'''
	}
	
}