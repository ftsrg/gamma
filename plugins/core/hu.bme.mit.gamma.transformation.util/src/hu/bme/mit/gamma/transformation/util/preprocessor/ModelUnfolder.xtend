/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util.preprocessor

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.statechart.composite.AbstractAsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent
import hu.bme.mit.gamma.statechart.composite.BroadcastChannel
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.composite.SimpleChannel
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.statechart.AsynchronousStatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.ClockTickReference
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.RunUponExternalEventAnnotation
import hu.bme.mit.gamma.statechart.statechart.RunUponExternalEventOrInternalTimeoutAnnotation
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import java.util.Collection
import java.util.Map
import org.eclipse.emf.ecore.EObject

import static com.google.common.base.Preconditions.checkNotNull
import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.transformation.util.Namings.*

class ModelUnfolder {
	
	protected final Package gammaPackage
	
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	
	protected final extension InterfaceModelFactory factory = InterfaceModelFactory.eINSTANCE
	protected final extension StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE
	
	new(Package gammaPackage) {
		this.gammaPackage = gammaPackage
	}
	
	def unfold() {
		val clonedPackage = gammaPackage.clone => [
			it.imports.clear // Clearing the imports as no reference will be needed in the "Instance container"
			// The interfaces and type declarations of imports are not copied here as the multiple
			// references in the (possible more than one) original models (due to instantiation)
			// would also be necessary to retarget. Therefore, the definition of interfaces and
			// type declarations is possible only in packages different from the component package
			it.name = it.name + "View"
			it.annotations += createUnfoldedPackageAnnotation // Denoting that the package is unfolded
		]
		val originalComponent = gammaPackage.topComponent
		// Clearing other components to prevent potential duplication of components
		val topComponent = clonedPackage.topComponentClearAdditionalComponents
		
		val trace = new Trace(clonedPackage, topComponent)
		
		topComponent.copyComponents(clonedPackage, trace)
		topComponent.renameInstances
		topComponent.validateInstanceNames
		originalComponent.traceComponentInstances(topComponent, trace)
		
		// Cloning and adding declarations from the original package
		clonedPackage.addDeclarations(gammaPackage)
		//
		
		// Resolving potential name collisions
		clonedPackage.constantDeclarations.resolveNameCollisions
		clonedPackage.functionDeclarations.resolveNameCollisions
		
		// Reset top component if the original one is replaces (async statechart)
		trace.topComponent = clonedPackage.topComponent
		
		// The created package, and the top component are returned
		return trace
	}
	
	private dispatch def void copyComponents(Component component, Package gammaPackage, Trace trace) {
		// Simple statecharts are already cloned
		component.removeAnnotations // To prevent importing unnecessary resources into the resource set
	}
	
	private dispatch def void copyComponents(AbstractSynchronousCompositeComponent component,
			Package gammaPackage, Trace trace) {
		for (instance : component.components) {
			val type = instance.type
			val clonedPackage = type.containingPackage.clone
			val clonedComponent = clonedPackage.components
					.findFirst[it.helperEquals(type)] as SynchronousComponent // Sync composite or Statechart
			clonedComponent.removeAnnotations // To prevent importing unnecessary resources into the resource set
			gammaPackage.components += clonedComponent // Adding it to the "Instance container"
			instance.type = clonedComponent // Setting the type to the new declaration
			// Declarations must be copied AFTER moving component instances to enable reference changes
			gammaPackage.addDeclarations(clonedPackage)
			
			// Changing the port binding
			fixPortBindings(component, instance)
			// Changing the providedPort references of Channels
			fixChannelProvidedPorts(component, instance)
			// Changing the requiredPort references of Channels
			fixChannelRequiredPorts(component, instance)
			if (clonedComponent instanceof AbstractSynchronousCompositeComponent) {
				clonedComponent.copyComponents(gammaPackage, trace) // Cloning the contained CompositeSystems recursively
			}
			// Tracing
			type.traceComponentInstances(clonedComponent, trace)
		}
	}
	
	private dispatch def void copyComponents(AbstractAsynchronousCompositeComponent component,
			Package gammaPackage, Trace trace) {
		for (instance : component.components) {
			val type = instance.type
			
			val clonedPackage = type.containingPackage.clone
			val clonedComponent = clonedPackage.components
						.findFirst[it.helperEquals(type)] as AsynchronousComponent
			gammaPackage.components += clonedComponent
			
			instance.type = clonedComponent
			// Declarations must be copied AFTER moving component instances to enable reference changes
			gammaPackage.addDeclarations(clonedPackage)
			
			clonedComponent.copyComponents(gammaPackage, trace) // Cloning the contained CompositeSystems recursively
			
			// Tracing
			type.traceComponentInstances(clonedComponent, trace)
			// Changing the port binding
			fixPortBindings(component, instance)
			// Changing the providedPort references of Channels
			fixChannelProvidedPorts(component, instance)
			// Changing the requiredPort references of Channels
			fixChannelRequiredPorts(component, instance)
		}
	}
	
	private dispatch def void copyComponents(AsynchronousAdapter component, Package gammaPackage,
			Trace trace) {
		val type = component.wrappedComponent.type
		val clonedPackage = type.containingPackage.clone
		val clonedComponent = clonedPackage.components
				.findFirst[it.helperEquals(type)] as SynchronousComponent  // Sync composite or Statechart
		gammaPackage.components += clonedComponent // Adding it to the "Instance container"
		component.wrappedComponent.type = clonedComponent // Setting the type to the new declaration
		// Declarations must be copied AFTER moving component instances to enable reference changes
		gammaPackage.addDeclarations(clonedPackage)
		
		component.fixControlEvents // Fixing control events
		component.fixMessageQueueEvents // Fixing the message queue event references 
		if (clonedComponent instanceof AbstractSynchronousCompositeComponent) {				
			clonedComponent.copyComponents(gammaPackage, trace) // Cloning the contained CompositeSystems recursively
		}
		// Tracing
		type.traceComponentInstances(clonedComponent, trace)
	}
	
	private dispatch def void copyComponents(AsynchronousStatechartDefinition component,
			Package gammaPackage, Trace trace) {
		val clonedPackage = component.containingPackage.clone
		val clonedComponent = clonedPackage.components
				.findFirst[it.helperEquals(component)] as AsynchronousStatechartDefinition
		
		// Attributes
		val synchronousStatechart = clonedComponent.mapIntoSynchronousStatechart
		
		val capacity = component.capacity
		val name = synchronousStatechart.name
		val adapter = if (capacity !== null) {
			synchronousStatechart.wrapIntoDefaultAdapter(name, name + "Queue", capacity.clone)
		}
		else {
			synchronousStatechart.wrapIntoDefaultAdapter(name)
		}
		adapter.addWrapperComponentAnnotation // The adapter is a wrapper component
		
		// Removing original async statechart as we create now an adapter
		adapter.change(component, gammaPackage)
		component.remove
		
		gammaPackage.components += adapter
		gammaPackage.components += synchronousStatechart
		gammaPackage.addDeclarations(clonedPackage)
		// No tracing as it handles only instances
	}
	
	protected def void removeAnnotations(Component component) {
		if (component instanceof StatechartDefinition) {
			val keepableAnnotations = #[ RunUponExternalEventAnnotation, RunUponExternalEventOrInternalTimeoutAnnotation ]
			
			for (annotation : component.annotations.toSet) {
				if (!keepableAnnotations.exists[it.isInstance(annotation)]) {
					annotation.remove
				}
			}
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
		for (portEventReference : wrapper.messageQueues.map[it.sourceAndTargetEventReferences]
				.flatten.filter(AnyPortEventReference)
				.filter[it.port.eContainer instanceof SynchronousComponent] /* Wrapper ports are not rearranged */ ) {
			val newPorts = wrappedComponent.type.ports.filter[it.helperEquals(portEventReference.port)]
			if (newPorts.size != 1) {
				throw new IllegalArgumentException("Not one port found: " + newPorts)
			}
			portEventReference.port = newPorts.head	
		}
		// Port events
		for (portEventReference : wrapper.messageQueues.map[it.sourceAndTargetEventReferences]
				.flatten.filter(PortEventReference)
				.filter[it.port.eContainer instanceof SynchronousComponent] /* Wrapper ports are not rearranged */ ) {
			val newPorts = wrappedComponent.type.ports.filter[it.helperEquals(portEventReference.port)]
			if (newPorts.size != 1) {
				throw new IllegalArgumentException("Not one port found: " + newPorts)
			}
			portEventReference.port = newPorts.head	
		}
		// Clock events
		for (clockTickReference : wrapper.messageQueues.map[it.sourceAndTargetEventReferences]
				.flatten.filter(ClockTickReference)) {
			val newClocks = wrapper.clocks.filter[it.helperEquals(clockTickReference.clock)]
			if (newClocks.size != 1) {
				throw new IllegalArgumentException("Not one clock found: " + newClocks)
			}
			clockTickReference.clock = newClocks.head	
		}
	}
	
	// Instance renames
	
	protected def dispatch void renameInstances(CompositeComponent component) {
		for (instance : component.derivedComponents) {
			val type = instance.derivedType
			type.renameInstances
			// After the contained components have been renamed!
			instance.name = instance.FQN
		}
	}
	
	protected def dispatch void renameInstances(AsynchronousAdapter component) {
		val instance = component.wrappedComponent
		val type = instance.type
		type.renameInstances
		// After the contained components have been renamed!
		instance.name = instance.FQN
	}
	
	protected def dispatch void renameInstances(StatechartDefinition component) {}
	
	//
	
	protected def void renameInstancesAccordingToWrapping(Component wrapper, Component wrapped) {
		val wrapperInstance = wrapper.instances.onlyElement
		val instances = wrapped.allInstances
		for (instance : instances) {
			instance.name = #[wrapperInstance, instance].FQN
		}
	}
	
	// Instance name validation
	
	private def void validateInstanceNames(Component component) {
		val names = newHashSet
		for (instance : component.allInstances) {
			val name = instance.name
			checkState(!names.contains(name),
				"The string " + name + " is generated as a name for multiple instances; " +
					"add different names for these instances")
			names += name
		}
	}
	
	// Util
	
	private def getTopComponent(Package gammaPackage) {
		// The first component is retrieved
		return gammaPackage.components.head
	}
	
	private def getTopComponentClearAdditionalComponents(Package gammaPackage) {
		val topComponent = gammaPackage.topComponent
		// Trick: so if there are multiple components in the gammaPackage,
		// they are not cloned and doubled
		val transientPackage = createPackage => [
			it.name = "TransientPackage"
		]
		transientPackage.components += gammaPackage.components
		// Only the top component stays in the original one
		gammaPackage.components += topComponent
		return topComponent
	}
	
	protected def addDeclarations(Package gammaPackage, Package clonedPackage) {
		val selfAndImports = clonedPackage.selfAndImports
		// As constants and functions can be imported - is the fact that imported packages are not cloned a problem? 
		val clones = <EObject, EObject>newHashMap 
		gammaPackage.constantDeclarations += selfAndImports
			.map[it.constantDeclarations].flatten.toSet
			.map[val clone = it.clone; clones += it -> clone; clone]
		// Crucial as we must not "steal" declarations from e.g., Interfaces.gcd
		gammaPackage.functionDeclarations += selfAndImports
			.map[it.functionDeclarations].flatten.toSet
			.map[val clone = it.clone; clones += it -> clone; clone] // Crucial...
		// Crucial as e.g, function declarations can refer to constant declarations
		for (original : clones.keySet) {
			val clone = clones.get(original)
			clone.change(original, gammaPackage)
		}
		// No interface and type declarations as their cloning causes a lot of trouble
	}
	
	private def dispatch traceComponentInstances(StatechartDefinition oldComponent,
			StatechartDefinition newComponent, Trace trace) {
		// No op
	}
	
	private def dispatch traceComponentInstances(AbstractSynchronousCompositeComponent oldComponent,
			AbstractSynchronousCompositeComponent newComponent, Trace trace) {
		for (var i = 0; i < oldComponent.components.size; i++) {
			trace.put(oldComponent.components.get(i), newComponent.components.get(i))
		}
	}
	
	private def dispatch traceComponentInstances(AbstractAsynchronousCompositeComponent oldComponent,
			AbstractAsynchronousCompositeComponent newComponent, Trace trace) {
		for (var i = 0; i < oldComponent.components.size; i++) {
			trace.put(oldComponent.components.get(i), newComponent.components.get(i))
		}
	}
	
	private def dispatch traceComponentInstances(AsynchronousAdapter oldComponent,
			AsynchronousAdapter newComponent, Trace trace) {
		trace.put(oldComponent.wrappedComponent, newComponent.wrappedComponent)
	}
	
	private def resolveNameCollisions(Collection<? extends Declaration> declarations) {
		var id = 0
		for (declaration : declarations) {
			for (sameNameDecl : declarations.filter[it.name == declaration.name]) {
				sameNameDecl.name = sameNameDecl.name + (id++).toString
			}
		}
	}
	
	static class Trace {
		
		Package _package
		Component topComponent
		
		Map<ComponentInstance, ComponentInstance> componentInstanceMappings = newHashMap
		
		new(Package _package, Component topComponent) {
			this._package = _package
			this.topComponent = topComponent
		}
		
		def getPackage() {
			return _package
		}
		
		def getTopComponent() {
			return topComponent
		}
		
		def put(ComponentInstance oldInstance, ComponentInstance newInstance) {
			checkNotNull(oldInstance)
			checkNotNull(newInstance)
			return componentInstanceMappings.put(oldInstance, newInstance)
		}
	
		def isMapped(ComponentInstance instance) {
			checkNotNull(instance)
			return componentInstanceMappings.containsKey(instance)
		}
	
		def get(ComponentInstance instance) {
			checkNotNull(instance)
			return componentInstanceMappings.get(instance)
		}
		
	}
	
}
