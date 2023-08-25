/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.Transition
import java.util.Collection
import java.util.Map

class Trace {
	
	// Proxy port (environment model port towards the environment)
	// Environment port (environment model port towards the component)
	// Component port (original component port towards the environment model)
	
	final Map<Port, Port> componentEnvironmentPorts = newLinkedHashMap
	final Map<Port, Port> componentProxyPorts = newLinkedHashMap
	final Map<Port, Port> proxyEnvironmentPorts = newLinkedHashMap // Proxy port -> environment port -> component port
	
	// Last states
	
	final Collection<Transition> firstStepTransitions = newLinkedHashSet
	
	State lastOutState
	
	// Component-environment ports
	
	def putComponentEnvironmentPort(Port componentPort, Port environmentPort) {
		return componentEnvironmentPorts.put(componentPort, environmentPort)
	}
	
	def getComponentEnvironmentPort(Port componentPort) {
		return componentEnvironmentPorts.get(componentPort)
	}
	
	def getComponentEnvironmentPortPairs() { // Need to be connected via a channel
		return componentEnvironmentPorts.entrySet
	}
	
	// Component-proxy ports
	
	def putComponentProxyPort(Port componentPort, Port proxyPort) {
		return componentProxyPorts.put(componentPort, proxyPort)
	}
	
	def getComponentProxyPort(Port componentPort) {
		return componentProxyPorts.get(componentPort)
	}
	
	// Proxy-environment ports
	
	def putProxyEnvironmentPort(Port proxyPort, Port environmentPort) {
		return proxyEnvironmentPorts.put(proxyPort, environmentPort)
	}
	
	def getProxyEnvironmentPort(Port proxyPort) {
		return proxyEnvironmentPorts.get(proxyPort)
	}
	
	def getProxyEnvironmentPortPairs() {
		return proxyEnvironmentPorts.entrySet
	}
	
	// Last states
	
	def addFirstStepTransitions(Iterable<? extends Transition> transitions) {
		firstStepTransitions += transitions
	}
	
	def addFirstStepTransition(Transition transition) {
		firstStepTransitions += transition
	}
	
	def isFirstStepTransition(Transition transition) {
		return firstStepTransitions.contains(transition)
	}
	
	def setLastOutState(State lastOutState) {
		this.lastOutState = lastOutState
	}
	
	def getLastOutState() {
		return lastOutState
	}
	
}