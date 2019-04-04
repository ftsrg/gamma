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
package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.constraint.model.BooleanTypeDefinition
import hu.bme.mit.gamma.constraint.model.IntegerTypeDefinition
import hu.bme.mit.gamma.constraint.model.ParameterDeclaration
import hu.bme.mit.gamma.constraint.model.DecimalTypeDefinition
import hu.bme.mit.gamma.statechart.model.AnyTrigger
import hu.bme.mit.gamma.statechart.model.Component
import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.RealizationMode
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.TimeSpecification
import hu.bme.mit.gamma.statechart.model.TimeUnit
import hu.bme.mit.gamma.statechart.model.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.ControlFunction
import hu.bme.mit.gamma.statechart.model.composite.PortBinding
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.SynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.statechart.model.interface_.EventDeclaration
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import hu.bme.mit.gamma.statechart.model.interface_.Interface
import hu.bme.mit.gamma.codegenerator.java.queries.AbstractSynchronousCompositeComponents
import hu.bme.mit.gamma.codegenerator.java.queries.AnyPortTriggersOfWrappers
import hu.bme.mit.gamma.codegenerator.java.queries.AsynchronousCompositeComponents
import hu.bme.mit.gamma.codegenerator.java.queries.BroadcastChannels
import hu.bme.mit.gamma.codegenerator.java.queries.ClockTriggersOfWrappers
import hu.bme.mit.gamma.codegenerator.java.queries.EventToEvent
import hu.bme.mit.gamma.codegenerator.java.queries.Interfaces
import hu.bme.mit.gamma.codegenerator.java.queries.PortEventTriggersOfWrappers
import hu.bme.mit.gamma.codegenerator.java.queries.QueuesOfClocks
import hu.bme.mit.gamma.codegenerator.java.queries.QueuesOfEvents
import hu.bme.mit.gamma.codegenerator.java.queries.SimpleChannels
import hu.bme.mit.gamma.codegenerator.java.queries.SimpleComponents
import hu.bme.mit.gamma.codegenerator.java.queries.SynchronousComponentWrappers
import hu.bme.mit.gamma.codegenerator.java.queries.Traces
import java.io.File
import java.io.FileWriter
import java.util.Collection
import java.util.Collections
import java.util.HashSet
import java.util.Set
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.api.IPatternMatch
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.api.ViatraQueryMatcher
import org.eclipse.viatra.query.runtime.emf.EMFScope
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRule
import org.eclipse.viatra.transformation.runtime.emf.rules.batch.BatchTransformationRuleFactory
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformation
import org.eclipse.viatra.transformation.runtime.emf.transformation.batch.BatchTransformationStatements
import org.yakindu.base.types.Direction
import org.yakindu.base.types.Type
import org.yakindu.sct.model.sgraph.Statechart
import org.yakindu.sct.model.stext.stext.InterfaceScope

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponent

class GlueCodeGenerator {
	// Transformation-related extensions
	extension BatchTransformation transformation 
	extension BatchTransformationStatements statements	
	// Transformation rule-related extensions
	extension BatchTransformationRuleFactory = new BatchTransformationRuleFactory
	// Query engines and resources
	protected final ViatraQueryEngine engine
	protected final ResourceSet resSet
	protected Component topComponent
	// File URIs where the classes need to be saved
	protected final String parentPackageUri
	protected final String eventUri
	protected final String channelUri
	protected final String interfaceUri
	protected final String timerUri
	// The base of the package name: hu.bme.mit.gamma.impl
	protected final String packageName
	// The base of the package name of the generated Yakindu components, not org.yakindu.scr anymore
	protected final String yakinduPackageName
	// Attributes of the message class
	protected final String EVENT_CLASS_NAME = "Event"	
	protected final String GET_EVENT_METHOD = "getEvent"	
	protected final String GET_VALUE_METHOD = "getValue"	
	protected final String EVENT_QUEUE = "eventQueue"	
	protected final String INSERT_QUEUE = "insertQueue"	
	protected final String PROCESS_QUEUE = "processQueue"	
	protected final String EVENT_INSTANCE_NAME = "event"	
	protected final String CHANNEL_CLASS_NAME = "Channel"
	protected final String CHANNEL_NAME = "channels"	
	protected final String INTERFACES_NAME = "interfaces"
	protected final String VIRTUAL_TIMER_CLASS_NAME = "VirtualTimerService"
	protected final String ITIMER_INTERFACE_NAME = "ITimer"
	protected final String ITIMER_CALLBACK_INTERFACE_NAME = "ITimerCallback"
	protected final String TIMER_SERVICE_CLASS_NAME = "TimerService"
	protected final String TIMER_OBJECT_NAME = "timer"
	// Expression serializer
	protected final extension ExpressionSerializer serializer = new ExpressionSerializer
	// Transformation rules
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> portInterfaceRule
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> simpleComponentsRule
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> synchronousCompositeComponentsRule
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> synchronousComponentWrapperRule
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> channelsRule
	protected BatchTransformationRule<? extends IPatternMatch, ? extends ViatraQueryMatcher<?>> asynchronousCompositeComponentsRule
	
	new(ResourceSet resourceSet, String basePackageName, String srcGenFolderUri) {
		this.packageName = basePackageName
		this.yakinduPackageName = basePackageName
		this.resSet = resourceSet
		this.resSet.loadModels
		engine = ViatraQueryEngine.on(new EMFScope(resSet))
		this.parentPackageUri = srcGenFolderUri + File.separator + basePackageName.replaceAll("\\.", "/");
		this.eventUri = this.parentPackageUri + File.separator + EVENT_INSTANCE_NAME
		this.channelUri = this.parentPackageUri + File.separator + CHANNEL_NAME
		this.interfaceUri = this.parentPackageUri + File.separator + INTERFACES_NAME
		this.timerUri = this.parentPackageUri
		setup
	}
	
	/**
	 * Loads the the top component from the resource set. 
	 */
	private def loadModels(ResourceSet resourceSet) {
		for (resource : resourceSet.resources) {
			// To eliminate empty resources
			if (!resource.getContents.empty) {
				if (resource.getContents.get(0) instanceof Package) {
					val gammaPackage = resource.getContents.get(0) as Package
					val components = gammaPackage.components
					if (!components.isEmpty) {
						topComponent = components.head
						return
					}
				}							
			}
		}	
	}
	
	/**
	 * Sets up the transformation infrastructure.
	 */
	protected def setup() {
		//Create VIATRA Batch transformation
		transformation = BatchTransformation.forEngine(engine).build
		//Initialize batch transformation statements
		statements = transformation.transformationStatements
	}

	/**
	 * Executes the code generation.
	 */
	def execute() {
		checkUniqueInterfaceNames
		generateEventClass
		if (topComponent.needTimer) {				
			// Virtual timer is generated only if there are timing specs (triggers) in the model
			generateTimerClasses	
		}	
		getPortInterfaceRule.fireAllCurrent
		getSimpleComponentDeclarationRule.fireAllCurrent
		getSynchronousCompositeComponentsRule.fireAllCurrent
		if (hasSynchronousWrapper) {
			generateLinkedBlockingMultiQueueClasses
		}
		getSynchronousComponentWrapperRule.fireAllCurrent
		if (hasAsynchronousComposite) {
			getChannelsRule.fireAllCurrent
		}
		getAsynchronousCompositeComponentsRule.fireAllCurrent
	}	
	
	/**
	 * Checks whether the ports are connected properly.
	 */
	protected def checkUniqueInterfaceNames() {
		val interfaces = Interfaces.Matcher.on(engine).allValuesOfinterface
		val nameSet = new HashSet<String>
		for (name : interfaces.map[it.name.toLowerCase]) {
			if (nameSet.contains(name)) {
				throw new IllegalArgumentException("Same interface names: " + name + "! Interface names must differ in more than just their initial character!")
			}
			nameSet.add(name)
		}
	}
	
	/**
	 * Returns the containing package of a component.
	 */
	protected def getContainingPackage(Component component) {
		return component.eContainer as Package
	}

	/**
	 * Returns the Java package name of the class generated from the component.
	 */
	protected def componentPackageName (Component component) '''«packageName».«(component.containingPackage).name.toLowerCase»'''
 	
 	/**
		 * Returns the name of the Java interface generated from the given Gamma interface. 
		 */
		protected def generateName(Interface anInterface) {
			return anInterface.name.toFirstUpper + "Interface"
		}
		
		/**
		 * Returns the name of the Java channel interface generated from the given Gamma interface. 
		 */
		protected def generateChannelName(Interface anInterface) {
			return anInterface.name.toFirstUpper + "Channel"
		}
		
		/**
		 * Returns the name of the Java channel interface generated from the given Gamma interface. 
		 */
		protected def generateChannelInterfaceName(Interface anInterface) {
			return anInterface.generateChannelName + "Interface"
		}
		
		/**
	 * Returns the name of the Java class of the component (the Yakindu statemachine wrapper).
	 */
	protected def getComponentClassName(Component component) {
		return component.name.toFirstUpper
	}
		
	/**
	 * Returns the name of the Yakindu statemachine the given component is transformed from.
	 * They use it for package namings. It does not contain the "Statemachine" suffix."
	 */
	protected def getYakinduStatemachineName(Component component) {
		return component.containingPackage.name
	}
	
	/**
	 * Returns the name of the statemachine class generated by Yakindu.
	 */
	protected def getStatemachineClassName(Component component) {
		return component.yakinduStatemachineName + "Statemachine"
	}
	
	/**
	 * Returns the name of the wrapped Yakindu statemachine instance.
	 */
	protected def getStatemachineInstanceName(Component component) {
		return component.statemachineClassName.toFirstLower
	}
	
	/**
	 * Returns the name of the wrapped Yakindu statemachine instance.
	 */
	protected def getWrappedComponentName(AsynchronousAdapter wrapper) {
		return wrapper.wrappedComponent.name.toFirstLower
	}
 	
 	/**
 	 * Returns whether the given component is a simple component (statechart).
 	 */
	protected def isSimple(Component component) {
		return SimpleComponents.Matcher.on(engine).hasMatch(component)
	}
	
	protected def hasNamelessInterface(Component component) {
		if (!component.isSimple) {
			return false
		}
		val yakinduStatecharts = component.allValuesOfFrom
		if (yakinduStatecharts.size != 1) {
			throw new IllegalArgumentException("More than one Yakindu statechart: " + yakinduStatecharts)
		}
		return yakinduStatecharts.filter(Statechart).head
				.scopes.filter(InterfaceScope).exists[it.name === null]
	}
	
	/**
	 * Returns whether there is a synchronous component wrapper in the model.
	 */
	protected def hasSynchronousWrapper() {
		return SynchronousComponentWrappers.Matcher.on(engine).hasMatch
	}
	
	/**
	 * Returns whether there is a synchronous component wrapper in the model.
	 */
	protected def hasAsynchronousComposite() {
		return AsynchronousCompositeComponents.Matcher.on(engine).hasMatch
	}
		
	/**
	 * Creates and saves the message class that is responsible for informing the statecharts about the event that has to be raised (with the given value).
	 */
	protected def generateEventClass() {
		val code = createEventClassCode
		code.saveCode(eventUri + File.separator + EVENT_CLASS_NAME + ".java")
	}
	
	/**
	 * Creates and saves the message class that is responsible for informing the statecharts about the event that has to be raised (with the given value).
	 */
	protected def generateTimerClasses() {
		val virtualTimerClassCode = createVirtualTimerClassCode
		virtualTimerClassCode.saveCode(parentPackageUri + File.separator + VIRTUAL_TIMER_CLASS_NAME + ".java")
		val timerInterfaceCode = createITimerInterfaceCode
		timerInterfaceCode.saveCode(parentPackageUri + File.separator + ITIMER_INTERFACE_NAME + ".java")
		val timerCallbackInterface = createITimerCallbackInterfaceCode
		timerCallbackInterface.saveCode(parentPackageUri + File.separator + ITIMER_CALLBACK_INTERFACE_NAME + ".java")
		val timerServiceClass = createTimerServiceClassCode
		timerServiceClass.saveCode(parentPackageUri + File.separator + TIMER_SERVICE_CLASS_NAME + ".java")
	}
	
	/**
	 * Creates the virtual timer class for the timings in the generated test cases.
	 */
	protected def createVirtualTimerClassCode() '''
		package «yakinduPackageName»;
		
		import java.util.ArrayList;
		import java.util.List;
		
		/**
		 * Virtual timer service implementation.
		 */
		public class «VIRTUAL_TIMER_CLASS_NAME» implements ITimer {
			
			private final List<TimeEventTask> timerTaskList = new ArrayList<TimeEventTask>();
			
			/**
			 * Timer task that reflects a time event. It's internally used by TimerService.
			 */
			private class TimeEventTask {
			
				private «ITIMER_CALLBACK_INTERFACE_NAME» callback;
			
				int eventID;
				
				private boolean periodic;
				private final long time;
				private long timeLeft;
			
				/**
				 * Constructor for a time event.
				 * 
				 * @param callback: Set to true if event should be repeated periodically.
				 * @param eventID: index position within the state machine's timeEvent array.
				 */
				public TimeEventTask(«ITIMER_CALLBACK_INTERFACE_NAME» callback, int eventID, long time, boolean isPeriodic) {
					this.callback = callback;
					this.eventID = eventID;
					this.time = time;
					this.timeLeft = time;
					this.periodic = isPeriodic;
				}
			
				public void run() {
					callback.timeElapsed(eventID);
				}
			
				public boolean equals(Object obj) {
					if (obj instanceof TimeEventTask) {
						return ((TimeEventTask) obj).callback.equals(callback)
								&& ((TimeEventTask) obj).eventID == eventID;
					}
					return super.equals(obj);
				}
				
				public void elapse(long amount) {				
					if (timeLeft <= 0) {
						return;
					}
					timeLeft -= amount;
					if (timeLeft <= 0) {
						run();
						if (periodic) {
							timeLeft = time + timeLeft;
						}
					}
				}
			}
			
			@Override
			public void setTimer(«ITIMER_CALLBACK_INTERFACE_NAME» callback, int eventID, long time, boolean isPeriodic) {	
				// Creating a new TimerTask for given event and storing it
				TimeEventTask timerTask = new TimeEventTask(callback, eventID, time, isPeriodic);
				timerTaskList.add(timerTask);
			}
			
			@Override
			public void unsetTimer(«ITIMER_CALLBACK_INTERFACE_NAME» callback, int eventID) {
				for (TimeEventTask timer : new ArrayList<TimeEventTask>(timerTaskList)) {
					if (timer.callback.equals(callback) && timer.eventID == eventID) {
						timerTaskList.remove(timer);
					}
				}
			}
			
			public void elapse(long amount) {
				for (TimeEventTask timer : timerTaskList) {
					timer.elapse(amount);
				}
			}
		
		}
	'''
	
	/**
	 * Creates the ITimer interface for the timings.
	 */
	protected def createITimerInterfaceCode() '''
		/**
		 * Based on the Yakindu ITimer interface.
		 */ 
		package «yakinduPackageName»;
		public interface «ITIMER_INTERFACE_NAME» {
			
			void setTimer(«ITIMER_CALLBACK_INTERFACE_NAME» callback, int eventID, long time, boolean isPeriodic);
			void unsetTimer(«ITIMER_CALLBACK_INTERFACE_NAME» callback, int eventID);
			
		}
	'''
	
	 /**
	 * Creates the ITimerCallback interface for the timings.
	 */
	protected def createITimerCallbackInterfaceCode() '''
		/**
		 * Based on the Yakindu ITimerCallback interface.
		 */ 
		package «packageName»;
		public interface «ITIMER_CALLBACK_INTERFACE_NAME» {
			
			void timeElapsed(int eventID);
			
		}
	'''
	
	/**
	 * Creates the TimerService class for the timings.
	 */
	protected def createTimerServiceClassCode() '''
		/**
		 * Based on the Yakindu TimerService class.
		 */ 
		package «packageName»;
		
		import java.util.ArrayList;
		import java.util.List;
		import java.util.Timer;
		import java.util.TimerTask;
		import java.util.concurrent.locks.Lock;
		import java.util.concurrent.locks.ReentrantLock;
		
		public class «TIMER_SERVICE_CLASS_NAME» implements «ITIMER_INTERFACE_NAME» {
		
			private final Timer timer = new Timer();
			private final List<TimeEventTask> timerTaskList = new ArrayList<TimeEventTask>();
			private final Lock lock = new ReentrantLock();
			
			/**
			 * Timer task that reflects a time event. It's internally used by
			 * {@link TimerService}.
			 *
			 */
			private class TimeEventTask extends TimerTask {
			
				private «ITIMER_CALLBACK_INTERFACE_NAME» callback;
				int eventID;
			
				/**
				 * Constructor for a time event.
				 *
				 * @param callback: Object that implements ITimerCallback, is called when the timer expires.
				 * @param eventID: Index position within the state machine's timeEvent array.
				 */
				public TimeEventTask(«ITIMER_CALLBACK_INTERFACE_NAME» callback, int eventID) {
					this.callback = callback;
					this.eventID = eventID;
				}
			
				public void run() {
					callback.timeElapsed(eventID);
				}
				
				@Override
				public boolean equals(Object obj) {
					if (obj instanceof TimeEventTask) {
						return ((TimeEventTask) obj).callback.equals(callback)
								&& ((TimeEventTask) obj).eventID == eventID;
					}
					return super.equals(obj);
				}
				
				@Override
				public int hashCode() {
					int prime = 37;
					int result = 1;
					
					int c = (int) this.eventID;
					result = prime * result + c;
					c = this.callback.hashCode();
					result = prime * result + c;
					return result;
				}
				
			}
			
			public void setTimer(«ITIMER_CALLBACK_INTERFACE_NAME» callback, int eventID,
					long time, boolean isPeriodic) {
			
				// Create a new TimerTask for given event and store it.
				TimeEventTask timerTask = new TimeEventTask(callback, eventID);
				lock.lock();
				timerTaskList.add(timerTask);
			
				// start scheduling the timer
				if (isPeriodic) {
					timer.scheduleAtFixedRate(timerTask, time, time);
				} else {
					timer.schedule(timerTask, time);
				}
				lock.unlock();
			}
			
			public void unsetTimer(«ITIMER_CALLBACK_INTERFACE_NAME» callback, int eventID) {
				lock.lock();
				int index = timerTaskList.indexOf(new TimeEventTask(callback, eventID));
				if (index != -1) {
					timerTaskList.get(index).cancel();
					timer.purge();
					timerTaskList.remove(index);
				}
				lock.unlock();
			}
			
			/**
			 * Cancel timer service. Use this to end possible timing threads and free
			 * memory resources.
			 */
			public void cancel() {
				lock.lock();
				timer.cancel();
				timer.purge();
				lock.unlock();
			}
			
		}
	'''
	
	/**
	 * Returns the code of the message class.
	 */
	protected def createEventClassCode() '''
		package «packageName».«EVENT_INSTANCE_NAME»;
		
		public class «EVENT_CLASS_NAME» {
		
			private String event;
			
			private Object value;
			
			public «EVENT_CLASS_NAME»(String event, Object value) {
				this.event = event;
				this.value = value;
			}
			
			public String getEvent() {
				return event;
			}
			
			public Object getValue() {
				return value;
			}
		
		}
	'''
	
	/**
	 * Creates a Java interface for each Port Interface.
	 */
	protected def getPortInterfaceRule() {
		if (portInterfaceRule === null) {
			 portInterfaceRule = createRule(Interfaces.instance).action [
				val code = it.interface.generatePortInterfaces
				code.saveCode(parentPackageUri + File.separator + INTERFACES_NAME + File.separator + it.interface.generateName + ".java")
			].build		
		}
		return portInterfaceRule
	}
	
	protected def generatePortInterfaces(Interface anInterface) {
			val interfaceCode = '''
				package «packageName».«INTERFACES_NAME»;
				
				import java.util.List;
				
				public interface «anInterface.generateName» {
					
					interface Provided extends Listener.Required {
						
						«anInterface.generateIsRaisedInterfaceMethods(EventDirection.IN)»
						
						void registerListener(Listener.Provided listener);
						List<Listener.Provided> getRegisteredListeners();
					}
					
					interface Required extends Listener.Provided {
						
						«anInterface.generateIsRaisedInterfaceMethods(EventDirection.OUT)»
						
						void registerListener(Listener.Required listener);
						List<Listener.Required> getRegisteredListeners();
					}
					
					interface Listener {
						
						interface Provided «IF !anInterface.parents.empty»extends «FOR parent : anInterface.parents»«parent.generateName».Listener.Provided«ENDFOR»«ENDIF» {
							«FOR event : anInterface.events.filter[it.direction != EventDirection.IN]»
								void raise«event.event.name.toFirstUpper»(«event.generateParameter»);
							«ENDFOR»							
						}
						
						interface Required «IF !anInterface.parents.empty»extends «FOR parent : anInterface.parents»«parent.generateName».Listener.Required«ENDFOR»«ENDIF» {
							«FOR event : anInterface.events.filter[it.direction != EventDirection.OUT]»
								void raise«event.event.name.toFirstUpper»(«event.generateParameter»);
							«ENDFOR»  					
						}
						
					}
				} 
			'''
			return interfaceCode
		}	
		
	protected def generateIsRaisedInterfaceMethods(Interface anInterface, EventDirection oppositeDirection) '''
		«««		Simple flag checks
	«FOR event : anInterface.events.filter[it.direction != oppositeDirection].map[it.event]»
			public boolean isRaised«event.name.toFirstUpper»();
		«««		ValueOf checks	
				«IF event.parameterDeclarations.size > 0»
					public «event.parameterDeclarations.eventParameterType» get«event.name.toFirstUpper»Value();
				«ENDIF»
		«ENDFOR»
		'''
		
		/**
		 * Returns the parameter type and name of the given event declaration, e.g., long value.
		 */
		protected def generateParameter(EventDeclaration eventDeclaration) '''
		«IF eventDeclaration.event.parameterDeclarations.size > 0»
			«eventDeclaration.event.parameterDeclarations.eventParameterType» «eventDeclaration.event.parameterDeclarations.eventParameterValue»«ENDIF»'''
		
		/**
		 * Returns the parameter name of the given event declaration, e.g., value.
		 */
	protected def generateParameterValue(EventDeclaration eventDeclaration) '''
		«IF eventDeclaration.event.parameterDeclarations.size > 0»
			«eventDeclaration.event.parameterDeclarations.eventParameterValue»«ENDIF»'''
	
	/**
	 * Creates a Java class for each component given in the component model.
	 */
	protected def getSimpleComponentDeclarationRule() {
		if (simpleComponentsRule === null) {
			 simpleComponentsRule = createRule(SimpleComponents.instance).action [
				val componentUri = parentPackageUri + File.separator + it.statechartDefinition.containingPackage.name.toLowerCase
				val code = it.statechartDefinition.createSimpleComponentClass
				code.saveCode(componentUri + File.separator + it.statechartDefinition.componentClassName + ".java")
				// Generating the interface for returning the Ports
				val interfaceCode = it.statechartDefinition.generateComponentInterface
				interfaceCode.saveCode(componentUri + File.separator + it.statechartDefinition.portOwnerInterfaceName + ".java")
			].build		
		}
		return simpleComponentsRule
	}
		
	/**
	 * Creates the Java code for the given component.
	 */
	protected def createSimpleComponentClass(Component component) '''		
		package «component.componentPackageName»;
		
		«component.generateSimpleComponentImports»
		
		public class «component.componentClassName» implements «component.portOwnerInterfaceName» {
			// The wrapped Yakindu statemachine
			private «component.statemachineClassName» «component.statemachineInstanceName»;
			// Port instances
			«FOR port : component.ports»
				private «port.name.toFirstUpper» «port.name.toFirstLower»;
			«ENDFOR»
			// Indicates which queues are active in this cycle
			private boolean «INSERT_QUEUE» = true;
			private boolean «PROCESS_QUEUE» = false;
			// Event queues for the synchronization of statecharts
			private Queue<«EVENT_CLASS_NAME»> «EVENT_QUEUE»1 = new LinkedList<«EVENT_CLASS_NAME»>();
			private Queue<«EVENT_CLASS_NAME»> «EVENT_QUEUE»2 = new LinkedList<«EVENT_CLASS_NAME»>();
			«component.generateParameterDeclarationFields»
			
			public «component.componentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", "»«parameter.type.transformType» «parameter.name»«ENDFOR») {
				«FOR parameter : component.parameterDeclarations SEPARATOR ", "»
					this.«parameter.name» = «parameter.name»;
				«ENDFOR»
				«component.statemachineInstanceName» = new «component.statemachineClassName»();
				«FOR port : component.ports»
					«port.name.toFirstLower» = new «port.name.toFirstUpper»();
				«ENDFOR»
				«IF component.needTimer»«component.statemachineInstanceName».setTimer(new TimerService());«ENDIF»
			}
			
			/** Resets the statemachine. Must be called to initialize the component. */
			@Override
			public void reset() {
				«component.statemachineInstanceName».init();
				«component.statemachineInstanceName».enter();
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
			private Queue<«EVENT_CLASS_NAME»> getInsertQueue() {
				if («INSERT_QUEUE») {
					return «EVENT_QUEUE»1;
				}
				return «EVENT_QUEUE»2;
			}
			
			/** Returns the event queue from which events should be inspected in the particular cycle. */
			private Queue<«EVENT_CLASS_NAME»> getProcessQueue() {
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
				Queue<«EVENT_CLASS_NAME»> «EVENT_QUEUE» = getProcessQueue();
				while (!«EVENT_QUEUE».isEmpty()) {
						«EVENT_CLASS_NAME» «EVENT_INSTANCE_NAME» = «EVENT_QUEUE».remove();
						switch («EVENT_INSTANCE_NAME».«GET_EVENT_METHOD»()) {
							«component.generateEventHandlers()»
							default:
								throw new IllegalArgumentException("No such event!");
						}
				}
				«component.statemachineInstanceName».runCycle();
			}			
			
			// Inner classes representing Ports
			«FOR port : component.ports SEPARATOR "\n"»
				public class «port.name.toFirstUpper» implements «port.implementedJavaInterface» {
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
					return «component.statemachineInstanceName».getSCInterface();
				}
			«ENDIF»
			
			/** Checks whether the wrapped statemachine is in the given state. */
			public boolean isStateActive(State state) {
				return «component.statemachineInstanceName».isStateActive(state);
			}
			
			«IF component.needTimer»
				public void setTimer(«ITIMER_INTERFACE_NAME» timer) {
					«component.statemachineInstanceName».setTimer(timer);
					reset();
				}
			«ENDIF»
			
		}
	'''
	
	/**
	 * Generates fields for parameter declarations
	 */
	protected def CharSequence generateParameterDeclarationFields(Component component) '''
		«IF !component.parameterDeclarations.empty»// Fields representing parameters«ENDIF»
		«FOR parameter : component.parameterDeclarations»
			private final «parameter.type.transformType» «parameter.name»;
		«ENDFOR»
	'''
	
	/**
	 * Returns the name of the Java interface the given port realizes, e.g., Controller.Required.
	 */
	protected def getImplementedJavaInterface(Port port) '''«port.interfaceRealization.interface.generateName».«port.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»'''
	
	/**
	 * Returns the opposite realitation mode of the given realization mode.
	 */
	protected def getOppositeRealizationMode(RealizationMode type) {
		switch (type) {
			case RealizationMode.PROVIDED:
				return RealizationMode.REQUIRED
			case RealizationMode.REQUIRED:
				return RealizationMode.PROVIDED
			default:
				throw new IllegalArgumentException("No such type: " + type)
		}
	}
	
	/**
	 * Generates methods that for in-event raisings in case of simple components.
	 */
	protected def CharSequence generateRaisingMethods(Port port) '''
		«FOR event : Collections.singletonList(port).getSemanticEvents(EventDirection.IN) SEPARATOR "\n"»
			@Override
			public void raise«event.name.toFirstUpper»(«(event.eContainer as EventDeclaration).generateParameter») {
				getInsertQueue().add(new «EVENT_CLASS_NAME»("«port.name.toFirstUpper».«event.name.toFirstUpper»", «event.toYakinduEvent(port).valueOrNull»));
			}
		«ENDFOR»
	'''
	
	/**
	 * Generates methods that for in-event raisings in case of composite components.
	 */
	protected def CharSequence delegateRaisingMethods(PortBinding connector) '''
		«FOR event : Collections.singletonList(connector.instancePortReference.port).getSemanticEvents(EventDirection.IN) SEPARATOR "\n"»
			@Override
			public void raise«event.name.toFirstUpper»(«(event.eContainer as EventDeclaration).generateParameter») {
				«connector.instancePortReference.instance.name».get«connector.instancePortReference.port.name.toFirstUpper»().raise«event.name.toFirstUpper»(«event.parameterDeclarations.head.eventParameterValue»);
			}
		«ENDFOR»
	'''	
	
	/**
	 * Returns the Java type of the given Yakindu type as a string.
	 */
	protected def getEventParameterType(Type type) {
		if (type !== null) {
			return type.name.transformType
		}
		return ""
	}
	
	/**
	 * Returns the Java type of the Yakindu type given in a singleton Colleection as a string.
	 */
	protected def String getEventParameterType(Collection<? extends ParameterDeclaration> parameters) {
		if (!parameters.empty) {
			if (parameters.size > 1) {
				throw new IllegalArgumentException("More than one parameter: " + parameters)
			}
			return parameters.head.type.transformType
		}
		return ""
	}
	
	/**
	 * Returns a "value" sting, if the given port refers to a typed event, "null" otherwise. Can be used, if the we want to create a message.
	 */
	protected def valueOrNull(org.yakindu.base.types.Event event) {
		if (event.type !== null) {
			return event.type.eventParameterValue
		}
		return "null"
	}
	
	/**
	 * Returns a "value" sting, if the given port refers to a typed event, "null" otherwise. Can be used, if the we want to create a message.
	 */
	protected def valueOrNull(Event event) {
		if (!event.parameterDeclarations.empty) {
			return event.parameterDeclarations.head.eventParameterValue
		}
		return "null"
	}
	
	/**
	 * Returns the parameter name of an event, or an empty string if the event has no parameter (type is null).
	 */
	protected def getEventParameterValue(Object type) {
		if (type !== null) {
			return "value"
		}
		return ""
	}
	
	/**
	 * Returns the Java type equivalent of the Gamma type.
	 */
	protected def transformType(hu.bme.mit.gamma.constraint.model.Type type) {
		switch (type) {
			IntegerTypeDefinition: {
				val types = type.getAllValuesOfFrom.filter(Type).toSet
				val strings = types.filter[it.name.equals("string")]
				val integers = types.filter[it.name.equals("integer")]
				if (strings.size > 0 && integers.size > 0) {
					throw new IllegalArgumentException("Integers and string mapped to the same integer type: " + type)
				}
				if (strings.size > 0) {
					return "string"
				}
				else {
					return "long"
				}
			}				
			BooleanTypeDefinition: 
				return "boolean"
			DecimalTypeDefinition: 
				return "double"
			default:
				throw new IllegalArgumentException("Not known type: " + type)
		}
	}
	
	/**
	 * Returns the Java type equivalent of the Yakindu type.
	 */
	protected def transformType(String type) {
		switch (type) {
			case "integer": 
				return "long"
			case "string": 
				return "String"
			case "real": 
				return "double"
			default:
				return type
		}
	}
	
	/**
	 * Returns the Yakindu event the given Gamma event is generated from.
	 */
	protected def org.yakindu.base.types.Event toYakinduEvent(Event event, Port port) {
		val yEvents = EventToEvent.Matcher.on(engine).getAllValuesOfyEvent(port, event)
		if (yEvents.size != 1) {
			throw new IllegalArgumentException("Not one Yakindu event mapped to Gamma event. Gamma port: " + port.name + ". " + "Gamma event: " + event.name + ". Yakindu event size: " + yEvents.size + ". Yakindu events:" + yEvents)
		}
		return yEvents.head
	}
	
	/**
	 * Generates methods for out-event checks in case of simple components.
	 */
	protected def CharSequence generateOutMethods(Component component, Port port) '''
«««		Simple flag checks
		«FOR event : Collections.singletonList(port).getSemanticEvents(EventDirection.OUT)»
			@Override
			public boolean isRaised«event.name.toFirstUpper»() {
				«IF port.name === null»
					return «component.statemachineInstanceName».isRaised«event.toYakinduEvent(port).name.toFirstUpper»();
				«ELSE»
					return «component.statemachineInstanceName».get«port.yakinduRealizationModeName»().isRaised«event.toYakinduEvent(port).name.toFirstUpper»();
				«ENDIF»
			}
«««		ValueOf checks
			«IF event.toYakinduEvent(port).type !== null»
				@Override
				public «event.toYakinduEvent(port).type.eventParameterType» get«event.name.toFirstUpper»Value() {
					return «component.statemachineInstanceName».get«port.yakinduRealizationModeName»().get«event.toYakinduEvent(port).name.toFirstUpper»Value();
				}
			«ENDIF»
		«ENDFOR»
	'''
	
	/**
	 * Generates methods for own out-event checks in case of composite components.
	 */
	protected def CharSequence implementOutMethods(PortBinding connector) '''
«««		Simple flag checks
		«FOR event : Collections.singletonList(connector.compositeSystemPort).getSemanticEvents(EventDirection.OUT) SEPARATOR "\n"»
			@Override
			public boolean isRaised«event.name.toFirstUpper»() {
				return isRaised«event.name.toFirstUpper»;
			}
«««		ValueOf checks
			«IF !event.parameterDeclarations.empty»
				@Override
				public «event.toYakinduEvent(connector.compositeSystemPort).type.eventParameterType» get«event.name.toFirstUpper»Value() {
					return «event.name.toFirstLower»Value;
				}
			«ENDIF»
		«ENDFOR»
	'''
	
	/**
	 * Generates methods for out-event check delegations in case of composite components.
	 */
	protected def CharSequence delegateOutMethods(PortBinding connector) '''
«««		Simple flag checks
		«FOR event : Collections.singletonList(connector.compositeSystemPort).getSemanticEvents(EventDirection.OUT)»
			@Override
			public boolean isRaised«event.name.toFirstUpper»() {
				return «connector.instancePortReference.instance.name».get«connector.instancePortReference.port.name.toFirstUpper»().isRaised«event.name.toFirstUpper»();
			}
«««		ValueOf checks
			«IF !event.parameterDeclarations.empty»
				@Override
				public «event.toYakinduEvent(connector.compositeSystemPort).type.eventParameterType» get«event.name.toFirstUpper»Value() {
					return «connector.instancePortReference.instance.name».get«connector.instancePortReference.port.name.toFirstUpper»().get«event.name.toFirstUpper»Value();
				}
			«ENDIF»
		«ENDFOR»
'''
	
	/**
	 * Genereates code responsible for overriding the "onRaised" method of the listener interface.
	 * E.g., generates code that raises event "b" of component "comp" if an "a"  out-event is raised inside the implemented component.
	 */
	protected def CharSequence registerListener(Component component, Port port, EventDirection oppositeDirection) '''
		«component.statemachineInstanceName».get«port.yakinduRealizationModeName»().getListeners().add(new «port.yakinduRealizationModeName»Listener() {
			«FOR event : port.interfaceRealization.interface.getAllEvents(oppositeDirection).map[it.eContainer as EventDeclaration] SEPARATOR "\n"»
				@Override
				public void on«event.event.toYakinduEvent(port).name.toFirstUpper»Raised(«event.generateParameter») {
					listener.raise«event.event.name.toFirstUpper»(«event.generateParameterValue»);
				}
			«ENDFOR»
		});
	'''	
	
	/**
	 * Returns the imports needed for the simple component classes.
	 */
	protected def generateSimpleComponentImports(Component component) '''
		import java.util.Queue;
		import java.util.List;
		import java.util.LinkedList;
		
		import «packageName».event.*;
		import «packageName».interfaces.*;
		// Yakindu listeners
		import «yakinduPackageName».«(component).yakinduStatemachineName.toLowerCase».I«(component).statemachineClassName».*;
		«IF component.needTimer»
			import «packageName».*;
		«ENDIF»
		import «yakinduPackageName».«(component).yakinduStatemachineName.toLowerCase».«(component).statemachineClassName»;
		import «yakinduPackageName».«(component).yakinduStatemachineName.toLowerCase».«(component).statemachineClassName».State;
	'''
	
	/**
	 * Returns whether there is a timing specification in any of the statecharts.
	 */
	protected def boolean needTimer(StatechartDefinition statechart) {
		return statechart.timeoutDeclarations.size > 0
	}
	
	/**
	 * Returns whether there is a time specification inside the given component.
	 */
	protected def boolean needTimer(Component component) {
		if (component instanceof StatechartDefinition) {
			return component.needTimer
		}
		else if (component instanceof CompositeComponent) {
			val composite = component as CompositeComponent
			return composite.derivedComponents.map[it.derivedType.needTimer].contains(true)
		}
		else if (component instanceof AsynchronousAdapter) {
			val wrapper = component as AsynchronousAdapter
			return !wrapper.clocks.empty || wrapper.wrappedComponent.type.needTimer
		}
		else {
			throw new IllegalArgumentException("No such component: " + component)
		}
	}
		
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
		
		/**
		 * Generates the Java interface code (implemented by the component) of the given component.
		 */
		protected def generateComponentInterface(Component component) {
			var ports = new HashSet<Port>
			if (component instanceof CompositeComponent) {
				val composite = component as CompositeComponent
				// Only bound ports are created
				ports += composite.portBindings.map[it.compositeSystemPort]
			}
			else if (component instanceof AsynchronousAdapter) {
				ports += component.allPorts
			}
			else {
				ports += component.ports
			}
			val interfaceCode = '''
				package «component.componentPackageName»;
				
				«FOR interfaceName : ports.map[it.interfaceRealization.interface.generateName].toSet»
					import «packageName».«INTERFACES_NAME».«interfaceName»;
				«ENDFOR»
				
				public interface «component.portOwnerInterfaceName» {
					
					«FOR port : ports»
						«port.implementedJavaInterface» get«port.name.toFirstUpper»();
					«ENDFOR»
					
					void reset();
					
					«IF component instanceof SynchronousComponent»void runCycle();«ENDIF»
					«IF component instanceof AbstractSynchronousCompositeComponent»void runFullCycle();«ENDIF»
					«IF component instanceof AsynchronousComponent»void start();«ENDIF»
					
				} 
			'''
			return interfaceCode
		}
		
		/**
		 * Returns the interface name (implemented by the component) of the given component.
		 */
		protected def getPortOwnerInterfaceName(Component component) {
			return component.componentClassName + "Interface";
		}
	
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
	 * Returns all events of the given ports that go in the given direciton through the ports.
	 */
		protected def getSemanticEvents(Collection<? extends Port> ports, EventDirection direction) {
			val events =  new HashSet<Event>
			for (anInterface : ports.filter[it.interfaceRealization.realizationMode == RealizationMode.PROVIDED].map[it.interfaceRealization.interface]) {
				events.addAll(anInterface.getAllEvents(direction.oppositeDirection))
			}
			for (anInterface : ports.filter[it.interfaceRealization.realizationMode == RealizationMode.REQUIRED].map[it.interfaceRealization.interface]) {
				events.addAll(anInterface.getAllEvents(direction))
			}
			return events
		}
		
		/**
		 * Returns EventDirection.IN in case of EventDirection.OUT directions and vice versa.
		 */
		protected def getOppositeDirection(EventDirection direction) {
			switch (direction) {
				case EventDirection.IN:
					return EventDirection.OUT
				case EventDirection.OUT:
					return EventDirection.IN
				default:
					throw new IllegalArgumentException("Not known direction: " + direction)
			} 
		}
		
		/** 
		 * Returns all events of a given interface whose direction is not oppositeDirection.
		 * The parent interfaces are taken into considerations as well.
		 */ 
		 protected def Set<Event> getAllEvents(Interface anInterface, EventDirection oppositeDirection) {
			if (anInterface === null) {
				return Collections.EMPTY_SET
			}
			val eventSet = new HashSet<Event>
			for (parentInterface : anInterface.parents) {
				eventSet.addAll(parentInterface.getAllEvents(oppositeDirection))
			}
			for (event : anInterface.events.filter[it.direction != oppositeDirection].map[it.event]) {
				eventSet.add(event)
			}
			return eventSet
		}
		
	/**
	 * Generates code raising the Yakindu statechart event "connected" to the given port and component.
	 */
		protected def delegateCall(org.yakindu.base.types.Event event, Component component, Port port) '''
			«component.statemachineInstanceName».get«port.yakinduRealizationModeName»().raise«event.name.toFirstUpper»(«event.castArgument»);
		'''
	
	/**
	* Returns a string that contains a cast and the value of the event if needed. E.g.: (Long) event.getValue();
	*/
		protected def castArgument(org.yakindu.base.types.Event event) '''
			«IF event.type !== null»
				(«event.type.eventParameterType.toFirstUpper») «EVENT_INSTANCE_NAME».«GET_VALUE_METHOD»()«ENDIF»'''
	
	/**
	 * Returns the type name of the interface of the wrapped Yakindu statemachine.
	 */
	protected def getYakinduRealizationModeName(Port port) {
		 if (port.name === null) {
		 	return "SCInterface"
		 }
		 return "SCI" + port.name.toFirstUpper
	} 
	
	protected def getSynchronousCompositeComponentsRule() {
		if (synchronousCompositeComponentsRule === null) {
			 synchronousCompositeComponentsRule = createRule(AbstractSynchronousCompositeComponents.instance).action [
				val compositeSystemUri = parentPackageUri + File.separator + it.synchronousCompositeComponent.containingPackage.name.toLowerCase
				val code = it.synchronousCompositeComponent.createSynchronousCompositeComponentClass
				code.saveCode(compositeSystemUri + File.separator + it.synchronousCompositeComponent.componentClassName + ".java")
				// Generating the interface that is able to return the Ports
				val interfaceCode = it.synchronousCompositeComponent.generateComponentInterface
				interfaceCode.saveCode(compositeSystemUri + File.separator + it.synchronousCompositeComponent.portOwnerInterfaceName + ".java")
			].build		
		}
		return synchronousCompositeComponentsRule
	}

	/**
	 * Generates the needed Java imports in case of the given composite component.
	 */
	protected def generateCompositeSystemImports(CompositeComponent component) '''
		import java.util.List;
		import java.util.LinkedList;
		
		«IF component.needTimer»
			import «yakinduPackageName».*;
		«ENDIF»
		import «packageName».interfaces.*;
		«IF component instanceof AsynchronousCompositeComponent»
			import «packageName».channels.*;
		«ENDIF»
		«FOR containedComponent : component.derivedComponents.map[it.derivedType]
			.filter[!it.componentPackageName.equals(component.componentPackageName)].toSet»
			import «containedComponent.componentPackageName».*;
		«ENDFOR»
	'''

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
				public «component.componentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", " AFTER ", "»«parameter.type.transformType» «parameter.name»«ENDFOR»«ITIMER_INTERFACE_NAME» timer) {
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
				public void setTimer(«ITIMER_INTERFACE_NAME» timer) {
					«FOR instance : component.components»
						«IF instance.type.needTimer»
							«instance.name».setTimer(timer);
						«ENDIF»
					«ENDFOR»
				}
			«ENDIF»
			
			/**  Getter for component instances, e.g. enabling to check their states. */
			«FOR instance : component.components SEPARATOR "\n"»
				public «instance.type.componentClassName» get«instance.name.toFirstUpper»() {
					return «instance.name»;
				}
			«ENDFOR»
			
		}
	'''
	
	/** Sets the parameters of the component and instantiates the necessary components with them. */
	private def createInstances(CompositeComponent component) '''
		«FOR parameter : component.parameterDeclarations SEPARATOR ", "»
			this.«parameter.name» = «parameter.name»;
		«ENDFOR»
		«FOR instance : component.derivedComponents»
			«instance.name» = new «instance.derivedType.componentClassName»(«FOR argument : instance.arguments SEPARATOR ", "»«argument.serialize»«ENDFOR»);
		«ENDFOR»
		«FOR port : component.portBindings.map[it.compositeSystemPort]»
			«port.name.toFirstLower» = new «port.name.toFirstUpper»();
		«ENDFOR»
	'''
	
	/**
	 * Returns the instances (in order) that should be scheduled in the given AbstractSynchronousCompositeComponent.
	 * Note that in casacade commposite an instance might be scheduled multiple times.
	 */
	private dispatch def getInstancesToBeScheduled(AbstractSynchronousCompositeComponent component) {
		return component.components
	}
	
	private dispatch def getInstancesToBeScheduled(CascadeCompositeComponent component) {
		if (component.executionList.empty) {
			return component.components
		}
		return component.executionList
	}
	
	protected def void generateLinkedBlockingMultiQueueClasses() {
		val compositeSystemUri = parentPackageUri.substring(0, parentPackageUri.length - packageName.length) + File.separator + "lbmq"
		LinkedBlockingQueueSource.AbstractOfferable.saveCode(compositeSystemUri + File.separator + "AbstractOfferable.java")
		LinkedBlockingQueueSource.AbstractPollable.saveCode(compositeSystemUri + File.separator + "AbstractPollable.java")
		LinkedBlockingQueueSource.LinkedBlockingMultiQueue.saveCode(compositeSystemUri + File.separator + "LinkedBlockingMultiQueue.java")
		LinkedBlockingQueueSource.Offerable.saveCode(compositeSystemUri + File.separator + "Offerable.java")
		LinkedBlockingQueueSource.Pollable.saveCode(compositeSystemUri + File.separator + "Pollable.java")
	}
	
	protected def getSynchronousComponentWrapperRule() {
		if (synchronousComponentWrapperRule === null) {
			 synchronousComponentWrapperRule = createRule(SynchronousComponentWrappers.instance).action [
				val compositeSystemUri = parentPackageUri + File.separator + it.synchronousComponentWrapper.containingPackage.name.toLowerCase
				val code = it.synchronousComponentWrapper.createSynchronousComponentWrapperClass
				code.saveCode(compositeSystemUri + File.separator + it.synchronousComponentWrapper.componentClassName + ".java")
				val interfaceCode = it.synchronousComponentWrapper.generateComponentInterface
				interfaceCode.saveCode(compositeSystemUri + File.separator + it.synchronousComponentWrapper.portOwnerInterfaceName + ".java")
			].build		
		}
		return synchronousComponentWrapperRule
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
				private «ITIMER_INTERFACE_NAME» timerService;
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
				public «component.componentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", " AFTER ", "»«parameter.type.transformType» «parameter.name»«ENDFOR»«ITIMER_INTERFACE_NAME» timer) {
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
				private «ITIMER_CALLBACK_INTERFACE_NAME» createTimerCallback() {
					return new «ITIMER_CALLBACK_INTERFACE_NAME»() {
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
				«EVENT_CLASS_NAME» «EVENT_INSTANCE_NAME» = __asyncQueue.poll();
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
						«EVENT_CLASS_NAME» «EVENT_INSTANCE_NAME» = __asyncQueue.take();		
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
			
			private boolean isControlEvent(«EVENT_CLASS_NAME» «EVENT_INSTANCE_NAME») {
				«IF component.ports.empty && component.clocks.empty»
					return false;
				«ELSE»
					String portName = «EVENT_INSTANCE_NAME».«GET_EVENT_METHOD»().split("\\.")[0];
					return «FOR port : component.ports SEPARATOR " || "»portName.equals("«port.name»")«ENDFOR»«IF !component.ports.empty && !component.clocks.empty» || «ENDIF»«FOR clock : component.clocks SEPARATOR " || "»portName.equals("«clock.name»")«ENDFOR»;
				«ENDIF»
			}
			
			private void forwardEvent(«EVENT_CLASS_NAME» «EVENT_INSTANCE_NAME») {
				switch («EVENT_INSTANCE_NAME».«GET_EVENT_METHOD»()) {
					«component.generateWrapperEventHandlers()»
					default:
						throw new IllegalArgumentException("No such event!");
				}
			}
			
			private void performControlActions(«EVENT_CLASS_NAME» «EVENT_INSTANCE_NAME») {
				String[] eventName = «EVENT_INSTANCE_NAME».«GET_EVENT_METHOD»().split("\\.");
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
				public void setTimer(«ITIMER_INTERFACE_NAME» timer) {
					«IF !component.clocks.empty»timerService = timer;«ENDIF»
					«IF component.wrappedComponent.type.needTimer»«component.wrappedComponentName».setTimer(timer);«ENDIF»
					init(); // To set the service into functioning state with clocks (so that "after 1 s" works with new timer as well)
				}
			«ENDIF»
			
		}
		'''
	}
	
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
	 * Serializes the value of the given time specification with respect to the time unit. 
	 */
	protected def getValueInMs(TimeSpecification specification) {
		if (specification.unit == TimeUnit.SECOND) {
			return "(" + specification.value.serialize + ") * 1000";
		}
		return specification.value.serialize
	}
	
	/**
	 * Generates the needed Java imports in case of the given composite component.
	 */
	protected def generateWrapperImports(AsynchronousAdapter component) '''
		import java.util.Collections;
		import java.util.List;
		
		import lbmq.*; 
		«IF component.needTimer»import «packageName».*;«ENDIF»

		import «packageName».event.*;
		import «packageName».interfaces.*;
		
		import «component.wrappedComponent.type.componentPackageName».*;
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
	 * Creates a Java interface for each Port Interface.
	 */
	protected def getChannelsRule() {
		if (channelsRule === null) {
			 channelsRule = createRule(Interfaces.instance).action [
				val channelInterfaceCode = it.interface.createChannelInterfaceCode
				channelInterfaceCode.saveCode(channelUri + File.separator + it.interface.generateChannelInterfaceName + ".java")
				val channelClassCode = it.interface.createChannelClassCode
				channelClassCode.saveCode(channelUri + File.separator + it.interface.generateChannelName + ".java")	
			].build		
		}
		return channelsRule
	}
	
	 /**
	 * Returns the Java interface code of the Channel class.
	 */
	protected def createChannelInterfaceCode(Interface anInterface) '''
		package «packageName».«CHANNEL_NAME»;
		
		import «packageName».«INTERFACES_NAME».«anInterface.generateName»;
		
		public interface «anInterface.generateChannelInterfaceName» {			
			
			void registerPort(«anInterface.generateName».Provided providedPort);
			
			void registerPort(«anInterface.generateName».Required requiredPort);
		
		}
	'''
	
	 /**
	 * Returns the Java class code of the Channel class.
	 */
	protected def createChannelClassCode(Interface anInterface) '''
		package «packageName».«CHANNEL_NAME»;
		
		import «packageName».«INTERFACES_NAME».«anInterface.generateName»;
		import java.util.List;
		import java.util.LinkedList;
		
		public class «anInterface.generateChannelName» implements «anInterface.generateChannelInterfaceName» {
			
			private «anInterface.generateName».Provided providedPort;
			private List<«anInterface.generateName».Required> requiredPorts = new LinkedList<«anInterface.generateName».Required>();
			
			public «anInterface.generateChannelName»() {}
			
			public «anInterface.generateChannelName»(«anInterface.generateName».Provided providedPort) {
				this.providedPort = providedPort;
			}
			
			public void registerPort(«anInterface.generateName».Provided providedPort) {
				// Former port is forgotten
				this.providedPort = providedPort;
				// Registering the listeners
				for («anInterface.generateName».Required requiredPort : requiredPorts) {
					providedPort.registerListener(requiredPort);
					requiredPort.registerListener(providedPort);
				}
			}
			
			public void registerPort(«anInterface.generateName».Required requiredPort) {
				requiredPorts.add(requiredPort);
				// Checking whether a provided port is already given
				if (providedPort != null) {
					providedPort.registerListener(requiredPort);
					requiredPort.registerListener(providedPort);
				}
			}
		
		}
	'''
	
	protected def getAsynchronousCompositeComponentsRule() {
		if (asynchronousCompositeComponentsRule === null) {
			 asynchronousCompositeComponentsRule = createRule(AsynchronousCompositeComponents.instance).action [
				val compositeSystemUri = parentPackageUri + File.separator + it.asynchronousCompositeComponent.containingPackage.name.toLowerCase
				// Main components
				val code = it.asynchronousCompositeComponent.createAsynchronousCompositeComponentClass(0, 0)
				code.saveCode(compositeSystemUri + File.separator + it.asynchronousCompositeComponent.componentClassName + ".java")
				val interfaceCode = it.asynchronousCompositeComponent.generateComponentInterface
				interfaceCode.saveCode(compositeSystemUri + File.separator + it.asynchronousCompositeComponent.portOwnerInterfaceName + ".java")
			].build		
		}
		return asynchronousCompositeComponentsRule
	}
	
	/**
	* Creates the Java code of the synchronous composite class, containing the statemachine instances.
	*/
	protected def createAsynchronousCompositeComponentClass(AsynchronousCompositeComponent component, int channelId1, int channelId2) '''
		package «component.componentPackageName»;
		
		«component.generateCompositeSystemImports»
		
		public class «component.componentClassName» implements «component.portOwnerInterfaceName» {			
			// Component instances
			«FOR instance : component.components»
				private «instance.type.componentClassName» «instance.name»;
			«ENDFOR»
			// Port instances
			«FOR port : component.portBindings.map[it.compositeSystemPort]»
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
				public «component.componentClassName»(«FOR parameter : component.parameterDeclarations SEPARATOR ", " AFTER ", "»«parameter.type.transformType» «parameter.name»«ENDFOR»«ITIMER_INTERFACE_NAME» timer) {
					«component.createInstances»
					setTimer(timer);
					init(); // Init is not called in setTimer like in the wrapper as it would be unnecessary
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
			}
			
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
			«FOR portDef : component.portBindings SEPARATOR "\n"»
				public class «portDef.compositeSystemPort.name.toFirstUpper» implements «portDef.compositeSystemPort.interfaceRealization.interface.generateName».«portDef.compositeSystemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» {
				
					«portDef.delegateRaisingMethods» 
					
					«portDef.delegateOutMethods»
					
					@Override
					public void registerListener(«portDef.compositeSystemPort.interfaceRealization.interface.generateName».Listener.«portDef.compositeSystemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper» listener) {
						«portDef.instancePortReference.instance.name».get«portDef.instancePortReference.port.name.toFirstUpper»().registerListener(listener);
					}
					
					@Override
					public List<«portDef.compositeSystemPort.interfaceRealization.interface.generateName».Listener.«portDef.compositeSystemPort.interfaceRealization.realizationMode.toString.toLowerCase.toFirstUpper»> getRegisteredListeners() {
						return «portDef.instancePortReference.instance.name».get«portDef.instancePortReference.port.name.toFirstUpper»().getRegisteredListeners();
					}
					
				}
				
				@Override
				public «portDef.compositeSystemPort.name.toFirstUpper» get«portDef.compositeSystemPort.name.toFirstUpper»() {
					return «portDef.compositeSystemPort.name.toFirstLower»;
				}
			«ENDFOR»
			
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
			
			«IF component.needTimer»
				/** Setter for the timer e.g., a virtual timer. */
				public void setTimer(«ITIMER_INTERFACE_NAME» timer) {
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

	/**
	 * Creates a Java class from the the given code at the location specified by the given URI.
	 */
	protected def saveCode(CharSequence code, String uri) {
		new File(uri.substring(0, uri.lastIndexOf(File.separator))).mkdirs
		val fw = new FileWriter(uri)
		fw.write(code.toString)
		fw.close
		return 
	}
	
	/**
	 * Returns a Set of EObjects that are created of the given "from" object.
	 */
	protected def getAllValuesOfTo(EObject from) {
		return engine.getMatcher(Traces.instance).getAllValuesOfto(null, from)		
	}
	
	/**
	 * Returns a Set of EObjects that the given "to" object is created of.
	 */
	protected def getAllValuesOfFrom(EObject to) {
		return engine.getMatcher(Traces.instance).getAllValuesOffrom(null, to)
	}

	/**
	 * Disposes of the code generator.
	 */
	def dispose() {
		if (transformation !== null) {
			transformation.dispose
		}
		transformation = null
		return
	}
}
