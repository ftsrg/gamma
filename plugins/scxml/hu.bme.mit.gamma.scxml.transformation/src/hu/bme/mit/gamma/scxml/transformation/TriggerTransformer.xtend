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
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.RealizationMode

class TriggerTransformer extends AtomicElementTransformer {

	protected final extension PortTransformer portTransformer
	protected final extension InterfaceTransformer interfaceTransformer
	protected final extension EventTransformer eventTransformer

	new(StatechartTraceability traceability) {
		super(traceability)

		this.portTransformer = new PortTransformer(traceability)
		this.interfaceTransformer = new InterfaceTransformer(traceability)
		this.eventTransformer = new EventTransformer(traceability)
	}

	// TODO sanitize and check eventString
	def transformTrigger(String eventString) {
		val tokens = eventString.split("\\.")
		if (tokens.size < 1 || tokens.size > 3) {
			throw new IllegalArgumentException(
				"Event descriptor " + eventString + " does not contain exactly 1, 2 or 3 dot separated tokens."
			)
		}

		var gammaInterface = null as Interface
		var gammaPort = null as Port
		var isDefault = false

		if (tokens.size == 1) {
			isDefault = true
			gammaInterface = getOrCreateDefaultInterface()
			gammaPort = getOrCreateDefaultPort()
		} else {
			val interfaceName = tokens.get(tokens.size - 2)
			gammaInterface = getOrTransformInterfaceByName(interfaceName)

			if (tokens.size >= 3) {
				val portName = tokens.head
				gammaPort = getOrTransformPortByName(gammaInterface, portName, RealizationMode.REQUIRED)
			} else {
				isDefault = true
				gammaPort = getOrTransformDefaultInterfacePort(gammaInterface)
			}
		}

		val eventName = tokens.lastOrNull

		// If a port is specified, the event will be an out event on an interface
		// realized in required mode by the port receiving the event.
		// In the case of default interfaces and ports, realization mode is provided
		// and trigger events are internal.
		val gammaEvent = if (isDefault) {
				getOrTransformInternalEvent(gammaInterface, eventName)
			} else {
				getOrTransformOutEvent(gammaInterface, eventName)
			}

		val gammaEventReference = createPortEventReference
		gammaEventReference.port = gammaPort
		gammaEventReference.event = gammaEvent

		val gammaEventTrigger = createEventTrigger
		gammaEventTrigger.eventReference = gammaEventReference
		return gammaEventTrigger
	}

}
