/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.constraint.model.Declaration
import hu.bme.mit.gamma.statechart.model.AnyPortEventReference
import hu.bme.mit.gamma.statechart.model.Component
import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.PortEventReference
import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.BroadcastChannel
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.SimpleChannel
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import java.util.AbstractMap.SimpleEntry
import java.util.Collection
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil.Copier
import org.eclipse.emf.ecore.util.EcoreUtil.EqualityHelper
import hu.bme.mit.gamma.statechart.model.EventTrigger
import hu.bme.mit.gamma.statechart.model.ClockTickReference

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class ModelUnfolder {
	
	def unfold(Package gammaPackage) {
		val clonedPackage = gammaPackage.clone(true, true) as Package => [
			it.imports.clear // Clearing the imports as no reference will be needed in the "Instance container"
			it.typeDeclarations.clear
			// Retrieve correct type declaration objects
			it.typeDeclarations += gammaPackage.typeDeclarations
			for (import : gammaPackage.imports) {
				it.typeDeclarations += import.typeDeclarations
			}
			it.name = it.name + "View"
		]
		val topComponent = clonedPackage.component
		topComponent.copyComponents(clonedPackage, "")
		// Resolving potential name collisions
		clonedPackage.constantDeclarations.resolveNameCollisions
		clonedPackage.functionDeclarations.resolveNameCollisions
		// The created package, and the top component are returned
		return new SimpleEntry<Package, Component>(clonedPackage, topComponent)
	}
	
	private dispatch def void copyComponents(Component component, Package gammaPackage, String containerInstanceName) {
		// Simple stateharts are already cloned
	}
	
	private dispatch def void copyComponents(AbstractSynchronousCompositeComponent component, Package gammaPackage, String containerInstanceName) {
		for (instance : component.components) {
			val type = instance.type
			val clonedPackage = type.eContainer.clone(true, true) as Package
			gammaPackage.constantDeclarations += clonedPackage.constantDeclarations
			gammaPackage.functionDeclarations += clonedPackage.functionDeclarations
			// Declarations have been moved
			val clonedComponent = clonedPackage.components.findFirst[it.helperEquals(type)] as SynchronousComponent // Sync Composite or Statechart
			gammaPackage.components += clonedComponent // Adding it to the "Instance container"
			instance.type = clonedComponent // Setting the type to the new declaration
			// Changing the port binding
			fixPortBindings(component, instance)
			// Changing the providedPort references of Channels
			fixChannelProvidedPorts(component, instance)
			// Changing the requiredPort references of Channels
			fixChannelRequiredPorts(component, instance)
			if (clonedComponent instanceof AbstractSynchronousCompositeComponent) {
				clonedComponent.copyComponents(gammaPackage, containerInstanceName + instance.name + "_") // Cloning the contained CompositeSystems recursively
			}
			// Renames because of unique UPPAAL variable names and well-functioning back-annotation capabilities
			instance.name = containerInstanceName + instance.name 
		}
	}
	
	private dispatch def void copyComponents(AsynchronousCompositeComponent component, Package gammaPackage, String containerInstanceName) {
		for (instance : component.components) {
			val type = instance.type
			if (type instanceof AsynchronousCompositeComponent) {
				val clonedPackage = type.eContainer.clone(true, true) as Package
				gammaPackage.constantDeclarations += clonedPackage.constantDeclarations
				gammaPackage.functionDeclarations += clonedPackage.functionDeclarations
				// Declarations have been moved		
				val clonedComposite = clonedPackage.components.findFirst[it.helperEquals(type)] as AsynchronousCompositeComponent // Cloning the declaration
				gammaPackage.components += clonedComposite // Adding it to the "Instance container"
				instance.type = clonedComposite // Setting the type to the new declaration
				clonedComposite.copyComponents(gammaPackage, containerInstanceName + instance.name + "_") // Cloning the contained CompositeSystems recursively
			}
			else if (type instanceof AsynchronousAdapter) {
				val clonedPackage = type.eContainer.clone(true, true) as Package
				gammaPackage.constantDeclarations += clonedPackage.constantDeclarations
				gammaPackage.functionDeclarations += clonedPackage.functionDeclarations
				// Declarations have been moved
				val clonedWrapper = clonedPackage.components.findFirst[it.helperEquals(type)] as AsynchronousAdapter // Cloning the declaration
				gammaPackage.components += clonedWrapper // Adding it to the "Instance container"
				instance.type = clonedWrapper // Setting the type to the new declaration
				clonedWrapper.copyComponents(gammaPackage, containerInstanceName + instance.name + "_") // Cloning the contained CompositeSystems recursively
			}
			// Changing the port binding
			fixPortBindings(component, instance)
			// Changing the providedPort references of Channels
			fixChannelProvidedPorts(component, instance)
			// Changing the requiredPort references of Channels
			fixChannelRequiredPorts(component, instance)
			// Renames because of unique UPPAAL variable names and well-functioning back-annotation capabilities
			instance.name = containerInstanceName + instance.name 
		}
	}
	
	private dispatch def void copyComponents(AsynchronousAdapter component, Package gammaPackage, String containerInstanceName) {
		val type = component.wrappedComponent.type
		val clonedPackage = type.eContainer.clone(true, true) as Package
		gammaPackage.constantDeclarations += clonedPackage.constantDeclarations
		gammaPackage.functionDeclarations += clonedPackage.functionDeclarations
		// Declarations have been moved
		val clonedComponent = clonedPackage.components.findFirst[it.helperEquals(type)] as SynchronousComponent  // Sync Composite or Statechart
		gammaPackage.components += clonedComponent // Adding it to the "Instance container"
		component.wrappedComponent.type = clonedComponent // Setting the type to the new declaration
		component.fixControlEvents // Fixing control events
		component.fixMessageQueueEvents // Fixing the message queue event references 
		if (clonedComponent instanceof AbstractSynchronousCompositeComponent) {				
			clonedComponent.copyComponents(gammaPackage, containerInstanceName) // Cloning the contained CompositeSystems recursively
		}
	}
	
	protected def void fixChannelRequiredPorts(CompositeComponent composite, ComponentInstance instance) {
		val type = instance.derivedType
		// Fixing the SimpleChannels
		for (simpleChannel : composite.channels.filter(SimpleChannel).filter[it.requiredPort.instance == instance].toList) {
			val ports = switch (type) {
				AsynchronousAdapter: type.allPorts // An individual check for wrappers is needed
				default: type.ports
			}
			val newPorts = ports.filter[it.helperEquals(simpleChannel.requiredPort.port)]
			if (newPorts.size != 1) {
				throw new IllegalArgumentException("Not one port found: " + newPorts)
			}
			simpleChannel.requiredPort.port = newPorts.head	
		}
		// Fixing BroadcastChannels
		for (broadcastChannel : composite.channels.filter(BroadcastChannel)) {
			for (requiredPort : broadcastChannel.requiredPorts.filter[it.instance == instance].toList) {
				val ports = switch (type) {
					AsynchronousAdapter: type.allPorts // An individual check for wrappers is needed
					default: type.ports
				}
				val newPorts = ports.filter[it.helperEquals(requiredPort.port)]
				if (newPorts.size != 1) {
					throw new IllegalArgumentException("Not one port found: " + newPorts)
				}
				requiredPort.port = newPorts.head	
			}
		}
	}
	
	protected def void fixChannelProvidedPorts(CompositeComponent composite, ComponentInstance instance) {
		val type = instance.derivedType
		for (channel : composite.channels.filter[it.providedPort.instance == instance].toList) {
			val ports = switch (type) {
				AsynchronousAdapter: type.allPorts // An individual check for wrappers is needed
				default: type.ports
			}
			val newPorts = ports.filter[it.helperEquals(channel.providedPort.port)]
			if (newPorts.size != 1) {
				throw new IllegalArgumentException("Not one port found: " + newPorts)
			}
			channel.providedPort.port = newPorts.head	
		}
	}
	
	protected def void fixPortBindings(CompositeComponent composite, ComponentInstance instance) {
		val type = instance.derivedType
		for (portBinding : composite.portBindings.filter[it.instancePortReference.instance == instance].toList) {
			val ports = switch (type) {
				AsynchronousAdapter: type.allPorts // An individual check for wrappers is needed
				default: type.ports
			}
			val newPorts = ports.filter[it.helperEquals(portBinding.instancePortReference.port)]
			if (newPorts.size != 1) {
				throw new IllegalArgumentException("Not one port found: " + newPorts)
			}
			portBinding.instancePortReference.port = newPorts.head	
		}
	}
	
	protected def void fixControlEvents(AsynchronousAdapter wrapper) {
		val wrappedComponent = wrapper.wrappedComponent
		// Any port events
		for (portEventReference : wrapper.controlSpecifications.map[it.trigger].filter(EventTrigger)
				.map[it.eventReference].filter(AnyPortEventReference)
				.filter[it.port.eContainer instanceof SynchronousComponent] /* Wrapper ports are not rearranged */ ) {
			val newPorts = wrappedComponent.type.ports.filter[it.helperEquals(portEventReference.port)]
			if (newPorts.size != 1) {
				throw new IllegalArgumentException("Not one port found: " + newPorts)
			}
			portEventReference.port = newPorts.head	
		}
		// Port Events
		for (portEventReference : wrapper.controlSpecifications.map[it.trigger].filter(EventTrigger)
				.map[it.eventReference].filter(PortEventReference)
				.filter[it.port.eContainer instanceof SynchronousComponent] /* Wrapper ports are not rearranged */ ) {
			val newPorts = wrappedComponent.type.ports.filter[it.helperEquals(portEventReference.port)]
			if (newPorts.size != 1) {
				throw new IllegalArgumentException("Not one port found: " + newPorts)
			}
			portEventReference.port = newPorts.head	
		}
		// Clocks
		for (clockTickReference : wrapper.controlSpecifications.map[it.trigger].filter(EventTrigger)
				.map[it.eventReference].filter(ClockTickReference)) {
			val newClocks = wrapper.clocks.filter[it.helperEquals(clockTickReference.clock)]
			if (newClocks.size != 1) {
				throw new IllegalArgumentException("Not one clock found: " + newClocks)
			}
			clockTickReference.clock = newClocks.head	
		}
	}
	
	protected def void fixMessageQueueEvents(AsynchronousAdapter wrapper) {
		val wrappedComponent = wrapper.wrappedComponent
		// Any port events
		for (portEventReference : wrapper.messageQueues.map[it.eventReference].flatten.filter(AnyPortEventReference)
				.filter[it.port.eContainer instanceof SynchronousComponent] /* Wrapper ports are not rearranged */ ) {
			val newPorts = wrappedComponent.type.ports.filter[it.helperEquals(portEventReference.port)]
			if (newPorts.size != 1) {
				throw new IllegalArgumentException("Not one port found: " + newPorts)
			}
			portEventReference.port = newPorts.head	
		}
		// Port events
		for (portEventReference : wrapper.messageQueues.map[it.eventReference].flatten.filter(PortEventReference)
				.filter[it.port.eContainer instanceof SynchronousComponent] /* Wrapper ports are not rearranged */ ) {
			val newPorts = wrappedComponent.type.ports.filter[it.helperEquals(portEventReference.port)]
			if (newPorts.size != 1) {
				throw new IllegalArgumentException("Not one port found: " + newPorts)
			}
			portEventReference.port = newPorts.head	
		}
		// Clock events
		for (clockTickReference : wrapper.messageQueues.map[it.eventReference].flatten.filter(ClockTickReference)) {
			val newClocks = wrapper.clocks.filter[it.helperEquals(clockTickReference.clock)]
			if (newClocks.size != 1) {
				throw new IllegalArgumentException("Not one clock found: " + newClocks)
			}
			clockTickReference.clock = newClocks.head	
		}
	}
	
	private def getComponent(Package gammaPackage) {
		// The first component is retrieved
		return gammaPackage.components.head
	}
	
	private def EObject clone(EObject model, boolean a, boolean b) {
		// A new copier should be used every time, otherwise anomalies happen (references are changed without asking)
		val copier = new Copier(a, b)
		val clone = copier.copy(model);
		copier.copyReferences();
		return clone;
	}
	
	private def helperEquals(EObject lhs, EObject rhs) {
		val helper = new EqualityHelper
		return helper.equals(lhs, rhs) 
	}
	
	private def resolveNameCollisions(Collection<? extends Declaration> declarations) {
		var id = 0
		for (declaration : declarations) {
			for (sameNameDecl : declarations.filter[it.name == declaration.name]) {
				sameNameDecl.name = sameNameDecl.name + (id++).toString
			}
		}
	}
	
}
