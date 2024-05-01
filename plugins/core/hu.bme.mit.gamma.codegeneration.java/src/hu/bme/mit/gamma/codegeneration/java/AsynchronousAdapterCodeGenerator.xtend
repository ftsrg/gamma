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

import hu.bme.mit.gamma.codegeneration.java.queries.AnyPortTriggersOfWrappers
import hu.bme.mit.gamma.codegeneration.java.queries.ClockTriggersOfWrappers
import hu.bme.mit.gamma.codegeneration.java.queries.PortEventTriggersOfWrappers
import hu.bme.mit.gamma.codegeneration.java.queries.QueuesOfClocks
import hu.bme.mit.gamma.codegeneration.java.queries.QueuesOfEvents
import hu.bme.mit.gamma.codegeneration.java.util.InternalEventHandlerCodeGenerator
import hu.bme.mit.gamma.codegeneration.java.util.TimingDeterminer
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.ControlFunction
import hu.bme.mit.gamma.statechart.composite.DiscardStrategy
import hu.bme.mit.gamma.statechart.composite.MessageQueue
import hu.bme.mit.gamma.statechart.interface_.AnyTrigger
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification
import hu.bme.mit.gamma.statechart.interface_.TimeUnit

import static extension hu.bme.mit.gamma.codegeneration.java.util.Namings.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class AsynchronousAdapterCodeGenerator {
	
	protected final String PACKAGE_NAME
	// 
	protected final extension TimingDeterminer timingDeterminer = TimingDeterminer.INSTANCE
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension Trace trace
	protected final extension NameGenerator nameGenerator
	protected final extension TypeTransformer typeTransformer
	protected final extension EventDeclarationHandler gammaEventDeclarationHandler
	protected final extension ComponentCodeGenerator componentCodeGenerator
	protected final extension CompositeComponentCodeGenerator compositeComponentCodeGenerator // Due to reset methods
	protected final extension InternalEventHandlerCodeGenerator internalEventHandler = InternalEventHandlerCodeGenerator.INSTANCE
	//
	protected final String EVENT_INSTANCE_NAME = "event"

	new(String packageName, Trace trace) {
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
	protected def createAsynchronousAdapterClass(AsynchronousAdapter component) {
		var clockId = 0
	'''
		package «component.generateComponentPackageName»;
		
		«component.generateWrapperImports»
		
		public class «component.generateComponentClassName» implements Runnable, «component.generatePortOwnerInterfaceName» { 
			// Thread running this wrapper instance
			private Thread thread;
			// Wrapped synchronous instance
			private «component.wrappedComponent.type.generateComponentClassName» «component.generateWrappedComponentName»;
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
				private «YAKINDU_TIMER_INTERFACE» timerService;
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
				public «component.generateComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", " AFTER ", "»«parameter.type.transformType» «parameter.name»«ENDFOR»«UNIFIED_TIMER_INTERFACE» timer) {
					«component.createInstances»
					setTimer(timer);
					init();
				}
			«ENDIF»
			
			public «component.generateComponentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.type.transformType» «parameter.name»«ENDFOR») {
				«component.createInstances»
				«IF !component.clocks.empty»this.timerService = new TimerService();«ENDIF»
				init();
			}
			
			/** Resets the wrapped component. Must be called to initialize the component. */
			@Override
			public void reset() {
				this.handleBeforeReset();
				this.resetVariables();
				this.resetStateConfigurations();
				this.raiseEntryEvents();
				this.handleAfterReset();
			}
			
			public void handleBeforeReset() {
				interrupt();
				«IF !component.clocks.empty»
					if (timerService != null) {
						«FOR match : QueuesOfClocks.Matcher.on(engine).getAllMatches(component, null, null)»
							timerService.unsetTimer(createTimerCallback(), «match.clock.name»);
							timerService.setTimer(createTimerCallback(), «match.clock.name», «match.clock.timeSpecification.valueInNanoseconds», true);
						«ENDFOR»
					}
				«ENDIF»
«««				Queues cannot be reset due to message sending upon reset (in other components)
«««				«FOR queue : component.messageQueues»
«««					«queue.name».clear();
«««				«ENDFOR»
				//
				«component.executeHandleBeforeReset»
			}
			
			«component.generateResetMethods»
			
			public void handleAfterReset() {
				«component.executeHandleAfterReset»
				//
				«IF component.hasInternalPort»handleInternalEvents();«ENDIF»
			}
			//
			
			/** Creates the subqueues, clocks and enters the wrapped synchronous component. */
			private void init() {
				«component.generateWrappedComponentName» = new «component.wrappedComponent.type.generateComponentClassName»(«FOR argument : component.wrappedComponent.arguments SEPARATOR ", "»«argument.serialize»«ENDFOR»);
				// Creating subqueues: the negative conversion regarding priorities is needed,
				// because the lbmq marks higher priority with lower integer values
				«FOR queue : component.messageQueues.sortWith(a, b | -1 * (a.priority.compareTo(b.priority)))»
					__asyncQueue.addSubQueue("«queue.name»", -(«queue.priority»), (int) «queue.capacity.serialize»);
					«queue.name» = __asyncQueue.getSubQueue("«queue.name»");
				«ENDFOR»
«««				«IF !component.clocks.empty»// Creating clock callbacks for the single timer service«ENDIF»
«««				«FOR match : QueuesOfClocks.Matcher.on(engine).getAllMatches(component, null, null)»
«««					 timerService.setTimer(createTimerCallback(), «match.clock.name», «match.clock.timeSpecification.valueInMs», true);
«««				«ENDFOR»
				«component.createInternalPortHandlingSettingCode»
				// The thread has to be started manually
			}
			
			«IF !component.clocks.empty»
				private «TIMER_CALLBACK_INTERFACE» createTimerCallback() {
					return new «TIMER_CALLBACK_INTERFACE»() {
						@Override
						public void timeElapsed(int eventId) {
							switch (eventId) {
								«FOR match : QueuesOfClocks.Matcher.on(engine).getAllMatches(component, null, null)»
									case «match.clock.name»:
										«match.queue.name».«match.queue.additionMethodName»(new Event("«match.clock.name»"));
									break;
								«ENDFOR»
								default:
									throw new IllegalArgumentException("No such event id: " + eventId);
							}
						}
						public boolean equals(Object object) {
							return this.getClass() == object.getClass();
						}
					};
				}
			«ENDIF»
			
			// Inner classes representing control ports
			«FOR port : component.ports SEPARATOR System.lineSeparator»
				public class «port.name.toFirstUpper» implements «port.interfaceRealization.interface.implementationName».«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» {
					
					«port.delegateWrapperRaisingMethods» 
					
					«port.delegateWrapperControlOutMethods»
					
					@Override
					public void registerListener(«port.interfaceRealization.interface.implementationName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener) {
						// No operation as out event are not interpreted in case of control ports
					}
					
					@Override
					public List<«port.interfaceRealization.interface.implementationName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> getRegisteredListeners() {
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
			«FOR port : component.wrappedComponent.type.ports SEPARATOR System.lineSeparator»
				public class «port.name.toFirstUpper» implements «port.interfaceRealization.interface.implementationName».«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» {
					
					«port.delegateWrapperRaisingMethods»
					
					«port.delegateWrapperOutMethods(component.generateWrappedComponentName)»
					
					@Override
					public void registerListener(«port.interfaceRealization.interface.implementationName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener) {
						«component.generateWrappedComponentName».get«port.name.toFirstUpper»().registerListener(listener);
					}
					
					@Override
					public List<«port.interfaceRealization.interface.implementationName».Listener.«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> getRegisteredListeners() {
						return «component.generateWrappedComponentName».get«port.name.toFirstUpper»().getRegisteredListeners();
					}
					
				}
				
				@Override
				public «port.name.toFirstUpper» get«port.name.toFirstUpper»() {
					return «port.name.toFirstLower»;
				}
			«ENDFOR»
			
			/** Manual scheduling. */
			public void schedule() {
				«GAMMA_EVENT_CLASS» «EVENT_INSTANCE_NAME» = __asyncQueue.poll();
				if («EVENT_INSTANCE_NAME» == null) {
					// There was no event in the queue
					return;
				}
				processEvent(«EVENT_INSTANCE_NAME»);
				«IF component.hasInternalPort»handleInternalEvents();«ENDIF»
			}
			
			/** Operation. */
			@Override
			public void run() {
				while (!Thread.currentThread().isInterrupted()) {
					try {
						«GAMMA_EVENT_CLASS» «EVENT_INSTANCE_NAME» = __asyncQueue.take();		
						processEvent(«EVENT_INSTANCE_NAME»);
						«IF component.hasInternalPort»handleInternalEvents();«ENDIF»
					} catch (InterruptedException e) {
						interrupt();
					}
				}
			}
			
			private void processEvent(«GAMMA_EVENT_CLASS» «EVENT_INSTANCE_NAME») {
				if (!isControlEvent(«EVENT_INSTANCE_NAME»)) {
					// Event is forwarded to the wrapped component
					forwardEvent(«EVENT_INSTANCE_NAME»);
				}
				performControlActions(«EVENT_INSTANCE_NAME»);
			}
			
			private boolean isControlEvent(«GAMMA_EVENT_CLASS» «EVENT_INSTANCE_NAME») {
				«IF component.ports.empty && component.clocks.empty»
					return false;
				«ELSE»
					String portName = «EVENT_INSTANCE_NAME».getEvent().split("\\.")[0];
					return «FOR port : component.ports SEPARATOR " || "»portName.equals("«port.name»")«ENDFOR»«IF !component.ports.empty && !component.clocks.empty» || «ENDIF»«FOR clock : component.clocks SEPARATOR " || "»portName.equals("«clock.name»")«ENDFOR»;
				«ENDIF»
			}
			
			private void forwardEvent(«GAMMA_EVENT_CLASS» «EVENT_INSTANCE_NAME») {
				switch («EVENT_INSTANCE_NAME».getEvent()) {
					«component.generateWrapperEventHandlers()»
					default:
						throw new IllegalArgumentException("No such event!");
				}
			}
			
			private void performControlActions(«GAMMA_EVENT_CLASS» «EVENT_INSTANCE_NAME») {
				String[] eventName = «EVENT_INSTANCE_NAME».getEvent().split("\\.");
				«FOR controlSpecification : component.controlSpecifications»
					«IF controlSpecification.trigger instanceof AnyTrigger»
						// Any trigger
						«controlSpecification.controlFunction.generateRunCycle(component.generateWrappedComponentName)»
						return;
					«ELSE»
						«FOR match : AnyPortTriggersOfWrappers.Matcher.on(engine).getAllMatches(component, controlSpecification, null, null)»
							// Port trigger
							if (eventName.length == 2 && eventName[0].equals("«match.port.name»")) {
								«match.controlFunction.generateRunCycle(component.generateWrappedComponentName)»
								return;
							}
						«ENDFOR»
						«FOR match : PortEventTriggersOfWrappers.Matcher.on(engine).getAllMatches(component, controlSpecification, null, null, null)»
							// Port event trigger
							if (eventName.length == 2 && eventName[0].equals("«match.port.name»") && eventName[1].equals("«match.event.name»")) {
								«match.controlFunction.generateRunCycle(component.generateWrappedComponentName)»
								return;
							}
						«ENDFOR»
						«FOR match : ClockTriggersOfWrappers.Matcher.on(engine).getAllMatches(component, controlSpecification, null, null)»
							// Clock trigger
							if (eventName.length == 1 && eventName[0].equals("«match.clock.name»")) {
								«match.controlFunction.generateRunCycle(component.generateWrappedComponentName)»
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
				if (thread != null) {
					thread.interrupt();
				}
			}
			
			public «component.wrappedComponent.type.generateComponentClassName» get«component.generateWrappedComponentName.toFirstUpper»() {
				return «component.generateWrappedComponentName»;
			}
			
			«IF component.needTimer»
				public void setTimer(«UNIFIED_TIMER_INTERFACE» timer) {
					«IF !component.clocks.empty»timerService = timer;«ENDIF»
					«IF component.wrappedComponent.type.needTimer»«component.generateWrappedComponentName».setTimer(timer);«ENDIF»
					// No need for an explicit "init()" call here
					// The above delegated calls set the service into functioning state with clocks (so that "after 1 s" works with new timer as well)
				}
			«ENDIF»
			
			«component.createInternalEventHandlingCode»
			
		}
		'''
	}
	
	/**
	 * Generates the needed Java imports in case of the given composite component.
	 */
	protected def generateWrapperImports(AsynchronousAdapter component) '''
		import java.util.Collections;
		import java.util.List;
		
		import «PACKAGE_NAME».*;

		«FOR _package : component.containingPackage.componentImports.toSet /* For type declarations */
				.filter[it.containsComponentsOrInterfacesOrTypes]»
			import «_package.getPackageString(PACKAGE_NAME)».*;
		«ENDFOR»
		
		import «component.wrappedComponent.type.generateComponentPackageName».*;
	'''
	
	/**
	 * Sets the parameters of the component and instantiates the necessary components with them.
	 */
	protected def createInstances(AsynchronousAdapter component) '''
		«FOR parameter : component.parameterDeclarations»
			this.«parameter.name» = «parameter.name»;
		«ENDFOR»
		«component.generateWrappedComponentName» = new «component.wrappedComponent.type.generateComponentClassName»(«FOR argument : component.wrappedComponent.arguments SEPARATOR ", "»«argument.serialize»«ENDFOR»);
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
		«FOR event : port.inputEvents»
			@Override
			public void raise«event.name.toFirstUpper»(«event.generateParameters») {
				«FOR queue : QueuesOfEvents.Matcher.on(engine).getAllValuesOfqueue(port, event) SEPARATOR System.lineSeparator»
					«queue.name».«queue.additionMethodName»(new Event("«port.name».«event.name»"«IF event.generateArguments.length != 0», «ENDIF»«event.generateArguments»));
				«ENDFOR»
			}
		«ENDFOR»
	'''
	
	protected def getAdditionMethodName(MessageQueue queue) {
		val eventDiscardStrategy = queue.eventDiscardStrategy
		switch (eventDiscardStrategy) {
			case DiscardStrategy.INCOMING:
				return "offer"
			case DiscardStrategy.OLDEST:
				return "push"
			default:
				throw new IllegalStateException("Not known strategy: " + eventDiscardStrategy)
		}
	}
	
	/**
	 * Generates methods for out-event checks in case of control ports of wrapper components.
	 */
	protected def CharSequence delegateWrapperControlOutMethods(Port port) '''
«««		Simple flag checks
		«FOR event : port.outputEvents SEPARATOR System.lineSeparator»
			@Override
			public boolean isRaised«event.name.toFirstUpper»() {
				// No real operation as out event are not interpreted in the case of control ports
				return false;
			}
«««			ValueOf checks
			«FOR parameter : event.parameterDeclarations»
				@Override
				public «parameter.type.transformType» get«parameter.name.toFirstUpper»() {
					// No real operation as out event are not interpreted in the case of control ports
					throw new IllegalAccessException("No value can be accessed!");
				}
			«ENDFOR»
		«ENDFOR»
	'''
	
	/**
	 * Generates methods for out-event checks in case of wrapped ports of wrapper components.
	 */
	protected def CharSequence delegateWrapperOutMethods(Port port, String instanceName) '''
«««		Simple flag checks
		«FOR event : port.outputEvents SEPARATOR System.lineSeparator»
			@Override
			public boolean isRaised«event.name.toFirstUpper»() {
				return «instanceName».get«port.name.toFirstUpper»().isRaised«event.name.toFirstUpper»();
			}
«««			ValueOf checks
			«FOR parameter : event.parameterDeclarations»
				@Override
				public «parameter.type.transformType» get«parameter.name.toFirstUpper»() {
					return «instanceName».get«port.name.toFirstUpper»().get«parameter.name.toFirstUpper»();
				}
			«ENDFOR»
		«ENDFOR»
	'''
	
	/**
	* Generates event handlers for wrapped in ports of the given wrapper component .
	*/
	protected def generateWrapperEventHandlers(AsynchronousAdapter component) '''
		«FOR queue : component.messageQueues»
			«FOR portEvent : queue.storedEvents
					.filter[component.wrappedComponent.derivedType.allPorts.contains(it.key)]»
				case "«portEvent.key.name».«portEvent.value.name»":
					«component.generateWrappedComponentName».get«
					queue.getTargetPortEvent(portEvent).key.name.toFirstUpper»().raise«
						queue.getTargetPortEvent(portEvent).value.name.toFirstUpper»(«
							FOR parameter : portEvent.value.parameterDeclarations SEPARATOR ", "» («
								parameter.type.transformType») event.getValue()[«
									portEvent.value.parameterDeclarations.indexOf(parameter)»]«ENDFOR»);
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
			default: '''''' // Probably queue-related control functions
			// TODO Add queue-related control
		}
	}
	
	/**
	 * Serializes the value of the given time specification with respect to the time unit. 
	 */
	protected def getValueInNanoseconds(TimeSpecification specification) {
		val unit = specification.unit
		val value = specification.value
		if (unit == TimeUnit.NANOSECOND) {
			return value.serialize
		}
		if (unit == TimeUnit.MICROSECOND) {
			return "(" + value.serialize + ") * 1000l";
		}
		if (unit == TimeUnit.MILLISECOND) {
			return "(" + value.serialize + ") * 1000000l";
		}
		if (unit == TimeUnit.SECOND) {
			return "(" + value.serialize + ") * 1000000000l";
		}
		if (unit == TimeUnit.HOUR) {
			return "(" + value.serialize + ") * 60 * 60 * 1000000000l";
		}
		return value.serialize
	}
	
}