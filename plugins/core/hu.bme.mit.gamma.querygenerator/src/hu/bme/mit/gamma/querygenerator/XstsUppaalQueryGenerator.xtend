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
package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.Region

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class XstsUppaalQueryGenerator extends ThetaQueryGenerator {
	
	new(Component component) {
		super(component)
	}
	
	def protected getSingleTargetStateName(int index, Region parentRegion, SynchronousComponentInstance instance) {
		return '''«parentRegion.customizeName(instance)» == «index»'''
	}
	
	override getSourceState(String targetStateName) {
		for (match : instanceStates) {
			val parentRegion = match.parentRegion
			val instance = match.instance
			val state = match.state
			val stateIndex = state.literalIndex
			val name = getSingleTargetStateName(stateIndex, parentRegion, instance)
			if (name.equals(targetStateName)) {
				return new Pair(match.state, match.instance)
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	// UPPAAL returns array values like this "b[1][2]" and here we need only "b"
	
	override getSourceVariable(String id) {
		val bracketLessId = id.bracketLessId
		return super.getSourceVariable(bracketLessId)
	}
	
	override getSourceVariableFieldHierarchy(String id) {
		val bracketLessId = id.bracketLessId
		return super.getSourceVariableFieldHierarchy(bracketLessId)
	}
	
	override getSourceOutEventParameterFieldHierarchy(String id) {
		val bracketLessId = id.bracketLessId
		return super.getSourceOutEventParameterFieldHierarchy(bracketLessId)
	}
	
	override getSynchronousSourceInEventParameterFieldHierarchy(String id) {
		val bracketLessId = id.bracketLessId
		return super.getSynchronousSourceInEventParameterFieldHierarchy(bracketLessId)
	}
	
	override getAsynchronousSourceMessageQueue(String id) {
		val bracketLessId = id.bracketLessId
		return super.getAsynchronousSourceMessageQueue(bracketLessId)
	}
	
	override getAsynchronousSourceInEventParameter(String id) {
		val bracketLessId = id.bracketLessId
		return super.getAsynchronousSourceInEventParameter(bracketLessId)
	}
	
	override getAsynchronousSourceInEventParameterFieldHierarchy(String id) {
		val bracketLessId = id.bracketLessId
		return super.getAsynchronousSourceInEventParameterFieldHierarchy(bracketLessId)
	}
	
}