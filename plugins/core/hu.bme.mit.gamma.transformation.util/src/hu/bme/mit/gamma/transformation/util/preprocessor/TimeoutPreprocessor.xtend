/********************************************************************************
 * Copyright (c) 2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util.preprocessor

import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.transformation.util.preprocessor.TimeoutPreprocessor.Namings.*

class TimeoutPreprocessor {
	//
	protected final StatechartDefinition statechart // TODO asynchronous adapter
	//
	protected final extension InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	//
	
	new(StatechartDefinition statechart) {
		this.statechart = statechart
	}
	
	def execute() {
		statechart.execute
	}
	
	//
	
	protected def execute(StatechartDefinition statechart) {
		val timeoutEventMapping  = newHashMap
		
		val _interface = getInterface
		val port = _interface.createPort
		statechart.ports += port
		
		val timeoutEventReferences = statechart.getAllContentsOfType(TimeoutEventReference)
		
		for (timeoutDeclaration : statechart.timeoutDeclarations) {
			val eventDeclaration = timeoutDeclaration.createEventDeclaration
			val event = eventDeclaration.event
			
			_interface.eventDeclarations += eventDeclaration
			timeoutEventMapping += timeoutDeclaration -> event
			
			for (timeoutEventReference : timeoutEventReferences
					.filter[it.timeout === timeoutDeclaration]) {
				val portEventReference = port.createPortEventReference(event)
				portEventReference.replace(timeoutEventReference)
			}
		}
		
		statechart.timeoutDeclarations.removeAll
		statechart.getAllContentsOfType(SetTimeoutAction)
				.forEach[it.remove]
				
		return _interface // Must be saved by the caller
	}
	
	protected def getInterface() {
		// TODO interface optimization
		val _interface = createInterface => [
			it.name = statechart.interfaceName
		]
		return _interface
	}
	
	protected def createPort(Interface _interface) {
		val name = _interface.portName
		val port = _interface.createPort(name)
		return port
	}
	
	protected def createEventDeclaration(TimeoutDeclaration timeoutDeclaration) {
		// TODO event optimization
		val event = createEvent => [
			it.name = timeoutDeclaration.timeoutEventName
		]
		val eventDeclaration = createEventDeclaration => [
			it.event = event
			it.direction = EventDirection.OUT
		]
		return eventDeclaration
	}
	
	//
	
	static class Namings {
		
		static def String getInterfaceName(Component component) '''TimeoutInterfaceOf«component.name»'''
		static def String getPortName(Interface _interface) '''«_interface.name»'''
		
		static def String getTimeoutEventName(TimeoutDeclaration timeoutDeclaration) '''«timeoutDeclaration.name»'''
		
	}
	
}