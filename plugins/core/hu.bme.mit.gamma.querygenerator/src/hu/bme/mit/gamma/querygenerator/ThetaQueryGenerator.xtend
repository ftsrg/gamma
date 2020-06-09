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

import hu.bme.mit.gamma.statechart.interface_.Package
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.expression.model.ParameterDeclaration

import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ThetaQueryGenerator extends AbstractQueryGenerator {
	
	new(Package gammaPackage) {
		val resourceSet = gammaPackage.eResource.resourceSet
		this.engine = ViatraQueryEngine.on(new EMFScope(resourceSet))
	}
	
	override parseRegularQuery(String text, TemporalOperator operator) {
		switch (operator) {
			case MUST_ALWAYS: {
				return operator.operator + " " + text.parseIdentifiers
			}
			case MIGHT_EVENTUALLY: {
				return operator.operator + " " + text.parseIdentifiers.wrap
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
		return '''«state.getSingleTargetStateName(parentRegion, instance)»«FOR parent : state.ancestors BEFORE " && " SEPARATOR " && "»«parent.getSingleTargetStateName(parent.parentRegion, instance)»«ENDFOR»'''
	}
	
	def protected getSingleTargetStateName(State state, Region parentRegion, SynchronousComponentInstance instance) {
		return '''«parentRegion.customizeName(instance)» == «state.customizeName»'''
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
	
	def protected getTargetInEventName(Event event, Port port, SynchronousComponentInstance instance) {
		return event.customizeInputName(port, instance)
	}
	
	def protected getTargetInEventParameterName(Event event, Port port, ParameterDeclaration parameter, SynchronousComponentInstance instance) {
		return parameter.customizeInName(port, instance)
	}
	
	// Auxiliary methods for back-annotation
	
	def getSourceState(String targetStateName) {
		for (match : instanceStates) {
			val name = getSingleTargetStateName(match.state, match.parentRegion, match.instance)
			if (name.equals(targetStateName)) {
				return new Pair(match.state, match.instance)
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	def getSourceVariable(String targetVariableName) {
		for (match : instanceVariables) {
			val name = getTargetVariableName(match.variable, match.instance)
			if (name.equals(targetVariableName)) {
				return new Pair(match.variable, match.instance)
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	def getSourceOutEvent(String targetOutEventName) {
		for (match : systemOutEvents) {
			val name = getTargetOutEventName(match.event, match.port, match.instance)
			if (name.equals(targetOutEventName)) {
				return #[match.event, match.port, match.instance]
			}
		}
		throw new IllegalArgumentException("Not known id")
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
		throw new IllegalArgumentException("Not known id")
	}
	
	def getSourceInEvent(String getTargetInEventName) {
		for (match : systemInEvents) {
			val name = getTargetInEventName(match.event, match.port, match.instance)
			if (name.equals(getTargetInEventName)) {
				return #[match.event, match.port, match.instance]
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	def getSourceInEventParamater(String targetInEventParameterName) {
		for (match : systemInEvents) {
			val event = match.event
			for (parameter : event.parameterDeclarations) {
				val name = getTargetInEventParameterName(event, match.port, parameter, match.instance)
				if (name.equals(targetInEventParameterName)) {
					return #[event, match.port, parameter, match.instance]
				}
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
}