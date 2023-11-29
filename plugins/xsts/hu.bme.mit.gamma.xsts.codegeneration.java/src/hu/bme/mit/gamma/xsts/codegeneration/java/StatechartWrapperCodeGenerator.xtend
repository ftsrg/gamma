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
package hu.bme.mit.gamma.xsts.codegeneration.java

import hu.bme.mit.gamma.codegeneration.java.util.InternalEventHandlerCodeGenerator
import hu.bme.mit.gamma.codegeneration.java.util.TypeSerializer
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.xsts.model.XSTS

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.LowlevelNamings.*

class StatechartWrapperCodeGenerator {

	final String BASE_PACKAGE_NAME
	final String STATECHART_PACKAGE_NAME
	final String CLASS_NAME

	final StatechartDefinition gammaStatechart
	final XSTS xSts

	final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	final extension PortDiagnoser portDiagnoser = PortDiagnoser.INSTANCE
	final extension ValueDeclarationAccessor valueDeclarationAccessor = ValueDeclarationAccessor.INSTANCE
	final extension InternalEventHandlerCodeGenerator internalEventHandler = InternalEventHandlerCodeGenerator.INSTANCE

	new(String basePackageName, String statechartPackageName, StatechartDefinition gammaStatechart, XSTS xSts) {
		this.BASE_PACKAGE_NAME = basePackageName
		this.STATECHART_PACKAGE_NAME = statechartPackageName
		this.CLASS_NAME = gammaStatechart.componentClassName
		this.gammaStatechart = gammaStatechart
		this.xSts = xSts
	}

	protected def createStatechartWrapperClass() '''
		package «STATECHART_PACKAGE_NAME»;
		
		import java.util.List;
		import java.util.Queue;
		import java.util.LinkedList;
		import «BASE_PACKAGE_NAME».*;
		import «BASE_PACKAGE_NAME».«GAMMA_TIMER_INTERFACE».*;
		«FOR _package : gammaStatechart.containingPackage.importsWithComponentsOrInterfacesOrTypes.toSet»
			import «_package.getPackageString(BASE_PACKAGE_NAME)».*;
		«ENDFOR»
		import «STATECHART_PACKAGE_NAME».«gammaStatechart.wrappedStatemachineClassName».*;
		
		public class «CLASS_NAME» implements «CLASS_NAME»Interface {
			// Port instances
			«FOR port : gammaStatechart.ports»
				private «port.name.toFirstUpper» «port.name.toFirstLower» = new «port.name.toFirstUpper»();
			«ENDFOR»
			// Wrapped statemachine
			private «gammaStatechart.wrappedStatemachineClassName» «CLASS_NAME.toFirstLower»;
			// Indicates which queue is active in a cycle
			private boolean insertQueue = true;
			private boolean processQueue = false;
			// Event queues for the synchronization of statecharts
			private Queue<Event> eventQueue1 = new LinkedList<Event>();
			private Queue<Event> eventQueue2 = new LinkedList<Event>();
			// Clocks
			private «GAMMA_TIMER_INTERFACE» timer = new «GAMMA_TIMER_CLASS»();
			«gammaStatechart.createInternalPortHandlingAttributes»
			
			public «CLASS_NAME»(«FOR parameter : gammaStatechart.parameterDeclarations SEPARATOR ', '»«parameter.type.serialize» «parameter.name»«ENDFOR») {
				«CLASS_NAME.toFirstLower» = new «gammaStatechart.wrappedStatemachineClassName»(«FOR parameter : gammaStatechart.parameterDeclarations SEPARATOR ', '»«parameter.name»«ENDFOR»);
			}
			
			//
			public void reset() {
				this.handleBeforeReset();
				this.resetVariables();
				this.resetStateConfigurations();
				this.raiseEntryEvents();
				this.handleAfterReset();
			}
			
			public void handleBeforeReset() {
				// Clearing the in events
				insertQueue = true;
				processQueue = false;
				eventQueue1.clear();
				eventQueue2.clear();
			}
			
			public void resetVariables() {
				«CLASS_NAME.toFirstLower».resetVariables();
			}
			
			public void resetStateConfigurations() {
				«CLASS_NAME.toFirstLower».resetStateConfigurations();
			}
			
			public void raiseEntryEvents() {
				«CLASS_NAME.toFirstLower».raiseEntryEvents();
			}
			
			public void handleAfterReset() {
				timer.saveTime(this);
				notifyListeners();
				«IF gammaStatechart.hasInternalPort»handleInternalEvents();«ENDIF»
			}
			//
		
			/** Changes the event queues of the component instance. Should be used only be the container (composite system) class. */
			public void changeEventQueues() {
				«IF gammaStatechart.synchronousStatechart»
					insertQueue = !insertQueue;
					processQueue = !processQueue;
				«ENDIF»
			}
			
			/** Changes the event queues to which the events are put. Should be used only be a cascade container (composite system) class. */
			public void changeInsertQueue() {
				«IF gammaStatechart.synchronousStatechart»
					insertQueue = !insertQueue;
				«ENDIF»
			}
			
			/** Returns whether the eventQueue containing incoming messages is empty. Should be used only be the container (composite system) class. */
			public boolean isEventQueueEmpty() {
				return getInsertQueue().isEmpty();
			}
			
			/** Returns the event queue into which events should be put in the particular cycle. */
			private Queue<Event> getInsertQueue() {
				if (insertQueue) {
					return eventQueue1;
				}
				return eventQueue2;
			}
			
			/** Returns the event queue from which events should be inspected in the particular cycle. */
			private Queue<Event> getProcessQueue() {
				«IF gammaStatechart.synchronousStatechart»
					if (processQueue) {
						return eventQueue1;
					}
					return eventQueue2;
				«ELSE»
					return getInsertQueue();
				«ENDIF»
			}
			
			«FOR port : gammaStatechart.ports SEPARATOR System.lineSeparator»
				public class «port.name.toFirstUpper» implements «port.interfaceRealization.interface.name.toFirstUpper»Interface.«port.interfaceRealization.realizationMode.literal.toLowerCase.toFirstUpper» {
					private List<«port.interfaceRealization.interface.name.toFirstUpper»Interface.Listener.«port.interfaceRealization.realizationMode.literal.toLowerCase.toFirstUpper»> listeners = new LinkedList<«port.interfaceRealization.interface.name.toFirstUpper»Interface.Listener.«port.interfaceRealization.realizationMode.literal.toLowerCase.toFirstUpper»>();
					«FOR event : port.getEvents(EventDirection.IN)»
						@Override
						public void raise«event.name.toFirstUpper»(«FOR parameter : event.parameterDeclarations SEPARATOR ', '»«parameter.type.serialize» «parameter.name»«ENDFOR») {
						getInsertQueue().add(new Event("«port.name».«event.name»"«IF !event.parameterDeclarations.empty», «FOR parameter : event.parameterDeclarations SEPARATOR ', '»«parameter.name»«ENDFOR»«ENDIF»));
						}
					«ENDFOR»
					«FOR event : port.getEvents(EventDirection.OUT)»
						@Override
						public boolean isRaised«event.name.toFirstUpper»() {
							return «CLASS_NAME.toFirstLower».get«event.getOutputName(port).toFirstUpper»();
						}
						«FOR parameter : event.parameterDeclarations»
							@Override
							public «parameter.type.serialize» get«parameter.name.toFirstUpper»() {
								return «CLASS_NAME.toFirstLower.accessOut(port, parameter)»;
							}
						«ENDFOR»
					«ENDFOR»
					@Override
					public void registerListener(«port.interfaceRealization.interface.name.toFirstUpper»Interface.Listener.«port.interfaceRealization.realizationMode.literal.toLowerCase.toFirstUpper» listener) {
						listeners.add(listener);
					}
					@Override
					public List<«port.interfaceRealization.interface.name.toFirstUpper»Interface.Listener.«port.interfaceRealization.realizationMode.literal.toLowerCase.toFirstUpper»> getRegisteredListeners() {
						return listeners;
					}
				}
				
				public «port.name.toFirstUpper» get«port.name.toFirstUpper»() {
					return «port.name.toFirstLower»;
				}
			«ENDFOR»
			
			public void runCycle() {
				changeEventQueues();
				runComponent();
			}
			
			public void schedule() {
				runCycle();
			}
			
		public «gammaStatechart.wrappedStatemachineClassName» get«CLASS_NAME.toFirstUpper»(){
			return «CLASS_NAME.toFirstLower»;
		}
			
			public void runComponent() {
				Queue<Event> eventQueue = getProcessQueue();
				«IF gammaStatechart.synchronousStatechart»while«ELSE»if«ENDIF» (!eventQueue.isEmpty()) {
					«GAMMA_EVENT_CLASS» event = eventQueue.remove();
					switch (event.getEvent()) {
						«FOR port : gammaStatechart.ports»
							«FOR event : port.getEvents(EventDirection.IN)»
								case "«port.name».«event.name»": 
									«CLASS_NAME.toFirstLower».set«event.getInputName(port).toFirstUpper»(true);
									«FOR parameter : event.parameterDeclarations»
										«CLASS_NAME.toFirstLower.writeIn(port, parameter, '''((«parameter.type.serialize») event.getValue()[«event.parameterDeclarations.indexOf(parameter)»])''')»
									«ENDFOR»
								break;
							«ENDFOR»
						«ENDFOR»
						default:
							throw new IllegalArgumentException("No such event: " + event);
					}
				}
				executeStep();
				«IF gammaStatechart.hasInternalPort»handleInternalEvents();«ENDIF»
			}
			
			private void executeStep() {
				«IF xSts.hasClockVariable»int elapsedTime = (int) timer.getElapsedTime(this, TimeUnit.MILLISECOND);«ENDIF»
				«FOR timeout : xSts.clockVariables»
					«CLASS_NAME.toFirstLower».set«timeout.name.toFirstUpper»(«CLASS_NAME.toFirstLower».get«timeout.name.toFirstUpper»() + elapsedTime);
				«ENDFOR»
				«CLASS_NAME.toFirstLower».runCycle();
				«IF xSts.hasClockVariable»timer.saveTime(this);«ENDIF»
				notifyListeners();
			}
			
			/** Interface method, needed for composite component initialization chain. */
			public void notifyAllListeners() {
				notifyListeners();
			}
			
			public void notifyListeners() {
				«FOR port : gammaStatechart.ports»
					«FOR event : port.getEvents(EventDirection.OUT)»
						if («port.name.toFirstLower».isRaised«event.name.toFirstUpper»()) {
							for («port.interfaceRealization.interface.name.toFirstUpper»Interface.Listener.«port.interfaceRealization.realizationMode.literal.toLowerCase.toFirstUpper» listener : «port.name.toFirstLower».getRegisteredListeners()) {
								listener.raise«event.name.toFirstUpper»(«FOR parameter : event.parameterDeclarations SEPARATOR ", "»«CLASS_NAME.toFirstLower.accessOut(port, parameter)»«ENDFOR»);
							}
						}
					«ENDFOR»
				«ENDFOR»
			}
			
			public void setTimer(«GAMMA_TIMER_INTERFACE» timer) {
				this.timer = timer;
			}
			
			public boolean isStateActive(String region, String state) {
				switch (region) {
					«FOR region : gammaStatechart.allRegions»
						case "«region.name»":
							return «CLASS_NAME.toFirstLower».get«region.name.toFirstUpper»() == «region.name.toFirstUpper».valueOf(state);
					«ENDFOR»
				}
				return false;
			}
			
			«FOR plainVariable : gammaStatechart.variableDeclarations
					.filter[!it.transient] SEPARATOR System.lineSeparator»
				public «plainVariable.type.serialize» get«plainVariable.name.toFirstUpper»() {
					return «CLASS_NAME.toFirstLower.access(plainVariable)»;
				}
			«ENDFOR»
			
			«gammaStatechart.createInternalPortHandlingSetters»
			
			«gammaStatechart.createInternalEventHandlingCode»
			
			«IF gammaStatechart.asynchronousStatechart»
				public void start() { }
				
				public boolean isWaiting() {
					return false;
				}
				
				public void interrupt() { }
			«ENDIF»
			
			@Override
			public String toString() {
				return «CLASS_NAME.toFirstLower».toString();
			}
		}
	'''
	
	def getClassName() {
		return CLASS_NAME
	}

}
