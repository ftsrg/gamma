/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 * 
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 * 
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scxml.transformation

import ac.soton.scxml.HistoryTypeDatatype
import ac.soton.scxml.ScxmlDataType
import ac.soton.scxml.ScxmlFinalType
import ac.soton.scxml.ScxmlHistoryType
import ac.soton.scxml.ScxmlInitialType
import ac.soton.scxml.ScxmlInvokeType
import ac.soton.scxml.ScxmlParallelType
import ac.soton.scxml.ScxmlScxmlType
import ac.soton.scxml.ScxmlStateType
import ac.soton.scxml.ScxmlTransitionType
import ac.soton.scxml.TransitionTypeDatatype
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponent
import hu.bme.mit.gamma.statechart.composite.ControlFunction
import hu.bme.mit.gamma.statechart.composite.DiscardStrategy
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.statechart.statechart.EntryState
import hu.bme.mit.gamma.statechart.statechart.GuardEvaluation
import hu.bme.mit.gamma.statechart.statechart.InitialState
import hu.bme.mit.gamma.statechart.statechart.OrthogonalRegionSchedulingOrder
import hu.bme.mit.gamma.statechart.statechart.SchedulingOrder
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.SynchronousStatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority
import java.math.BigInteger
import java.util.List
import java.util.logging.Level
import org.eclipse.emf.common.util.URI

import static ac.soton.scxml.ScxmlModelDerivedFeatures.*
import static hu.bme.mit.gamma.scxml.transformation.Namings.*

// TODO Scoping in variable transformation and assignment
// TODO History, parallel
class ScxmlToGammaStatechartTransformer extends AtomicElementTransformer {

	// Reference to the composite transformation traceability model
	protected final CompositeTraceability compositeTraceability

	protected final extension ActionTransformer actionTransformer
	protected final extension DataTransformer dataTransformer
	protected final extension PortTransformer portTransformer
	protected final extension TriggerTransformer triggerTransformer

	// Root element of the SCXML statechart model to transform
	protected ScxmlScxmlType scxmlRoot

	// Contained <invoke> elements invoking SCXML substatecharts
	protected List<ScxmlInvokeType> invokes

	// Asynchronous wrapper component around the synchronous statechart definition
	protected AsynchronousAdapter adapter

	// Root element of the Gamma statechart definition as the transformation result
	protected SynchronousStatechartDefinition gammaStatechart

	new(StatechartTraceability traceability) {
		super(traceability)

		compositeTraceability = traceability.compositeTraceability

		/* TODO Load and set scxmlRoot, create default StDef
		 * scxmlRoot
		 * this.gammaStatechart = createSynchronousStatechartDefinition => [
		 * 	it.name = getStatechartName(scxmlRoot)
		 * ]
		 */
		this.actionTransformer = new ActionTransformer(traceability)
		this.dataTransformer = new DataTransformer(traceability)
		this.portTransformer = new PortTransformer(traceability)
		this.triggerTransformer = new TriggerTransformer(traceability)
	}

	// TODO This will be the execute() method, combine with former statechart transformer execute()
	protected def AsynchronousComponent execute() {

		// Put statechart traceability in composite traceability object
		compositeTraceability.putTraceability(traceability.fileURI, traceability)

		// TODO Check if not already transformed (at caller side or in this transformation method)
		val fileURI = traceability.fileURI
		scxmlRoot = loadSubcomponent(fileURI)
		traceability.scxmlRoot = scxmlRoot

		gammaStatechart = createSynchronousStatechartDefinition => [
			it.name = getStatechartName(scxmlRoot)
		]
		traceability.statechart = gammaStatechart

		// TODO First, transform all invoked statechart types
		// (recursively, through transformation calls to types of contained components)
		// Then transform individual statecharts with invoke actions, referencing invoked types
		// Note: circular references in invoke chains are not supported.
		invokes = getAllInvokes(scxmlRoot)

		for (invoke : invokes) {
			// TODO Check src | srcexpr
			val invokedSrc = invoke.src

			if (!compositeTraceability.containsTraceability(invokedSrc)) {
				// Create (and store reference to) new statechart type transformation traceability
				val invokedStatechartTraceability = compositeTraceability.createStatechartTraceability(invokedSrc)
				compositeTraceability.putTraceability(invokedSrc, invokedStatechartTraceability)

				// Execute root statechart transformation.
				// The object rootStatechartTraceability is populated with trace data during transformation.
				val invokedStatechartTransformer = new ScxmlToGammaStatechartTransformer(invokedStatechartTraceability)
				invokedStatechartTransformer.execute()
			}
		}

		// Transform statechart after invoked statechart type transformations have finished
		// TODO Transform control, action, data and communication elements
		return scxmlRoot.transformStatechart
	}

	private def loadSubcomponent(String path) {
		val fileURI = URI.createPlatformResourceURI(path, true);
		val documentRoot = ecoreUtil.normalLoad(fileURI);

		val scxmlRoot = ecoreUtil.getFirstOfAllContentsOfType(documentRoot, ScxmlScxmlType);
		return scxmlRoot
	}

	protected def transformStatechart(ScxmlScxmlType scxmlRoot) {
		val gammaComposite = createScheduledAsynchronousCompositeComponent
		gammaComposite.name = getCompositeStatechartName(scxmlRoot)

		// Instantiate transformed invoked child statecharts
		for (invoke : invokes) {
			val statechartTraceability = compositeTraceability.getTraceability(invoke.src)

			// TODO Extend to deeper composition hierarchy levels later
			val gammaSubcomponentType = statechartTraceability.adapter as AsynchronousComponent

			val gammaSubcomponent = gammaSubcomponentType.instantiateAsynchronousComponent
			gammaSubcomponent.name = invoke.id
			gammaComposite.components += gammaSubcomponent

			compositeTraceability.putComponentInstance(invoke, gammaSubcomponent)
		}

		// Create ports, port bindings and channels in the composite component
		val datamodels = scxmlRoot.datamodel
		if (datamodels !== null) {
			val datamodel = datamodels.head
			if (datamodel !== null) {
				val dataElements = getDataElements(datamodel)

				// TODO Move string literal parts of names to Namings
				val portDataElements = dataElements.filter [ it |
					it.eContainer.eContainer instanceof ScxmlScxmlType && it.id.startsWith("pro_port_") ||
						it.id.startsWith("req_port_")
				]
				for (portData : portDataElements) {
					val gammaPort = portData.getOrCreatePort
					gammaComposite.ports += gammaPort
				}

				val bindingDataElements = dataElements.filter [ it |
					it.eContainer.eContainer instanceof ScxmlScxmlType && it.id.startsWith("binding_")
				]
				for (binding : bindingDataElements) {
					val gammaPortBinding = binding.createBinding
					gammaComposite.portBindings += gammaPortBinding
				}

				val channelDataElements = dataElements.filter [ it |
					it.eContainer.eContainer instanceof ScxmlScxmlType && it.id.startsWith("channel_")
				]
				for (channel : channelDataElements) {
					val gammaChannel = channel.createChannel
					gammaComposite.channels += gammaChannel
				}
			}
		}
		
		// TODO Merge methods logically
		transformStatechartInnerElements

		return gammaComposite
	}
	
	// TODO Merge this statechart transformation with 'composite' transformation method
	// Transformation of the SCXML root element and its contents recursively.
	// Invoked types are assumed to be already transformed by this point.
	def transformStatechartInnerElements() {
		traceability.setStatechart(gammaStatechart)

		logger.log(Level.INFO, "Transforming <scxml> root element (" + scxmlRoot.name + ")")

		// Configure transition selection and execution
		// TODO Check settings!
		gammaStatechart.schedulingOrder = SchedulingOrder.BOTTOM_UP
		gammaStatechart.orthogonalRegionSchedulingOrder = OrthogonalRegionSchedulingOrder.SEQUENTIAL
		gammaStatechart.transitionPriority = TransitionPriority.ORDER_BASED;
		gammaStatechart.guardEvaluation = GuardEvaluation.BEGINNING_OF_STEP

		val datamodels = scxmlRoot.datamodel
		if (datamodels !== null) {
			val datamodel = datamodels.head
			if (datamodel !== null) {
				val dataElements = getDataElements(datamodel)

				// TODO Move string literal parts of names to Namings
				val portDataElements = dataElements.filter [ it |
					it.eContainer.eContainer instanceof ScxmlScxmlType && it.id.startsWith("pro_port_") ||
						it.id.startsWith("req_port_")
				]
				for (portData : portDataElements) {
					val gammaPort = portData.getOrCreatePort
					gammaStatechart.ports += gammaPort
				}

				val variableDataElements = dataElements.filter[it|!portDataElements.contains(it)]
				for (variableData : variableDataElements) {
					val gammaVariableDeclaration = dataTransformer.transform(variableData)
					gammaStatechart.variableDeclarations += gammaVariableDeclaration
				}
			}
		}

		val mainRegion = createRegion => [
			it.name = getRegionName(scxmlRoot.name)
		]
		gammaStatechart.regions += mainRegion

		val scxmlStateNodes = getStateNodes(scxmlRoot)
		for (scxmlStateNode : scxmlStateNodes) {
			if (isParallel(scxmlStateNode)) {
				val parallel = scxmlStateNode as ScxmlParallelType
				mainRegion.stateNodes += parallel.transformParallel
			} else if (isState(scxmlStateNode)) {
				val state = scxmlStateNode as ScxmlStateType
				mainRegion.stateNodes += state.transformState
			} else if (isFinal(scxmlStateNode)) {
				val final = scxmlStateNode as ScxmlFinalType
				mainRegion.stateNodes += final.transformFinal
			} else {
				throw new IllegalArgumentException("Object " + scxmlStateNode + " is of unknown SCXML <state> type.")
			}
		}

		val transitions = getAllTransitions(scxmlRoot)
		for (transition : transitions) {
			transition.transformTransition
		}

		// Transform the SCXML root element's initial attribute,
		// or select its first child as initial state if it is not present.
		val gammaInitial = createInitialState => [
			it.name = getInitialName(scxmlRoot)
		]
		mainRegion.stateNodes += gammaInitial

		val scxmlInitialAttribute = scxmlRoot.initial
		val scxmlFirstInitialAttribute = scxmlInitialAttribute?.head
		if (scxmlFirstInitialAttribute !== null) {
			val gammaInitialTarget = traceability.getStateNodeById(scxmlFirstInitialAttribute)
			gammaInitial.createTransition(gammaInitialTarget)
		} else {
			val firstScxmlStateChild = getFirstChildStateNode(scxmlRoot) as ScxmlStateType
			val gammaInitialTarget = traceability.getState(firstScxmlStateChild)
			gammaInitial.createTransition(gammaInitialTarget)
		}

		// Add all transitions from initial states of Gamma compound states
		// specified by scxml initial attributes or document order
		gammaStatechart.transitions += traceability.getInitialTransitions

		// Add all ports from traceability
		if (traceability.getDefaultPort !== null) {
			gammaStatechart.ports += traceability.getDefaultPort
		}
		gammaStatechart.ports += traceability.defaultInterfacePorts.values
		gammaStatechart.ports += traceability.ports.values

		val adapter = wrapIntoAdapter
		traceability.adapter = adapter

		return traceability
	}

	protected def getOrCreatePort(ScxmlDataType portData) {
		val isProvided = portData.id.startsWith("pro_port_")
		val realizationMode = isProvided ? RealizationMode.PROVIDED : RealizationMode.REQUIRED

		// Get port name and interface name from port descriptor string
		val portString = portData.expr.trim
		val tokens = portString.split("\\.")
		if (tokens.size < 1 || tokens.size > 2) {
			throw new IllegalArgumentException(
				"Port descriptor " + portString + " does not contain exactly 1 or 2 dot separated tokens."
			)
		}

		var scxmlInterfaceName = ""
		var scxmlPortName = ""

		if (tokens.size == 1) {
			scxmlInterfaceName = portString
			scxmlPortName = portString
		} else {
			scxmlInterfaceName = tokens.get(tokens.size - 1)
			scxmlPortName = tokens.head
		}
		//
		val gammaPort = portTransformer.getOrTransformPort(
			scxmlPortName,
			scxmlInterfaceName,
			realizationMode
		)

		// TODO Put port into composite or statechart traceability?
		compositeTraceability.putPort(scxmlPortName, gammaPort)

		return gammaPort
	}

	protected def createBinding(ScxmlDataType bindingData) {
		val bindingString = bindingData.expr.trim
		val tokens = bindingString.split("\\.|\\s*\\-\\s*")
		if (tokens.size != 3) {
			throw new IllegalArgumentException(
				"Binding descriptor " + bindingString + " does not contain exactly 3 dot separated tokens."
			)
		}

		val sourcePortName = tokens.get(0)
		val targetInstanceName = tokens.get(1)
		val targetPortName = tokens.get(2)

		//
		val gammaSourcePort = compositeTraceability.getPort(sourcePortName)
		val gammaInstancePortReference = createInstancePortReference(targetInstanceName, targetPortName)

		val gammaPortBinding = createPortBinding(gammaSourcePort, gammaInstancePortReference)
		return gammaPortBinding
	}

	protected def createChannel(ScxmlDataType channelData) {
		val channelString = channelData.expr.trim
		val tokens = channelString.split("\\.|\\s*\\-\\s*")
		if (tokens.size != 4) {
			throw new IllegalArgumentException(
				"Channel descriptor " + channelString + " does not contain exactly 4 dot separated tokens."
			)
		}

		val sourceInstanceName = tokens.get(0)
		val sourcePortName = tokens.get(1)
		val targetInstanceName = tokens.get(2)
		val targetPortName = tokens.get(3)

		//
		val sourceInstancePortReference = createInstancePortReference(sourceInstanceName, sourcePortName)
		val targetInstancePortReference = createInstancePortReference(targetInstanceName, targetPortName)

		val gammaChannel = createChannel(sourceInstancePortReference, targetInstancePortReference)
		return gammaChannel
	}

	private def createInstancePortReference(String instanceName, String scxmlPortName) {
		val instance = compositeTraceability.getComponentInstance(instanceName)

		// TODO Make it more performant to get statechart traceability
		// by instance invokeId or source URI.
		val statechartTraceability = compositeTraceability.getTraceabilityById(instanceName)
		val port = statechartTraceability.getPort(scxmlPortName)

		val instancePortReference = createInstancePortReference(instance, port)
		return instancePortReference
	}

	protected def AsynchronousAdapter wrapIntoAdapter() {
		adapter = gammaStatechart.wrapIntoAdapter(getAdapterName(scxmlRoot))

		val allStatechartPorts = StatechartModelDerivedFeatures.getAllPortsWithInput(gammaStatechart)
		val allInternalPorts = allStatechartPorts.filter[it|StatechartModelDerivedFeatures.isInternal(it)]
		val allExternalPorts = allStatechartPorts.filter[it|!StatechartModelDerivedFeatures.isInternal(it)]

		// Set control specification
		// TODO Check if internal port event triggers should be added as control specification triggers.
		for (port : allExternalPorts) {
			val portEvents = StatechartModelDerivedFeatures.getInputEvents(port)
			for (event : portEvents) {
				val controlSpecification = createControlSpecification
				controlSpecification.controlFunction = ControlFunction.RUN_ONCE

				val eventReference = createPortEventReference
				eventReference.port = port
				eventReference.event = event

				val trigger = createEventTrigger
				trigger.eventReference = eventReference
				controlSpecification.trigger = trigger

				adapter.controlSpecifications += controlSpecification
			}
		}

		// Create internal event queue
		val internalEventQueue = createMessageQueue
		internalEventQueue.name = getInternalEventQueueName(scxmlRoot)
		internalEventQueue.eventDiscardStrategy = DiscardStrategy.INCOMING
		internalEventQueue.priority = BigInteger.TWO

		val internalCapacityReference = createDirectReferenceExpression
		internalCapacityReference.declaration = traceability.queueCapacityDeclaration
		internalEventQueue.capacity = internalCapacityReference

		for (port : allInternalPorts) {
			val portEvents = StatechartModelDerivedFeatures.getInputEvents(port)
			for (event : portEvents) {
				val reference = createPortEventReference
				reference.port = port
				reference.event = event

				val eventPassing = createEventPassing(reference)
				internalEventQueue.eventPassings += eventPassing
			}
		}

		adapter.messageQueues += internalEventQueue

		// Create external event queue
		val externalEventQueue = createMessageQueue
		externalEventQueue.name = getExternalEventQueueName(scxmlRoot)
		externalEventQueue.eventDiscardStrategy = DiscardStrategy.INCOMING
		externalEventQueue.priority = BigInteger.ONE

		val externalCapacityReference = createDirectReferenceExpression
		externalCapacityReference.declaration = traceability.queueCapacityDeclaration
		externalEventQueue.capacity = externalCapacityReference

		for (port : allExternalPorts) {
			val portEvents = StatechartModelDerivedFeatures.getInputEvents(port)
			for (event : portEvents) {
				val reference = createPortEventReference
				reference.port = port
				reference.event = event

				val eventPassing = createEventPassing(reference)
				externalEventQueue.eventPassings += eventPassing
			}
		}

		adapter.messageQueues.add(externalEventQueue)

		return adapter
	}

	protected def State transformParallel(ScxmlParallelType parallelNode) {
		logger.log(Level.INFO, "Transforming <parallel> element (" + parallelNode.id + ")")

		val gammaParallel = createState => [
			it.name = getParallelName(parallelNode)
		]

		val scxmlStateNodes = getStateNodes(parallelNode)
		for (scxmlStateNode : scxmlStateNodes) {
			val region = createRegion => [
				it.name = getRegionName(gammaParallel.name)
			]
			gammaParallel.regions += region

			if (isParallel(scxmlStateNode)) {
				val parallel = scxmlStateNode as ScxmlParallelType
				region.stateNodes += parallel.transformParallel
			} else if (isState(scxmlStateNode)) {
				val state = scxmlStateNode as ScxmlStateType
				region.stateNodes += state.transformState
			} else if (isFinal(scxmlStateNode)) {
				val final = scxmlStateNode as ScxmlFinalType
				region.stateNodes += final.transformFinal
			} else {
				throw new IllegalArgumentException("Object " + scxmlStateNode + " is of unknown SCXML <state> type.")
			}
		}

		// TODO Transform history pseudo-states (by adding a wrapper compound state perhaps)
		// Initial-ok kicserélése a gyerek state-ekben, amely parallelekben találok historyt
		// Vagy history node hozzáadása minden gyerek régióhoz, ha van kívül history?
		/*val scxmlHistoryStates = parallelNode.history
		 * for (scxmlHistoryState : scxmlHistoryStates) {
		 * 	
		 }*/
		// Transform onentry and onexit handlers
		val onentryActions = parallelNode.onentry
		for (onentryAction : onentryActions) {
			if (onentryAction !== null) {
				gammaParallel.entryActions += onentryAction.transformOnentry
			}
		}

		val onexitActions = parallelNode.onexit
		for (onexitAction : onexitActions) {
			if (onexitAction !== null) {
				gammaParallel.exitActions += onexitAction.transformOnexit
			}
		}

		traceability.put(parallelNode, gammaParallel)

		return gammaParallel
	}

	protected def State transformState(ScxmlStateType scxmlState) {
		logger.log(Level.INFO, "Transforming <state> element (" + scxmlState.id + ")")

		val gammaState = createState => [
			it.name = getStateName(scxmlState)
		]

		if (isCompoundState(scxmlState)) {
			val region = createRegion => [
				it.name = getRegionName(gammaState.name)
			]
			gammaState.regions += region

			val scxmlStateNodes = getStateNodes(scxmlState)
			for (scxmlStateNode : scxmlStateNodes) {
				if (isParallel(scxmlStateNode)) {
					val parallel = scxmlStateNode as ScxmlParallelType
					region.stateNodes += parallel.transformParallel
				} else if (isState(scxmlStateNode)) {
					val state = scxmlStateNode as ScxmlStateType
					region.stateNodes += state.transformState
				} else if (isFinal(scxmlStateNode)) {
					val final = scxmlStateNode as ScxmlFinalType
					region.stateNodes += final.transformFinal
				} else {
					throw new IllegalArgumentException(
						"Object " + scxmlStateNode + " is of unknown SCXML <state> type.")
				}
			}

			// Transform history pseudo-states
			val scxmlHistoryStates = scxmlState.history
			for (scxmlHistoryState : scxmlHistoryStates) {
				region.stateNodes += scxmlHistoryState.transform
			}

			// Transform the state's initial element or attribute,
			// or select its first child as initial state if neither one above is present.
			val scxmlInitialElement = scxmlState.initial.head
			if (scxmlInitialElement !== null) {
				region.stateNodes += scxmlInitialElement.transform
			} else {
				val gammaInitial = createInitialState => [
					it.name = getInitialName(scxmlState)
				]
				region.stateNodes += gammaInitial

				val scxmlInitialAttribute = scxmlState.initial1.head
				if (scxmlInitialAttribute !== null) {
					val gammaInitialTarget = traceability.getStateNodeById(scxmlInitialAttribute)
					val initialTransition = gammaInitial.createTransition(gammaInitialTarget)
					traceability.putInitialTransition(initialTransition)
				} else {
					val firstScxmlStateChild = getFirstChildStateNode(scxmlState) as ScxmlStateType
					val gammaInitialTarget = traceability.getState(firstScxmlStateChild)
					val initialTransition = gammaInitial.createTransition(gammaInitialTarget)
					traceability.putInitialTransition(initialTransition)
				}
			}
		}

		// Transform onentry and onexit handlers
		val onentryActions = scxmlState.onentry
		for (onentryAction : onentryActions) {
			if (onentryAction !== null) {
				val gammaOnEntryActions = onentryAction.transformOnentry
				if (gammaOnEntryActions !== null) {
					gammaState.entryActions += gammaOnEntryActions
				}
			}
		}

		val onexitActions = scxmlState.onexit
		for (onexitAction : onexitActions) {
			if (onexitAction !== null) {
				val gammaOnExitActions = onexitAction.transformOnexit
				if (gammaOnExitActions !== null) {
					gammaState.exitActions += gammaOnExitActions
				}
			}
		}

		traceability.put(scxmlState, gammaState)

		return gammaState
	}

	protected def State transformFinal(ScxmlFinalType scxmlFinal) {
		logger.log(Level.INFO, "Transforming <final> element (" + scxmlFinal.id + ")")

		val gammaFinal = createState => [
			it.name = getFinalName(scxmlFinal)
		]

		// Transform onentry and onexit handlers
		val onentryActions = scxmlFinal.onentry
		for (onentryAction : onentryActions) {
			if (onentryAction !== null) {
				gammaFinal.entryActions += onentryAction.transformOnentry
			}
		}

		val onexitActions = scxmlFinal.onexit
		for (onexitAction : onexitActions) {
			if (onexitAction !== null) {
				gammaFinal.exitActions += onexitAction.transformOnexit
			}
		}

		traceability.put(scxmlFinal, gammaFinal)

		return gammaFinal
	}

	protected def InitialState transform(ScxmlInitialType scxmlInitial) {
		logger.log(Level.INFO, "Transforming <initial> element")

		val parentState = getParentState(scxmlInitial)
		val gammaInitial = createInitialState => [
			it.name = getInitialName(parentState)
		]

		traceability.put(scxmlInitial, gammaInitial)

		return gammaInitial
	}

	protected def EntryState transform(ScxmlHistoryType scxmlHistory) {
		logger.log(Level.INFO, "Transforming <history> element (" + scxmlHistory.id + ")")

		if (scxmlHistory.type == HistoryTypeDatatype.SHALLOW) {
			val gammaShallowHistory = createShallowHistoryState => [
				it.name = getShallowHistoryName(scxmlHistory)
			]

			traceability.put(scxmlHistory, gammaShallowHistory)
			return gammaShallowHistory
		} else {
			val gammaDeepHistory = createDeepHistoryState => [
				it.name = getDeepHistoryName(scxmlHistory)
			]

			traceability.put(scxmlHistory, gammaDeepHistory)
			return gammaDeepHistory
		}
	}

	// Internal transitions are not supported by the transformer.
	protected def Transition transformTransition(ScxmlTransitionType transition) {
		if (transition.type == TransitionTypeDatatype.INTERNAL) {
			throw new IllegalArgumentException("Transforming internal transition " + transition + " is not supported.")
		}

		val sourceState = getTransitionSource(transition)
		val targetId = transition.target.head

		val gammaSource = traceability.getStateNode(sourceState)
		val gammaTarget = traceability.getStateNodeById(targetId)

		logger.log(Level.INFO, "Transforming transition" + gammaSource.name + " -> " + gammaTarget.name)

		val gammaTransition = gammaSource.createTransition(gammaTarget)

		// Transform event trigger if present
		val eventName = transition.event
		if (!eventName.nullOrEmpty) {
			val eventTrigger = transformTrigger(eventName)
			gammaTransition.trigger = eventTrigger
		}

		// Transform guard if present
		val guardStr = transition.cond
		if (!guardStr.nullOrEmpty) {
			val gammaGuardExpression = expressionLanguageParser.parse(guardStr, traceability.variables)
			gammaTransition.guard = gammaGuardExpression
		}

		// TODO for all types of actions
		val effects = transition.assign + transition.raise
		if (!effects.nullOrEmpty) {
			gammaTransition.effects += effects.transformBlock
		}
		//
		traceability.put(transition, gammaTransition)

		return gammaTransition
	}

}
