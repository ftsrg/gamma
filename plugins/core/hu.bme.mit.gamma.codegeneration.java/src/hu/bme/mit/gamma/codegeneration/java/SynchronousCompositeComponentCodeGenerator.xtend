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
package hu.bme.mit.gamma.codegeneration.java

import hu.bme.mit.gamma.codegeneration.java.queries.BroadcastChannels
import hu.bme.mit.gamma.codegeneration.java.queries.SimpleChannels
import hu.bme.mit.gamma.codegeneration.java.util.InternalEventHandlerCodeGenerator
import hu.bme.mit.gamma.codegeneration.java.util.Namings
import hu.bme.mit.gamma.codegeneration.java.util.TimingDeterminer
import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.SynchronousCompositeComponent

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class SynchronousCompositeComponentCodeGenerator {
	
	protected final String PACKAGE_NAME
	// 
	protected final extension Trace trace
	protected final extension NameGenerator nameGenerator
	protected final extension TypeTransformer typeTransformer
	protected final extension EventDeclarationHandler gammaEventDeclarationHandler
	protected final extension ComponentCodeGenerator componentCodeGenerator
	protected final extension CompositeComponentCodeGenerator compositeComponentCodeGenerator
	//
	protected final extension TimingDeterminer timingDeterminer = TimingDeterminer.INSTANCE
	protected final extension InternalEventHandlerCodeGenerator internalEventHandler = InternalEventHandlerCodeGenerator.INSTANCE
	//
	protected final String INSERT_QUEUE = "insertQueue"
	protected final String EVENT_QUEUE = "eventQueue"

	new(String packageName, String yakinduPackageName, Trace trace) {
		this.PACKAGE_NAME = packageName
		this.trace = trace
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
		this.typeTransformer = new TypeTransformer(trace)
		this.gammaEventDeclarationHandler = new EventDeclarationHandler(this.trace)
		this.componentCodeGenerator = new ComponentCodeGenerator(this.trace)
		this.compositeComponentCodeGenerator = new CompositeComponentCodeGenerator(this.PACKAGE_NAME, this.trace)
	}
	
	/**
	* Creates the Java code of the synchronous composite class, containing the statemachine instances.
	*/
	protected def createSynchronousCompositeComponentClass(AbstractSynchronousCompositeComponent component) '''
		package «component.generateComponentPackageName»;
		
		«component.generateCompositeSystemImports»
		
		public class «component.generateComponentClassName» implements «component.generatePortOwnerInterfaceName» {
			// Component instances
			«FOR instance : component.components»
				private «instance.type.generateComponentClassName» «instance.name»;
			«ENDFOR»
			// Port instances
			«FOR port : component.ports»
				private «port.name.toFirstUpper» «port.name.toFirstLower»;
			«ENDFOR»
			«component.generateParameterDeclarationFields»
			«component.createInternalPortHandlingAttributes»
			
			«IF component.needTimer»
				public «component.generateComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", " AFTER ", "»«parameter.type.transformType» «parameter.name»«ENDFOR»«Namings.UNIFIED_TIMER_INTERFACE» timer) {
					«component.createInstances»
					setTimer(timer);
					init();
				}
			«ENDIF»
			
			public «component.generateComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.type.transformType» «parameter.name»«ENDFOR») {
				«component.createInstances»
				init();
			}
			
			//
			/** Resets the contained statemachines recursively. Must be called to initialize the component. */
			@Override
			public void reset() {
				this.handleBeforeReset();
				this.resetVariables();
				this.resetStateConfigurations();
				this.raiseEntryEvents();
				this.handleAfterReset();
			}
			
			public void handleBeforeReset() {
				//
				«component.executeHandleBeforeReset»
			}
			
			«component.generateResetMethods»
			
			public void handleAfterReset() {
				«component.executeHandleAfterReset»
				//
				«IF component instanceof CascadeCompositeComponent»
					// Setting only a single queue for cascade statecharts
					«FOR instance : component.components.filter[it.isStatechart]»
						«instance.name».change«INSERT_QUEUE.toFirstUpper»();
					«ENDFOR»
				«ENDIF»
				clearPorts();
				// Initializing chain of listeners and events 
				notifyAllSublisteners();
«««				Potentially executing instances before first environment transition (cascade only)
«««				System out-events are NOT cleared
				«IF component instanceof CascadeCompositeComponent»
					«FOR instance : component.initallyScheduledInstances»
«««						Instance in-events are implicitly cleared of course
						«instance.runCycleOrComponent(component)» ««« Not runCycle?
					«ENDFOR»
				«ENDIF»
				// Notifying registered listeners
				notifyListeners();
				«IF component.hasInternalPort»handleInternalEvents();«ENDIF»
			}
			//
			
			/** Creates the channel mappings and enters the wrapped statemachines. */
			private void init() {
				// Registration of simple channels
				«FOR channelMatch : SimpleChannels.Matcher.on(engine).getAllMatches(component, null, null, null)»
					«channelMatch.providedPort.instance.name».get«channelMatch.providedPort.port.name.toFirstUpper»().registerListener(«channelMatch.requiredPort.instance.name».get«channelMatch.requiredPort.port.name.toFirstUpper»());
					«channelMatch.requiredPort.instance.name».get«channelMatch.requiredPort.port.name.toFirstUpper»().registerListener(«channelMatch.providedPort.instance.name».get«channelMatch.providedPort.port.name.toFirstUpper»());
				«ENDFOR»
				// Registration of broadcast channels
				«FOR channelMatch : BroadcastChannels.Matcher.on(engine).getAllMatches(component, null, null, null)»
					«channelMatch.providedPort.instance.name».get«channelMatch.providedPort.port.name.toFirstUpper»().registerListener(«channelMatch.requiredPort.instance.name».get«channelMatch.requiredPort.port.name.toFirstUpper»());
				«ENDFOR»
				«component.createInternalPortHandlingSettingCode»
			}
			
			// Inner classes representing Ports
			«FOR systemPort : component.ports SEPARATOR System.lineSeparator»
				public class «systemPort.name.toFirstUpper» implements «systemPort.interfaceRealization.interface.implementationName».«systemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» {
					private List<«systemPort.interfaceRealization.interface.implementationName».Listener.«systemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> listeners = new LinkedList<«systemPort.interfaceRealization.interface.implementationName».Listener.«systemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»>();
«««					Cascade components need their raised events saved (multiple schedule of a component in a single turn)
					«FOR event : systemPort.outputEvents»
						boolean isRaised«event.name.toFirstUpper»;
						«FOR parameter : event.parameterDeclarations»
							«parameter.type.transformType» «parameter.generateName»;
						«ENDFOR»
					«ENDFOR»
					
					public «systemPort.name.toFirstUpper»() {
						// Registering the listener to the contained component
						«FOR portBinding : systemPort.portBindings»
							«portBinding.instancePortReference.instance.name».get«portBinding.instancePortReference.port.name.toFirstUpper»().registerListener(new «portBinding.compositeSystemPort.name.toFirstUpper»Util());
						«ENDFOR»
					}
					
					«systemPort.delegateRaisingMethods» 
					
					«systemPort.implementOutMethods»
					
					// Class for the setting of the boolean fields (events)
					private class «systemPort.name.toFirstUpper»Util implements «systemPort.interfaceRealization.interface.implementationName».Listener.«systemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» {
						«FOR event : systemPort.outputEvents SEPARATOR System.lineSeparator»
							@Override
							public void raise«event.name.toFirstUpper»(«event.generateParameters») {
								isRaised«event.name.toFirstUpper» = true;
								«FOR parameter : event.parameterDeclarations»
									«systemPort.name.toFirstUpper».this.«parameter.generateName» = «parameter.generateName»;
								«ENDFOR»
							}
						«ENDFOR»
					}
					
					@Override
					public void registerListener(«systemPort.interfaceRealization.interface.implementationName».Listener.«systemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener) {
						listeners.add(listener);
					}
					
					@Override
					public List<«systemPort.interfaceRealization.interface.implementationName».Listener.«systemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> getRegisteredListeners() {
						return listeners;
					}
					
					/** Resetting the boolean event flags to false. */
					public void clear() {
						«FOR event : systemPort.outputEvents»
							isRaised«event.name.toFirstUpper» = false;
						«ENDFOR»
					}
					
					/** Notifying the registered listeners. */
					public void notifyListeners() {
						«FOR event : systemPort.outputEvents»
							if (isRaised«event.name.toFirstUpper») {
								for («systemPort.interfaceRealization.interface.implementationName».Listener.«systemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener : listeners) {
									listener.raise«event.name.toFirstUpper»(«event.generateArguments»);
								}
							}
						«ENDFOR»
					}
					
				}
				
				@Override
				public «systemPort.name.toFirstUpper» get«systemPort.name.toFirstUpper»() {
					return «systemPort.name.toFirstLower»;
				}
			«ENDFOR»
			
			/** Clears the the boolean flags of all out-events in each contained port. */
			private void clearPorts() {
				«FOR portBinding : component.portBindings»
					get«portBinding.compositeSystemPort.name.toFirstUpper»().clear();
				«ENDFOR»
			}
			
			/** Notifies all registered listeners in each contained port. */
			public void notifyAllListeners() {
«««				This subcomponent notification is necessery in hierarchical composite components
				notifyAllSublisteners();
				notifyListeners();
			}
			
			public void notifyAllSublisteners() {
				«FOR subcomponent : component.components»
					«subcomponent.name».notifyAllListeners();
				«ENDFOR»
			}
			
			public void notifyListeners() {
				«FOR portBinding : component.portBindings»
					get«portBinding.compositeSystemPort.name.toFirstUpper»().notifyListeners();
				«ENDFOR»
			}
			
			«IF component instanceof SynchronousCompositeComponent»
				/** Changes the event and process queues of all component instances. Should be used only be the container (composite system) class. */
				public void change«EVENT_QUEUE.toFirstUpper»s() {
					«FOR instance : component.components.filter[!(it.type instanceof CascadeCompositeComponent)]»
						«instance.name».change«EVENT_QUEUE.toFirstUpper»s();
					«ENDFOR»
				}
			«ENDIF»
			
			/** Returns whether all event queues of the contained component instances are empty. 
			Should be used only be the container (composite system) class. */
			public boolean is«EVENT_QUEUE.toFirstUpper»Empty() {
				return «FOR instance : component.components SEPARATOR " && "»«instance.name».is«EVENT_QUEUE.toFirstUpper»Empty()«ENDFOR»;
			}
			
			/** Initiates cycle runs until all event queues of component instances are empty. */
			@Override
			public void runFullCycle() {
				do {
					runCycle();
				}
				while (!is«EVENT_QUEUE.toFirstUpper»Empty());
			}
			
			/** Changes event queues and initiates a cycle run.
			 * This should be the execution point from an asynchronous component. */
			@Override
			public void runCycle() {
				«IF component instanceof SynchronousCompositeComponent»
					// Changing the insert and process queues for all synchronous subcomponents
					change«EVENT_QUEUE.toFirstUpper»s();
				«ENDIF»
				// Composite type-dependent behavior
				runComponent();
			}
			
			/** Initiates a cycle run without changing the event queues.
			 * Should be used only be the container (composite system) class. */
			public void runComponent() {
				// Starts with the clearing of the previous out-event flags
				clearPorts();
				// Running contained components
				«FOR instance : component.scheduledInstances»
					«instance.runCycleOrComponent(component)»
				«ENDFOR»
				// Notifying registered listeners
				notifyListeners();
				«IF component.hasInternalPort»handleInternalEvents();«ENDIF»
			}
		
			«IF component.needTimer»
				/** Setter for the timer e.g., a virtual timer. */
				public void setTimer(«Namings.UNIFIED_TIMER_INTERFACE» timer) {
					«FOR instance : component.components»
						«IF instance.type.needTimer»
							«instance.name».setTimer(timer);
						«ENDIF»
					«ENDFOR»
					reset();
				}
			«ENDIF»
			
			/**  Getter for component instances, e.g., enabling to check their states. */
			«FOR instance : component.components SEPARATOR System.lineSeparator»
				public «instance.type.generateComponentClassName» get«instance.name.toFirstUpper»() {
					return «instance.name»;
				}
			«ENDFOR»
			
			«component.createInternalPortHandlingSetters»
			
			«component.createInternalEventHandlingCode»
			
		}
	'''
	
	protected def runCycleOrComponent(ComponentInstance instance,
			AbstractSynchronousCompositeComponent component) '''
		«IF component instanceof CascadeCompositeComponent && instance.derivedType instanceof SynchronousCompositeComponent»
			«instance.name».runCycle();
		«ELSE»
			«instance.name».runComponent();
		«ENDIF»
	'''
	
}