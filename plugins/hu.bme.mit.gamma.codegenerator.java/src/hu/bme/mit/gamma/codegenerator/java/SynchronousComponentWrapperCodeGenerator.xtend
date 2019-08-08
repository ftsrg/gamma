package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.codegenerator.java.queries.AnyPortTriggersOfWrappers
import hu.bme.mit.gamma.codegenerator.java.queries.ClockTriggersOfWrappers
import hu.bme.mit.gamma.codegenerator.java.queries.PortEventTriggersOfWrappers
import hu.bme.mit.gamma.codegenerator.java.queries.QueuesOfClocks
import hu.bme.mit.gamma.codegenerator.java.queries.QueuesOfEvents
import hu.bme.mit.gamma.statechart.model.AnyTrigger
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.TimeSpecification
import hu.bme.mit.gamma.statechart.model.TimeUnit
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.ControlFunction
import hu.bme.mit.gamma.statechart.model.interface_.EventDeclaration
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import java.util.Collections

class SynchronousComponentWrapperCodeGenerator {
	
	final String PACKAGE_NAME
	// 
	final extension TimingDeterminer timingDeterminer = new TimingDeterminer
	final extension ExpressionSerializer expressionSerializer = new ExpressionSerializer
	final extension Trace trace
	final extension NameGenerator nameGenerator
	final extension TypeTransformer typeTransformer
	final extension EventDeclarationHandler gammaEventDeclarationHandler
	final extension ComponentCodeGenerator componentCodeGenerator
	//
	final String EVENT_INSTANCE_NAME = "event"

	new(String packageName, Trace trace) {
		this.PACKAGE_NAME = packageName
		this.trace = trace
		this.nameGenerator = new NameGenerator(this.PACKAGE_NAME)
		this.typeTransformer = new TypeTransformer(trace)
		this.gammaEventDeclarationHandler = new EventDeclarationHandler(this.trace)
		this.componentCodeGenerator = new ComponentCodeGenerator(this.trace)
	}
	
	/**
	* Creates the Java code of the synchronous composite class, containing the statemachine instances.
	*/
	protected def createSynchronousComponentWrapperClass(AsynchronousAdapter component) {
		var clockId = 0
	'''
		package «component.componentPackageName»;
		
		«component.generateWrapperImports»
		
		public class «component.componentClassName» implements Runnable, «component.portOwnerInterfaceName» {			
			// Thread running this wrapper instance
			private Thread thread;
			// Wrapped synchronous instance
			private «component.wrappedComponent.type.componentClassName» «component.wrappedComponentName»;
			// Control port instances
			«FOR port : component.ports»
				private «port.name.toFirstUpper» «port.name.toFirstLower»;
			«ENDFOR»
			// Wrapped port instances
			«FOR port : component.wrappedComponent.type.ports»
				private «port.name.toFirstUpper» «port.name.toFirstLower»;
			«ENDFOR»
			«IF !component.clocks.empty»
				// Clocks
				private «Namings.YAKINDU_TIMER_INTERFACE» timerService;
			«ENDIF»
			«FOR clock : component.clocks»
				private final int «clock.name» = «clockId++»;
			«ENDFOR»
			// Main queue
			private LinkedBlockingMultiQueue<String, Event> __asyncQueue = new LinkedBlockingMultiQueue<String, Event>();
			// Subqueues
			«FOR queue : component.messageQueues»
				private LinkedBlockingMultiQueue<String, Event>.SubQueue «queue.name»;
			«ENDFOR»
			«component.generateParameterDeclarationFields»
			
			«IF component.needTimer»
				public «component.componentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", " AFTER ", "»«parameter.type.transformType» «parameter.name»«ENDFOR»«Namings.YAKINDU_TIMER_INTERFACE» timer) {
					«component.createInstances»
					setTimer(timer);
					// Init is done in setTimer
				}
			«ENDIF»
			
			public «component.componentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.type.transformType» «parameter.name»«ENDFOR») {
				«component.createInstances»
				«IF !component.clocks.empty»this.timerService = new TimerService();«ENDIF»
				init();
			}
			
			/** Resets the wrapped component. Must be called to initialize the component. */
			@Override
			public void reset() {
				«component.wrappedComponentName».reset();
			}
			
			/** Creates the subqueues, clocks and enters the wrapped synchronous component. */
			private void init() {
				«component.wrappedComponentName» = new «component.wrappedComponent.type.componentClassName»(«FOR argument : component.wrappedComponent.arguments SEPARATOR ", "»«argument.serialize»«ENDFOR»);
				// Creating subqueues: the negative conversion regarding priorities is needed,
				// because the lbmq marks higher priority with lower integer values
				«FOR queue : component.messageQueues.sortWith(a, b | -1 * (a.priority.compareTo(b.priority)))»
					__asyncQueue.addSubQueue("«queue.name»", -(«queue.priority»), (int) «queue.capacity.serialize»);
					«queue.name» = __asyncQueue.getSubQueue("«queue.name»");
				«ENDFOR»
				«IF !component.clocks.empty»// Creating clock callbacks for the single timer service«ENDIF»
				«FOR match : QueuesOfClocks.Matcher.on(engine).getAllMatches(component, null, null)»
					 timerService.setTimer(createTimerCallback(), «match.clock.name», «match.clock.timeSpecification.valueInMs», true);
				«ENDFOR»
				// The thread has to be started manually
			}
			
			«IF !component.clocks.empty»
				private «Namings.TIMER_CALLBACK_INTERFACE» createTimerCallback() {
					return new «Namings.TIMER_CALLBACK_INTERFACE»() {
						@Override
						public void timeElapsed(int eventId) {
							switch (eventId) {
								«FOR match : QueuesOfClocks.Matcher.on(engine).getAllMatches(component, null, null)»
									case «match.clock.name»:
										«match.queue.name».offer(new Event("«match.clock.name»", null));
									break;
								«ENDFOR»
								default:
									throw new IllegalArgumentException("No such event id: " + eventId);
							}
						}
					};
				}
			«ENDIF»
			
			// Inner classes representing control ports
			«FOR port : component.ports SEPARATOR "\n"»
				public class «port.name.toFirstUpper» implements «port.interfaceRealization.interface.generateName».«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» {
					
					«port.delegateWrapperRaisingMethods» 
					
					«port.delegateWrapperControlOutMethods»
					
					@Override
					public void registerListener(«port.interfaceRealization.interface.generateName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener) {
						// No operation as out event are not interpreted in case of control ports
					}
					
					@Override
					public List<«port.interfaceRealization.interface.generateName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> getRegisteredListeners() {
						// Empty list as out event are not interpreted in case of control ports
						return Collections.emptyList();
					}
					
				}
				
				@Override
				public «port.name.toFirstUpper» get«port.name.toFirstUpper»() {
					return «port.name.toFirstLower»;
				}
			«ENDFOR»
			
			// Inner classes representing wrapped ports
			«FOR port : component.wrappedComponent.type.ports SEPARATOR "\n"»
				public class «port.name.toFirstUpper» implements «port.interfaceRealization.interface.generateName».«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» {
					
					«port.delegateWrapperRaisingMethods»
					
					«port.delegateWrapperOutMethods(component.wrappedComponentName)»
					
					@Override
					public void registerListener(«port.interfaceRealization.interface.generateName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener) {
						«component.wrappedComponentName».get«port.name.toFirstUpper»().registerListener(listener);
					}
					
					@Override
					public List<«port.interfaceRealization.interface.generateName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> getRegisteredListeners() {
						return «component.wrappedComponentName».get«port.name.toFirstUpper»().getRegisteredListeners();
					}
					
				}
				
				@Override
				public «port.name.toFirstUpper» get«port.name.toFirstUpper»() {
					return «port.name.toFirstLower»;
				}
			«ENDFOR»
			
			/** Manual scheduling. */
			public void schedule() {
				«Namings.GAMMA_EVENT_CLASS» «EVENT_INSTANCE_NAME» = __asyncQueue.poll();
				if («EVENT_INSTANCE_NAME» == null) {
					// There was no event in the queue
					return;
				}
				if (!isControlEvent(«EVENT_INSTANCE_NAME»)) {
					// Event is forwarded to the wrapped component
					forwardEvent(«EVENT_INSTANCE_NAME»);
				}
				performControlActions(«EVENT_INSTANCE_NAME»);
			}
			
			/** Operation. */
			@Override
			public void run() {
				while (!Thread.currentThread().isInterrupted()) {
					try {
						«Namings.GAMMA_EVENT_CLASS» «EVENT_INSTANCE_NAME» = __asyncQueue.take();		
						if (!isControlEvent(«EVENT_INSTANCE_NAME»)) {
							// Event is forwarded to the wrapped component
							forwardEvent(«EVENT_INSTANCE_NAME»);
						}
						performControlActions(«EVENT_INSTANCE_NAME»);
					} catch (InterruptedException e) {
						thread.interrupt();
					}
				}
			}
			
			private boolean isControlEvent(«Namings.GAMMA_EVENT_CLASS» «EVENT_INSTANCE_NAME») {
				«IF component.ports.empty && component.clocks.empty»
					return false;
				«ELSE»
					String portName = «EVENT_INSTANCE_NAME».getEvent().split("\\.")[0];
					return «FOR port : component.ports SEPARATOR " || "»portName.equals("«port.name»")«ENDFOR»«IF !component.ports.empty && !component.clocks.empty» || «ENDIF»«FOR clock : component.clocks SEPARATOR " || "»portName.equals("«clock.name»")«ENDFOR»;
				«ENDIF»
			}
			
			private void forwardEvent(«Namings.GAMMA_EVENT_CLASS» «EVENT_INSTANCE_NAME») {
				switch («EVENT_INSTANCE_NAME».getEvent()) {
					«component.generateWrapperEventHandlers()»
					default:
						throw new IllegalArgumentException("No such event!");
				}
			}
			
			private void performControlActions(«Namings.GAMMA_EVENT_CLASS» «EVENT_INSTANCE_NAME») {
				String[] eventName = «EVENT_INSTANCE_NAME».getEvent().split("\\.");
				«FOR controlSpecification : component.controlSpecifications»
					«IF controlSpecification.trigger instanceof AnyTrigger»
						// Any trigger
						«controlSpecification.controlFunction.generateRunCycle(component.wrappedComponentName)»
						return;
					«ELSE»
						«FOR match : AnyPortTriggersOfWrappers.Matcher.on(engine).getAllMatches(component, controlSpecification, null, null)»
							// Port trigger
							if (eventName.length == 2 && eventName[0].equals("«match.port.name»")) {
								«match.controlFunction.generateRunCycle(component.wrappedComponentName)»
								return;
							}
						«ENDFOR»
						«FOR match : PortEventTriggersOfWrappers.Matcher.on(engine).getAllMatches(component, controlSpecification, null, null, null)»
							// Port event trigger
							if (eventName.length == 2 && eventName[0].equals("«match.port.name»") && eventName[1].equals("«match.event.name»")) {
								«match.controlFunction.generateRunCycle(component.wrappedComponentName)»
								return;
							}
						«ENDFOR»
						«FOR match : ClockTriggersOfWrappers.Matcher.on(engine).getAllMatches(component, controlSpecification, null, null)»
							// Clock trigger
							if (eventName.length == 1 && eventName[0].equals("«match.clock.name»")) {
								«match.controlFunction.generateRunCycle(component.wrappedComponentName)»
								return;
							}
						«ENDFOR»
					«ENDIF»
				«ENDFOR»
			}
			
			/** Starts this wrapper instance on a thread. */
			@Override
			public void start() {
				thread = new Thread(this);
				thread.start();
			}
			
			public boolean isWaiting() {
				return thread.getState() == Thread.State.WAITING;
			}
			
			/** Stops the thread running this wrapper instance. */
			public void interrupt() {
				thread.interrupt();
			}
			
			public «component.wrappedComponent.type.componentClassName» get«component.wrappedComponentName.toFirstUpper»() {
				return «component.wrappedComponentName»;
			}
			
			«IF component.needTimer»
				public void setTimer(«Namings.YAKINDU_TIMER_INTERFACE» timer) {
					«IF !component.clocks.empty»timerService = timer;«ENDIF»
					«IF component.wrappedComponent.type.needTimer»«component.wrappedComponentName».setTimer(timer);«ENDIF»
					init(); // To set the service into functioning state with clocks (so that "after 1 s" works with new timer as well)
				}
			«ENDIF»
			
		}
		'''
	}
	
	/**
	 * Generates the needed Java imports in case of the given composite component.
	 */
	protected def generateWrapperImports(AsynchronousAdapter component) '''
		import java.util.Collections;
		import java.util.List;
		
		import lbmq.*; 
		import «PACKAGE_NAME».*;

		import «PACKAGE_NAME».interfaces.*;
		
		import «component.wrappedComponent.type.componentPackageName».*;
	'''
	
	/** Sets the parameters of the component and instantiates the necessary components with them. */
	private def createInstances(AsynchronousAdapter component) '''
		«FOR parameter : component.parameterDeclarations SEPARATOR ", "»
			this.«parameter.name» = «parameter.name»;
		«ENDFOR»
		«component.wrappedComponentName» = new «component.wrappedComponent.type.componentClassName»(«FOR argument : component.wrappedComponent.arguments SEPARATOR ", "»«argument.serialize»«ENDFOR»);
		«FOR port : component.ports»
			«port.name.toFirstLower» = new «port.name.toFirstUpper»();
		«ENDFOR»
		// Wrapped port instances
		«FOR port : component.wrappedComponent.type.ports»
			«port.name.toFirstLower» = new «port.name.toFirstUpper»();
		«ENDFOR»
	'''
	
	/**
	 * Generates methods that for in-event raisings in case of composite components.
	 */
	protected def CharSequence delegateWrapperRaisingMethods(Port port) '''
		«FOR event : Collections.singletonList(port).getSemanticEvents(EventDirection.IN)»
			@Override
			public void raise«event.name.toFirstUpper»(«(event.eContainer as EventDeclaration).generateParameter») {
				«FOR queue : QueuesOfEvents.Matcher.on(engine).getAllValuesOfqueue(port, event) SEPARATOR "\n"»
					«queue.name».offer(new Event("«port.name».«event.name»", «event.valueOrNull»));
				«ENDFOR»
			}
		«ENDFOR»
	'''
	
	/**
	 * Generates methods for out-event checks in case of control ports of wrapper components.
	 */
	protected def CharSequence delegateWrapperControlOutMethods(Port port) '''
«««		Simple flag checks
		«FOR event : Collections.singletonList(port).getSemanticEvents(EventDirection.OUT) SEPARATOR "\n"»
			@Override
			public boolean isRaised«event.name.toFirstUpper»() {
				// No real operation as out event are not interpreted in case of control ports
				return false;
			}
«««		ValueOf checks
			«IF !event.parameterDeclarations.empty»
				@Override
				public «event.toYakinduEvent(port).type.eventParameterType» get«event.name.toFirstUpper»Value() {
					// No real operation as out event are not interpreted in case of control ports
					throw new IllegalAccessException("No value can be accessed!");
				}
			«ENDIF»
		«ENDFOR»
	'''
	
	/**
	 * Generates methods for out-event checks in case of wrapped ports of wrapper components.
	 */
	protected def CharSequence delegateWrapperOutMethods(Port port, String instanceName) '''
«««		Simple flag checks
		«FOR event : Collections.singletonList(port).getSemanticEvents(EventDirection.OUT) SEPARATOR "\n"»
			@Override
			public boolean isRaised«event.name.toFirstUpper»() {
				return «instanceName».get«port.name.toFirstUpper»().isRaised«event.name.toFirstUpper»();
			}
«««		ValueOf checks
			«IF !event.parameterDeclarations.empty»
				@Override
				public «event.toYakinduEvent(port).type.eventParameterType» get«event.name.toFirstUpper»Value() {
					return «instanceName».get«port.name.toFirstUpper»().get«event.name.toFirstUpper»Value();
				}
			«ENDIF»
		«ENDFOR»
	'''
	
	/**
	* Generates event handlers for wrapped in ports of the given wrapper component .
	*/
	protected def generateWrapperEventHandlers(AsynchronousAdapter component) '''
	«FOR port : component.wrappedComponent.type.ports»
			«FOR event : Collections.singletonList(port).getSemanticEvents(EventDirection.IN)»
				case "«port.name».«event.name»":
					«component.wrappedComponentName».get«port.name.toFirstUpper»().raise«event.name.toFirstUpper»(«IF !event.parameterDeclarations.empty»(«event.parameterDeclarations.head.type.transformType.toFirstUpper») event.getValue()«ENDIF»);
				break;
			«ENDFOR»
		«ENDFOR»
	'''
	
	/**
	* Generates a run cycle to the given instance based on the given control function. 
	*/
	protected def generateRunCycle(ControlFunction controlFunction, String instanceName) {
		switch (controlFunction) {
			case ControlFunction.RUN_ONCE:
				'''«instanceName».runCycle();'''			
			case ControlFunction.RUN_TO_COMPLETION:
				'''«instanceName».runFullCycle();'''	
			case ControlFunction.RESET:
				'''«instanceName».reset();'''
		}
	}
	
	/**
	 * Serializes the value of the given time specification with respect to the time unit. 
	 */
	protected def getValueInMs(TimeSpecification specification) {
		if (specification.unit == TimeUnit.SECOND) {
			return "(" + specification.value.serialize + ") * 1000";
		}
		return specification.value.serialize
	}
	
}