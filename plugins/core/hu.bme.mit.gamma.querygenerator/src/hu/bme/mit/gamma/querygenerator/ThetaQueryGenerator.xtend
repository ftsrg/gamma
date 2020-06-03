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

import hu.bme.mit.gamma.statechart.model.Package
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.Region
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.expression.model.ParameterDeclaration

import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class ThetaQueryGenerator extends AbstractQueryGenerator {
	
	new(Package gammaPackage) {
		val resourceSet = gammaPackage.eResource.resourceSet
		this.engine = ViatraQueryEngine.on(new EMFScope(resourceSet))
	}
	
	override parseRegularQuery(String text, TemporalOperator operator) {
		switch (operator) {
			case MUST_ALWAYS: {
				return text.parseIdentifiers
			}
			case MIGHT_EVENTUALLY: {
				return "!" + text.parseIdentifiers.wrap
			}
			default: {
				throw new IllegalArgumentException("Not supported temporal operator: " + operator.toString)
			}
		}
	}
	
	override parseLeadsToQuery(String first, String second) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	override protected getTargetStateName(State state, Region parentRegion, SynchronousComponentInstance instance) {
		return '''«parentRegion.customizeName(instance)» == «state.customizeName»«FOR parent : state.ancestors BEFORE " && " SEPARATOR " && "»«parent.parentRegion.customizeName(instance)» == «parent.customizeName»«ENDFOR»'''
	}
	
	override protected getTargetVariableName(VariableDeclaration variable, SynchronousComponentInstance instance) {
		return variable.customizeName(instance)
	}
	
	override protected getTargetOutEventName(Event event, Port port, SynchronousComponentInstance instance) {
		return event.customizeOutputName(port, instance)
	}
	
	override protected getTargetOutEventParameterName(Event event, Port port, ParameterDeclaration parameter, SynchronousComponentInstance instance) {
		return parameter.customizeOutName(port, instance)
	}
	
	// Auxiliary methods for back-annotation
	
	def getSourceState(String targetStateName) {
		for (match : instanceStates) {
			val name = getTargetStateName(match.state, match.parentRegion, match.instance)
			if (name.equals(targetStateName)) {
				return new Pair(match.state, match.instance)
			}
		}
	}
	
	def getSourceVariable(String targetVariableName) {
		for (match : instanceVariables) {
			val name = getTargetVariableName(match.variable, match.instance)
			if (name.equals(targetVariableName)) {
				return new Pair(match.variable, match.instance)
			}
		}
	}
	
	def getSourceOutEvent(String targetOutEventName) {
		for (match : systemOutEvents) {
			val name = getTargetOutEventName(match.event, match.port, match.instance)
			if (name.equals(targetOutEventName)) {
				return #[match.event, match.port, match.instance]
			}
		}
	}
	
	def getSourceOutEventParamater(String targetOutEventParameterName) {
		for (match : systemOutEvents) {
			val event = match.event
			for (parameter : event.parameterDeclarations) {
				val name = getTargetOutEventParameterName(event, match.port, parameter, match.instance)
				if (name.equals(targetOutEventParameterName)) {
					return #[event, match.port, parameter, match.instance]
				}
			}
		}
	}
	
}