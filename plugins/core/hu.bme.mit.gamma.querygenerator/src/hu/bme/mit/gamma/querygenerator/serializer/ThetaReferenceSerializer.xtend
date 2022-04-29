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
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class ThetaReferenceSerializer implements AbstractReferenceSerializer {
	// Singleton
	public static final ThetaReferenceSerializer INSTANCE = new ThetaReferenceSerializer
	protected new() {}
	//
	
	override getId(State state, Region parentRegion, ComponentInstanceReferenceExpression instance) {
		return '''«state.getSingleTargetStateName(parentRegion, instance)»«FOR parent : state.ancestors BEFORE " && " SEPARATOR " && "»«parent.getSingleTargetStateName(parent.parentRegion, instance)»«ENDFOR»'''
	}
	
	def protected getSingleTargetStateName(State state, Region parentRegion, ComponentInstanceReferenceExpression instance) {
		return '''«parentRegion.customizeName(instance)» == «state.customizeName»'''
	}
	
	override getId(VariableDeclaration variable, ComponentInstanceReferenceExpression instance) {
		return variable.customizeNames(instance)
	}
	
	override getId(Event event, Port port, ComponentInstanceReferenceExpression instance) {
		if (port.isInputEvent(event)) {
			event.customizeInputName(port, instance)
		}
		return event.customizeOutputName(port, instance)
	}
	
	override getId(Event event, Port port, ParameterDeclaration parameter, ComponentInstanceReferenceExpression instance) {
		if (port.isInputEvent(event)) {
			parameter.customizeInNames(port, instance)
		}
		return parameter.customizeOutNames(port, instance)
	}
	
}