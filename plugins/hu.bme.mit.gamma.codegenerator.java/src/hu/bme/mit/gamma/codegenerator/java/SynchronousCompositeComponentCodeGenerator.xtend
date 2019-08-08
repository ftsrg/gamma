package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.codegenerator.java.queries.BroadcastChannels
import hu.bme.mit.gamma.codegenerator.java.queries.SimpleChannels
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.SynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.interface_.EventDeclaration
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import java.util.Collections

class SynchronousCompositeComponentCodeGenerator {
	
	final String PACKAGE_NAME
	// 
	final extension TimingDeterminer timingDeterminer = new TimingDeterminer
	final extension Trace trace
	final extension NameGenerator nameGenerator
	final extension TypeTransformer typeTransformer
	final extension EventDeclarationHandler gammaEventDeclarationHandler
	final extension ComponentCodeGenerator componentCodeGenerator
	final extension CompositeComponentCodeGenerator compositeComponentCodeGenerator
	//
	final String INSERT_QUEUE = "insertQueue"
	final String EVENT_QUEUE = "eventQueue"

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
		package «component.componentPackageName»;
	
		«component.generateCompositeSystemImports»
		
		public class «component.componentClassName» implements «component.portOwnerInterfaceName» {
			// Component instances
			«FOR instance : component.components»
				private «instance.type.componentClassName» «instance.name»;
			«ENDFOR»
			// Port instances
			«FOR port : component.portBindings.map[it.compositeSystemPort]»
				private «port.name.toFirstUpper» «port.name.toFirstLower»;
			«ENDFOR»
			«component.generateParameterDeclarationFields»
			
			«IF component.needTimer»
				public «component.componentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", " AFTER ", "»«parameter.type.transformType» «parameter.name»«ENDFOR»«Namings.UNIFIED_TIMER_INTERFACE» timer) {
					«component.createInstances»
					setTimer(timer);
					init();
				}
			«ENDIF»
			
			public «component.componentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.type.transformType» «parameter.name»«ENDFOR») {
				«component.createInstances»
				init();
			}
			
			/** Resets the contained statemachines recursively. Must be called to initialize the component. */
			@Override
			public void reset() {
				«FOR instance : component.components»
					«instance.name».reset();
				«ENDFOR»								
				// Initializing chain of listeners and events 
				initListenerChain();
			}
			
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
				«IF component instanceof CascadeCompositeComponent»
					// Setting only a single queue for cascade statecharts
					«FOR instance : component.components.filter[it.type instanceof StatechartDefinition]»
						«instance.name».change«INSERT_QUEUE.toFirstUpper»();
					«ENDFOR»
				«ENDIF»
			}
			
			// Inner classes representing Ports
			«FOR portBinding : component.portBindings SEPARATOR "\n"»
				public class «portBinding.compositeSystemPort.name.toFirstUpper» implements «portBinding.compositeSystemPort.interfaceRealization.interface.generateName».«portBinding.compositeSystemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» {
					private List<«portBinding.compositeSystemPort.interfaceRealization.interface.generateName».Listener.«portBinding.compositeSystemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> listeners = new LinkedList<«portBinding.compositeSystemPort.interfaceRealization.interface.generateName».Listener.«portBinding.compositeSystemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»>();

«««					Cascade components need their raised events saved (multiple schedule of a component in a single turn)
					«FOR event : Collections.singletonList(portBinding.compositeSystemPort).getSemanticEvents(EventDirection.OUT)»
						boolean isRaised«event.name.toFirstUpper»;
						«IF !event.parameterDeclarations.empty»
							«event.toYakinduEvent(portBinding.compositeSystemPort).type.eventParameterType» «event.name.toFirstLower»Value;
						«ENDIF»
					«ENDFOR»
					
					public «portBinding.compositeSystemPort.name.toFirstUpper»() {
						// Registering the listener to the contained component
						«portBinding.instancePortReference.instance.name».get«portBinding.instancePortReference.port.name.toFirstUpper»().registerListener(new «portBinding.compositeSystemPort.name.toFirstUpper»Util());
					}
					
					«portBinding.delegateRaisingMethods» 
					
					«portBinding.implementOutMethods»
					
					// Class for the setting of the boolean fields (events)
					private class «portBinding.compositeSystemPort.name.toFirstUpper»Util implements «portBinding.compositeSystemPort.interfaceRealization.interface.generateName».Listener.«portBinding.compositeSystemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» {
						«FOR event : Collections.singletonList(portBinding.compositeSystemPort).getSemanticEvents(EventDirection.OUT) SEPARATOR "\n"»
							@Override
							public void raise«event.name.toFirstUpper»(«(event.eContainer as EventDeclaration).generateParameter») {
								isRaised«event.name.toFirstUpper» = true;
								«IF !event.parameterDeclarations.empty»
										«event.name.toFirstLower»Value = «event.parameterDeclarations.head.eventParameterValue»;
								«ENDIF»
							}
						«ENDFOR»
					}
					
					@Override
					public void registerListener(«portBinding.compositeSystemPort.interfaceRealization.interface.generateName».Listener.«portBinding.compositeSystemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener) {
						listeners.add(listener);
					}
					
					@Override
					public List<«portBinding.compositeSystemPort.interfaceRealization.interface.generateName».Listener.«portBinding.compositeSystemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> getRegisteredListeners() {
						return listeners;
					}
					
					/** Resetting the boolean event flags to false. */
					public void clear() {
						«FOR event : Collections.singletonList(portBinding.compositeSystemPort).getSemanticEvents(EventDirection.OUT)»
							isRaised«event.name.toFirstUpper» = false;
						«ENDFOR»
					}
					
					/** Notifying the registered listeners. */
					public void notifyListeners() {
						«FOR event : Collections.singletonList(portBinding.compositeSystemPort).getSemanticEvents(EventDirection.OUT)»
							if (isRaised«event.name.toFirstUpper») {
								for («portBinding.compositeSystemPort.interfaceRealization.interface.generateName».Listener.«portBinding.compositeSystemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener : listeners) {
									listener.raise«event.name.toFirstUpper»(«IF !event.parameterDeclarations.empty»«event.name.toFirstLower»Value«ENDIF»);
								}
							}
						«ENDFOR»
					}
					
				}
				
				@Override
				public «portBinding.compositeSystemPort.name.toFirstUpper» get«portBinding.compositeSystemPort.name.toFirstUpper»() {
					return «portBinding.compositeSystemPort.name.toFirstLower»;
				}
			«ENDFOR»
			
			/** Clears the the boolean flags of all out-events in each contained port. */
			private void clearPorts() {
				«FOR portBinding : component.portBindings»
					get«portBinding.compositeSystemPort.name.toFirstUpper»().clear();
				«ENDFOR»
			}
			
			/** Notifies all registered listeners in each contained port. */
			private void notifyListeners() {
				«FOR portBinding : component.portBindings»
					get«portBinding.compositeSystemPort.name.toFirstUpper»().notifyListeners();
				«ENDFOR»
			}
			
			/** Needed for the right event notification after initialization, as event notification from contained components
			 * does not happen automatically (see the port implementations and runComponent method). */
			public void initListenerChain() {
				«FOR instance : component.components.filter[!(it.type instanceof StatechartDefinition)]»
					«instance.name».initListenerChain();
				«ENDFOR»
				notifyListeners();
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
				This should be the execution point from an asynchronous component. */
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
				«FOR instance : component.instancesToBeScheduled»
					«IF component instanceof CascadeCompositeComponent && instance.type instanceof SynchronousCompositeComponent»
						«instance.name».runCycle();
					«ELSE»
						«instance.name».runComponent();
					«ENDIF»
				«ENDFOR»
				// Notifying registered listeners
				notifyListeners();
			}
	
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
			«FOR instance : component.components SEPARATOR "\n"»
				public «instance.type.componentClassName» get«instance.name.toFirstUpper»() {
					return «instance.name»;
				}
			«ENDFOR»
			
		}
	'''
	
}