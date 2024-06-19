/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
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
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.lowlevel.xsts.transformation.LowlevelToXstsTransformer
import hu.bme.mit.gamma.lowlevel.xsts.transformation.TransitionMerging
import hu.bme.mit.gamma.statechart.composite.AbstractAsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AbstractSynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.composite.AsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.DiscardStrategy
import hu.bme.mit.gamma.statechart.composite.MessageQueue
import hu.bme.mit.gamma.statechart.composite.ScheduledAsynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
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
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.InEventGroup
import hu.bme.mit.gamma.xsts.model.RegionGroup
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.transformation.util.OrthogonalActionTransformer
import hu.bme.mit.gamma.xsts.transformation.util.VariableGroupRetriever
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.AbstractMap.SimpleEntry
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.Map.Entry
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
	protected XSTS xSts
	// Transformation settings
	protected final boolean transformOrthogonalActions
	protected final boolean optimize
	protected final boolean optimizeEnvironmentalMessageQueues
	protected final TransitionMerging transitionMerging
	// Auxiliary objects
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected final extension VariableGroupRetriever retriever = VariableGroupRetriever.INSTANCE
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
	//
	
	new(GammaToLowlevelTransformer gammaToLowlevelTransformer, boolean transformOrthogonalActions,
			boolean optimize, boolean optimizeEnvironmentalMessageQueues, TransitionMerging transitionMerging) {
		this.gammaToLowlevelTransformer = gammaToLowlevelTransformer
		this.transformOrthogonalActions = transformOrthogonalActions
		this.optimize = optimize
		this.optimizeEnvironmentalMessageQueues = optimizeEnvironmentalMessageQueues
		this.transitionMerging = transitionMerging
		this.queueTraceability = new MessageQueueTraceability
	}
	
	def dispatch XSTS transform(Component component, Package lowlevelPackage) {
		throw new IllegalArgumentException("Not supported component type: " + component)
	}
	
	def dispatch XSTS transform(AbstractAsynchronousCompositeComponent component, Package lowlevelPackage) {
		val systemPorts = component.allPorts
		// Parameters of all asynchronous composite components
		component.extractAllParameters
		// Retrieving the adapter instances - hierarchy does not matter here apart from the order
		val adapterInstances = component.allAsynchronousSimpleInstances
		val environmentalQueues = newLinkedHashSet
		
		val name = component.name
		val xSts = name.createXsts
		this.xSts = xSts
		
		val eventReferenceMapper = new ReferenceToXstsVariableMapper(xSts)
		val valueDeclarationTransformer = new ValueDeclarationTransformer
		val variableTrace = valueDeclarationTransformer.getTrace
		
		val variableInitAction = createSequentialAction
		val configInitAction = createSequentialAction
		val entryAction = createSequentialAction
		
		val inEventAction = createSequentialAction
//		val outEventAction = createSequentialAction

		val mergedClockAction = createSequentialAction
		
		// Transforming and saving the adapter instances
		
		val mergedSynchronousActions = newHashMap
		val mergedSynchronousInitActions = newHashMap
		
		for (adapterInstance : adapterInstances) {
			val adapterComponentType = adapterInstance.type as AsynchronousAdapter
			
			/// Deleting unnecessary port-event references in queues
			adapterInstance.deleteUnusedPortReferencesInQueues
			//
			
			adapterComponentType.extractParameters(adapterInstance.arguments) // Parameters
			val adapterXsts = adapterComponentType.transform(lowlevelPackage)
			xSts.merge(adapterXsts) // Adding variables, types, etc.
			
			mergedSynchronousInitActions += adapterInstance -> adapterXsts.initializingAction
			// Saving the init action before the change
			variableInitAction.actions += adapterXsts.variableInitializingTransition.action
			configInitAction.actions += adapterXsts.configurationInitializingTransition.action
			entryAction.actions += adapterXsts.entryEventTransition.action
			
			mergedSynchronousActions += adapterInstance -> adapterXsts.mergedAction
			
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
				
				val storedClocks = newLinkedHashSet
				for (clock : queue.storedClocks) {
					val id = queue.getEventId(clock) // Id is needed during back-annotation
					queueTraceability.put(clock, id)
					storedClocks += clock
					logger.info( '''Assigning «id» to «clock.name»''')
				}
				val storedPortEvents = newLinkedHashSet
				val events = queue.storedEvents
				for (event : events) {
					val id = queue.getEventId(event) // Id is needed during back-annotation
					queueTraceability.put(event, id)
					storedPortEvents += event
					logger.info( '''Assigning «id» to «event.key.name».«event.value.name»''')
				}
				
				val masterQueueName = queue.getMasterQueueName(adapterInstance)
				
				// Creating the event ID type with an EMPTY literal for master message queues
				val eventIdType = createEnumerationTypeDefinition // To limit the possible values for message identifiers
				eventIdType.literals += "EMPTY".createEnumerationLiteralDefinition
				val eventIdTypeDeclaration = eventIdType.createTypeDeclaration(
						"EventIdTypeOf" + masterQueueName)
				//
				
				val evaluatedCapacity = queue.getCapacity(systemPorts)
				val masterQueueType = createArrayTypeDefinition => [
					it.elementType = eventIdTypeDeclaration.createTypeReference
					it.size = evaluatedCapacity.toIntegerLiteral
				]
				val masterQueue = masterQueueType.createVariableDeclaration(masterQueueName)
				
				val masterSizeVariableName = queue.getMasterSizeVariableName(adapterInstance)
				val masterSizeVariable = (evaluatedCapacity == 1) ? null : // Master array size var optimization
					createIntegerTypeDefinition
						.createVariableDeclaration(masterSizeVariableName)
				
				val slaveQueuesMap = newLinkedHashMap
				val typeSlaveQueuesMap = newLinkedHashMap // Reusing slave queues for same types if possible
				for (portEvent : events) {
					val port = portEvent.key
					val event = portEvent.value
					val List<MessageQueueStruct> slaveQueues = newArrayList
					
					// Potentially the same as port and event; makes a difference only in the case of EventPassings
					val targetPortEvent = queue.getTargetPortEvent(portEvent)
					val targetPort = targetPortEvent.key
					val targetEvent = targetPortEvent.value
					//
					
					// Important optimization - we create a queue only if the event is used
					if (eventReferenceMapper.hasInputEventVariable(targetEvent, targetPort)) {
						for (parameter : event.parameterDeclarations) {
							val parameterType = parameter.type
							val parameterTypeDefinition = parameterType.typeDefinition
							// Optimization - we compare the type definitions of parameters
							val typeSlaveQueues = typeSlaveQueuesMap.getOrCreateList(parameterTypeDefinition)
							
							val index = parameter.indexOfParametersWithSameTypeDefinition
							// Indexing works: parameters of an event are not deleted separately
							if (queue.isEnvironmentalAndCheck(systemPorts) || // Traceability reasons: no optimization for system parameters
									typeSlaveQueues.size <= index) {
								// index is less at most by 1 - creating a new slave queue for type
								val slaveQueueType = createArrayTypeDefinition => [
									it.elementType = parameterType.clone // Not type definition due to enums
									it.size = evaluatedCapacity.toIntegerLiteral
								]
								val slaveQueueName = parameter.getSlaveQueueName(port, adapterInstance)
								val slaveQueue = slaveQueueType.createVariableDeclaration(slaveQueueName)
								
								val slaveSizeVariableName = parameter.getSlaveSizeVariableName(port, adapterInstance)
								// Slave queue size variables cannot be optimized as 0 can be a valid value
								val slaveSizeVariable = (masterSizeVariable === null) ? null : createIntegerTypeDefinition
										.createVariableDeclaration(slaveSizeVariableName)
								
								val isInternal = parameter.isInternal
								
								val messageQueueStruct = new MessageQueueStruct(slaveQueue, slaveSizeVariable, isInternal)
								slaveQueues += messageQueueStruct
								typeSlaveQueues += messageQueueStruct
								logger.info( '''Created a slave queue for «port.name».«event.name»::«parameter.name»''')
							}
							else {
								// Internal queue, we do not care about traceability here
								val messageQueueStruct = typeSlaveQueues.get(index)
								slaveQueues += messageQueueStruct // Optimization - reusing an existing slave queue
								logger.info( '''Found a slave queue for «port.name».«event.name»::«parameter.name»''')
							}
						}
					} // If no input event variable - slaveQueues is empty
					slaveQueuesMap += portEvent -> slaveQueues
				}
				
				val messageQueueMapping = new MessageQueueMapping(storedClocks, storedPortEvents, eventIdType,
						new MessageQueueStruct(masterQueue, masterSizeVariable, false), slaveQueuesMap, typeSlaveQueuesMap)
				queueTraceability.put(queue, messageQueueMapping)
				val slaveQueueMappings = messageQueueMapping.typeSlaveQueues
			
				// Transforming the message queue constructions into native XSTS variables
				// We do not care about the names (renaming) here
				// Namings.customize* covers the same naming behavior as QueueNamings + valueDeclarationTransformer
				
				val xStsMasterQueueVariable = valueDeclarationTransformer.transform(masterQueue).onlyElement
//				xStsMasterQueueVariable.addStrictControlAnnotation
				xSts.variableDeclarations += xStsMasterQueueVariable
				xSts.masterMessageQueueGroup.variables += xStsMasterQueueVariable
				val isQueueEnvironmental = queue.isEnvironmentalAndCheck(systemPorts)
				if (isQueueEnvironmental) {
					xSts.systemMasterMessageQueueGroup.variables += xStsMasterQueueVariable
				}
				if (masterSizeVariable !== null) { // Can be null due to potential optimization
					val xStsMasterSizeVariable = valueDeclarationTransformer.transform(masterSizeVariable).onlyElement
					xStsMasterSizeVariable.addDeclarationReferenceAnnotation(xStsMasterQueueVariable)
					xStsMasterQueueVariable.addDeclarationReferenceAnnotation(xStsMasterSizeVariable)
					
					xSts.variableDeclarations += xStsMasterSizeVariable
					xSts.messageQueueSizeGroup.variables += xStsMasterSizeVariable
					xStsMasterSizeVariable.addStrictControlAnnotation // Needed for loops
				}
				
				val slaveQueuesCollection = slaveQueueMappings.values
				val slaveQueueStructs = slaveQueuesCollection.flatten
				checkState(slaveQueueStructs.unique)
				for (slaveQueueStruct : slaveQueueStructs) {
					val slaveQueue = slaveQueueStruct.arrayVariable
					val xStsSlaveQueueVariables = valueDeclarationTransformer.transform(slaveQueue)
					xSts.variableDeclarations += xStsSlaveQueueVariables
					xSts.slaveMessageQueueGroup.variables += xStsSlaveQueueVariables
					if (isQueueEnvironmental) {
						xSts.systemSlaveMessageQueueGroup.variables += xStsSlaveQueueVariables
					}
					val slaveSizeVariable = slaveQueueStruct.sizeVariable
					if (slaveSizeVariable !== null) {
						val xStsSlaveSizeVariable = valueDeclarationTransformer.transform(slaveSizeVariable).onlyElement
						xStsSlaveSizeVariable.addDeclarationReferenceAnnotation(xStsSlaveQueueVariables.head) // Not sound due to slave queue opt?
						for (xStsSlaveQueueVariable : xStsSlaveQueueVariables) {
							xStsSlaveQueueVariable.addDeclarationReferenceAnnotation(xStsSlaveSizeVariable)
						}
						
						xSts.variableDeclarations += xStsSlaveSizeVariable
						xSts.messageQueueSizeGroup.variables += xStsSlaveSizeVariable
						xStsSlaveSizeVariable.addStrictControlAnnotation // Needed for loops
						// The type might not be correct here and later has to be reassigned to handle enums
					}
				}
				//
				val messageQueueGroup = xSts.masterMessageQueueGroup // Slaves must not be retrieved here: exception in type declaration opt. part
				val xStsTypeDeclarations = messageQueueGroup.variables.map[it.elementTypeDefinition]
						.filter[it.isContainedBy(TypeDeclaration)].map[it.typeDeclaration]
				xSts.typeDeclarations += xStsTypeDeclarations
				//
			}
		}
		
		// Creating queue process behavior
		
		val queueHandlingMergedActions = newHashMap // Cache for queue-handling merged action and message dispatch
		val mergedAdapterActions = newHashMap // Cache for adapter actions
		
		for (adapterInstance : adapterInstances) {
			val instanceMergedAction = createSequentialAction
			
			val adapterComponentType = adapterInstance.type as AsynchronousAdapter
			val originalMergedAction = mergedSynchronousActions.get(adapterInstance)
			// Input event processing
			val inputIfAction = createIfAction // Will be appended when handling queues
			instanceMergedAction.actions += inputIfAction
			
			// Queues in order of priority
			for (queue : adapterComponentType.functioningMessageQueuesInPriorityOrder) {
				val queueMapping = queueTraceability.get(queue)
				val masterQueue = queueMapping.masterQueue.arrayVariable
				val masterSizeVariable = queueMapping.masterQueue.sizeVariable
				val slaveQueues = queueMapping.slaveQueues
				
				// Actually, the following values are "low-level values", but we handle them as XSTS values
				val xStsMasterQueue = variableTrace.getAll(masterQueue).onlyElement
				val xStsMasterSizeVariable = (masterSizeVariable === null) ? null :
						variableTrace.getAll(masterSizeVariable).onlyElement
				// Retrieving the event ID enumeration type
				val xStsEventIdType = xStsMasterQueue.elementTypeDefinition as EnumerationTypeDefinition
				val xStsEventIdTypeDeclaration = xStsEventIdType.typeDeclaration
				//
				
				val block = createSequentialAction
				// if (0 < size) { ... }
				inputIfAction.append(
						xStsMasterQueue.isMasterQueueNotEmpty(xStsMasterSizeVariable), block)
				
				val xStsEventIdVariableAction = xStsEventIdTypeDeclaration.createVariableDeclarationAction(
						xStsMasterQueue.eventIdLocalVariableName, xStsMasterQueue.peek)
				val xStsEventIdVariable = xStsEventIdVariableAction.variableDeclaration
				block.actions += xStsEventIdVariableAction
				block.actions += xStsMasterQueue.popAndPotentiallyDecrement(xStsMasterSizeVariable)
				
				// Processing the possible different event identifiers
				
				val branchExpressions = <Expression>newArrayList
				val branchActions = <Action>newArrayList
				
//				val emptyValue = xStsMasterQueue.arrayElementType.defaultExpression
				// if (eventId == 0) { empty } // This is impossible
//				branchExpressions += xStsEventIdVariable.createEqualityExpression(emptyValue)
//				branchActions += createEmptyAction
				// if (0 < sizeOfQueue) {..} - If this holds above, then the emptyValue cannot be present in the queue
				
				val eventReferences = queue.storedEvents + queue.storedClocks
				for (eventReference : eventReferences) {
					val eventIntegerId = queueTraceability.get(eventReference)
					val eventId = xStsEventIdType.addOrGetEventIdLiteral(eventIntegerId)
					
					// Mapping source event reference to target
					val targetPortEvent = queue.getTargetPortEvent(eventReference)
					val targetPort = targetPortEvent?.key
					val targetEvent = targetPortEvent?.value
					val xStsInEventVariables = newArrayList // Can be empty due to optimization or adapter event
					if (targetPortEvent !== null) {
						xStsInEventVariables += eventReferenceMapper.getInputEventVariables(targetEvent, targetPort)
					}
					
					val ifExpression = xStsEventIdVariable.createReferenceExpression
							.createEqualityExpression(eventId.createEnumerationLiteralExpression)
					val thenAction = createSequentialAction
					// Setting the event variables to true (multiple binding is supported)
					for (xStsInEventVariable : xStsInEventVariables) {
						thenAction.actions += xStsInEventVariable.createAssignmentAction(
								createTrueExpression)
					}
					//// Optimization: if the control specification is 'when any / run' then all other inputs are known to be false
					if (adapterComponentType.whenAnyRunOnce) {
						val inputPorts = adapterComponentType.allPortsWithInput
						for (inputPort : inputPorts) {
							for (inputEvent : inputPort.inputEvents) {
								val xStsFalseInEventVariables = eventReferenceMapper.getInputEventVariables(inputEvent, inputPort)
										.reject[xStsInEventVariables.contains(it)]
								thenAction.actions += xStsFalseInEventVariables.map[it.createVariableResetAction] // 'Assume' would be better?
							}
						}
					}
					////
					// Setting the parameter variables with values stored in slave queues
					val slaveQueueStructs = if (eventReference instanceof Entry<?, ?>) {
						val portEvent = eventReference as Entry<Port, Event>
						slaveQueues.get(portEvent) // Might be empty
					} else { #[] } // Empty array for clocks
					
					val inParameters = (targetEvent !== null) ? targetEvent.parameterDeclarations : #[]
					val slaveQueueSize = slaveQueueStructs.size // Might be 0 if there is no in-event var
					
					if (inParameters.size <= slaveQueueSize) {
						for (var i = 0; i < slaveQueueSize; i++) {
							val slaveQueueStruct = slaveQueueStructs.get(i)
							val slaveQueue = slaveQueueStruct.arrayVariable
							val slaveSizeVariable = slaveQueueStruct.sizeVariable
							val inParameter = inParameters.get(i)
							
							val xStsSlaveQueues = variableTrace.getAll(slaveQueue)
							val xStsSlaveSizeVariable = (slaveSizeVariable === null) ? null :
									variableTrace.getAll(slaveSizeVariable).onlyElement
							val xStsInParameterVariableLists = eventReferenceMapper
									.getInputParameterVariablesByPorts(inParameter, targetPort)
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
							thenAction.actions += xStsSlaveQueues.popAllAndPotentiallyDecrement(xStsSlaveSizeVariable)
						}
					}
					else {
						// It can happen that a control event, which has no in-event variable, has parameters
						// In this case, the parameters are not handled and there are no slave queues:
						// (inParameters.size > slaveQueueSize) -> slaveQueueSize == 0
						checkState(slaveQueueSize == 0)
					}
					
					// queue reset > component reset > component run
					val resetQueues = adapterComponentType.getResetQueues(eventReference)
					if (!resetQueues.empty) {
						val xStsQueueResetActions = resetQueues.resetMessageQueues(variableTrace)
						thenAction.actions += xStsQueueResetActions
					}
					else if (adapterComponentType.isComponentResetSpecification(eventReference)) {
						val originalInitAction = mergedSynchronousInitActions.get(adapterInstance)
						thenAction.actions += originalInitAction.clone
					}
					else if (adapterComponentType.isRunSpecification(eventReference)) { // Execution if necessary
						thenAction.actions += originalMergedAction.clone
					}
					// ...here other control actions could be mapped (implemented)
					
					// if (eventId == ..) { "transfer slave queue values" if (isControlSpec) { "run" }
					branchExpressions += ifExpression
					branchActions += thenAction
				}
				// Note that the last expression is unnecessary as all branches (event ids) are disjoint and
				// complete -> removing the last one to create an 'else' branch (optimization) if queue is not empty
				if (!branchExpressions.empty) {
					branchExpressions.removeLast
				}
				if (branchExpressions.empty) {
					val onlyAction = (branchActions.empty) ? createEmptyAction // No message can be placed in the queue
							: branchActions.onlyElement // Only one event can come
					block.actions += onlyAction
				}
				else {
					// Excluding branches for the different event identifiers
					// Fixed disjoint set of eventIds - 'if' + 'else' instead of 'choice'
					block.actions += branchExpressions.createIfAction(branchActions)
				}
			}
			if (inputIfAction.condition === null) {
				logger.warning('''Component instance «adapterInstance.name» has no incoming messages, so it is never executed...''')
				createEmptyAction.replace(inputIfAction)
			}
			
			// Clock mechanisms
			val clockActions = createSequentialAction
			for (clock : adapterComponentType.clocks) {
				val clockRate = clock.timeSpecification.timeInMilliseconds
				
				val xStsClockName = clock.customizeName(adapterInstance)
				val xStsVariable = createIntegerTypeDefinition
						.createVariableDeclarationWithDefaultInitialValue(xStsClockName)
				xSts.variableDeclarations += xStsVariable // Target model modification
				
				variableInitAction.actions += xStsVariable.createAssignmentAction(
						0.toIntegerLiteral)
				
				xStsVariable.addClockAnnotation // Because of this, time passing is modeled "automatically"
				xSts.timeoutGroup.variables += xStsVariable
				
				val hasClockTimeElapsed = clockRate.createLessEqualExpression(
						xStsVariable.createReferenceExpression)
				val clockHandlingBlock = createSequentialAction
				val clockHandling = hasClockTimeElapsed.createIfAction(clockHandlingBlock)
				clockHandlingBlock.actions += xStsVariable.createVariableResetAction // clock := 0
				clockActions.actions += clockHandling
				
				for (queue : clock.storingMessageQueues) {
					val queueMapping = queueTraceability.get(queue)
					val masterQueue = queueMapping.masterQueue.arrayVariable
					val masterSizeVariable = queueMapping.masterQueue.sizeVariable
					
					val xStsMasterQueue = variableTrace.getAll(masterQueue).onlyElement
					val xStsMasterSizeVariable = (masterSizeVariable === null) ? null :
							variableTrace.getAll(masterSizeVariable).onlyElement
					
					val xStsEventIdType = xStsMasterQueue.elementTypeDefinition as EnumerationTypeDefinition
					val clockIntegerId = queueTraceability.get(clock)
					val clockId = xStsEventIdType.addOrGetEventIdLiteral(clockIntegerId)
					
					val clockIdAddition = xStsMasterQueue.addAndPotentiallyIncrement(
								xStsMasterSizeVariable, clockId.createEnumerationLiteralExpression)
					
					val eventDiscardStrategy = queue.eventDiscardStrategy
					if (eventDiscardStrategy == DiscardStrategy.INCOMING) {
						// if (size < capacity) { "add elements into master  queue" }
						val isMasterQueueNotFull = xStsMasterQueue.isMasterQueueNotFull(xStsMasterSizeVariable)
						clockHandlingBlock.actions += isMasterQueueNotFull.createIfAction(clockIdAddition)
					}
					else if (eventDiscardStrategy == DiscardStrategy.OLDEST) {
						// if (size >= capacity) { "pop"} "add elements into master queue"
						val isMasterQueueFull = xStsMasterQueue.isMasterQueueFull(xStsMasterSizeVariable)
						clockHandlingBlock.actions += isMasterQueueFull.createIfAction(
								xStsMasterQueue.popAndPotentiallyDecrement(xStsMasterSizeVariable))
						clockHandlingBlock.actions += clockIdAddition
					}
					else {
						throw new IllegalStateException("Not known behavior: " + eventDiscardStrategy)
					}
				}
			}
			if (!clockActions.actions.empty) {
				// We have to move it to the start of the final merged action
				mergedClockAction.actions.add(0, clockActions)
			}
			//
			
			// Dispatching events to connected message queues
			val eventDispatches = createSequentialAction // For caching
			for (port : adapterComponentType.allPorts) {
				// Semantical question: now out events are dispatched according to this order
				val eventDispatchAction = port.createEventDispatchAction(
						eventReferenceMapper, systemPorts, variableTrace)
				instanceMergedAction.actions += eventDispatchAction.clone
				entryAction.actions += eventDispatchAction // Same for initial action
				
				eventDispatches.actions += eventDispatchAction.clone // Caching
			}
			
			// Tracing the behavior of the atomic component to enable the construction of 
			// choice ('pure' async) o)- seq (sheduled async) action trees later 
			mergedAdapterActions += adapterInstance -> instanceMergedAction
			
			// Caching
			queueHandlingMergedActions += adapterInstance -> (inputIfAction.clone /* Crucial */ -> eventDispatches)
			//
		}
		
		// Initializing message queue related variables - done here and not in initial expression
		// as the potential enumeration type declarations of slave queues there are not traced
		
		val xStsQueueVariables = newArrayList
		for (queueStruct : queueTraceability.allQueues) {
			val queue = queueStruct.arrayVariable
			xStsQueueVariables += variableTrace.getAll(queue)
			
			val sizeVariable = queueStruct.sizeVariable
			if (sizeVariable !== null) {
				xStsQueueVariables += variableTrace.getAll(sizeVariable)
			}
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
					logger.info(
						'''Found «systemAsynchronousSimplePort.name».«inEvent.name» as system input event''')
					systemInEvents += portEvent
				}
			}
		}
		val xStsDeletableSlaveQueues = newHashSet
		for (queue : environmentalQueues) {
			val adapter = queue.containingComponent
			
			val queueMapping = queueTraceability.get(queue)
			val masterQueue = queueMapping.masterQueue.arrayVariable
			val masterSizeVariable = queueMapping.masterQueue.sizeVariable
			val slaveQueues = queueMapping.slaveQueues
			
			val xStsMasterQueue = variableTrace.getAll(masterQueue).onlyElement
			val xStsMasterSizeVariable = (masterSizeVariable === null) ? null :
					variableTrace.getAll(masterSizeVariable).onlyElement
			
			val xStsEventIdType = xStsMasterQueue.elementTypeDefinition as EnumerationTypeDefinition
			val xStsEmptyId = xStsEventIdType.emptyLiteral
			
			val xStsQueueHandlingAction = createSequentialAction
			
			val queueSizes = newArrayList(
					xStsMasterQueue.getMasterQueueSize(xStsMasterSizeVariable) /* current queue size */)
			val queueTheoreticalCapacities = adapter.scheduleCount // Max message processing in a turn
			// Calculating size and theoretical capacity for higher priority queues
			for (higherPriorityQueue : queue.higherPriorityQueues) {
				val higherPriorityQueueMapping = queueTraceability.get(higherPriorityQueue)
				val higherPriorityMasterQueue = higherPriorityQueueMapping.masterQueue.arrayVariable
				val higherPriorityMasterQueueSizeVariable =
						higherPriorityQueueMapping.masterQueue.sizeVariable
				
				val xStsHigherPriorityMasterQueue = variableTrace.getAll(higherPriorityMasterQueue).onlyElement
				val xStsHigherPriorityMasterQueueSizeVariable = (higherPriorityMasterQueueSizeVariable === null) ? null :
						variableTrace.getAll(higherPriorityMasterQueueSizeVariable).onlyElement
				
				queueSizes += xStsHigherPriorityMasterQueue.getMasterQueueSize(xStsHigherPriorityMasterQueueSizeVariable)
			}
			// A value should be inserted into the queue if
			// (size + (higher1Size + ... + higher(N-1)Size) < theoreticalTotalCapacity))
			val isThereTheoreticalCapacityExpression = queueSizes.wrapIntoAddExpression.createLessExpression(
					queueTheoreticalCapacities.toIntegerLiteral) // TODO ?? remove itself ??
			// And the actual queue is not full
			val isMasterQueueNotFull = xStsMasterQueue.isMasterQueueNotFull(xStsMasterSizeVariable)
			// The first part is necessary if there are more queues
			val isQueueInsertableExpression = (queueSizes.size == 1) ? isMasterQueueNotFull : 
					isMasterQueueNotFull.wrapIntoAndExpression(isThereTheoreticalCapacityExpression)
			val xStsQueueInsertionAction = isQueueInsertableExpression.createIfAction(xStsQueueHandlingAction)
			// If queue is insertable
			inEventAction.actions += xStsQueueInsertionAction
			
			val xStsEventIdVariableAction = xStsMasterQueue.createVariableDeclarationActionForArray(
					xStsMasterQueue.eventIdLocalVariableName)
			val xStsEventIdVariable = xStsEventIdVariableAction.variableDeclaration
			
			xStsQueueHandlingAction.actions += xStsEventIdVariableAction
			
			// Queue capacity can be greater than 1 if a component is executed multiple times in execution lists
			for (var i = 0; i < queue.getCapacity(systemPorts); i++) {
				// queue.getCapacity(systemPorts) is 1 most of the time, so i remains 0
				xStsQueueHandlingAction.actions += xStsEventIdVariable.createHavocAction
				
//				val storesOnlySystemPort = systemPorts.containsAll(
//						queue.storedPorts.map[it.boundTopComponentPort])
				// Semantically equivalent but maybe the second interval is easier to handle by SMT solvers
//				val isValidIdExpression = if (!storesOnlySystemPort) {
//					// (0 < eventId && eventId <= maxPotentialEventId) does not work now with internal events
//					val eventIds = queue.getEventIdsOfPorts(systemPorts)
//					
//					// (eventId == 1 || eventId == 3 || ...)
//					val idComparisons = eventIds.map[
//						xStsEventIdVariable.createReferenceExpression
//							.createEqualityExpression(
//								it.toIntegerLiteral)]
//					idComparisons.wrapIntoOrExpression
//				}
//				else {
//					val emptyValue = xStsEventIdVariable.defaultExpression
//					val maxEventId = queue.maxEventId.toIntegerLiteral
//					// 0 < eventId && eventId <= maxPotentialEventId
//					val leftInterval = emptyValue.createLessExpression(
//							xStsEventIdVariable.createReferenceExpression)
//					val rightInterval = xStsEventIdVariable.createReferenceExpression
//							.createLessEqualExpression(maxEventId)
//					#[leftInterval, rightInterval].wrapIntoAndExpression
//				}
				// If the id is a valid event
				val isValidIdExpression = xStsEventIdVariable.createReferenceExpression
							.createInequalityExpression(xStsEmptyId.createEnumerationLiteralExpression)
				
				val xStsSetQueuesAction = createSequentialAction
				xStsSetQueuesAction.actions += xStsMasterQueue.addAndPotentiallyIncrement(
						xStsMasterSizeVariable, xStsEventIdVariable.createReferenceExpression)
				
				val xStsEventIdHandlingAction = isValidIdExpression.createIfAction( // If the generated id is valid
							xStsSetQueuesAction)
				xStsQueueHandlingAction.actions += (i == 0 /* First iteration - surely insertable */) ? xStsEventIdHandlingAction : 
					isQueueInsertableExpression.clone.createIfAction( // If it is still insertable (check the containing loop)
						xStsEventIdHandlingAction)
				
				val branchExpressions = <Expression>newArrayList
				val xStsBranchActions = <Action>newArrayList
				for (portEvent : slaveQueues.keySet
							.filter[systemInEvents.contains(it) /*Only system events*/]) {
					val slaveQueueStructs = slaveQueues.get(portEvent)
					val eventIntegerId = queueTraceability.get(portEvent)
					val eventId = xStsEventIdType.addOrGetEventIdLiteral(eventIntegerId)
					branchExpressions += xStsEventIdVariable
							.createEqualityExpression(eventId.createEnumerationLiteralExpression)
					val xStsSlaveQueueSetting = createSequentialAction
					xStsBranchActions += xStsSlaveQueueSetting
					
					for (slaveQueueStruct : slaveQueueStructs) {
						val slaveQueue = slaveQueueStruct.arrayVariable
						val slaveSizeVariable = slaveQueueStruct.sizeVariable
						
						val xStsSlaveQueues = variableTrace.getAll(slaveQueue)
						val xStsSlaveSizeVariable = (slaveSizeVariable === null) ? null :
								variableTrace.getAll(slaveSizeVariable).onlyElement
						
						val xStsRandomValues = newArrayList
						for (xStsSlaveQueue : xStsSlaveQueues) {
							val xStsRandomVariableAction = xStsSlaveQueue
								.createVariableDeclarationActionForArray(
									xStsSlaveQueue.randomValueLocalVariableName)
							val xStsRandomVariable = xStsRandomVariableAction.variableDeclaration
							xStsSlaveQueueSetting.actions += xStsRandomVariableAction
							if (slaveQueueStruct.internal) {
								// Assigning default values to internal parameter queues. This is needed if 
								// the queue is not environmental, otherwise parameter values can shift to wrong indexes
								xStsRandomVariable.expression = xStsRandomVariable.defaultExpression
								if (queue.isEnvironmentalAndCheck(systemPorts)) {
									// We delete this slave queue later as we do not want to override internal parameters
									logger.info( "Internal parameter slave queue for system port: " + xStsSlaveQueue.name)
									xStsDeletableSlaveQueues += xStsSlaveQueue
								}
								else {
									// Currently cannot be reached due to isEnvironmentalAndCheck
								}
							}
							else {
								// Assigning a random value
								xStsSlaveQueueSetting.actions += xStsRandomVariable.createHavocAction
							}
							xStsRandomValues += xStsRandomVariable.createReferenceExpression
						}
						xStsSlaveQueueSetting.actions += xStsSlaveQueues
								.addAllAndPotentiallyIncrement(xStsSlaveSizeVariable, xStsRandomValues)
					}
				}
				xStsSetQueuesAction.actions += branchExpressions.createChoiceAction(xStsBranchActions)
			}
		}
		
		xSts.inEventTransition = inEventAction.wrap
		// Must not reset out events here: adapter instances reset them after running (no running, no reset)
//		xSts.outEventTransition = outEventAction.wrap
		
		// Merging the adapter actions along a 'choice' and 'seq' tree 
		val mergedAction = component.mergeAsynchronousCompositeActions(mergedAdapterActions)
		// Merging it with clocks
		mergedClockAction.actions += mergedAction
		
		// Replacing invariants if any (otherwise, they remain in the body of the if, not affecting the state if there are no input messages)
		// Modification: not for environmental ones, as the replacement of these invariants would not affect variable (event) values in the correct place!
		// Not a restrictive-enough solution for AA though as input events can be sent this way if there is an event in a prioritized queue
		val assumeActions = mergedAction.getSelfAndAllContentsOfType(AssumeAction)
//		val environmentalInvariants = assumeActions.filter[it.environmentalInvariant]
//		for (environmentalInvariant : environmentalInvariants) {
//			createEmptyAction.replace(environmentalInvariant)
//			mergedClockAction.actions.add(0, environmentalInvariant)
//		}
		val internalInvariants = assumeActions.filter[it.internalInvariant]
		for (internalInvariant : internalInvariants) {
			createEmptyAction.replace(internalInvariant)
			mergedClockAction.actions += internalInvariant
		}
		//
		
		xSts.changeTransitions(mergedClockAction.wrap)
		
		// Deleting environmental slave queues for internal parameters;
		// after the construction of the entire XSTS to handle in events and merged events, too
		xStsDeletableSlaveQueues.changeAssignmentsAndReadingAssignmentsToEmptyActions(xSts)
		xStsDeletableSlaveQueues.forEach[it.deleteDeclaration] // Variable groups
		//
		
		return xSts
	}
	
	//
	
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
						val eventIntegerId = queueTraceability.get(connectedPortEvent)
						// Highest priority in the case of multiple queues allowing storage 
						val queueTrace = queueTraceability.getMessageQueues(connectedPortEvent)
						val originalQueue = queueTrace.key
						val eventDiscardStrategy = originalQueue.eventDiscardStrategy
						val queueMapping = queueTrace.value
						
						val masterQueueStruct = queueMapping.masterQueue
						val masterQueue = masterQueueStruct.arrayVariable
						val masterSizeVariable = masterQueueStruct.sizeVariable
						val slaveQueues = queueMapping.slaveQueues.get(connectedPortEvent)
						
						val xStsMasterQueue = variableTrace.getAll(masterQueue).onlyElement
						val xStsMasterSizeVariable = (masterSizeVariable === null) ? null :
								variableTrace.getAll(masterSizeVariable).onlyElement
						
						val xStsEventIdType = xStsMasterQueue.elementTypeDefinition as EnumerationTypeDefinition
						val eventId = xStsEventIdType.addOrGetEventIdLiteral(eventIntegerId)
						
						// Expressions and actions that are used in every queue behavior
						
						val block = createSequentialAction
						// Master
						block.actions += xStsMasterQueue.addAndPotentiallyIncrement(
								xStsMasterSizeVariable, eventId.createEnumerationLiteralExpression)
						// Resetting out event variable if it is not  led out to the system
						// Duplicated for broadcast ports - not a problem, but could be refactored
						val boundTopComponentPort = port.boundTopComponentPort
						val isSystemPort = systemPorts.contains(boundTopComponentPort)
						val isInternalPort = port.internal
						if (!isSystemPort || isInternalPort /* Though, the code keeps the internal raisings */) {
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
							val xStsSlaveSizeVariable = (slaveSizeVariable === null) ? null :
									variableTrace.getAll(slaveSizeVariable).onlyElement
							// Output is unidirectional
							val xStsOutParameterVariables = eventReferenceMapper
									.getOutputParameterVariables(parameter, port)
							// Parameter optimization problem: parameters are not deleted independently
							block.actions += xStsSlaveQueues.addAllAndPotentiallyIncrement(xStsSlaveSizeVariable,
									xStsOutParameterVariables.map[it.createReferenceExpression])
							// Resetting out parameter variables if they are not led out to the system
							// Duplicated for broadcast ports - not a problem, but could be refactored
							if (!isSystemPort || isInternalPort /* Though, the code keeps the internal raisings */) {
								outEventResetActions.actions += xStsOutParameterVariables.map[it.createVariableResetAction]
							}
						}
						
						if (eventDiscardStrategy == DiscardStrategy.INCOMING) {
							// if (size < capacity) { "add elements into master and slave queues" }
							val isMasterQueueNotFull = xStsMasterQueue.isMasterQueueNotFull(xStsMasterSizeVariable)
							thenAction.actions += isMasterQueueNotFull.createIfAction(block)
						}
						else if (eventDiscardStrategy == DiscardStrategy.OLDEST) {
							val popActions = createSequentialAction
							popActions.actions += xStsMasterQueue.popAndPotentiallyDecrement(xStsMasterSizeVariable)
							for (slaveQueueStruct : slaveQueues) {
								val slaveQueue = slaveQueueStruct.arrayVariable
								val slaveSizeVariable = slaveQueueStruct.sizeVariable
								val xStsSlaveQueues = variableTrace.getAll(slaveQueue)
								val xStsSlaveSizeVariable = (slaveSizeVariable === null) ? null :
										variableTrace.getAll(slaveSizeVariable).onlyElement
								popActions.actions += xStsSlaveQueues.popAllAndPotentiallyDecrement(xStsSlaveSizeVariable)
							}
							// if ((!(size < capacity)) { "pop" }
							// "add elements into master and slave queues"
							val isMasterQueueFull = xStsMasterQueue.isMasterQueueFull(xStsMasterSizeVariable)
							thenAction.actions += isMasterQueueFull
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
	
	//
	
	protected def createAsynchronousCompositeAction(AbstractAsynchronousCompositeComponent component) {
		switch (component) {
			ScheduledAsynchronousCompositeComponent: {
				return createSequentialAction 
			}
			AsynchronousCompositeComponent: {
				return createNonDeterministicAction
			}
			default: {
				throw new IllegalArgumentException("Not known component: " + component)
			}
		}
	}
	
	protected def Action mergeAsynchronousCompositeActions(
			AbstractAsynchronousCompositeComponent component,
			Map<AsynchronousComponentInstance, ? extends Action> mergedAdapterActions) {
		val asynchronousCompositeAction = component.createAsynchronousCompositeAction
		
		for (instance : component.scheduledInstances) { // To support multiple execution
			val instanceType = instance.type
			val action =
			if (instanceType instanceof AbstractAsynchronousCompositeComponent) {
				instanceType.mergeAsynchronousCompositeActions(mergedAdapterActions)
			}
			else {
				val adapterAction = mergedAdapterActions.checkAndGet(instance)
				adapterAction.clone // Important due to multiple executions
			}
			asynchronousCompositeAction.actions += action
			
			// Encode asynchronous component instances
			instance.encodeAsynchronousComponentInstances(action)
			//
		}
		
		return asynchronousCompositeAction
	}
	
	//
	
	protected def void encodeAsynchronousComponentInstances(
			AsynchronousComponentInstance instance, Action action) {
		if (!instance.needsScheduling) {
			return
		}
		
		val xSts = this.xSts
		
		val instanceEndcodingVariable = xSts.getOrCreateInstanceEndcodingVariable
		
		val index = instance.schedulingIndex
		
		val encodingAssignment = instanceEndcodingVariable.createAssignmentAction(
				index.toIntegerLiteral)
		action.appendToAction(encodingAssignment)
	}
	
	protected def getOrCreateInstanceEndcodingVariable(XSTS xSts) {
		val name = instanceEndcodingVariableName
		
		var instanceEndcodingVariable = xSts.getVariable(name)
		if (instanceEndcodingVariable === null) {
			instanceEndcodingVariable = createIntegerTypeDefinition
					.createVariableDeclaration(name)
			
			instanceEndcodingVariable.addUnremovableAnnotation
			instanceEndcodingVariable.addResettableAnnotation
			
			xSts.variableDeclarations += instanceEndcodingVariable
		}
		
		return instanceEndcodingVariable
	}
	
	protected def resetMessageQueues(Collection<? extends MessageQueue> resetQueues, Trace variableTrace) {
		val xStsQueueResetActions = createSequentialAction
		
		for (resetQueue : resetQueues) {
			val resetQueueMapping = queueTraceability.get(resetQueue)
			val resetMasterQueue = resetQueueMapping.masterQueue.arrayVariable
			val resetMasterSizeVariable = resetQueueMapping.masterQueue.sizeVariable
			val resetSlaveQueues = resetQueueMapping.slaveQueues
			
			// Actually, the following values are "low-level values", but we handle them as XSTS values
			val xStsResetMasterQueue = variableTrace.getAll(resetMasterQueue).onlyElement
			val xStsResetMasterSizeVariable = (resetMasterSizeVariable === null) ? null :
					variableTrace.getAll(resetMasterSizeVariable).onlyElement
			
			xStsQueueResetActions.actions += xStsResetMasterQueue.createVariableResetAction
			if (xStsResetMasterSizeVariable !== null) {
				xStsQueueResetActions.actions += xStsResetMasterSizeVariable.createVariableResetAction
			}
			
			for (resetSlaveQueueStruct : resetSlaveQueues.values.flatten.toSet) {
				val resetSlaveQueue = resetSlaveQueueStruct.arrayVariable
				val resetSlaveSizeVariable = resetSlaveQueueStruct.sizeVariable
			
				val xStsSlaveQueues = variableTrace.getAll(resetSlaveQueue)
				val xStsSlaveSizeVariable = (resetSlaveSizeVariable === null) ? null :
						variableTrace.getAll(resetSlaveSizeVariable).onlyElement
				
				xStsQueueResetActions.actions += xStsSlaveQueues.createVariableResetActions
				if (xStsSlaveSizeVariable !== null) {
					xStsQueueResetActions.actions += xStsSlaveSizeVariable.createVariableResetAction
				}
			}
		}
		
		return xStsQueueResetActions
	}
	
	//
	
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
		
		// Resetting out, in and internal events manually as a "schedule" call in the code does that
		xSts.resetOutEventsBeforeMergedAction(wrappedType)
		xSts.resetInEventsAfterMergedAction(wrappedType)
		xSts.addInternalEventResetingActionsInMergedAction(wrappedType)
		//
		
		// Internal event handling not required - event dispatch will tend to the addition
		
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
			val allXStsInputEventVariables = storedEvents
					.map[it.value.getInputEventVariables(it.key)].flatten.toList
			
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
					// Setting the "unselected" events to false; needed to make it explicit for SMV iVARs
					branchAction.appendToAction(
						allXStsInputEventVariables
							.reject[xStsInputEventVariables.contains(it)].toList
							.createVariableResetActions)
					// Maybe more than one event variable - one port can be mapped to multiple instance ports
					// Can be empty if it is a control port
					for (xStsInputEventVariable : xStsInputEventVariables) {
						branchAction.appendToAction(xStsInputEventVariable
								.createAssignmentAction(createTrueExpression))
					}
				}
			}
			removableBranchActions.forEach[it.remove] // Removing now - it would break the indexes in the loop
			
			// Note that if the sync component has no port, the event transmission is not mapped
			
			// Original parameter settings
			// Parameters that come from the same ports are bound to the same values - done by previous call
			newInEventAction.actions += inEventAction.action
			
			// Removing internal parameter settings
			val xStsInternalInEventPrameters = xSts.inEventParameterVariableGroup.variables
					.filter[it.internal].toList
			xStsInternalInEventPrameters.changeAssignmentsToEmptyActions(newInEventAction)
			//
			
			xSts.inEventTransition = newInEventAction.wrap
		}
		
		return xSts
	}
	
	def dispatch XSTS transform(AbstractSynchronousCompositeComponent component, Package lowlevelPackage) {
		val name = component.name
		logger.info( "Transforming abstract synchronous composite " + name)
		val xSts = name.createXsts
		val componentMergedActions = <Component, Action>newHashMap // To handle multiple schedulings in CascadeCompositeComponents
		val components = component.components
		
		if (components.empty) {
			logger.warning("No components in abstract synchronous composite " + name)
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
			
			// Internal event handling here as EventReferenceHandler cannot be used without customizeDeclarationNames
			if (subcomponentType.statechart) {
				newXSts.addInternalEventHandlingActions(subcomponentType)
			}
			//
			
			// Adding new elements
			xSts.merge(newXSts)
			
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
		
		logger.info( "Deleting unused instance ports in " + name)
		xSts.deleteUnusedPorts(component) // Deleting variable assignments for unused ports
		
		// Connect only after "xSts.mergedTransition.action = mergedAction" / "xSts.changeTransitions"
		logger.info( "Connecting events through channels in " + name)
		xSts.connectEventsThroughChannels(component) // Event (variable setting) connecting across channels
		
		logger.info( "Binding event to system port events in " + name)
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
			logger.info( "Transforming orthogonal actions in XSTS " + name)
			xSts.mergedAction.transform(xSts)
			// Before optimize actions
		}
		
		if (optimize) {
			// Optimization: system in events (but not PERSISTENT parameters) can be reset after the merged transition
			// E.g., synchronous components do not reset system events
			xSts.resetInEventsAfterMergedAction(component)
		}
		
		// After in event optimization
		logger.info( "Adding internal event handlings in " + name)
		xSts.addInternalEventHandlingActions(component)
		
		return xSts
	}
	
	def dispatch XSTS transform(StatechartDefinition statechart, Package lowlevelPackage) {
		logger.info( "Transforming statechart " + statechart.name)
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
		for (variable : xSts.variableDeclarations.reject[it.clock]) { // Except for timeout declarations
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
		val capacity = queue.capacity
		val originalCapacity = capacity.evaluateInteger
		if (queue.isEnvironmentalAndCheck(systemPorts) && optimizeEnvironmentalMessageQueues) {
			val maxCapacity = queue.getTheoreticalMaximumCapacity(systemPorts)
			return Integer.min(originalCapacity, maxCapacity) // No more than the user-defined capacity
		}
		return originalCapacity
	}
	
	private def getTheoreticalMaximumCapacity(MessageQueue queue, Collection<? extends Port> systemPorts) {
		if (queue.isEnvironmentalAndCheck(systemPorts)) {
			val adapter = queue.containingComponent
			val messageRetrievalCount = queue.messageRetrievalCount // Always 1
			val executionCount = adapter.scheduleCount // 1 if not scheduled composite
			// 1 * (how many times the component can be executed in a cycle)
			val maxCapacity = messageRetrievalCount * executionCount
			return maxCapacity
		}
		val capacity = queue.capacity
		val originalCapacity = capacity.evaluateInteger
		return originalCapacity
	}
	
	private def getMessageRetrievalCount(MessageQueue queue) {
		return 1 // This used to be customizable but loop actions did not work
	}
	
	private def isEnvironmentalAndCheck(MessageQueue queue, Collection<? extends Port> systemPorts) {
		if (queue.isEnvironmental(systemPorts)) {
			return true // All events are system events (no internal events)
		}
		val portEvents = queue.storedEvents
		val ports = portEvents.map[it.key]
		val topPorts = ports.map[it.boundTopComponentPort]
		val capacity = queue.capacity.evaluateInteger // No evaluateCapacity: endless recursion
		if (systemPorts.containsAny(topPorts) && capacity == 1 &&
				queue.eventDiscardStrategy == DiscardStrategy.INCOMING) {
			 /* Contains other events too, but the capacity is 1,
			  * and the discard strategy is incoming: therefore, the in-event handler
			  * if ((sizeOfQueue <= 0)) { .. } limits the valid addition possibilities,
			  * if the queue is not empty, e.g., initial raises and internal events */
			return true
		}
		checkState(systemPorts.containsNone(topPorts) || topPorts.forall[it.internal],
			"All or none of the event references must be of system ports in " + queue.containingComponent.name + "' queue " + queue.name)
		return false
	}
	
	private def addOrGetEventIdLiteral(EnumerationTypeDefinition eventIdType, Integer eventIntegerId) {
		val literalName = "_" + eventIntegerId // Back-annotation depends on this convention
		val literals = eventIdType.literals
		
		if (!literals.exists[it.name == literalName]) {
			val eventId = literalName.createEnumerationLiteralDefinition
			if (eventIntegerId < literals.size) {
				literals.add(eventIntegerId, eventId)
			}
			else {
				literals += eventId
			}
		}
		
		val literal = literals.filter[it.name == literalName].onlyElement
		
		return literal
	}
	
	private def getEmptyLiteral(EnumerationTypeDefinition eventIdType) {
		val literals = eventIdType.literals
		val literal = literals.head
		
		return literal
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
					.map[it.variables].flatten
					.map[it.type].filter(TypeReference)
					.map[it.reference]) {
				regionType.name = regionType.customizeRegionTypeName(type)
			}
		}
	}
	
}