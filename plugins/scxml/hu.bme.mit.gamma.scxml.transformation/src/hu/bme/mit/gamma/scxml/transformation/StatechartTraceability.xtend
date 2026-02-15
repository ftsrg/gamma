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

import ac.soton.scxml.ScxmlDataType
import ac.soton.scxml.ScxmlFinalType
import ac.soton.scxml.ScxmlHistoryType
import ac.soton.scxml.ScxmlInitialType
import ac.soton.scxml.ScxmlParallelType
import ac.soton.scxml.ScxmlScxmlType
import ac.soton.scxml.ScxmlStateType
import ac.soton.scxml.ScxmlTransitionType
import hu.bme.mit.gamma.expression.model.ConstantDeclaration
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.EntryState
import hu.bme.mit.gamma.statechart.statechart.InitialState
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.SynchronousStatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Map
import java.util.Set
import org.eclipse.emf.ecore.EObject

import static com.google.common.base.Preconditions.checkNotNull

class StatechartTraceability {

	// Reference to the composite transformation traceability model
	protected final CompositeTraceability compositeTraceability

	// URI of the root SCXML statechart model to transform
	protected final String fileURI

	// Root element of the atomic SCXML statechart model to transform.
	protected ScxmlScxmlType scxmlRoot
	protected SynchronousStatechartDefinition statechart
	protected AsynchronousAdapter adapter
	protected ConstantDeclaration queueCapacity

	protected final Map<ScxmlParallelType, State> parallels = newHashMap
	protected final Map<ScxmlStateType, State> states = newHashMap
	protected final Map<ScxmlFinalType, State> finals = newHashMap
	protected final Map<ScxmlInitialType, InitialState> initials = newHashMap
	protected final Map<ScxmlHistoryType, EntryState> historyStates = newHashMap
	protected final Map<ScxmlTransitionType, Transition> transitions = newHashMap
	protected final Set<Transition> initialTransitions = newHashSet

	protected final Map<ScxmlDataType, Declaration> dataElements = newHashMap
	protected final Map<String, ParameterDeclaration> parameters = newHashMap
	// The variables map works only if variables are globally unique and have a global scope
	protected final Map<String, VariableDeclaration> variables = newHashMap

	// Internal mappings (internal to the statechart)
	protected Port defaultPort
	protected Interface defaultInterface
	protected final Map<Interface, Port> defaultInterfacePorts = newHashMap
	protected final Map<String, Port> ports = newHashMap

	// Global mappings (from composite traceability)
	protected final Map<String, Interface> interfaces
	protected final Map<Pair<Interface, String>, Event> internalEvents
	protected final Map<Pair<Interface, String>, Event> inEvents
	protected final Map<Pair<Interface, String>, Event> outEvents
	protected final Map<String, Event> allEvents
	protected final Map<String, ParameterDeclaration> allEventParameters

	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE

	// <scxml> - Synchronous Statechart Definition
	new(
		CompositeTraceability compositeTraceability,
		String rootFileURI,
		Map<String, Interface> interfaces,
		ConstantDeclaration queueCapacity,
		Map<Pair<Interface, String>, Event> internalEvents,
		Map<Pair<Interface, String>, Event> inEvents,
		Map<Pair<Interface, String>, Event> outEvents,
		Map<String, Event> allEvents,
		Map<String, ParameterDeclaration> allEventParameters
	) {
		this.compositeTraceability = compositeTraceability
		this.fileURI = rootFileURI
		this.interfaces = interfaces
		this.queueCapacity = queueCapacity
		this.internalEvents = internalEvents
		this.inEvents = inEvents
		this.outEvents = outEvents
		this.allEvents = allEvents
		this.allEventParameters = allEventParameters
	}

	def getScxmlRoot() {
		return scxmlRoot
	}

	def getTypeName() {
		return scxmlRoot.name
	}

	def setAdapter(AsynchronousAdapter adapter) {
		this.adapter = adapter
	}

	def getAdapter() {
		return adapter
	}

	def getQueueCapacityDeclaration() {
		checkNotNull(queueCapacity)
		return queueCapacity
	}

	def setStatechart(SynchronousStatechartDefinition gammaStatechart) {
		checkNotNull(gammaStatechart)
		statechart = gammaStatechart
	}

	def getStatechart() {
		return statechart
	}

	// <parallel> - State (with orthogonal Region children)
	def put(ScxmlParallelType scxmlParallel, State gammaParallel) {
		checkNotNull(scxmlParallel)
		checkNotNull(gammaParallel)
		parallels += scxmlParallel -> gammaParallel
	}

	def getParallel(ScxmlParallelType scxmlParallel) {
		checkNotNull(scxmlParallel)
		val gammaParallel = parallels.get(scxmlParallel)
		checkNotNull(gammaParallel)
		return gammaParallel
	}

	def getParallelById(String scxmlParallelId) {
		checkNotNull(scxmlParallelId)
		val keySet = states.keySet
		val scxmlParallel = keySet.findFirst[parallel|parallel.id == scxmlParallelId]
		checkNotNull(scxmlParallel)
		return getState(scxmlParallel)
	}

	// <state> - State (with a Region child if it is compound)
	def put(ScxmlStateType scxmlState, State gammaState) {
		checkNotNull(scxmlState)
		checkNotNull(gammaState)
		states += scxmlState -> gammaState
	}

	def getState(ScxmlStateType scxmlState) {
		checkNotNull(scxmlState)
		val gammaState = states.get(scxmlState)
		checkNotNull(gammaState)
		return gammaState
	}

	def getStateById(String scxmlStateId) {
		checkNotNull(scxmlStateId)
		val keySet = states.keySet
		val scxmlState = keySet.findFirst[state|state.id == scxmlStateId]
		checkNotNull(scxmlState)
		return getState(scxmlState)
	}

	// <final> - State
	def put(ScxmlFinalType scxmlFinal, State gammaFinal) {
		checkNotNull(scxmlFinal)
		checkNotNull(gammaFinal)
		finals += scxmlFinal -> gammaFinal
	}

	def getFinalState(ScxmlFinalType scxmlFinal) {
		checkNotNull(scxmlFinal)
		val gammaFinal = finals.get(scxmlFinal)
		checkNotNull(gammaFinal)
		return gammaFinal
	}

	def getFinalById(String scxmlFinalId) {
		checkNotNull(scxmlFinalId)
		val keySet = finals.keySet
		val scxmlFinal = keySet.findFirst[final|final.id == scxmlFinalId]
		checkNotNull(scxmlFinal)
		return getFinalState(scxmlFinal)
	}

	// <initial> - InitialState
	def put(ScxmlInitialType scxmlInitial, InitialState gammaInitial) {
		checkNotNull(scxmlInitial)
		checkNotNull(gammaInitial)
		initials += scxmlInitial -> gammaInitial
	}

	def getInitialState(ScxmlInitialType scxmlInitial) {
		checkNotNull(scxmlInitial)
		val gammaInitial = initials.get(scxmlInitial)
		checkNotNull(gammaInitial)
		return gammaInitial
	}

	// <history> - ShallowHistoryState or DeepHistoryState (stored as an EntryState)
	def put(ScxmlHistoryType scxmlHistory, EntryState gammaHistory) {
		checkNotNull(scxmlHistory)
		checkNotNull(gammaHistory)
		historyStates += scxmlHistory -> gammaHistory
	}

	def getHistoryState(ScxmlHistoryType scxmlHistory) {
		checkNotNull(scxmlHistory)
		val gammaHistory = historyStates.get(scxmlHistory)
		checkNotNull(gammaHistory)
		return gammaHistory
	}

	def getHistoryStateById(String scxmlHistoryId) {
		checkNotNull(scxmlHistoryId)
		val keySet = historyStates.keySet
		val scxmlHistory = keySet.findFirst[history|history.id == scxmlHistoryId]
		checkNotNull(scxmlHistory)
		return getHistoryState(scxmlHistory)
	}

	// General functions returning a mapped Gamma StateNode
	// Retrieves the mapped Gamma StateNode for an arbitrary transition source state
	def getStateNode(EObject scxmlStateNode) {
		val gammaState = states.get(scxmlStateNode)
		if (gammaState !== null) {
			return gammaState as StateNode
		}
		val gammaParallel = parallels.get(scxmlStateNode)
		if (gammaParallel !== null) {
			return gammaParallel as StateNode
		}
		val gammaInitial = initials.get(scxmlStateNode)
		if (gammaInitial !== null) {
			return gammaInitial as StateNode
		}
		val gammaHistory = historyStates.get(scxmlStateNode)
		checkNotNull(gammaHistory)
		return gammaHistory as StateNode
	}

	// Retrieves the mapped Gamma StateNode for an arbitrary transition target state id
	def getStateNodeById(String scxmlStateNodeId) {
		val gammaState = states.entrySet.findFirst[entry|entry.key.id == scxmlStateNodeId]?.value
		if (gammaState !== null) {
			return gammaState
		}
		val gammaParallel = parallels.entrySet.findFirst[entry|entry.key.id == scxmlStateNodeId]?.value
		if (gammaParallel !== null) {
			return gammaParallel
		}
		val gammaFinal = finals.entrySet.findFirst[entry|entry.key.id == scxmlStateNodeId]?.value
		if (gammaFinal !== null) {
			return gammaFinal
		}
		val gammaHistory = historyStates.entrySet.findFirst[entry|entry.key.id == scxmlStateNodeId]?.value
		checkNotNull(gammaHistory)
		return gammaHistory

	}

	// <transition> - Transition
	def put(ScxmlTransitionType scxmlTransition, Transition gammaTransition) {
		checkNotNull(scxmlTransition)
		checkNotNull(gammaTransition)
		transitions += scxmlTransition -> gammaTransition
	}

	def getTransition(ScxmlTransitionType scxmlTransition) {
		checkNotNull(scxmlTransition)
		val gammaTransition = transitions.get(scxmlTransition)
		checkNotNull(gammaTransition)
		return gammaTransition
	}

	// Transitions from initial states of Gamma compound states
	// specified by scxml initial attributes or document order
	def putInitialTransition(Transition gammaTransition) {
		checkNotNull(gammaTransition)
		initialTransitions += gammaTransition
	}

	def getInitialTransitions() {
		return initialTransitions
	}

	// <data> - ParameterDeclaration
	def put(ScxmlDataType scxmlData, ParameterDeclaration gammaDeclaration) {
		checkNotNull(scxmlData)
		checkNotNull(gammaDeclaration)
		dataElements += scxmlData -> gammaDeclaration

		put(scxmlData.id, gammaDeclaration)
	}

	def getParameter(ScxmlDataType scxmlData) {
		checkNotNull(scxmlData)
		val gammaDeclaration = dataElements.get(scxmlData)
		checkNotNull(gammaDeclaration)
		return gammaDeclaration
	}

	// <data> - VariableDeclaration
	def put(ScxmlDataType scxmlData, VariableDeclaration gammaDeclaration) {
		checkNotNull(scxmlData)
		checkNotNull(gammaDeclaration)
		dataElements += scxmlData -> gammaDeclaration

		put(scxmlData.id, gammaDeclaration)
	}

	def getVariable(ScxmlDataType scxmlData) {
		checkNotNull(scxmlData)
		val gammaDeclaration = dataElements.get(scxmlData)
		checkNotNull(gammaDeclaration)
		return gammaDeclaration
	}

	// Parameter Declarations by String identifier
	private def put(String scxmlParameterName, ParameterDeclaration gammaDeclaration) {
		checkNotNull(scxmlParameterName)
		checkNotNull(gammaDeclaration)
		parameters += scxmlParameterName -> gammaDeclaration
	}

	def containsParameter(String scxmlParameterName) {
		checkNotNull(scxmlParameterName)
		return parameters.containsKey(scxmlParameterName)
	}

	def getParameter(String scxmlParameterName) {
		checkNotNull(scxmlParameterName)
		val gammaDeclaration = parameters.get(scxmlParameterName)
		checkNotNull(gammaDeclaration)
		return gammaDeclaration
	}

	// Variable Declarations by String identifier
	private def put(String scxmlVariableName, VariableDeclaration gammaDeclaration) {
		checkNotNull(scxmlVariableName)
		checkNotNull(gammaDeclaration)
		variables += scxmlVariableName -> gammaDeclaration
	}

	def containsVariable(String scxmlVariableName) {
		checkNotNull(scxmlVariableName)
		return variables.containsKey(scxmlVariableName)
	}

	def getVariable(String scxmlVariableName) {
		checkNotNull(scxmlVariableName)
		val gammaDeclaration = variables.get(scxmlVariableName)
		checkNotNull(gammaDeclaration)
		return gammaDeclaration
	}

	// Default port and interface (for event strings like 'event')
	def getDefaultInterface() {
		return defaultInterface
	}

	def setDefaultInterface(Interface defaultInterface) {
		this.defaultInterface = defaultInterface
	}

	def getDefaultPort() {
		return defaultPort
	}

	def setDefaultPort(Port defaultPort) {
		this.defaultPort = defaultPort
	}

	// Default ports of interfaces (for event strings like 'interface.event')
	def putDefaultInterfacePort(Interface gammaInterface, Port gammaPort) {
		checkNotNull(gammaInterface)
		checkNotNull(gammaPort)
		defaultInterfacePorts += gammaInterface -> gammaPort
	}

	def getDefaultInterfacePort(Interface gammaInterface) {
		checkNotNull(gammaInterface)
		val gammaPort = defaultInterfacePorts.get(gammaInterface)
		checkNotNull(gammaPort)
		return gammaPort
	}

	def containsDefaultInterfacePort(Interface gammaInterface) {
		checkNotNull(gammaInterface)
		return defaultInterfacePorts.containsKey(gammaInterface)
	}

	// Interfaces by string identifier (for event strings like '[port.]interface.event)
	def putInterface(String scxmlInterfaceName, Interface gammaInterface) {
		checkNotNull(scxmlInterfaceName)
		checkNotNull(gammaInterface)
		interfaces += scxmlInterfaceName -> gammaInterface
	}

	def getInterface(String scxmlInterfaceName) {
		checkNotNull(scxmlInterfaceName)
		val gammaInterface = interfaces.get(scxmlInterfaceName)
		checkNotNull(gammaInterface)
		return gammaInterface
	}

	def containsInterface(String scxmlInterfaceName) {
		checkNotNull(scxmlInterfaceName)
		return interfaces.containsKey(scxmlInterfaceName)
	}

	def getInterfaces() {
		return interfaces;
	}

	def getAllInterfaces() {
		var allInterfaces = interfaces.values.toList
		allInterfaces += defaultInterfacePorts.keySet.toList
		if (getDefaultInterface !== null) {
			allInterfaces += getDefaultInterface
		}
		return allInterfaces
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

	// Internal events by pairs of {Gamma interface; event name}
	def putInternalEvent(Pair<Interface, String> interfaceEvent, Event gammaEvent) {
		checkNotNull(interfaceEvent)
		checkNotNull(interfaceEvent.key)
		checkNotNull(interfaceEvent.value)
		checkNotNull(gammaEvent)

		val interface = interfaceEvent.key
		val eventName = interfaceEvent.value
		internalEvents += (interface -> eventName) -> gammaEvent

		putEvent(eventName, gammaEvent)
	}

	def getInternalEvent(Pair<Interface, String> interfaceEvent) {
		checkNotNull(interfaceEvent)
		checkNotNull(interfaceEvent.key)
		checkNotNull(interfaceEvent.value)

		val interface = interfaceEvent.key
		val eventName = interfaceEvent.value
		val gammaEvent = internalEvents.get(interface -> eventName)

		checkNotNull(gammaEvent)
		return gammaEvent
	}

	def containsInternalEvent(Pair<Interface, String> interfaceEvent) {
		checkNotNull(interfaceEvent)
		checkNotNull(interfaceEvent.key)
		checkNotNull(interfaceEvent.value)

		val interface = interfaceEvent.key
		val eventName = interfaceEvent.value
		return internalEvents.containsKey(interface -> eventName)
	}

	// Input events by pairs of {Gamma interface; event name}
	def putInEvent(Pair<Interface, String> interfaceEvent, Event gammaEvent) {
		checkNotNull(interfaceEvent)
		checkNotNull(interfaceEvent.key)
		checkNotNull(interfaceEvent.value)
		checkNotNull(gammaEvent)

		val interface = interfaceEvent.key
		val eventName = interfaceEvent.value
		inEvents += (interface -> eventName) -> gammaEvent

		putEvent(eventName, gammaEvent)
	}

	def getInEvent(Pair<Interface, String> interfaceEvent) {
		checkNotNull(interfaceEvent)
		checkNotNull(interfaceEvent.key)
		checkNotNull(interfaceEvent.value)

		val interface = interfaceEvent.key
		val eventName = interfaceEvent.value
		val gammaEvent = inEvents.get(interface -> eventName)

		checkNotNull(gammaEvent)
		return gammaEvent
	}

	def containsInEvent(Pair<Interface, String> interfaceEvent) {
		checkNotNull(interfaceEvent)
		checkNotNull(interfaceEvent.key)
		checkNotNull(interfaceEvent.value)

		val interface = interfaceEvent.key
		val eventName = interfaceEvent.value
		return inEvents.containsKey(interface -> eventName)
	}

	// Output events by pairs of {port name; event name}
	def putOutEvent(Pair<Interface, String> interfaceEvent, Event gammaEvent) {
		checkNotNull(interfaceEvent)
		checkNotNull(interfaceEvent.key)
		checkNotNull(interfaceEvent.value)
		checkNotNull(gammaEvent)

		val interface = interfaceEvent.key
		val eventName = interfaceEvent.value
		outEvents += (interface -> eventName) -> gammaEvent

		putEvent(eventName, gammaEvent)
	}

	def getOutEvent(Pair<Interface, String> interfaceEvent) {
		checkNotNull(interfaceEvent)
		checkNotNull(interfaceEvent.key)
		checkNotNull(interfaceEvent.value)

		val interface = interfaceEvent.key
		val eventName = interfaceEvent.value
		val gammaEvent = outEvents.get(interface -> eventName)

		checkNotNull(gammaEvent)
		return gammaEvent
	}

	def containsOutEvent(Pair<Interface, String> interfaceEvent) {
		checkNotNull(interfaceEvent)
		checkNotNull(interfaceEvent.key)
		checkNotNull(interfaceEvent.value)

		val interface = interfaceEvent.key
		val eventName = interfaceEvent.value
		return outEvents.containsKey(interface -> eventName)
	}

	// Events by string identifier
	def putEvent(String scxmlEventName, Event gammaEvent) {
		checkNotNull(scxmlEventName)
		checkNotNull(gammaEvent)
		allEvents += scxmlEventName -> gammaEvent
	}

	def getEvent(String scxmlEventName) {
		checkNotNull(scxmlEventName)
		val gammaEvent = allEvents.get(scxmlEventName)
		checkNotNull(gammaEvent)
		return gammaEvent
	}

	def containsEvent(String scxmlEventName) {
		checkNotNull(scxmlEventName)
		return allEvents.containsKey(scxmlEventName)
	}

	// Event parameters by string identifier
	def putEventParameter(String scxmlEventParameterName, ParameterDeclaration gammaEventParameter) {
		checkNotNull(scxmlEventParameterName)
		checkNotNull(gammaEventParameter)
		allEventParameters += scxmlEventParameterName -> gammaEventParameter
	}

	def getEventParameter(String scxmlEventParameterName) {
		checkNotNull(scxmlEventParameterName)
		val gammaEventParameter = allEventParameters.get(scxmlEventParameterName)
		checkNotNull(gammaEventParameter)
		return gammaEventParameter
	}

	def containsEventParameter(String scxmlEventParameterName) {
		checkNotNull(scxmlEventParameterName)
		return allEventParameters.containsKey(scxmlEventParameterName)
	}

}
