/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.lowlevel.xsts.transformation.LowlevelToXstsTransformer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.TransitionMerging
import hu.bme.mit.gamma.statechart.composite.AbstractAsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.DiscardStrategy
import hu.bme.mit.gamma.statechart.composite.MessageQueue
import hu.bme.mit.gamma.statechart.composite.ScheduledAsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.lowlevel.model.Package
import hu.bme.mit.gamma.statechart.lowlevel.transformation.GammaToLowlevelTransformer
import hu.bme.mit.gamma.statechart.lowlevel.transformation.Trace
import hu.bme.mit.gamma.statechart.lowlevel.transformation.ValueDeclarationTransformer
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.InEventGroup
import hu.bme.mit.gamma.xsts.model.RegionGroup
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.transformation.util.OrthogonalActionTransformer
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.AbstractMap.SimpleEntry
import java.util.Collection
import java.util.List
import java.util.logging.Level
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.QueueNamings.*
import static extension java.lang.Math.*

class ComponentTransformer {
	// This gammaToLowlevelTransformer must be the same during this transformation cycle due to tracing
	protected final GammaToLowlevelTransformer gammaToLowlevelTransformer
	protected final MessageQueueTraceability queueTraceability
	// Traceability
	protected final Traceability traceability
	// Transformation settings
	protected final boolean transformOrthogonalActions
	protected final boolean optimize
	protected final TransitionMerging transitionMerging
	// Auxiliary objects
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension EnvironmentalActionFilter environmentalActionFilter =
			EnvironmentalActionFilter.INSTANCE
	protected final extension OrthogonalActionTransformer orthogonalActionTransformer =
			OrthogonalActionTransformer.INSTANCE
	protected final extension EventConnector eventConnector = EventConnector.INSTANCE
	protected final extension InternalEventHandler internalEventHandler = InternalEventHandler.INSTANCE
	protected final extension SystemReducer systemReducer = SystemReducer.INSTANCE
	
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension XSTSModelFactory xStsModelFactory = XSTSModelFactory.eINSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	// Logger
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	new(GammaToLowlevelTransformer gammaToLowlevelTransformer, boolean transformOrthogonalActions,
			boolean optimize, TransitionMerging transitionMerging) {
		this.gammaToLowlevelTransformer = gammaToLowlevelTransformer
		this.transformOrthogonalActions = transformOrthogonalActions
		this.optimize = optimize
		this.transitionMerging = transitionMerging
		this.queueTraceability = new MessageQueueTraceability
		this.traceability = new Traceability
	}
	
	def dispatch XSTS transform(Component component, Package lowlevelPackage) {
		throw new IllegalArgumentException("Not supported component type: " + component)
	}
	
	def dispatch XSTS transform(ScheduledAsynchronousCompositeComponent component,
			Package lowlevelPackage) {
		val systemPorts = component.allPorts
		// Parameters of all asynchronous composite components
		component.extractAllParameters
		// Retrieving the adapter instances - hierarchy does not matter here apart from the order
		val adapterInstances = component.allAsynchronousSimpleInstances
		val environmentalQueues = newHashSet
		
		val name = component.name
		val xSts = name.createXsts
		
		val eventReferenceMapper = new ReferenceToXstsVariableMapper(xSts)
		val valueDeclarationTransformer = new ValueDeclarationTransformer
		val variableTrace = valueDeclarationTransformer.getTrace
		
		val variableInitAction = createSequentialAction
		val configInitAction = createSequentialAction
		val entryAction = createSequentialAction
		
		val inEventAction = createSequentialAction
//		val outEventAction = createSequentialAction
		
		val mergedAction = createSequentialAction
		
		// Transforming and saving the adapter instances
		
		val mergedActions = newHashMap
		for (adapterInstance : adapterInstances) {
			val adapterComponentType = adapterInstance.type as AsynchronousAdapter
			
			adapterComponentType.extractParameters(adapterInstance.arguments) // Parameters
			val adapterXsts = adapterComponentType.transform(lowlevelPackage)
			xSts.merge(adapterXsts) // Adding variables, types, etc.
			
			variableInitAction.actions += adapterXsts.variableInitializingTransition.action
			configInitAction.actions += adapterXsts.configurationInitializingTransition.action
			entryAction.actions += adapterXsts.entryEventTransition.action
			
			mergedActions += adapterInstance -> adapterXsts.mergedAction
			
			// inEventActions later
			// Filtering events can be used (internal ones and ones led out to the environment)
			// Not necessary as the component instances do this, but this a reset here could save resource
//			outEventAction.actions += adapterXsts.outEventTransition.action
		}
		
		// Creating the message queue constructions
		
		for (adapterInstance : adapterInstances) {
			val adapterComponentType = adapterInstance.type as AsynchronousAdapter
			for (queue : adapterComponentType.functioningMessageQueues) {
				if (queue.isEnvironmentalAndCheck(systemPorts)) {
					environmentalQueues += queue // Tracing
				}
				
				val storedPortEvents = newHashSet
				val events = queue.storedEvents
				for (event : events) {
					val id = queue.getEventId(event) // Id is needed during back-annotation
					queueTraceability.put(event, id)
					storedPortEvents += event
					logger.log(Level.INFO, '''Assigning «id» to «event.key.name».«event.value.name»''')
				}
				
				val evaluatedCapacity = queue.getCapacity(systemPorts)
				val masterQueueType = createArrayTypeDefinition => [
					it.elementType = createIntegerTypeDefinition
					it.size = evaluatedCapacity.toIntegerLiteral
				]
				val masterQueueName = queue.getMasterQueueName(adapterInstance)
				val masterQueue = masterQueueType.createVariableDeclaration(masterQueueName)
				
				val masterSizeVariableName = queue.getMasterSizeVariableName(adapterInstance)
				val masterSizeVariable = createIntegerTypeDefinition
						.createVariableDeclaration(masterSizeVariableName)
				
				val slaveQueuesMap = newHashMap
				val typeSlaveQueuesMap = newHashMap // Reusing slave queues for same types if possible
				for (portEvent : events) {
					val port = portEvent.key
					val event = portEvent.value
					val List<MessageQueueStruct> slaveQueues = newArrayList
					// Important optimization - we create a queue only if the event is used
					if (eventReferenceMapper.hasInputEventVariable(event, port)) {
						for (parameter : event.parameterDeclarations) {
							val parameterType = parameter.type
							val parameterTypeDefinition = parameterType.typeDefinition
							// Optimization - we compare the type definitions of parameters
							val typeSlaveQueues = typeSlaveQueuesMap.getOrCreateList(parameterTypeDefinition)
							
							val index = parameter.indexOfParametersWithSameTypeDefinition
							// Indexing works: parameters of an event are not deleted separately
							if (queue.isEnvironmental(systemPorts) || // Traceability reasons: no optimization for system parameters
									typeSlaveQueues.size <= index) {
								// index is less at most by 1 - creating a new slave queue for type
								val slaveQueueType = createArrayTypeDefinition => [
									it.elementType = parameterType.clone // Not type definition due to enums
									it.size = evaluatedCapacity.toIntegerLiteral
								]
								val slaveQueueName = parameter.getSlaveQueueName(port, adapterInstance)
								val slaveQueue = slaveQueueType.createVariableDeclaration(slaveQueueName)
								
								val slaveSizeVariableName = parameter.getSlaveSizeVariableName(port, adapterInstance)
								val slaveSizeVariable = createIntegerTypeDefinition
										.createVariableDeclaration(slaveSizeVariableName)
								
								val messageQueueStruct = new MessageQueueStruct(slaveQueue, slaveSizeVariable)
								slaveQueues += messageQueueStruct
								typeSlaveQueues += messageQueueStruct
								logger.log(Level.INFO, '''Created a slave queue for «port.name».«event.name»::«parameter.name»''')
							}
							else {
								// Internal queue, we do not care about traceability here
								val messageQueueStruct = typeSlaveQueues.get(index)
								slaveQueues += messageQueueStruct // Optimization - reusing an existing slave queue
								logger.log(Level.INFO, '''Found a slave queue for «port.name».«event.name»::«parameter.name»''')
							}
						}
					} // If no input event variable - slaveQueues is empty
					slaveQueuesMap += portEvent -> slaveQueues
				}
				
				val messageQueueMapping = new MessageQueueMapping(storedPortEvents,
						new MessageQueueStruct(masterQueue, masterSizeVariable), slaveQueuesMap, typeSlaveQueuesMap)
				queueTraceability.put(queue, messageQueueMapping)
				val slaveQueueMappings = messageQueueMapping.typeSlaveQueues
			
				// Transforming the message queue constructions into native XSTS variables
				// We do not care about the names (renaming) here
				// Namings.customize* covers the same naming behavior as QueueNamings + valueDeclarationTransformer
				
				xSts.variableDeclarations += valueDeclarationTransformer.transform(masterQueue)
				val xStsMasterSizeVariable = valueDeclarationTransformer.transform(masterSizeVariable).onlyElement
				xSts.variableDeclarations += xStsMasterSizeVariable
				xStsMasterSizeVariable.addStrictControlAnnotation // Needed for loops
				
				val slaveQueuesCollection = slaveQueueMappings.values
				val slaveQueueStructs = slaveQueuesCollection.flatten
				checkState(slaveQueueStructs.unique)
				for (slaveQueueStruct : slaveQueueStructs) {
					val slaveQueue = slaveQueueStruct.arrayVariable
					val slaveSizeVariable = slaveQueueStruct.sizeVariable
					xSts.variableDeclarations += valueDeclarationTransformer.transform(slaveQueue)
					val xStsSlaveSizeVariable = valueDeclarationTransformer.transform(slaveSizeVariable).onlyElement
					xSts.variableDeclarations += xStsSlaveSizeVariable
					xStsSlaveSizeVariable.addStrictControlAnnotation // Needed for loops
					// The type might not be correct here and later has to be reassigned to handle enums
				}
			}
		}
		
		// Creating queue process behavior
		
		val queueHandlingMergedActions = newHashMap // Cache for queue-handling merged action and message dispatch
		
		val executionList = component.allScheduledAsynchronousSimpleInstances // One instance could be executed multiple times
		for (adapterInstance : executionList) {
			val adapterComponentType = adapterInstance.type as AsynchronousAdapter
			val originalMergedAction = mergedActions.get(adapterInstance)
			// Input event processing
			val inputIfAction = createIfAction // Will be appended when handling queues
			mergedAction.actions += inputIfAction
			
			// Queues in order of priority
			for (queue : adapterComponentType.functioningMessageQueuesInPriorityOrder) {
				val queueMapping = queueTraceability.get(queue)
				val masterQueue = queueMapping.masterQueue.arrayVariable
				val masterSizeVariable = queueMapping.masterQueue.sizeVariable
				val slaveQueues = queueMapping.slaveQueues
				
				// Actually, the following values are "low-level values", but we handle them as XSTS values
				val xStsMasterQueue = variableTrace.getAll(masterQueue).onlyElement
				val xStsMasterSizeVariable = variableTrace.getAll(masterSizeVariable).onlyElement
				
				val block = createSequentialAction
				// if (0 < size) { ... }
				inputIfAction.append(0.toIntegerLiteral.createLessExpression(
					xStsMasterSizeVariable.createReferenceExpression), block)
				
				val xStsEventIdVariableAction = createIntegerTypeDefinition.createVariableDeclarationAction(
						xStsMasterQueue.eventIdLocalVariableName, xStsMasterQueue.peek)
				val xStsEventIdVariable = xStsEventIdVariableAction.variableDeclaration
				block.actions += xStsEventIdVariableAction
				block.actions += xStsMasterQueue.popAndDecrement(xStsMasterSizeVariable)
				
				// Processing the possible different event identifiers
				
				val branchExpressions = <Expression>newArrayList
				val branchActions = <Action>newArrayList
				
				val emptyValue = xStsMasterQueue.arrayElementType.defaultExpression
				// if (eventId == 0) { empty }
				branchExpressions += xStsEventIdVariable.createEqualityExpression(emptyValue)
				branchActions += createEmptyAction
				
				val events = queue.storedEvents
				for (portEvent : events) {
					val port = portEvent.key
					val event = portEvent.value
					val eventId = queueTraceability.get(portEvent)
					
					// Can be empty due to optimization or adapter event
					val xStsInEventVariables = eventReferenceMapper.getInputEventVariables(event, port)
					
					val ifExpression = xStsEventIdVariable.createReferenceExpression
							.createEqualityExpression(eventId.toIntegerLiteral)
					val thenAction = createSequentialAction
					// Setting the event variables to true (multiple binding is supported)
					for (xStsInEventVariable : xStsInEventVariables) {
						thenAction.actions += xStsInEventVariable.createAssignmentAction(
								createTrueExpression)
					}
					// Setting the parameter variables with values stored in slave queues
					val slaveQueueStructs = slaveQueues.get(portEvent) // Might be empty
					
					val inParameters = event.parameterDeclarations
					val slaveQueueSize = slaveQueueStructs.size // Might be 0 if there is no in-event var
					
					if (inParameters.size <= slaveQueueSize) {
						for (var i = 0; i < slaveQueueSize; i++) {
							val slaveQueueStruct = slaveQueueStructs.get(i)
							val slaveQueue = slaveQueueStruct.arrayVariable
							val slaveSizeVariable = slaveQueueStruct.sizeVariable
							val inParameter = inParameters.get(i)
							
							val xStsSlaveQueues = variableTrace.getAll(slaveQueue)
							val xStsSlaveSizeVariable = variableTrace.getAll(slaveSizeVariable).onlyElement
							val xStsInParameterVariableLists = eventReferenceMapper
									.getInputParameterVariablesByPorts(inParameter, port)
							// Separated in the lists according to ports
							for (xStsInParameterVariables : xStsInParameterVariableLists) {
								// Parameter optimization problem: parameters are not deleted independently
								val size = xStsInParameterVariables.size 
								for (var j = 0; j < size; j++) {
									val xStsInParameterVariable = xStsInParameterVariables.get(j)
									val xStsSlaveQueue = xStsSlaveQueues.get(j)
									// Setting type to prevent enum problems (multiple times, though, not a problem)
									val xStsSlaveQueueType = xStsSlaveQueue.typeDefinition as ArrayTypeDefinition
									xStsSlaveQueueType.elementType = xStsInParameterVariable.type.clone
									//
									thenAction.actions += xStsInParameterVariable
											.createAssignmentAction(xStsSlaveQueue.peek)
								}
							}
							thenAction.actions += xStsSlaveQueues.popAllAndDecrement(xStsSlaveSizeVariable)
						}
					}
					else {
						// It can happen that a control event, which has no in-event variable, has parameters
						// In this case, the parameters are not handled and there are no slave queues:
						// (inParameters.size > slaveQueueSize) -> slaveQueueSize == 0
						checkState(slaveQueueSize == 0)
					}
					
					// Execution if necessary
					if (adapterComponentType.isControlSpecification(portEvent)) {
						thenAction.actions += originalMergedAction.clone
					}
					// if (eventId == ..) { "transfer slave queue values" if (isControlSpec) { "run" }
					branchExpressions += ifExpression
					branchActions += thenAction
				}
				// Excluding branches for the different event identifiers
				block.actions += branchExpressions.createChoiceAction(branchActions)
			}
			
			// Dispatching events to connected message queues
			val eventDispatches = createSequentialAction // For caching
			for (port : adapterComponentType.allPorts) {
				// Semantical question: now out events are dispatched according to this order
				val eventDispatchAction = port.createEventDispatchAction(
						eventReferenceMapper, systemPorts, variableTrace)
				mergedAction.actions += eventDispatchAction.clone
				entryAction.actions += eventDispatchAction // Same for initial action
				
				eventDispatches.actions += eventDispatchAction.clone // Caching
			}
			// Caching
			queueHandlingMergedActions += adapterInstance -> (inputIfAction.clone /* Crucial */ -> eventDispatches)
			//
		}
		
		// Initializing message queue related variables - done here and not in initial expression
		// as the potential enumeration type declarations of slave queues there are not traced
		
		val xStsQueueVariables = newArrayList
		for (queueStruct : queueTraceability.allQueues) {
			val queue = queueStruct.arrayVariable
			val sizeVariable = queueStruct.sizeVariable
			xStsQueueVariables += variableTrace.getAll(queue)
			xStsQueueVariables += variableTrace.getAll(sizeVariable)
		}
		for (xStsQueueVariable : xStsQueueVariables) {
			variableInitAction.actions += xStsQueueVariable.createVariableResetAction
		}
		
		//
		
		xSts.variableInitializingTransition = variableInitAction.wrap
		xSts.configurationInitializingTransition = configInitAction.wrap
		xSts.entryEventTransition = entryAction.wrap
		
		// Setting initial execution lists
		for (adapterInstance : component.allInitallyScheduledAsynchronousSimpleInstances) {
			val actions = queueHandlingMergedActions.get(adapterInstance)
			val inputIfAction = actions.key // These actions are already cloned
			val eventDispatches = actions.value
			
			entryAction.actions += inputIfAction
			entryAction.actions += eventDispatches
		}
		
		// Creating environment behavior
		
		val systemInEvents = newHashSet
		for (systemAsynchronousSimplePort : component.allBoundAsynchronousSimplePorts
					.reject[it.internal]) {
			for (inEvent : systemAsynchronousSimplePort.inputEvents) {
				val portEvent = new SimpleEntry(systemAsynchronousSimplePort, inEvent)
				if (queueTraceability.contains(portEvent)) {
					logger.log(Level.INFO,
						'''Found «systemAsynchronousSimplePort.name».«inEvent.name» as system input event''')
					systemInEvents += portEvent
				}
			}
		}
		for (queue : environmentalQueues) { // All with capacity 1 and size 0, no internal events
			val queueMapping = queueTraceability.get(queue)
			val masterQueue = queueMapping.masterQueue.arrayVariable
			val masterSizeVariable = queueMapping.masterQueue.sizeVariable
			val slaveQueues = queueMapping.slaveQueues
			
			val xStsMasterQueue = variableTrace.getAll(masterQueue).onlyElement
			val xStsMasterSizeVariable = variableTrace.getAll(masterSizeVariable).onlyElement
			
			val xStsQueueHandlingAction = createSequentialAction
			val isQueueEmptyExpression = xStsMasterSizeVariable.empty
			val ifEmptyAction = isQueueEmptyExpression.createIfAction(xStsQueueHandlingAction)
			// If queue is empty
			inEventAction.actions += ifEmptyAction
			
			val xStsEventIdVariableAction = xStsMasterQueue.createVariableDeclarationActionForArray(
					xStsMasterQueue.eventIdLocalVariableName)
			val xStsEventIdVariable = xStsEventIdVariableAction.variableDeclaration
			
			xStsQueueHandlingAction.actions += xStsEventIdVariableAction
			xStsQueueHandlingAction.actions += xStsEventIdVariable.createHavocAction
			
			// If the id is a valid event
			val storesInternalPort = queue.storedEvents.exists[it.key.internal]
			// Semantically equivalent but maybe the second interval is easier to handle by SMT solvers
			val isValidIdExpression = if (storesInternalPort) {
				// (0 < eventId && eventId <= maxPotentialEventId) does not work now with internal events
				val eventIds = queue.eventIdsOfNonInternalEvents
				// (eventId == 1 || eventId == 3 || ...)
				val idComparisons = eventIds.map[
					xStsEventIdVariable.createReferenceExpression
						.createEqualityExpression(
							it.toIntegerLiteral)]
				idComparisons.wrapIntoOrExpression
			}
			else {
				val emptyValue = xStsEventIdVariable.defaultExpression
				val maxEventId = queue.maxEventId.toIntegerLiteral
				// 0 < eventId && eventId <= maxPotentialEventId
				val leftInterval = emptyValue
						.createLessExpression(xStsEventIdVariable.createReferenceExpression)
				val rightInterval = xStsEventIdVariable.createReferenceExpression
						.createLessEqualExpression(maxEventId)
				#[leftInterval, rightInterval].wrapIntoAndExpression
			}
			
			val setQueuesAction = createSequentialAction
			setQueuesAction.actions += xStsMasterQueue.addAndIncrement( // Or could be used 0 literals for index
					xStsMasterSizeVariable, xStsEventIdVariable.createReferenceExpression)
			
			xStsQueueHandlingAction.actions += isValidIdExpression.createIfAction(setQueuesAction)
			
			val branchExpressions = <Expression>newArrayList
			val branchActions = <Action>newArrayList
			for (portEvent : slaveQueues.keySet
						.filter[systemInEvents.contains(it) /*Only system events*/]) {
				val slaveQueueStructs = slaveQueues.get(portEvent)
				val eventId = queueTraceability.get(portEvent)
				branchExpressions += xStsEventIdVariable
						.createEqualityExpression(eventId.toIntegerLiteral)
				val slaveQueueSetting = createSequentialAction
				branchActions += slaveQueueSetting
				
				for (slaveQueueStruct : slaveQueueStructs) {
					val slaveQueue = slaveQueueStruct.arrayVariable
					val slaveSizeVariable = slaveQueueStruct.sizeVariable
					
					val xStsSlaveQueues = variableTrace.getAll(slaveQueue)
					val xStsSlaveSizeVariable = variableTrace.getAll(slaveSizeVariable).onlyElement
					
					for (xStsSlaveQueue : xStsSlaveQueues) {
						val xStsRandomVariableAction = xStsSlaveQueue
							.createVariableDeclarationActionForArray(
								xStsSlaveQueue.randomValueLocalVariableName)
						val xStsRandomVariable = xStsRandomVariableAction.variableDeclaration
						slaveQueueSetting.actions += xStsRandomVariableAction
						slaveQueueSetting.actions += xStsRandomVariable.createHavocAction
						slaveQueueSetting.actions += xStsSlaveQueue.add(
							0.toIntegerLiteral,	xStsRandomVariable.createReferenceExpression)
					}
					slaveQueueSetting.actions += xStsSlaveSizeVariable.increment
				}
			}
			setQueuesAction.actions += branchExpressions.createChoiceAction(branchActions)
		}
		
		xSts.inEventTransition = inEventAction.wrap
		// Must not reset out events here: adapter instances reset them after running (no running, no reset)
//		xSts.outEventTransition = outEventAction.wrap
		
		xSts.changeTransitions(mergedAction.wrap)
		
		return xSts
	}
	
	protected def createEventDispatchAction(Port port,
			ReferenceToXstsVariableMapper eventReferenceMapper,
			Collection<? extends Port> systemPorts, Trace variableTrace) {
		val eventDispatchAction = createSequentialAction
		for (outEvent : port.outputEvents) {
			// Output binding is unidirectional
			val xStsOutEventVariable = eventReferenceMapper.getOutputEventVariable(outEvent, port)
			if (xStsOutEventVariable !== null) { // This can happen if out events are never referenced
			
				val ifExpression = xStsOutEventVariable.createReferenceExpression
				val thenAction = createSequentialAction
				val outEventResetActions = createSequentialAction
				
				val connectedAdapterPorts = newLinkedHashSet
				connectedAdapterPorts += port.allConnectedAsynchronousSimplePorts
				if (port.internal) {
					// Works as the same internal event is connected to the same port and traced in the message queue
					connectedAdapterPorts += port
				}
				
				for (connectedAdapterPort : connectedAdapterPorts) {
					val connectedPortEvent = new SimpleEntry(connectedAdapterPort, outEvent)
					if (queueTraceability.contains(connectedPortEvent)) {
						// The event is stored and has not been removed due to optimization
						val eventId = queueTraceability.get(connectedPortEvent)
						// Highest priority in the case of multiple queues allowing storage 
						val queueTrace = queueTraceability.getMessageQueues(connectedPortEvent)
						val originalQueue = queueTrace.key
						val capacity = originalQueue.getCapacity(systemPorts)
						val eventDiscardStrategy = originalQueue.eventDiscardStrategy
						val queueMapping = queueTrace.value
						
						val masterQueueStruct = queueMapping.masterQueue
						val masterQueue = masterQueueStruct.arrayVariable
						val masterSizeVariable = masterQueueStruct.sizeVariable
						val slaveQueues = queueMapping.slaveQueues.get(connectedPortEvent)
						
						val xStsMasterQueue = variableTrace.getAll(masterQueue).onlyElement
						val xStsMasterSizeVariable = variableTrace.getAll(masterSizeVariable).onlyElement
						
						// Expressions and actions that are used in every queue behavior
						val evaluatedCapacity = capacity.toIntegerLiteral
						val hasFreeCapacityExpression = xStsMasterSizeVariable.createReferenceExpression
								.createLessExpression(evaluatedCapacity)
						val block = createSequentialAction
						// Master
						block.actions += xStsMasterQueue.addAndIncrement(
								xStsMasterSizeVariable, eventId.toIntegerLiteral)
						// Resetting out event variable if it is not  led out to the system
						// Duplicated for broadcast ports - not a problem, but could be refactored
						val isSystemPort = systemPorts.contains(connectedAdapterPort.boundTopComponentPort)
						if (!isSystemPort || connectedAdapterPort.internal /* Though, the code keeps the internal raisings */) {
							// Variable can be reset even if the event is persistent as the in-pair will store it
							outEventResetActions.actions += xStsOutEventVariable.createVariableResetAction
						}
						// Slaves
						val parameters = outEvent.parameterDeclarations
						val slaveQueueSize = slaveQueues.size // Might be 0 if there is no in-event var
						for (var i = 0; i < slaveQueueSize; i++) {
							val parameter = parameters.get(i)
							val slaveQueueStruct = slaveQueues.get(i)
							val slaveQueue = slaveQueueStruct.arrayVariable
							val slaveSizeVariable = slaveQueueStruct.sizeVariable
							val xStsSlaveQueues = variableTrace.getAll(slaveQueue)
							val xStsSlaveSizeVariable = variableTrace.getAll(slaveSizeVariable).onlyElement
							// Output is unidirectional
							val xStsOutParameterVariables = eventReferenceMapper
									.getOutputParameterVariables(parameter, port)
							// Parameter optimization problem: parameters are not deleted independently
							block.actions += xStsSlaveQueues.addAllAndIncrement(xStsSlaveSizeVariable,
									xStsOutParameterVariables.map[it.createReferenceExpression])
							// Resetting out parameter variables if they are not led out to the system
							// Duplicated for broadcast ports - not a problem, but could be refactored
							if (!isSystemPort || connectedAdapterPort.internal /* Though, the code keeps the internal raisings */) {
								outEventResetActions.actions += xStsOutParameterVariables.map[it.createVariableResetAction]
							}
						}
						
						if (eventDiscardStrategy == DiscardStrategy.INCOMING) {
							// if (size < capacity) { "add elements into master and slave queues" }
							thenAction.actions += hasFreeCapacityExpression.createIfAction(block)
						}
						else if (eventDiscardStrategy == DiscardStrategy.OLDEST) {
							val popActions = createSequentialAction
							popActions.actions += xStsMasterQueue.popAndDecrement(xStsMasterSizeVariable)
							for (slaveQueueStruct : slaveQueues) {
								val slaveQueue = slaveQueueStruct.arrayVariable
								val slaveSizeVariable = slaveQueueStruct.sizeVariable
								val xStsSlaveQueues = variableTrace.getAll(slaveQueue)
								val xStsSlaveSizeVariable = variableTrace.getAll(slaveSizeVariable).onlyElement
								popActions.actions += xStsSlaveQueues.popAllAndDecrement(xStsSlaveSizeVariable)
							}
							// if ((!(size < capacity)) { "pop" }
							// "add elements into master and slave queues"
							thenAction.actions += hasFreeCapacityExpression.createNotExpression
									.createIfAction(popActions)
							thenAction.actions += block
						}
						else {
							throw new IllegalStateException("Not known behavior: " + eventDiscardStrategy)
						}
						// if (isRaised) { if ((!(size < capacity)) { "pop" }; isRasied = false; }
						thenAction.actions += outEventResetActions
					}
				}
				// if (inEvent) { "add elements into master and slave queues" }
				eventDispatchAction.actions += ifExpression.createIfAction(thenAction)
			}
		}
		return eventDispatchAction
	}
	
	def dispatch XSTS transform(AsynchronousAdapter component, Package lowlevelPackage) {
		val isTopInPackage = component.topInPackage
		if (isTopInPackage) {
			component.checkAdapter
		}
		
		val wrappedInstance = component.wrappedComponent
		val wrappedType = wrappedInstance.type
		
		wrappedType.extractParameters(wrappedInstance.arguments) 
		val xSts = wrappedType.transform(lowlevelPackage)
		if (wrappedType.statechart) {
			// Customize names as the type can be a statechart (before setting the new in event)
			xSts.customizeDeclarationNames(wrappedInstance)
		}
		
		// Resetting out and events manually as a "schedule" call in the code does that
		xSts.resetOutEventsBeforeMergedAction(wrappedType)
		xSts.resetInEventsAfterMergedAction(wrappedType)
		xSts.addInternalEventResetingActionsInMergedAction(wrappedType)
		//
		
		// Internal event handling: only remove - event dispatch will tend to the addition
		xSts.removeInternalEventHandlingActions(component, traceability)
		//
		
		if (isTopInPackage) {
			val inEventAction = xSts.inEventTransition
			// Deleting synchronous event assignments
			val xStsSynchronousInEventVariables = xSts.variableGroups
				.filter[it.annotation instanceof InEventGroup].map[it.variables]
				.flatten.toSet // There are more than one
			for (xStsAssignment : inEventAction.getAllContentsOfType(AbstractAssignmentAction)) {
				val xStsReference = xStsAssignment.lhs
				val xStsDeclaration = xStsReference.declaration
				if (xStsSynchronousInEventVariables.contains(xStsDeclaration)) {
					xStsAssignment.remove // Deleting in-event bool flags
				}
			}
			
			val extension eventRef = new ReferenceToXstsVariableMapper(xSts)
			// Collecting the referenced event variables
			val messageQueue = component.messageQueues.head // Only one
			
			val newInEventAction = createSequentialAction
			// Choosing a random event to raise
			val storedEvents = messageQueue.storedEvents
			val min = messageQueue.minEventId
			val max = messageQueue.maxEventId
			
			val randomActions = createChoiceActionForRandomValues(
					messageQueue.name + "_" + messageQueue.hashCode.abs, min, max + 1 /* exclusive */)
			val storageAction = randomActions.key
			newInEventAction.actions += storageAction
			val choiceAction = randomActions.value
			val branchActions = choiceAction.actions
			
			val removableBranchActions = newArrayList
			for (var i = min; i <= max; i++) {
				val index = i - min // As indexing starts from 0, not from min
				val branchAction = branchActions.get(index)
				val portEvent = storedEvents.get(index)
				val port = portEvent.key
				val event = portEvent.value
				
				val xStsInputEventVariables = event.getInputEventVariables(port)
				if (xStsInputEventVariables.empty &&
						// We have to keep the control ports
						!component.ports.contains(port)) {
					removableBranchActions += branchAction // The input event is unused
				}
				else {
					// Can be more than one - one port can be mapped to multiple instance ports
					// Can be empty if it is a control port
					for (xStsInputEventVariable : xStsInputEventVariables) {
						branchAction.appendToAction(xStsInputEventVariable
							.createAssignmentAction(createTrueExpression))
					}
				}
			}
			removableBranchActions.forEach[it.remove] // Removing now - it would break the indexes in the loop
			
			// Original parameter settings
			// Parameters that come from the same ports are bound to the same values - done by previous call
			newInEventAction.actions += inEventAction.action
			
			xSts.inEventTransition = newInEventAction.wrap
		}
		
		return xSts
	}
	
	def dispatch XSTS transform(AbstractSynchronousCompositeComponent component, Package lowlevelPackage) {
		val name = component.name
		logger.log(Level.INFO, "Transforming abstract synchronous composite " + name)
		val xSts = name.createXsts
		val componentMergedActions = <Component, Action>newHashMap // To handle multiple schedulings in CascadeCompositeComponents
		val components = component.components
		
		if (components.empty) {
			logger.log(Level.WARNING, "No components in abstract synchronous composite " + name)
			return xSts
		}
		
		// Input, output and tracing merged actions
		for (var i = 0; i < components.size; i++) {
			val subcomponent = components.get(i)
			val subcomponentType = subcomponent.type
			
			// Normal transformation
			subcomponentType.extractParameters(subcomponent.arguments) // Change the reference from parameters to constants
			val newXSts = subcomponentType.transform(lowlevelPackage)
			newXSts.customizeDeclarationNames(subcomponent)
			
			// Adding new elements
			xSts.merge(newXSts)
			
			// Internal event handling here as EventReferenceHandler cannot be used without customizeDeclarationNames
			if (subcomponentType.statechart) {
				xSts.addInternalEventHandlingActions(subcomponentType, traceability)
			}
			//
			
			// Initializing action
			val variableInitAction = createSequentialAction
			variableInitAction.actions += xSts.variableInitializingTransition.action
			variableInitAction.actions += newXSts.variableInitializingTransition.action
			xSts.variableInitializingTransition = variableInitAction.wrap
			val configInitAction = createSequentialAction
			configInitAction.actions += xSts.configurationInitializingTransition.action
			configInitAction.actions += newXSts.configurationInitializingTransition.action
			xSts.configurationInitializingTransition = configInitAction.wrap
			val entryAction = createSequentialAction
			entryAction.actions += xSts.entryEventTransition.action
			entryAction.actions += newXSts.entryEventTransition.action
			xSts.entryEventTransition = entryAction.wrap
			
			// Merged action
			val actualComponentMergedAction = createSequentialAction => [
				it.actions += newXSts.mergedAction
			]
			// In and Out actions - using sequential actions to make sure they are composite actions
			// Methods reset... and delete... require this
			val newInEventAction = createSequentialAction => [ it.actions += newXSts.inEventTransition.action ]
			newXSts.inEventTransition = newInEventAction.wrap
			val newOutEventAction = createSequentialAction => [ it.actions += newXSts.outEventTransition.action ]
			newXSts.outEventTransition = newOutEventAction.wrap
			// Resetting channel events
			// 1) the Sync ort semantics: Resetting channel IN events AFTER schedule would result in a deadlock
			// 2) the Casc semantics: Resetting channel OUT events BEFORE schedule would delete in events of subsequent components
			// Note, System in and out events are reset in the env action
			if (component instanceof CascadeCompositeComponent) {
				// Resetting IN events AFTER schedule - refactor to method call
				val clonedNewInEventAction = newInEventAction.clone
						.resetEverythingExceptPersistentParameters(subcomponentType) // Clone is important
				actualComponentMergedAction.actions += clonedNewInEventAction // Putting the new action AFTER
			}
			else {
				// Resetting OUT events BEFORE schedule
				val clonedNewOutEventAction = newOutEventAction.clone // Clone is important
						.resetEverythingExceptPersistentParameters(subcomponentType)
				actualComponentMergedAction.actions.add(0, clonedNewOutEventAction) // Putting the new action BEFORE
			}
			// Tracing merged action
			componentMergedActions += subcomponentType -> actualComponentMergedAction.clone
			
			// In event
			newInEventAction.deleteEverythingExceptSystemEventsAndParameters(component)
			if (xSts !== newXSts) { // Only if this is not the first component
				val inEventAction = createSequentialAction
				inEventAction.actions += xSts.inEventTransition.action
				inEventAction.actions += newInEventAction
				xSts.inEventTransition = inEventAction.wrap
			}
			// Out event
			newOutEventAction.deleteEverythingExceptSystemEventsAndParameters(component)
			if (xSts !== newXSts) { // Only if this is not the first component
				val outEventAction = createSequentialAction
				outEventAction.actions += xSts.outEventTransition.action
				outEventAction.actions += newOutEventAction
				xSts.outEventTransition = outEventAction.wrap
			}
		}
		
		// Potentially executing instances before first environment transition (cascade only)
		// System out events are NOT cleared
		if (component instanceof CascadeCompositeComponent) {
			for (subcomponent : component.initallyScheduledInstances) {
				val componentType = subcomponent.derivedType
				checkState(componentMergedActions.containsKey(componentType))
				val entryEventAction = xSts.entryEventTransition.action
				// Component instance in events are cleared, see above "newInEventAction.clone
				//			.resetEverythingExceptPersistentParameters(componentType)"
				val componentMergedAction = componentMergedActions.get(componentType).clone
				entryEventAction.appendToAction(componentMergedAction)
			}
		}
		
		// Merged action based on scheduling instances
		val scheduledInstances = component.scheduledInstances
		val mergedAction = (component instanceof CascadeCompositeComponent) ?
				createSequentialAction : createOrthogonalAction
		for (var i = 0; i < scheduledInstances.size; i++) {
			val subcomponent = scheduledInstances.get(i)
			val componentType = subcomponent.type
			checkState(componentMergedActions.containsKey(componentType))
			val componentMergedAction = componentMergedActions.get(componentType).clone
			mergedAction.actions += componentMergedAction
		}
		xSts.changeTransitions(mergedAction.wrap)
		
		logger.log(Level.INFO, "Deleting unused instance ports in " + name)
		xSts.deleteUnusedPorts(component) // Deleting variable assignments for unused ports
		
		// Connect only after "xSts.mergedTransition.action = mergedAction" / "xSts.changeTransitions"
		logger.log(Level.INFO, "Connecting events through channels in " + name)
		xSts.connectEventsThroughChannels(component) // Event (variable setting) connecting across channels
		
		logger.log(Level.INFO, "Binding event to system port events in " + name)
		val oldInEventAction = xSts.inEventTransition.action
		val bindingAssignments = xSts.createEventAndParameterAssignmentsBoundToTheSameSystemPort(component)
		// Optimization: removing old NonDeterministicActions 
		bindingAssignments.removeNonDeterministicActionsReferencingAssignedVariables(oldInEventAction)
		
		val newInEventAction = createSequentialAction => [
			it.actions += oldInEventAction
			// Bind together ports connected to the same system port
			it.actions += bindingAssignments
		]
		
		xSts.inEventTransition = newInEventAction.wrap
		
		if (transformOrthogonalActions) {
			// After connectEventsThroughChannels
			logger.log(Level.INFO, "Transforming orthogonal actions in XSTS " + name)
			xSts.mergedAction.transform(xSts)
			// Before optimize actions
		}
		
		if (optimize) {
			// Optimization: system in events (but not PERSISTENT parameters) can be reset after the merged transition
			// E.g., synchronous components do not reset system events
			xSts.resetInEventsAfterMergedAction(component)
		}
		
		// After in event optimization
		logger.log(Level.INFO, "Readjusting internal event handlings in " + name)
		xSts.replaceInternalEventHandlingActions(component, traceability)
		// TODO internal event optimization?
		
		return xSts
	}
	
	def dispatch XSTS transform(StatechartDefinition statechart, Package lowlevelPackage) {
		logger.log(Level.INFO, "Transforming statechart " + statechart.name)
		/* Note that the package is already transformed and traced because of
		   the "val lowlevelPackage = gammaToLowlevelTransformer.transform(_package)" call */
		val lowlevelStatechart = gammaToLowlevelTransformer.transform(statechart)
		lowlevelPackage.components += lowlevelStatechart
		val lowlevelToXSTSTransformer = new LowlevelToXstsTransformer(
			lowlevelPackage, optimize, transitionMerging)
		val xStsEntry = lowlevelToXSTSTransformer.execute
		lowlevelPackage.components -= lowlevelStatechart // So that next time the matches do not return elements from this statechart
		val xSts = xStsEntry.key
		
		// 0-ing all variable declaration initial expression, the normal ones are in the init action
		for (variable : xSts.variableDeclarations) {
			variable.expression = variable.defaultExpression
		}
		
		return xSts
	}
	
	// Utils
	
	private def void extractAllParameters(AbstractAsynchronousCompositeComponent component) {
		for (instance : component.components) {
			val arguments = instance.arguments
			val type = instance.type
			type.extractParameters(arguments)
			if (type instanceof AbstractAsynchronousCompositeComponent) {
				type.extractAllParameters
			}
		}
	}
	
	private def extractParameters(Component component, List<Expression> arguments) {
		val _package = component.containingPackage
		val parameters = newArrayList
		parameters += component.parameterDeclarations // So delete does not mess the list up
		// Theta back-annotation retrieves the argument values from the constant list
		
		_package.constantDeclarations += parameters.extractParameters(
				parameters.map['''_«it.name»_«it.hashCode.abs»'''], arguments)
		
		// Deleting after the index settings have been completed (otherwise the index always returns 0)
		parameters.deleteAll
	}
	
	private def checkAdapter(AsynchronousAdapter component) {
		checkState(component.simplifiable)
	}
	
	private def getCapacity(MessageQueue queue, Collection<? extends Port> systemPorts) {
		if (queue.isEnvironmentalAndCheck(systemPorts)) {
			val messageRetrievalCount = queue.messageRetrievalCount
			return messageRetrievalCount // capacity can be equal to messageRetrievalCount for env. queues
		}
		val capacity = queue.capacity
		return capacity.evaluateInteger
	}
	
	private def getMessageRetrievalCount(MessageQueue queue) {
		return 1
	}
	
	private def isEnvironmentalAndCheck(MessageQueue queue, Collection<? extends Port> systemPorts) {
		if (queue.isEnvironmental(systemPorts)) {
			return true // All events are system events (no internal events)
		}
		val portEvents = queue.storedEvents
		val ports = portEvents.map[it.key]
		val topPorts = ports.map[it.boundTopComponentPort]
		val capacity = queue.capacity.evaluateInteger
		if (systemPorts.containsAny(topPorts) && capacity == 1) {
//			return true /* Contains other events too, but the queue will always be empty,
//				when handling it in the in-event action */
			// Not true: except if the initial action raises some internal events
			// Not true: internal events?
			return false
		}
		checkState(systemPorts.containsNone(topPorts) || topPorts.forall[it.internal],
				"All or none of the ports must be system ports")
		return false
	}
	
	private def void resetOutEventsBeforeMergedAction(XSTS xSts, Component type) {
		val outEventAction = xSts.outEventTransition.action
		val clonedOutEventAction = outEventAction.clone
		// Not PERSISTENT parameters
		val resetAction = clonedOutEventAction.resetEverythingExceptPersistentParameters(type)
		val mergedAction = xSts.mergedAction
		resetAction.prependToAction(mergedAction)
	}
	
	private def void resetInEventsAfterMergedAction(XSTS xSts, Component type) {
		val inEventAction = xSts.inEventTransition.action
		val clonedInEventAction = inEventAction.clone
		// Not PERSISTENT parameters
		val resetAction = clonedInEventAction.resetEverythingExceptPersistentParameters(type)
		val mergedAction = xSts.mergedAction
		mergedAction.appendToAction(resetAction)
	}
	
	private def void customizeDeclarationNames(XSTS xSts, ComponentInstance instance) {
		val type = instance.derivedType
		if (type instanceof StatechartDefinition) {
			// Customizing every variable name
			for (variable : xSts.variableDeclarations) {
				variable.name = variable.getCustomizedName(instance)
			}
			// Customizing region type declaration name
			for (regionType : xSts.variableGroups.filter[it.annotation instanceof RegionGroup]
					.map[it.variables].flatten.map[it.type].filter(TypeReference).map[it.reference]) {
				regionType.name = regionType.customizeRegionTypeName(type)
			}
		}
	}
	
}