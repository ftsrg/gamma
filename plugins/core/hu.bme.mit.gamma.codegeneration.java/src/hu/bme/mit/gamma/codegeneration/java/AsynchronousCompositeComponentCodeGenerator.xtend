/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
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
import hu.bme.mit.gamma.codegeneration.java.util.Namings
import hu.bme.mit.gamma.codegeneration.java.util.TimingDeterminer
import hu.bme.mit.gamma.statechart.composite.AbstractAsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.ScheduledAsynchronousCompositeComponent

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class AsynchronousCompositeComponentCodeGenerator {

	protected final String PACKAGE_NAME
	//
	protected final extension TimingDeterminer timingDeterminer = TimingDeterminer.INSTANCE
	protected final extension Trace trace
	protected final extension NameGenerator nameGenerator
	protected final extension TypeTransformer typeTransformer
	protected final extension ComponentCodeGenerator componentCodeGenerator
	protected final extension CompositeComponentCodeGenerator compositeComponentCodeGenerator

	new(String packageName, Trace trace) {
		this.PACKAGE_NAME = packageName
		this.trace = trace
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
		this.typeTransformer = new TypeTransformer(trace)
		this.componentCodeGenerator = new ComponentCodeGenerator(this.trace)
		this.compositeComponentCodeGenerator = new CompositeComponentCodeGenerator(this.PACKAGE_NAME, this.trace)
	}

	def createAsynchronousCompositeComponentClass(AbstractAsynchronousCompositeComponent component) {
		return component.createAsynchronousCompositeComponentClass(0, 0)
	}

	/**
	 * Creates the Java code of the asynchronous composite class, containing asynchronous components.
	 */
	protected def createAsynchronousCompositeComponentClass(AbstractAsynchronousCompositeComponent component,
		int channelId1, int channelId2) '''
		package «component.generateComponentPackageName»;
		
		«component.generateCompositeSystemImports»
		
		public class «component.generateComponentClassName» implements «component.generatePortOwnerInterfaceName»«IF component instanceof ScheduledAsynchronousCompositeComponent», Runnable«ENDIF» {
			«IF component instanceof ScheduledAsynchronousCompositeComponent»private Thread thread;«ENDIF»
			// Component instances
			«FOR instance : component.components»
				private «instance.type.generateComponentClassName» «instance.name»;
			«ENDFOR»
			// Port instances
			«FOR port : component.ports»
				private «port.name.toFirstUpper» «port.name.toFirstLower» = new «port.name.toFirstUpper»();
			«ENDFOR»
			// Channel instances
			«FOR channel : SimpleChannels.Matcher.on(engine).getAllValuesOfsimpleChannel(component, null, null)»
				private «channel.providedPort.port.interfaceRealization.interface.generateChannelInterfaceName» channel«channel.providedPort.port.name.toFirstUpper»Of«channel.providedPort.instance.name.toFirstUpper»;
			«ENDFOR»
			«FOR channel : BroadcastChannels.Matcher.on(engine).getAllValuesOfbroadcastChannel(component, null, null)»
				private «channel.providedPort.port.interfaceRealization.interface.generateChannelInterfaceName» channel«channel.providedPort.port.name.toFirstUpper»Of«channel.providedPort.instance.name.toFirstUpper»;
			«ENDFOR»
			«component.generateParameterDeclarationFields»
			
			«IF component.needTimer»
				public «component.generateComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", " AFTER ", "»«parameter.type.transformType» «parameter.name»«ENDFOR»«Namings.UNIFIED_TIMER_INTERFACE» timer) {
					«component.createInstances»
					setTimer(timer);
					init(); // Init is not called in setTimer like in the wrapper as it would be unnecessary
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
				«IF component instanceof ScheduledAsynchronousCompositeComponent»interrupt();«ENDIF»
				//
				«component.executeHandleBeforeReset»
			}
			
			«component.generateResetMethods»
			
			public void handleAfterReset() {
				«component.executeHandleAfterReset»
				//
				«IF component instanceof ScheduledAsynchronousCompositeComponent»
					«FOR instance : component.initallyScheduledInstances»
						«instance.name».schedule();
					«ENDFOR»
				«ENDIF»
			}
			//
			
			/** Creates the channel mappings and enters the wrapped statemachines. */
			private void init() {				
				// Registration of simple channels
				«FOR channelMatch : SimpleChannels.Matcher.on(engine).getAllMatches(component, null, null, null)»
					channel«channelMatch.providedPort.port.name.toFirstUpper»Of«channelMatch.providedPort.instance.name.toFirstUpper» = new «channelMatch.providedPort.port.interfaceRealization.interface.generateChannelName»(«channelMatch.providedPort.instance.name».get«channelMatch.providedPort.port.name.toFirstUpper»());
					channel«channelMatch.providedPort.port.name.toFirstUpper»Of«channelMatch.providedPort.instance.name.toFirstUpper».registerPort(«channelMatch.requiredPort.instance.name».get«channelMatch.requiredPort.port.name.toFirstUpper»());
				«ENDFOR»
				// Registration of broadcast channels
				«FOR channel : BroadcastChannels.Matcher.on(engine).getAllValuesOfbroadcastChannel(component, null, null)»
					channel«channel.providedPort.port.name.toFirstUpper»Of«channel.providedPort.instance.name.toFirstUpper» = new «channel.providedPort.port.interfaceRealization.interface.generateChannelName»(«channel.providedPort.instance.name».get«channel.providedPort.port.name.toFirstUpper»());
«««					Broadcast channels can have incoming messages in case of asynchronous components
					«FOR channelMatch : BroadcastChannels.Matcher.on(engine).getAllMatches(component, channel, null, null)»
						channel«channelMatch.providedPort.port.name.toFirstUpper»Of«channelMatch.providedPort.instance.name.toFirstUpper».registerPort(«channelMatch.requiredPort.instance.name».get«channelMatch.requiredPort.port.name.toFirstUpper»());
					«ENDFOR»
				«ENDFOR»
			}
			
			// Inner classes representing Ports
			«FOR systemPort : component.ports SEPARATOR System.lineSeparator»
				public class «systemPort.name.toFirstUpper» implements «systemPort.interfaceRealization.interface.implementationName».«systemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» {
				
					«systemPort.delegateRaisingMethods» 
					
					«systemPort.delegateOutMethods»
					
					@Override
					public void registerListener(«systemPort.interfaceRealization.interface.implementationName».Listener.«systemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener) {
						«FOR portDef : systemPort.portBindings»
							«portDef.instancePortReference.instance.name».get«portDef.instancePortReference.port.name.toFirstUpper»().registerListener(listener);
						«ENDFOR»
					}
					
					@Override
					public List<«systemPort.interfaceRealization.interface.implementationName».Listener.«systemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> getRegisteredListeners() {
						«IF systemPort.portBindings.empty»
							return List.of();
						«ELSE»
							«FOR portDef : systemPort.portBindings»
								return «portDef.instancePortReference.instance.name».get«portDef.instancePortReference.port.name.toFirstUpper»().getRegisteredListeners();
							«ENDFOR»
						«ENDIF»
					}
					
				}
				
				@Override
				public «systemPort.name.toFirstUpper» get«systemPort.name.toFirstUpper»() {
					return «systemPort.name.toFirstLower»;
				}
			«ENDFOR»
			
			«IF component instanceof AsynchronousCompositeComponent»
				/** Starts the running of the asynchronous component. */
				@Override
				public void start() {
					«FOR instance : component.components»
						«instance.name».start();
					«ENDFOR»
				}
				
				public boolean isWaiting() {
					return «FOR instance : component.components SEPARATOR " && "»«instance.name».isWaiting()«ENDFOR»;
				}
				
				/** Delegates the interruptions. */
				public void interrupt() {
					«FOR instance : component.components»
						«instance.name».interrupt();
					«ENDFOR»
				}
			«ELSEIF component instanceof ScheduledAsynchronousCompositeComponent»
				/** Starts the running of the asynchronous component. */
				@Override
				public void start() {
					thread = new Thread(this);
					thread.start();
				}
				
				@Override
				public void run() {
					while (!Thread.currentThread().isInterrupted()) {
						schedule(); // Resource-intensive, should be changed
					}
				}
				
				public void schedule() {
					«FOR instance : component.scheduledInstances»
						«instance.name».schedule();
					«ENDFOR»
				}
				
				/** Stops the thread running this composite instance. */
				public void interrupt() {
					if (thread != null) {
						thread.interrupt();
					}
				}
			«ENDIF»
			
			«IF component.needTimer»
				/** Setter for the timer e.g., a virtual timer. */
				public void setTimer(«Namings.UNIFIED_TIMER_INTERFACE» timer) {
					«FOR instance : component.components»
						«IF instance.type.needTimer»
							«instance.name».setTimer(timer);
						«ENDIF»
					«ENDFOR»
				}
			«ENDIF»
			
			/**  Getter for component instances, e.g., enabling to check their states. */
			«FOR instance : component.components SEPARATOR System.lineSeparator»
				public «instance.type.generateComponentClassName» get«instance.name.toFirstUpper»() {
					return «instance.name»;
				}
			«ENDFOR»
			
		}
	'''

}
