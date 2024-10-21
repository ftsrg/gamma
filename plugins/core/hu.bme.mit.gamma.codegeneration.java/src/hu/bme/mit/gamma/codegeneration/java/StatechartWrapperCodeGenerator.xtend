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

import hu.bme.mit.gamma.codegeneration.java.util.Namings
import hu.bme.mit.gamma.codegeneration.java.util.TimingDeterminer
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Persistency
import hu.bme.mit.gamma.statechart.interface_.Port

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class StatechartWrapperCodeGenerator {

	protected final String PACKAGE_NAME
	protected final String YAKINDU_PACKAGE_NAME
	//
	protected final extension TimingDeterminer timingDeterminer = TimingDeterminer.INSTANCE
	protected final extension Trace trace
	protected final extension NameGenerator nameGenerator
	protected final extension TypeTransformer typeTransformer
	protected final extension EventDeclarationHandler gammaEventDeclarationHandler
	protected final extension ComponentCodeGenerator componentCodeGenerator
	//
	protected final String INSERT_QUEUE = "insertQueue"
	protected final String PROCESS_QUEUE = "processQueue"
	protected final String EVENT_QUEUE = "eventQueue"
	protected final String EVENT_INSTANCE_NAME = "event"

	new(String packageName, String yakinduPackageName, Trace trace) {
		this.PACKAGE_NAME = packageName
		this.YAKINDU_PACKAGE_NAME = yakinduPackageName
		this.trace = trace
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
		this.typeTransformer = new TypeTransformer(trace)
		this.gammaEventDeclarationHandler = new EventDeclarationHandler(this.trace)
		this.componentCodeGenerator = new ComponentCodeGenerator(this.trace)
	}

	/**
	 * Creates the Java code for the given component.
	 */
//	def createSimpleComponentClass(StatechartDefinition component) '''		
//		package «component.generateComponentPackageName»;
//		
//		«component.generateSimpleComponentImports»
//		
//		public class «component.generateComponentClassName» implements «component.generatePortOwnerInterfaceName» {
//			// The wrapped Yakindu statemachine
//			private «component.statemachineClassName» «component.generateStatemachineInstanceName»;
//			// Port instances
//			«FOR port : component.ports»
//				private «port.name.toFirstUpper» «port.name.toFirstLower»;
//			«ENDFOR»
//			// Indicates which queue is active in a cycle
//			private boolean «INSERT_QUEUE» = true;
//			private boolean «PROCESS_QUEUE» = false;
//			// Event queues for the synchronization of statecharts
//			private Queue<«Namings.GAMMA_EVENT_CLASS»> «EVENT_QUEUE»1 = new LinkedList<«Namings.GAMMA_EVENT_CLASS»>();
//			private Queue<«Namings.GAMMA_EVENT_CLASS»> «EVENT_QUEUE»2 = new LinkedList<«Namings.GAMMA_EVENT_CLASS»>();
//			«component.generateParameterDeclarationFields»
//		
//		
//			public «component.statemachineClassName» get«component.generateStatemachineInstanceName.toFirstUpper»(){
//			return  «component.generateStatemachineInstanceName»;
//			}
//		
//			public «component.generateComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.type.transformType» «parameter.name»«ENDFOR») {
//			«FOR parameter : component.parameterDeclarations SEPARATOR ", "»
//				this.«parameter.name» = «parameter.name»;
//			«ENDFOR»
//			«component.generateStatemachineInstanceName» = new «component.statemachineClassName»();
//			«FOR port : component.ports»
//				«port.name.toFirstLower» = new «port.name.toFirstUpper»();
//			«ENDFOR»
//			«IF component.needTimer»«component.generateStatemachineInstanceName».setTimer(new TimerService());«ENDIF»
//			}
//			
//			//
//			/** Resets the statemachine. Must be called to initialize the component. */
//			@Override
//			public void reset() {
//				// Clearing the in events
//				«INSERT_QUEUE» = true;
//				«PROCESS_QUEUE» = false;
//				«EVENT_QUEUE»1.clear();
//				«EVENT_QUEUE»2.clear();
//				//
//				«component.generateStatemachineInstanceName».init();
//				«component.generateStatemachineInstanceName».enter();
//				notifyListeners();
//			}
//			
//			public void handleBeforeReset() {
//			}
//			
//			public void resetVariables() { // Incompatible reset of Yakindu statecharts
//			}
//			
//			public void resetStateConfigurations() { // Incompatible reset of Yakindu statecharts
//				this.reset();
//			}
//			
//			public void raiseEntryEvents() { // Incompatible reset of Yakindu statecharts
//			}
//			
//			public void handleAfterReset() {
//			}
//			//
//			
//			/** Changes the event queues of the component instance. Should be used only be the container (composite system) class. */
//			public void change«EVENT_QUEUE.toFirstUpper»s() {
//				«INSERT_QUEUE» = !«INSERT_QUEUE»;
//				«PROCESS_QUEUE» = !«PROCESS_QUEUE»;
//			}
//			
//			/** Changes the event queues to which the events are put. Should be used only be a cascade container (composite system) class. */
//			public void change«INSERT_QUEUE.toFirstUpper»() {
//				«INSERT_QUEUE» = !«INSERT_QUEUE»;
//			}
//			
//			/** Returns whether the eventQueue containing incoming messages is empty. Should be used only be the container (composite system) class. */
//			public boolean is«EVENT_QUEUE.toFirstUpper»Empty() {
//				return getInsertQueue().isEmpty();
//			}
//			
//			/** Returns the event queue into which events should be put in the particular cycle. */
//			private Queue<«Namings.GAMMA_EVENT_CLASS»> getInsertQueue() {
//				if («INSERT_QUEUE») {
//					return «EVENT_QUEUE»1;
//				}
//				return «EVENT_QUEUE»2;
//			}
//			
//			/** Returns the event queue from which events should be inspected in the particular cycle. */
//			private Queue<«Namings.GAMMA_EVENT_CLASS»> getProcessQueue() {
//				if («PROCESS_QUEUE») {
//					return «EVENT_QUEUE»1;
//				}
//				return «EVENT_QUEUE»2;
//			}
//			
//			/** Changes event queues and initiating a cycle run. */
//			@Override
//			public void runCycle() {
//				change«EVENT_QUEUE.toFirstUpper»s();
//				runComponent();
//			}
//			
//			/** Changes the insert queue and initiates a run. */
//			public void runAndRechangeInsertQueue() {
//				// First the insert queue is changed back, so self-event sending can work
//				change«INSERT_QUEUE.toFirstUpper»();
//				runComponent();
//			}
//			
//			/** Initiates a cycle run without changing the event queues. It is needed if this component is contained (wrapped) by another component.
//			Should be used only be the container (composite system) class. */
//			public void runComponent() {
//				Queue<«Namings.GAMMA_EVENT_CLASS»> «EVENT_QUEUE» = getProcessQueue();
//				while (!«EVENT_QUEUE».isEmpty()) {
//						«Namings.GAMMA_EVENT_CLASS» «EVENT_INSTANCE_NAME» = «EVENT_QUEUE».remove();
//						switch («EVENT_INSTANCE_NAME».getEvent()) {
//							«component.generateEventHandlers()»
//							default:
//								throw new IllegalArgumentException("No such event!");
//						}
//				}
//				«component.generateStatemachineInstanceName».runCycle();
//				
//				notifyListeners(); ««« The parameters of transient in events do not eave to be reset, as Yakindu does not allow to use a parameter, if the event is not raised
//			}
//			
//			// Inner classes representing Ports
//			«FOR port : component.ports SEPARATOR System.lineSeparator»
//				public class «port.name.toFirstUpper» implements «port.implementedInterfaceName» {
//					private List<«port.interfaceRealization.interface.implementationName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> registeredListeners = new LinkedList<«port.interfaceRealization.interface.implementationName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»>();
//					
//					«port.generateRaisingMethods» 
//				
//					«component.generateOutMethods(port)»
//					@Override
//					public void registerListener(final «port.interfaceRealization.interface.implementationName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener) {
//						registeredListeners.add(listener);
//					}
//					
//					@Override
//					public List<«port.interfaceRealization.interface.implementationName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> getRegisteredListeners() {
//						return registeredListeners;
//					}
//					
//					/** Notifying the registered listeners. */
//					public void notifyListeners() {
//						«FOR event : port.outputEvents»
//							if (isRaised«event.name.toFirstUpper»()) {
//								for («port.interfaceRealization.interface.implementationName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener : registeredListeners) {
//									listener.raise«event.name.toFirstUpper»(«IF !event.parameterDeclarations.empty»get«event.name.toFirstUpper»Value()«ENDIF»);
//								}
//							}
//						«ENDFOR»
//					}
//					
//				}
//				
//				@Override
//				public «port.name.toFirstUpper» get«port.name.toFirstUpper»() {
//					return «port.name.toFirstLower»;
//				}
//			«ENDFOR»
//			
//			/** Interface method, needed for composite component initialization chain. */
//			public void notifyAllListeners() {
//			notifyListeners();
//			}
//			
//			/** Notifies all registered listeners in each contained port. */
//			public void notifyListeners() {
//				«FOR port : component.ports»
//					get«port.name.toFirstUpper»().notifyListeners();
//				«ENDFOR»
//			}
//			
//			«IF component.hasNamelessInterface»
//				public SCInterface getInterface() {
//					return «component.generateStatemachineInstanceName».getSCInterface();
//				}
//			«ENDIF»
//			
//			/** Checks whether the wrapped statemachine is in the given state. */
//			public boolean isStateActive(State state) {
//				return «component.generateStatemachineInstanceName».isStateActive(state);
//			}
//			
//			public boolean isStateActive(String region, String state) {
//				switch (region) {
//					«FOR region : component.allRegions»
//						case "«region.name»":
//							switch (state) {
//								«FOR state : region.states»
//									case "«state.name»":
//										return isStateActive(State.«state.fullContainmentHierarchy»);
//								«ENDFOR»
//							}
//					«ENDFOR»
//				}
//				return false;
//			}
//		
//«««			Getters for variables on named interfaces
//			«FOR port : component.allPorts»
//				«FOR yakinduInterface : port.allValuesOfFrom.filter(InterfaceScope)»
//					«FOR yakinduVariable : yakinduInterface.declarations.filter(VariableDefinition)»
//						«FOR gammaVariable : yakinduVariable.allValuesOfTo.filter(VariableDeclaration)»
//							public «gammaVariable.type.transformType» get«gammaVariable.name.toFirstUpper»() {
//								return «yakinduVariable.castDeclaration» «component.generateStatemachineInstanceName».get«port.yakinduInterfaceName»().get«yakinduVariable.name.toFirstUpper»();
//							}
//						«ENDFOR»
//					«ENDFOR»
//				«ENDFOR»
//			«ENDFOR»
//			
//«««			Getters for variables on non-named interfaces
//			«FOR yakinduVariable : component.variableDeclarations
//					.map[it.allValuesOfFrom.filter(VariableDefinition).head].filterNull SEPARATOR System.lineSeparator»
//				«IF (yakinduVariable.eContainer instanceof InterfaceScope && (yakinduVariable.eContainer as InterfaceScope).name.nullOrEmpty)
//						 	|| yakinduVariable.eContainer instanceof InternalScope»
//					public «yakinduVariable.allValuesOfTo.filter(VariableDeclaration).head.type.transformType» get«yakinduVariable.name.toFirstUpper»() {
//						return «yakinduVariable.castDeclaration» «component.generateStatemachineInstanceName».get«yakinduVariable.name.toFirstUpper»();
//					}
//				«ENDIF»
//			«ENDFOR»
//			
//			«IF component.needTimer»
//				public void setTimer(«Namings.YAKINDU_TIMER_INTERFACE» timer) {
//					«component.generateStatemachineInstanceName».setTimer(timer);
//				}
//			«ENDIF»
//			
//			public void setHandleInternalEvents(boolean handleInternalEvents) {}
//			
//		}
//	'''

	/**
	 * Returns the imports needed for the simple component classes.
	 */
	protected def generateSimpleComponentImports(Component component) '''
		import java.util.Queue;
		import java.util.List;
		import java.util.LinkedList;
		«IF component.ports.map[it.outputEvents].flatten.exists[it.persistency == Persistency.PERSISTENT]»
			import java.lang.reflect.Field;
		«ENDIF»
		
		«FOR _package : component.containingPackage.importsWithComponentsOrInterfacesOrTypes»
			import «_package.getPackageString(PACKAGE_NAME)».*;
		«ENDFOR»
		// Yakindu listeners
		import «YAKINDU_PACKAGE_NAME».«component.yakinduStatemachineName.toLowerCase».I«component.statemachineClassName».*;
		import «PACKAGE_NAME».*;
		import «YAKINDU_PACKAGE_NAME».«component.yakinduStatemachineName.toLowerCase».«component.statemachineClassName».State;
	'''

	/**
	 * Generates event handlers for all in ports of the given component that is responsible for raising the correct Yakindu statemachine event based on the received message.
	 */
//	protected def generateEventHandlers(Component component) '''
//«««		It is done this way, so all Yakindu interfaces mapped to the same Gamma interface can process the same event
//		«FOR port : component.ports»
//			«FOR event : port.inputEvents»
//				case "«port.name.toFirstUpper».«event.name.toFirstUpper»": 
//					«event.toYakinduEvent(port).delegateCall(component, port)»
//				break;
//			«ENDFOR»
//		«ENDFOR»
//	'''

	/**
	 * Generates code raising the Yakindu statechart event "connected" to the given port and component.
	 */
//	protected def delegateCall(Event event, Component component, Port port) '''
//		«component.generateStatemachineInstanceName».get«port.yakinduInterfaceName»().raise«event.name.toFirstUpper»(«event.castArgument»);
//	'''

	/**
	 * Returns a string that contains a cast and the value of the event if needed. E.g., (Long) event.getValue();
	 */
//	protected def castArgument(Event event) '''
//	«IF event.type !== null»
//		(«event.type.eventParameterType.toFirstUpper») «EVENT_INSTANCE_NAME».getValue()[0]«ENDIF»'''

	/**
	 * Generates methods that for in-event raisings in case of simple components.
	 */
	protected def CharSequence generateRaisingMethods(Port port) '''
		«FOR event : port.inputEvents SEPARATOR System.lineSeparator»
			@Override
			public void raise«event.name.toFirstUpper»(«event.generateParameters») {
				getInsertQueue().add(new «Namings.GAMMA_EVENT_CLASS»("«port.name.toFirstUpper».«event.name.toFirstUpper»"«IF event.generateArguments.length != 0», «ENDIF»«event.generateArguments»));
			}
		«ENDFOR»
	'''

	/**
	 * Generates methods for out-event checks in case of simple components.
	 */
//	protected def CharSequence generateOutMethods(Component component, Port port) '''
//«««		Simple flag checks
//		«FOR event : port.outputEvents»
//			@Override
//			public boolean isRaised«event.name.toFirstUpper»() {
//				«IF port.name === null»
//					return «component.generateStatemachineInstanceName».isRaised«event.toYakinduEvent(port).name.toFirstUpper»();
//				«ELSE»
//					return «component.generateStatemachineInstanceName».get«port.yakinduInterfaceName»().isRaised«event.toYakinduEvent(port).name.toFirstUpper»();
//				«ENDIF»
//			}
//«««			ValueOf checks
//			«IF event.toYakinduEvent(port).type !== null»
//				@Override
//				public «event.toYakinduEvent(port).type.eventParameterType» get«event.name.toFirstUpper»Value() {
//					«IF event.persistency == Persistency.PERSISTENT»
//						try {
//							// Using reflection to retrieve the value of the persistent private field
//							Class<? extends «port.yakinduInterfaceName»> interfaceClass = «component.generateStatemachineInstanceName».get«port.yakinduInterfaceName»().getClass();
//							Field field = interfaceClass.getDeclaredField("«event.toYakinduEvent(port).name.toFirstLower»Value");
//							field.setAccessible(true);
//							«event.toYakinduEvent(port).type.eventParameterType» value = field.get«event.toYakinduEvent(port).type.eventParameterType.toFirstUpper»(«component.generateStatemachineInstanceName».get«port.yakinduInterfaceName»());
//							field.setAccessible(false);
//							return «event.toYakinduEvent(port).castDeclaration» value;
//						} catch (Exception e) {
//							throw new IllegalStateException(e);
//						}
//					«ELSE»
//						try {
//							return «component.generateStatemachineInstanceName».get«port.yakinduInterfaceName»().get«event.toYakinduEvent(port).name.toFirstUpper»Value();
//						} catch (IllegalStateException e) {
//							// If this is a reset parameter of a transient event, we return a default expression
//							return «event.toYakinduEvent(port).castDeclaration» «event.toYakinduEvent(port).type.defaultExpression»;
//						}
//					«ENDIF»
//				}
//			«ENDIF»
//		«ENDFOR»
//	'''

	/**
	 * Returns whether there is an out event in the given port.
	 */
	protected def hasOutEvent(Port port) {
		return port.hasOutputEvents
	}

	protected def hasNamelessInterface(Component component) {
		return false
//		val yakinduStatecharts = component.allValuesOfFrom
//		if (yakinduStatecharts.size != 1) {
//			throw new IllegalArgumentException("More than one Yakindu statechart: " + yakinduStatecharts)
//		}
//		return yakinduStatecharts.filter(Statechart).head.scopes.filter(InterfaceScope).exists[it.name === null]
	}

}
