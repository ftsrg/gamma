/********************************************************************************
 * Copyright (c) 2023-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.ScxmlInvokeType
import ac.soton.scxml.ScxmlScxmlType
import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.Port
import java.util.List
import java.util.Map

import static com.google.common.base.Preconditions.checkNotNull

class CompositeTraceability {

	// URI of the root SCXML statechart model to transform
	protected final String rootFileURI

	// Resulting root component
	protected Component rootComponent

	// Default message queue capacity
	protected ConstantDeclaration queueCapacity

	// TODO Add interfaces, events, ports, bindings and channels
	// (Needed for the declarations package and serialization of the components package.)
	protected final Map<String, StatechartTraceability> statecharts = newHashMap
	protected final Map<ScxmlInvokeType, AsynchronousComponentInstance> instances = newHashMap
	protected final Map<String, Port> ports = newHashMap

	// Global mappings: Interfaces, events, declarations
	protected final Map<String, Interface> interfaces = newHashMap
	protected final Map<Pair<Interface, String>, Event> internalEvents = newHashMap
	protected final Map<Pair<Interface, String>, Event> inEvents = newHashMap
	protected final Map<Pair<Interface, String>, Event> outEvents = newHashMap
	protected final Map<String, Event> allEvents = newHashMap
	protected final Map<String, ParameterDeclaration> allEventParameters = newHashMap

	// <scxml> - Asynchronous Component
	new(String rootFileURI) {
		this.rootFileURI = rootFileURI
	}

	// Creates a traceability object for the Gamma transformation of
	// the SCXML statechart model found at rootFileURI.
	def createStatechartTraceability(String rootFileURI) {
		return new StatechartTraceability(
			this,
			rootFileURI,
			interfaces,
			queueCapacity,
			internalEvents,
			inEvents,
			outEvents,
			allEvents,
			allEventParameters
		)
	}

	// TODO Get from statecharts or instances map by rootFileURI string, if needed
	def getScxmlRoot() {
		val rootTraceability = getTraceability(rootFileURI)
		val rootScxmlElement = rootTraceability.scxmlRoot
		checkNotNull(rootScxmlElement)
		return rootScxmlElement
	}

	def getRootComponent() {
		val rootTraceability = getTraceability(rootFileURI)

		// TODO Which kind of root Gamma component should we return? statechart / adapter / other?
		val rootComponent = rootTraceability.statechart
		checkNotNull(rootComponent)
		return rootComponent
	}

	def setRootComponent(Component rootComponent) {
		this.rootComponent = rootComponent
	}

	def getQueueCapacityDeclaration() {
		return queueCapacity
	}

	def setQueueCapacity(ConstantDeclaration capacity) {
		this.queueCapacity = capacity
	}

	// String URI of the SCXML statechart definition source - Statechart Traceability
	def putTraceability(String statechartUri, StatechartTraceability statechartTraceability) {
		checkNotNull(statechartUri)
		checkNotNull(statechartTraceability)
		statecharts += statechartUri -> statechartTraceability
	}

	def getTraceability(String statechartUri) {
		checkNotNull(statechartUri)
		val statechartTraceability = statecharts.get(statechartUri)
		checkNotNull(statechartTraceability)
		return statechartTraceability
	}

	// TODO Simplify map structure and getter.
	def getTraceabilityById(String scxmlInvokeId) {
		checkNotNull(scxmlInvokeId)
		val invoke = instances.keySet.findFirst[invoke|invoke.id == scxmlInvokeId]
		checkNotNull(invoke)
		val statechartTraceability = statecharts.filter[source, _|source == invoke.src].values.head
		checkNotNull(statechartTraceability)
		return statechartTraceability
	}

	def getTraceability(ScxmlScxmlType scxmlRoot) {
		checkNotNull(scxmlRoot)
		val statechartTraceability = statecharts.values.findFirst[it.scxmlRoot === scxmlRoot]
		checkNotNull(statechartTraceability)
		return statechartTraceability
	}

	def containsTraceability(String statechartUri) {
		checkNotNull(statechartUri)
		return statecharts.containsKey(statechartUri)
	}

	// <invoke> - Asynchronous Component Instance
	def putComponentInstance(ScxmlInvokeType scxmlInvoke, AsynchronousComponentInstance instance) {
		checkNotNull(scxmlInvoke)
		checkNotNull(instance)
		instances += scxmlInvoke -> instance
	}

	def getComponentInstance(ScxmlInvokeType scxmlInvoke) {
		checkNotNull(scxmlInvoke)
		val instance = instances.get(scxmlInvoke)
		checkNotNull(instance)
		return instance
	}

	def getComponentInstance(String scxmlInvokeId) {
		checkNotNull(scxmlInvokeId)
		val instance = instances.filter[invoke, _|invoke.id == scxmlInvokeId].values.head
		checkNotNull(instance)
		return instance
	}

	// Ports by string identifier (for event strings like 'port.interface.event)
	def putPort(String scxmlPortName, Port gammaPort) {
		checkNotNull(scxmlPortName)
		checkNotNull(gammaPort)
		ports += scxmlPortName -> gammaPort
	}

	def getPort(String scxmlPortName) {
		checkNotNull(scxmlPortName)
		val gammaPort = ports.get(scxmlPortName)
		checkNotNull(gammaPort)
		return gammaPort
	}

	def containsPort(String scxmlPortName) {
		checkNotNull(scxmlPortName)
		return ports.containsKey(scxmlPortName)
	}

	//

	def getInEvents() {
		return inEvents
	}

	def getOutEvents() {
		return outEvents
	}

	def getInstances() {
		return instances
	}

	def getStatecharts() {
		return statecharts.values.toList
	}

	//

	def getConstantDeclarations() {
		return List.of(queueCapacity)
	}

	def getInterfaces() {
		val statechartTraceabilities = statecharts.values
		return (
			interfaces.values +
			statechartTraceabilities.map[it.defaultInterface] +
			statechartTraceabilities.map[it.defaultInterfacePorts.keySet].flatten
		).toSet
	}

	def getComponents() {
		val statechartTraceabilities = statecharts.values
		return (
			instances.values.map[it.getType] +
			/* TODO Serialize async adapters */
			/* statechartTraceabilities.map[it.getAdapter] + */
			statechartTraceabilities.map[it.getStatechart]
		).toSet
	}

}
