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
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.xsts.transformation.util.Namings

import static extension hu.bme.mit.gamma.xsts.iml.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class ImlReferenceSerializer extends ThetaReferenceSerializer {
	// Singleton
	public static final ImlReferenceSerializer INSTANCE = new ImlReferenceSerializer
	protected new() {}
	//
	
	def static getRecordIdentifier() {
		return GLOBAL_RECORD_IDENTIFIER
	}
	
	//
	
	override getId(State state, Region parentRegion, ComponentInstanceReferenceExpression instance) {
		return '''«state.getSingleTargetStateName(parentRegion, instance)»''' // Enough due to __Inactive__ and __history__ literals
	}
	
	override getSingleTargetStateName(State state, Region parentRegion, ComponentInstanceReferenceExpression instance) {
		return '''«recordIdentifier».«parentRegion.customizeName(instance).customizeDeclarationName» = «Namings.customizeRegionTypeName(parentRegion).customizeTypeDeclarationName».«state.XStsId.customizeEnumLiteralName»'''
	}
	
	// Needed by the property adjustor to remove nonexisting state references
//	override getId(Region region, ComponentInstanceReferenceExpression instance) {
//		return region.customizeName(instance).customizeDeclarationName
//	}
//	
//	override getXStsId(State state) '''«super.getXStsId(state).customizeEnumLiteralName»'''
	//
	
	override getId(VariableDeclaration variable, ComponentInstanceReferenceExpression instance) {
		return super.getId(variable, instance).map[recordIdentifier + "." + it.customizeDeclarationName]
	}
	
	override getId(Event event, Port port, ComponentInstanceReferenceExpression instance) {
		return recordIdentifier + "." + super.getId(event, port, instance).customizeDeclarationName
	}
	
	override getId(Event event, Port port, ParameterDeclaration parameter, ComponentInstanceReferenceExpression instance) {
		return super.getId(event, port, parameter, instance).map[recordIdentifier + "." + it.customizeDeclarationName]
	}
	
}