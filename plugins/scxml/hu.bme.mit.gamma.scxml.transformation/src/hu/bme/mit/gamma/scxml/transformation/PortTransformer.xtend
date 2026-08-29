/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scxml.transformation

import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.RealizationMode

import static com.google.common.base.Preconditions.checkState
import static hu.bme.mit.gamma.scxml.transformation.Namings.*

class PortTransformer extends AtomicElementTransformer {
	
	protected final extension InterfaceTransformer interfaceTransformer
	
	new(StatechartTraceability traceability) {
		super(traceability)
		
		this.interfaceTransformer = new InterfaceTransformer(traceability)
	}
	
	// Gets or creates an interface and a port realizing the interface in the specified mode.
	def getOrTransformPort(String scxmlPortName,
		String scxmlInterfaceName, RealizationMode realizationMode
	) {
		val gammaInterfaceName = getInterfaceName(scxmlInterfaceName)
		val gammaInterface = interfaceTransformer.getOrTransformInterfaceByName(gammaInterfaceName)
		
		val gammaPortName = getPortName(scxmlPortName)
		val gammaPort = getOrTransformPortByName(gammaInterface, gammaPortName, realizationMode)
		
		return gammaPort
	}
	
	def getOrCreateDefaultPort() {
		val defaultPort = traceability.getDefaultPort
		if (defaultPort !== null) {
			return defaultPort
		}
		else {
			val gammaPort = createDefaultPort
			traceability.setDefaultPort(gammaPort)
			return gammaPort
		}
	}
	
	// We assume that the statechart's default interface already exists at this point.
	protected def createDefaultPort() {
		val defaultInterface = interfaceTransformer.getOrCreateDefaultInterface
			
		val defaultInterfaceRealization = createInterfaceRealization
		defaultInterfaceRealization.realizationMode = RealizationMode.PROVIDED
		defaultInterfaceRealization.interface = defaultInterface
			
		val defaultPort = createPort
		defaultPort.name = getDefaultPortName(traceability.getTypeName())
		defaultPort.interfaceRealization = defaultInterfaceRealization
		
		return defaultPort
	}
	
	def getOrTransformDefaultInterfacePort(Interface gammaInterface) {
		checkState(gammaInterface !== null)
		if (traceability.containsDefaultInterfacePort(gammaInterface)) {
			return traceability.getDefaultInterfacePort(gammaInterface)
		}
		else {
			val gammaPort = transformDefaultInterfacePort(gammaInterface)
			traceability.putDefaultInterfacePort(gammaInterface, gammaPort)
			return gammaPort
		}
	}
	
	// For now, all ports realize their interfaces in provided mode.
	protected def transformDefaultInterfacePort(Interface gammaInterface) {		
		val gammaInterfaceRealization = createInterfaceRealization
		gammaInterfaceRealization.realizationMode = RealizationMode.PROVIDED
		gammaInterfaceRealization.interface = gammaInterface
		
		val gammaPort = createPort
		val gammaInterfaceName = gammaInterface.name
		gammaPort.name = getDefaultInterfacePortName(gammaInterfaceName)
		gammaPort.interfaceRealization = gammaInterfaceRealization
		
		return gammaPort
	}
	
	def getOrTransformPortByName(Interface gammaInterface,
		String portName, RealizationMode realizationMode
	) {
		checkState(gammaInterface !== null)
		checkState(portName !== null)
		checkState(realizationMode !== null)
		
		if (traceability.containsPort(portName)) {
			return traceability.getPort(portName)
		}
		else {
			val gammaPort = transformPortByName(gammaInterface, portName, realizationMode)
			traceability.putPort(portName, gammaPort)
			return gammaPort
		}
	}
	
	protected def transformPortByName(Interface gammaInterface,
		String portName, RealizationMode realizationMode
	) {		
		val gammaInterfaceRealization = createInterfaceRealization
		gammaInterfaceRealization.realizationMode = realizationMode
		gammaInterfaceRealization.interface = gammaInterface
		
		val gammaPort = createPort
		gammaPort.name = getPortName(portName)
		gammaPort.interfaceRealization = gammaInterfaceRealization
		
		return gammaPort
	}
	
}