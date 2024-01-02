/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
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
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import java.util.List

import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

abstract interface AbstractReferenceSerializer {
	
	def String getId(State state, Region parentRegion, ComponentInstanceReferenceExpression instance)
	def String getId(Region region, ComponentInstanceReferenceExpression instance)
	def String getId(Event event, Port port, ComponentInstanceReferenceExpression instance)
	def List<String> getId(VariableDeclaration variable, ComponentInstanceReferenceExpression instance)
	def List<String> getId(Event event, Port port, ParameterDeclaration parameter,
			ComponentInstanceReferenceExpression instance)
	//
	def String getXStsId(State state) '''«state.customizeName»'''
	//
	
	def getId(ComponentInstanceElementReferenceExpression reference) {
		return switch(reference) {
			ComponentInstanceStateReferenceExpression: {
				val state = reference.state
				if (state === null) {
					getId(reference.region, reference.instance)
				}
				else {
					getId(state, reference.region, reference.instance)
				}
			}
			ComponentInstanceEventReferenceExpression:
				getId(reference.event, reference.port, reference.instance)
			ComponentInstanceVariableReferenceExpression:
				getId(reference.variableDeclaration, reference.instance)
			ComponentInstanceEventParameterReferenceExpression:
				getId(reference.event, reference.port, reference.parameterDeclaration, reference.instance)
		}
	}
	
	def getSingleId(ComponentInstanceElementReferenceExpression reference) {
		val stringOrListId = reference.id
		
		if (stringOrListId instanceof String) {
			return stringOrListId
		}
		if (stringOrListId instanceof List) {
			val string = stringOrListId.head
			return string as String
		}
	}
	
	def getSingleIdWithoutState(ComponentInstanceElementReferenceExpression reference) {
		if (reference instanceof ComponentInstanceStateReferenceExpression) {
			val state = reference.state
			reference.state = null
			val id = reference.singleId
			reference.state = state
			
			return id
		}
		return reference.singleId
	}
	
}