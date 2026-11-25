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

import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Interface
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import java.util.List
import java.util.Map

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.transformation.util.preprocessor.TimeoutPreprocessor.Namings.*

class TimeoutPreprocessor {
	//
	protected final Component component
	//
	protected final extension InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	//
	protected final Package interfacePackage = createPackage
	protected final Map<Component, List<Port>> timeoutPorts = newHashMap
	//
	
	new(Component component) {
		this.component = component
	}
	
	def execute() {
		component.execute
		interfacePackage.name = component.interfacePackageName
		return interfacePackage // Interface package must be saved by the caller
	}
	
	//
	
	protected def void execute(Component component) {
		if (timeoutPorts.containsKey(component)) {
			return // Already preprocessed in previous execution call
		}
		
		switch (component) {
			StatechartDefinition: {
				component.execute
			}
			AsynchronousAdapter: {
				val wrappedComponent = component.wrappedComponent
				val type = wrappedComponent.type
				type.execute
				val timeoutSubports = timeoutPorts.getOrCreateList(type)
				timeoutPorts.getOrCreateList(component) += timeoutSubports
			}
			CompositeComponent: {
				val componentPackage = component.containingPackage
				val instances = component.derivedComponents
				for (instance : instances) {
					val subcomponent = instance.getDerivedType
					subcomponent.execute
					val timeoutSubports = timeoutPorts.getOrCreateList(subcomponent)
					for (subport : timeoutSubports) {
						val systemPort = subport.clone
						systemPort.name = systemPort.interface.getSystemPortName(instance)
						component.ports += systemPort
						timeoutPorts.getOrCreateList(component) += systemPort
						
						val instancePortReference = instance.createInstancePortReference(subport)
						val portBinding = systemPort.createPortBinding(instancePortReference)
						component.portBindings += portBinding
						
						componentPackage.imports += systemPort.interface.containingPackage
					}
				}
			}
			default:
				throw new IllegalArgumentException("Unknown: " + component)
		}
	}
	
	protected def execute(StatechartDefinition statechart) {
		val timeoutPorts = timeoutPorts.getOrCreateList(statechart)
		
		val timeoutDeclarations = statechart.timeoutDeclarations
		if (!timeoutDeclarations.empty) {
			val timeoutEventMapping  = newHashMap
			
			val _interface = statechart.getInterface
			val port = _interface.createPort
			statechart.ports += port
			timeoutPorts += port
			
			val timeoutEventReferences = statechart.getAllContentsOfType(TimeoutEventReference)
			
			for (timeoutDeclaration : timeoutDeclarations) {
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
			
			val componentPackage = component.containingPackage
			componentPackage.imports += _interface.containingPackage
		}
	}
	
	protected def getInterface(StatechartDefinition statechart) {
		// TODO interface optimization
		val _interface = createInterface => [
			it.name = statechart.interfaceName
		]
		interfacePackage.interfaces += _interface
		return _interface
	}
	
	protected def createPort(Interface _interface) {
		val name = _interface.portName
		val port = _interface.createPort(RealizationMode.REQUIRED, name)
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
		
		static int id = 0
		
		static def String getInterfacePackageName(Component component) '''timeout_interface_package_of_«component.name»'''
		
		static def String getInterfaceName(Component component) '''TimeoutInterfaceOf«component.name»_«id++»'''
		static def String getPortName(Interface _interface) '''«_interface.name»'''
		static def String getSystemPortName(Interface _interface, ComponentInstance instance) '''«_interface.portName»Of«instance.name»'''
		
		static def String getTimeoutEventName(TimeoutDeclaration timeoutDeclaration) '''«timeoutDeclaration.name»'''
		
	}
	
}