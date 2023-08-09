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
import static extension hu.bme.mit.gamma.uppaal.util.Namings.*

class UppaalReferenceSerializer implements AbstractReferenceSerializer {
	// Singleton
	public static final UppaalReferenceSerializer INSTANCE = new UppaalReferenceSerializer
	protected new() {}
	//
	
	override getId(State state, Region parentRegion, ComponentInstanceReferenceExpression instance) {
		val processName = parentRegion.getId(instance)
		val locationName = new StringBuilder
		locationName.append('''«processName».«state.locationName»''')
		if (parentRegion.subregion) {
			locationName.append(" && " + processName + ".isActive") 
		}
		return locationName.toString
	}
	
	override getId(Region region, ComponentInstanceReferenceExpression instance) {
		return region.getTemplateName(instance).processName
	}
	
	override getId(VariableDeclaration variable, ComponentInstanceReferenceExpression instance) {
		return #[getVariableName(variable, instance)]
	}
	
	override getId(Event event, Port port, ComponentInstanceReferenceExpression instance) {
		if (port.isInputEvent(event)) {
			return getToRaiseName(event, port, instance)
		}
		return getOutEventName(event, port, instance)
	}
	
	override getId(Event event, Port port, ParameterDeclaration parameter, ComponentInstanceReferenceExpression instance) {
		if (port.isInputEvent(event)) {
			return #[getToRaiseValueOfName(event, port, parameter, instance)]
		}
		return #[getOutValueOfName(event, port, parameter, instance)]
	}
	
}