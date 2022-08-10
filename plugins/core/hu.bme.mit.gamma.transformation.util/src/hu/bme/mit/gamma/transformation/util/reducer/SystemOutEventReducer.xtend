/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util.reducer

import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection
import java.util.Map.Entry
import java.util.logging.Level

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class SystemOutEventReducer implements Reducer {
	
	protected final Component topComponent
	protected final Collection<Entry<Port, Event>> relevantEvents
	//
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	
	new(Component topComponent) {
		this(topComponent, #[])
	}
	new(Component topComponent, Collection<Entry<Port, Event>> relevantEvents) {
		this.topComponent = topComponent
		this.relevantEvents = relevantEvents
	}
	
	override execute() {
		val simplePortsConnectedToSystemPorts = topComponent.allBoundSimplePorts
				.reject[it.isInChannel] // Broadcast ports can be connected using channels, hence the reject
		val components = simplePortsConnectedToSystemPorts.map[it.containingStatefulComponent].toSet
		for (component : components) {
			val raiseEventActions = component.getAllContentsOfType(RaiseEventAction)
				.filter[simplePortsConnectedToSystemPorts.contains(it.port)]
			for (raiseEventAction : raiseEventActions) {
				val port = raiseEventAction.port
				val event = raiseEventAction.event
				if (port.isOutputEvent(event) /* Must be always true */ &&
						!relevantEvents.exists[it.key == port && it.value == event]) {
					raiseEventAction.remove
					logger.log(Level.INFO, port.name + "-" + event.name + " raising has been deleted")
				}
			}
		}
		
	}
	
}