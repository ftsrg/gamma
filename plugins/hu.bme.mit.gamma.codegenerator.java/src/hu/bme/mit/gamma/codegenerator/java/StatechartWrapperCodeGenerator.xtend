package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.RealizationMode
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.interface_.EventDeclaration
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import java.util.Collections
import org.yakindu.base.types.Direction
import org.yakindu.base.types.Event
import org.yakindu.sct.model.sgraph.Statechart
import org.yakindu.sct.model.stext.stext.InterfaceScope

class StatechartWrapperCodeGenerator {
	
	final String PACKAGE_NAME
	final String YAKINDU_PACKAGE_NAME
	// 
	final extension TimingDeterminer timingDeterminer = new TimingDeterminer
	final extension Trace trace
	final extension NameGenerator nameGenerator
	final extension TypeTransformer typeTransformer
	final extension EventDeclarationHandler gammaEventDeclarationHandler
	final extension ComponentCodeGenerator componentCodeGenerator
	//
	final String INSERT_QUEUE = "insertQueue"
	final String PROCESS_QUEUE = "processQueue"
	final String EVENT_QUEUE = "eventQueue"
	final String EVENT_INSTANCE_NAME = "event"

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
	def createSimpleComponentClass(Component component) '''		
		package «component.generateComponentPackageName»;
		
		«component.generateSimpleComponentImports»
		
		public class «component.generateComponentClassName» implements «component.generatePortOwnerInterfaceName» {
			// The wrapped Yakindu statemachine
			private «component.statemachineClassName» «component.generateStatemachineInstanceName»;
			// Port instances
			«FOR port : component.ports»
				private «port.name.toFirstUpper» «port.name.toFirstLower»;
			«ENDFOR»
			// Indicates which queue is active in a cycle
			private boolean «INSERT_QUEUE» = true;
			private boolean «PROCESS_QUEUE» = false;
			// Event queues for the synchronization of statecharts
			private Queue<«Namings.GAMMA_EVENT_CLASS»> «EVENT_QUEUE»1 = new LinkedList<«Namings.GAMMA_EVENT_CLASS»>();
			private Queue<«Namings.GAMMA_EVENT_CLASS»> «EVENT_QUEUE»2 = new LinkedList<«Namings.GAMMA_EVENT_CLASS»>();
			«component.generateParameterDeclarationFields»
			
			public «component.generateComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.type.transformType» «parameter.name»«ENDFOR») {
				«FOR parameter : component.parameterDeclarations SEPARATOR ", "»
					this.«parameter.name» = «parameter.name»;
				«ENDFOR»
				«component.generateStatemachineInstanceName» = new «component.statemachineClassName»();
				«FOR port : component.ports»
					«port.name.toFirstLower» = new «port.name.toFirstUpper»();
				«ENDFOR»
				«IF component.needTimer»«component.generateStatemachineInstanceName».setTimer(new TimerService());«ENDIF»
			}
			
			/** Resets the statemachine. Must be called to initialize the component. */
			@Override
			public void reset() {
				«component.generateStatemachineInstanceName».init();
				«component.generateStatemachineInstanceName».enter();
			}
			
			/** Changes the event queues of the component instance. Should be used only be the container (composite system) class. */
			public void change«EVENT_QUEUE.toFirstUpper»s() {
				«INSERT_QUEUE» = !«INSERT_QUEUE»;
				«PROCESS_QUEUE» = !«PROCESS_QUEUE»;
			}
			
			/** Changes the event queues to which the events are put. Should be used only be a cascade container (composite system) class. */
			public void change«INSERT_QUEUE.toFirstUpper»() {
				«INSERT_QUEUE» = !«INSERT_QUEUE»;
			}
			
			/** Returns whether the eventQueue containing incoming messages is empty. Should be used only be the container (composite system) class. */
			public boolean is«EVENT_QUEUE.toFirstUpper»Empty() {
				return getInsertQueue().isEmpty();
			}
			
			/** Returns the event queue into which events should be put in the particular cycle. */
			private Queue<«Namings.GAMMA_EVENT_CLASS»> getInsertQueue() {
				if («INSERT_QUEUE») {
					return «EVENT_QUEUE»1;
				}
				return «EVENT_QUEUE»2;
			}
			
			/** Returns the event queue from which events should be inspected in the particular cycle. */
			private Queue<«Namings.GAMMA_EVENT_CLASS»> getProcessQueue() {
				if («PROCESS_QUEUE») {
					return «EVENT_QUEUE»1;
				}
				return «EVENT_QUEUE»2;
			}
			
			/** Changes event queues and initiating a cycle run. */
			@Override
			public void runCycle() {
				change«EVENT_QUEUE.toFirstUpper»s();
				runComponent();
			}
			
			/** Changes the insert queue and initiates a run. */
			public void runAndRechangeInsertQueue() {
				// First the insert queue is changed back, so self-event sending can work
				change«INSERT_QUEUE.toFirstUpper»();
				runComponent();
			}
			
			/** Initiates a cycle run without changing the event queues. It is needed if this component is contained (wrapped) by another component.
			Should be used only be the container (composite system) class. */
			public void runComponent() {
				Queue<«Namings.GAMMA_EVENT_CLASS»> «EVENT_QUEUE» = getProcessQueue();
				while (!«EVENT_QUEUE».isEmpty()) {
						«Namings.GAMMA_EVENT_CLASS» «EVENT_INSTANCE_NAME» = «EVENT_QUEUE».remove();
						switch («EVENT_INSTANCE_NAME».getEvent()) {
							«component.generateEventHandlers()»
							default:
								throw new IllegalArgumentException("No such event!");
						}
				}
				«component.generateStatemachineInstanceName».runCycle();
			}
			
			// Inner classes representing Ports
			«FOR port : component.ports SEPARATOR "\n"»
				public class «port.name.toFirstUpper» implements «port.implementedJavaInterfaceName» {
					private List<«port.interfaceRealization.interface.generateName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> registeredListeners = new LinkedList<«port.interfaceRealization.interface.generateName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»>();

					«port.generateRaisingMethods» 

					«component.generateOutMethods(port)»
					@Override
					public void registerListener(final «port.interfaceRealization.interface.generateName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener) {
						registeredListeners.add(listener);
						«IF port.hasOutEvent»
«««							If the clearing of previous registration is ever needed
«««							«IF !port.interfaceRealization.isBroadcast»«component.statemachineInstanceName».get«port.yakinduRealizationModeName»().getListeners().clear();«ENDIF»
							«IF port.interfaceRealization.realizationMode == RealizationMode.REQUIRED»
								«component.registerListener(port, EventDirection.OUT)»
							«ELSE»
								«component.registerListener(port, EventDirection.IN)»
							«ENDIF»
						«ENDIF»
					}
					
					@Override
					public List<«port.interfaceRealization.interface.generateName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> getRegisteredListeners() {
						return registeredListeners;
					}

				}
				
				@Override
				public «port.name.toFirstUpper» get«port.name.toFirstUpper»() {
					return «port.name.toFirstLower»;
				}
			«ENDFOR»
			
			
			«IF component.hasNamelessInterface»
				public SCInterface getInterface() {
					return «component.generateStatemachineInstanceName».getSCInterface();
				}
			«ENDIF»
			
			/** Checks whether the wrapped statemachine is in the given state. */
			public boolean isStateActive(State state) {
				return «component.generateStatemachineInstanceName».isStateActive(state);
			}
			
			«IF component.needTimer»
				public void setTimer(«Namings.YAKINDU_TIMER_INTERFACE» timer) {
					«component.generateStatemachineInstanceName».setTimer(timer);
					reset();
				}
			«ENDIF»
			
		}
	'''
	
	/**
	 * Returns the imports needed for the simple component classes.
	 */
	protected def generateSimpleComponentImports(Component component) '''
		import java.util.Queue;
		import java.util.List;
		import java.util.LinkedList;
		
		import «PACKAGE_NAME».interfaces.*;
		// Yakindu listeners
		import «YAKINDU_PACKAGE_NAME».«(component).yakinduStatemachineName.toLowerCase».I«(component).statemachineClassName».*;
		import «PACKAGE_NAME».*;
		import «YAKINDU_PACKAGE_NAME».«(component).yakinduStatemachineName.toLowerCase».«(component).statemachineClassName»;
		import «YAKINDU_PACKAGE_NAME».«(component).yakinduStatemachineName.toLowerCase».«(component).statemachineClassName».State;
	'''
	
		/**
	* Generates event handlers for all in ports of the given component that is responsible for raising the correct Yakindu statemachine event based on the received message.
	*/
	protected def generateEventHandlers(Component component) '''
««« It is done this way, so all Yakindu interfaces mapped to the same Gamma interface can process the same event
	«FOR port : component.ports»
			«FOR event : Collections.singletonList(port).getSemanticEvents(EventDirection.IN)»
				case "«port.name.toFirstUpper».«event.name.toFirstUpper»": 
					«event.toYakinduEvent(port).delegateCall(component, port)»
				break;
			«ENDFOR»
		«ENDFOR»
	'''
	
	/**
	 * Generates code raising the Yakindu statechart event "connected" to the given port and component.
	 */
	protected def delegateCall(Event event, Component component, Port port) '''
		«component.generateStatemachineInstanceName».get«port.yakinduRealizationModeName»().raise«event.name.toFirstUpper»(«event.castArgument»);
	'''
	
	/**
	* Returns a string that contains a cast and the value of the event if needed. E.g., (Long) event.getValue();
	*/
	protected def castArgument(Event event) '''
		«IF event.type !== null»
			(«event.type.eventParameterType.toFirstUpper») «EVENT_INSTANCE_NAME».getValue()«ENDIF»'''
	
	
	/**
	 * Generates code responsible for overriding the "onRaised" method of the listener interface.
	 * E.g., generates code that raises event "b" of component "comp" if an "a"  out-event is raised inside the implemented component.
	 */
	protected def CharSequence registerListener(Component component, Port port, EventDirection oppositeDirection) '''
		«component.generateStatemachineInstanceName».get«port.yakinduRealizationModeName»().getListeners().add(new «port.yakinduRealizationModeName»Listener() {
			«FOR event : port.interfaceRealization.interface.getAllEvents(oppositeDirection).map[it.eContainer as EventDeclaration] SEPARATOR "\n"»
				@Override
				public void on«event.event.toYakinduEvent(port).name.toFirstUpper»Raised(«event.generateParameter») {
					listener.raise«event.event.name.toFirstUpper»(«event.generateParameterValue»);
				}
			«ENDFOR»
		});
	'''	
		
	/**
	 * Generates methods that for in-event raisings in case of simple components.
	 */
	protected def CharSequence generateRaisingMethods(Port port) '''
		«FOR event : Collections.singletonList(port).getSemanticEvents(EventDirection.IN) SEPARATOR "\n"»
			@Override
			public void raise«event.name.toFirstUpper»(«(event.eContainer as EventDeclaration).generateParameter») {
				getInsertQueue().add(new «Namings.GAMMA_EVENT_CLASS»("«port.name.toFirstUpper».«event.name.toFirstUpper»", «event.toYakinduEvent(port).valueOrNull»));
			}
		«ENDFOR»
	'''
	
	/**
	 * Generates methods for out-event checks in case of simple components.
	 */
	protected def CharSequence generateOutMethods(Component component, Port port) '''
«««		Simple flag checks
		«FOR event : Collections.singletonList(port).getSemanticEvents(EventDirection.OUT)»
			@Override
			public boolean isRaised«event.name.toFirstUpper»() {
				«IF port.name === null»
					return «component.generateStatemachineInstanceName».isRaised«event.toYakinduEvent(port).name.toFirstUpper»();
				«ELSE»
					return «component.generateStatemachineInstanceName».get«port.yakinduRealizationModeName»().isRaised«event.toYakinduEvent(port).name.toFirstUpper»();
				«ENDIF»
			}
«««		ValueOf checks
			«IF event.toYakinduEvent(port).type !== null»
				@Override
				public «event.toYakinduEvent(port).type.eventParameterType» get«event.name.toFirstUpper»Value() {
					return «component.generateStatemachineInstanceName».get«port.yakinduRealizationModeName»().get«event.toYakinduEvent(port).name.toFirstUpper»Value();
				}
			«ENDIF»
		«ENDFOR»
	'''
	
	/**
	 * Returns whether there is an out event in the given port.
	 */
	protected def hasOutEvent(Port port) {
		val interfaces = port.allValuesOfFrom.filter(InterfaceScope)
		if (interfaces.size != 1) {
			throw new IllegalArgumentException("Not one interface. Port: " + port.name + ". Interfaces:" + interfaces + ". Component: " + port.eContainer)
		}
		val anInterface = interfaces.head
		return anInterface.events.filter[it.direction == Direction.OUT].size > 0
	}
	
	protected def hasNamelessInterface(Component component) {
		val yakinduStatecharts = component.allValuesOfFrom
		if (yakinduStatecharts.size != 1) {
			throw new IllegalArgumentException("More than one Yakindu statechart: " + yakinduStatecharts)
		}
		return yakinduStatecharts.filter(Statechart).head
				.scopes.filter(InterfaceScope).exists[it.name === null]
	}
	
}