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

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator
import hu.bme.mit.gamma.querygenerator.patterns.InstanceStates
import hu.bme.mit.gamma.querygenerator.patterns.InstanceVariables
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.transformation.util.queries.TopSyncSystemInEvents
import hu.bme.mit.gamma.transformation.util.queries.TopSyncSystemOutEvents
import hu.bme.mit.gamma.util.Triple
import java.util.List
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

abstract class AbstractQueryGenerator {
	
	protected final Component component
	protected final ViatraQueryEngine engine
	
	new(Component component) {
		this.component = component
		val scope = new EMFScope(component.eResource.resourceSet)
		this.engine = ViatraQueryEngine.on(scope)
	}
	
	def getComponent() {
		return component
	}
	
	def wrap(String id) {
		return "(" + id + ")"
	}
	
	def unwrap(String id) {
		return id.substring(1, id.length - 1)
	}
	
	def unwrapAll(String id) {
		var i = 0
		for ( ; id.charAt(i).toString == "("; i++) {}
		var j = id.length - 1
		for ( ; id.charAt(j).toString == ")"; j--) {}
		return id.substring(i, j + 1)
	}
	
	// Gamma identifiers
	
	def getInstanceStates() {
		return InstanceStates.Matcher.on(engine).allMatches
	}
	
	def List<String> getStateNames() {
		val stateNames = newArrayList
		for (statesMatch : getInstanceStates) {
			val stateName = statesMatch.state.name
			val entry = getStateName(statesMatch.instance, statesMatch.parentRegion, statesMatch.state)
			if (!stateName.startsWith("LocalReaction")) {
				stateNames.add(entry)				
			}
		}
		return stateNames
	}
	
	def getStateName(SynchronousComponentInstance instance, Region parentRegion, State state) {
		return (instance.name + "." + getFullRegionPathName(parentRegion) + "." + state.name).wrap
	}
	
	def getInstanceVariables() {
		return InstanceVariables.Matcher.on(engine).allMatches
	}
	
	def List<String> getVariableNames() {
		val variableNames = newArrayList
		for (variableMatch : getInstanceVariables) {
			val entry = variableMatch.instance.getVariableName(variableMatch.variable)
			variableNames.add(entry)
		}
		return variableNames
	}
	
	def getVariableName(SynchronousComponentInstance instance, VariableDeclaration variable) {
		return (instance.name + "." + variable.name).wrap
	}
	
	def getSynchronousSystemInEvents() {
		return TopSyncSystemInEvents.Matcher.on(engine).allMatches
	}
	
	def getSynchronousSystemOutEvents() {
		return TopSyncSystemOutEvents.Matcher.on(engine).allMatches
	}
	
	def getAsynchronousSystemOutEvents() {
		val inEvents = newArrayList
		for (systemPort : component.allPorts) {
			for (port : systemPort.allBoundSimplePorts) {
				val instance = port.containingComponentInstance as SynchronousComponentInstance
				for (inEvent : port.outputEvents) {
					inEvents += new Triple(inEvent, port, instance)
				}
			}
		}
		return inEvents
	}
	
	def List<String> getSynchronousSystemOutEventNames() {
		val eventNames = newArrayList
		for (eventsMatch : getSynchronousSystemOutEvents) {
			val entry = getSystemOutEventName(eventsMatch.systemPort, eventsMatch.event)
			eventNames.add(entry)
		}
		return eventNames
	}
	
	def String getSystemOutEventName(Port systemPort, Event event) {
		return (systemPort.name + "." + event.name).wrap
	}
	
	def List<String> getSynchronousSystemOutEventParameterNames() {
		val parameterNames = newArrayList
		for (eventsMatch : getSynchronousSystemOutEvents) {
			val event = eventsMatch.event
			for (ParameterDeclaration parameter : event.parameterDeclarations) {
				val systemPort = eventsMatch.systemPort
				val entry = getSystemOutEventParameterName(systemPort, event, parameter)
				parameterNames.add(entry)
			}
		}
		return parameterNames
	}
	
	def String getSystemOutEventParameterName(Port systemPort, Event event, ParameterDeclaration parameter) {
		return (getSystemOutEventName(systemPort, event).unwrap + "::" + parameter.name).wrap
	}
	
	//
	
	def getAynchronousMessageQueues() {
		val queues = newHashSet
		for (asynchronousSimpleInstance : component.allAsynchronousSimpleInstances) {
			val adapter = asynchronousSimpleInstance.type as AsynchronousAdapter
			for (messageQueue : adapter.messageQueues) {
				queues += asynchronousSimpleInstance -> messageQueue
			}
		}
		return queues
	}
	
	def getAsynchronousSystemInEvents() {
		val portEvents = newHashSet
		for (asynchronousSimpleInstance : component.allAsynchronousSimpleInstances) {
			val adapter = asynchronousSimpleInstance.type as AsynchronousAdapter
			for (port : adapter.allPorts) {
				for (inEvent : port.inputEvents) {
					portEvents += new Triple(port, inEvent, asynchronousSimpleInstance)
				}
			}
		}
		return portEvents
	}
	
	// Parsing identifiers
	
	protected def String parseIdentifiers(String text) {
		var result = text
		if (text.contains("deadlock")) {
			return text
		}
		val stateNames = this.getStateNames
		val variableNames = this.getVariableNames
		val systemOutEventNames = this.getSynchronousSystemOutEventNames
		val systemOutEventParameterNames = this.getSynchronousSystemOutEventParameterNames
		for (String stateName : stateNames) {
			if (result.contains(stateName)) {
				val targetStateName = getTargetStateName(stateName)
				// The parentheses need to be \-d
				result = result.replace(stateName, targetStateName)  // Replaces all occurrences
			}
		}
		for (String variableName : variableNames) {
			if (result.contains(variableName)) {
				val targetVariableName = getTargetVariableName(variableName)
				result = result.replace(variableName, targetVariableName) // Replaces all occurrences
			}
		}
		for (String systemOutEventName : systemOutEventNames) {
			if (result.contains(systemOutEventName)) {
				val targetVariableName = getTargetOutEventName(systemOutEventName)
				result = result.replace(systemOutEventName, targetVariableName) // Replaces all occurrences
			}
		}
		for (String systemOutEventParameterName : systemOutEventParameterNames) {
			if (result.contains(systemOutEventParameterName)) {
				val targetVariableName = getTargetOutEventParameterName(systemOutEventParameterName)
				result = result.replace(systemOutEventParameterName, targetVariableName)  // Replaces all occurrences
			}
		}
		return result.wrap
	}
	
	def abstract String parseRegularQuery(String text, TemporalOperator operator)
	
	def abstract String parseLeadsToQuery(String first, String second)
	
	// Getting target identifiers
	
	protected def String getTargetStateName(String stateName) {
		val splittedStateName = stateName.unwrap.split("\\.")
		val matches = InstanceStates.Matcher.on(engine).getAllMatches(null, splittedStateName.get(0),
				null, splittedStateName.get(splittedStateName.length - 2) /* parent region */,
				null, splittedStateName.get(splittedStateName.length - 1) /* state */)
		checkArgument(matches.size == 1, "Not known state: " + stateName)
		val match = matches.head
		return getTargetStateName(match.state, match.parentRegion, match.instance)
	}
	
	protected def String getTargetVariableName(String variableName) {
		for (instancesMatch : getInstanceVariables) {
			val name = getVariableName(instancesMatch.instance, instancesMatch.variable)
			if (variableName.equals(name)) {
				val ids =  getTargetVariableNames(instancesMatch.variable, instancesMatch.instance)
				// TODO complex types?
				return ids.head
			}
		}
		throw new IllegalArgumentException("Not known variable: " + variableName)
	}
	
	protected def String getTargetOutEventName(String portEventName) {
		for (eventsMatch : getSynchronousSystemOutEvents) { // Asynchronous systems use the same
			val name = getSystemOutEventName(eventsMatch.systemPort, eventsMatch.event)
			if (name.equals(portEventName)) {
				return getTargetOutEventName(eventsMatch.event, eventsMatch.port, eventsMatch.instance)
			}
		}
		throw new IllegalArgumentException("Not known system event: " + portEventName)
	}
	
	protected def String getTargetOutEventParameterName(String portEventParameterName) {
		for (eventsMatch : getSynchronousSystemOutEvents) { // Asynchronous systems use the same
			val systemPort = eventsMatch.systemPort
			val event = eventsMatch.event
			for (ParameterDeclaration parameter : event.parameterDeclarations) {
				if (portEventParameterName.equals(
						getSystemOutEventParameterName(systemPort, event, parameter))) {
					val ids = getTargetOutEventParameterNames(
						event, eventsMatch.port, parameter, eventsMatch.instance)
					// TODO what about complex types
					return ids.head
				}
			}
		}
		throw new IllegalArgumentException("Not known system parameter event: " + portEventParameterName)
	}
	
	//
	
	protected abstract def String getTargetStateName(State state, Region parentRegion,
		SynchronousComponentInstance instance)
	
	protected abstract def List<String> getTargetVariableNames(VariableDeclaration variable,
		SynchronousComponentInstance instance)
	
	protected abstract def String getTargetOutEventName(Event event, Port port,
		SynchronousComponentInstance instance)
	
	protected abstract def List<String> getTargetOutEventParameterNames(Event event, Port port,
		ParameterDeclaration parameter, SynchronousComponentInstance instance)
	
}