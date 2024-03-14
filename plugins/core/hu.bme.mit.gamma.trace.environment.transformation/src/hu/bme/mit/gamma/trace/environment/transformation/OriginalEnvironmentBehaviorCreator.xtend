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
package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.CompositeElement
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.environment.transformation.TraceToEnvironmentModelTransformer.Namings
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import java.util.Collection
import java.util.Map.Entry
import java.util.Set
import java.util.function.Function

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class OriginalEnvironmentBehaviorCreator {
	
	protected final Trace trace
	protected final EnvironmentModel environmentModel
	protected final boolean handleOutEventPassing
	
	protected final extension Namings namings
	
	protected extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	
	protected extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	protected extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	
	new(Trace trace, EnvironmentModel environmentModel, Namings namings, boolean handleOutEventPassing) {
		this.trace = trace
		this.environmentModel = environmentModel
		this.handleOutEventPassing = handleOutEventPassing
		this.namings = namings
	}
	
	def createOriginalEnvironmentBehavior(State lastState) {
		if (environmentModel == EnvironmentModel.SYNCHRONOUS) {
			lastState.createSynchronousEnvironmentBehavior
		}
		else if (environmentModel == EnvironmentModel.ASYNCHRONOUS) {
			lastState.createAsynchronousEnvironmentBehavior
		}
		// No behavior in the case of OFF
		if (handleOutEventPassing) {
			val environmentModel = lastState.containingStatechart
			val inOutCycleVariable = createBooleanTypeDefinition.createVariableDeclaration(
				inOutCycleVariableName, createFalseExpression /* false- check initial execution
				 * of the composite component to handle initial raises*/)
			environmentModel.variableDeclarations += inOutCycleVariable
			
			val stateTransitions = environmentModel.transitions.filter[it.sourceState instanceof State]
			for (stateTransition : stateTransitions) {
				val source = stateTransition.sourceState
				val variableReference = inOutCycleVariable.createReferenceExpression
				if (source === trace.lastOutState) {
					stateTransition.guard = variableReference.createNotExpression
				}
				else if (!trace.isFirstStepTransition(stateTransition)) { // No guard at the first step
					stateTransition.guard = variableReference
				}
			}
			
			// New region for setting the inOutCycleVariable
			val inOutCycleState = environmentModel.createRegionWithState(inOutCycleRegionName,
					inOutCycleInitialStateName, inOutCycleStateName)
			val inOutCycleTransition = inOutCycleState.createTransition(inOutCycleState)
			inOutCycleTransition.trigger = createOnCycleTrigger
			inOutCycleTransition.effects += inOutCycleVariable.createAssignment(
					inOutCycleVariable.createReferenceExpression.createNotExpression)
		}
	}
	
	private def createSynchronousEnvironmentBehavior(State lastState) {
		val proxyEnvironmentPortPairs = trace.proxyEnvironmentPortPairs
		val lastInState = lastState.createSynchronousEnvironmentBehavior(proxyEnvironmentPortPairs,
				[it.inputEvents], inputRegionName, inputInitialStateName, inputStateName)
		if (true) {
			lastInState.relocateOutgoingTransitionsAndNodes(lastState)
			lastState.removeRegions
		}
		
		if (handleOutEventPassing) {
			val envrionmentModel = lastState.containingStatechart
			val environmentProxyPortPairs = proxyEnvironmentPortPairs.invert.toSet
			val lastOutState = envrionmentModel.createSynchronousEnvironmentBehavior(environmentProxyPortPairs,
					[it.inputEvents /*See inversion*/], outputRegionName, outputInitialStateName, outputStateName)
			val outputRegion = lastOutState.parentRegion
			trace.lastOutState = lastOutState
			// Adding another step
			val firstOutputState = envrionmentModel.createSynchronousEnvironmentBehavior(
					environmentProxyPortPairs, [it.inputEvents /*See inversion*/], "", "", firstOutputStateName)
			val firstOutputRegion = firstOutputState.parentRegion
			outputRegion.addStep(firstOutputRegion)
		}
	}
	
	private def createSynchronousEnvironmentBehavior(CompositeElement compositeElement,
			Set<Entry<Port, Port>> proxyPortPairs, Function<Port, Collection<Event>> eventRetriever,
			String regionName, String initialStateName, String stateName) {
		val envrionmentModel = compositeElement.getSelfOrContainerOfType(StatechartDefinition)
		
		val internalLastState = compositeElement.createRegionWithState(
			regionName, initialStateName, stateName)
		
		val region = internalLastState.parentRegion
		
		val transitions = proxyPortPairs.createEventPassingTransitions(eventRetriever)
		if (transitions.empty) {
			return internalLastState
		}
		
		var StateNode lastTargetState = createChoiceState => [
			it.name = choiceName
		]
		region.stateNodes += lastTargetState
		
		val firstTransition = createTransition => [
			it.trigger = createOnCycleTrigger
		]
		firstTransition.sourceState = internalLastState
		firstTransition.targetState = lastTargetState
		envrionmentModel.transitions += firstTransition
		
		for (transition : transitions) {
			val elseTransition = createTransition => [
				it.guard = createElseExpression
			]
			envrionmentModel.transitions += transition
			envrionmentModel.transitions += elseTransition
			
			transition.sourceState = lastTargetState
			elseTransition.sourceState = lastTargetState
			
			val mergeState = createMergeState => [
				it.name = mergeName
			]
			region.stateNodes += mergeState
			
			transition.targetState = mergeState
			elseTransition.targetState = mergeState
			
			lastTargetState = createChoiceState => [
				it.name = choiceName
			]
			region.stateNodes += lastTargetState
			val mergeChoiceTransition = createTransition
			mergeChoiceTransition.sourceState = mergeState
			mergeChoiceTransition.targetState = lastTargetState
			
			envrionmentModel.transitions += mergeChoiceTransition
		}
		// Cleanup
		val lastMergeChoiceTransition = lastTargetState.incomingTransitions.onlyElement
		val lastMerge = lastMergeChoiceTransition.sourceState
		val lastTransitions = lastMerge.incomingTransitions
		for (lastTransition : lastTransitions) {
			lastTransition.targetState = internalLastState
		}
		
		lastTargetState.remove
		lastMergeChoiceTransition.remove
		lastMerge.remove
		
		return internalLastState
	}
	
	private def createAsynchronousEnvironmentBehavior(State lastState) {
		val proxyEnvironmentPortPairs = trace.proxyEnvironmentPortPairs
		val lastInState = lastState.createAsynchronousEnvironmentBehavior(proxyEnvironmentPortPairs,
				[it.inputEvents], inputRegionName, inputInitialStateName, inputStateName)
		if (true) {
			lastInState.relocateOutgoingTransitionsAndNodes(lastState)
			lastState.removeRegions
		}
		
		if (handleOutEventPassing) {
			val envrionmentModel = lastState.containingStatechart
			val environmentProxyPortPairs = proxyEnvironmentPortPairs.invert.toSet
			val lastOutState = envrionmentModel.createAsynchronousEnvironmentBehavior(environmentProxyPortPairs,
					[it.inputEvents /*See inversion*/], outputRegionName, outputInitialStateName, outputStateName)
			val outputRegion = lastOutState.parentRegion
			trace.lastOutState = lastOutState
			// Adding another step
			val firstOutputState = envrionmentModel.createAsynchronousEnvironmentBehavior(
					environmentProxyPortPairs, [it.inputEvents /*See inversion*/], "", "", firstOutputStateName)
			val firstOutputRegion = firstOutputState.parentRegion
			outputRegion.addStep(firstOutputRegion)
		}
	}
	
	private def addStep(Region original, Region ^extension) {
		val initialExtensionTransition = ^extension.initialTransition
		val initialState = initialExtensionTransition.sourceState
		initialExtensionTransition.remove
		initialState.remove
		
		val state = ^extension.states.onlyElement
		original.stateNodes += ^extension.stateNodes // First step for out-events added in TraceReplay...
		
		val lastOutState = trace.lastOutState
		
		for (incomingTransition : state.incomingTransitions) {
			incomingTransition.targetState = lastOutState
		}
		trace.addFirstStepTransitions(state.outgoingTransitions)
		
		val initialOriginalTransition = original.initialTransition
		initialOriginalTransition.targetState = state
		
		^extension.remove
	}
	
	private def createAsynchronousEnvironmentBehavior(CompositeElement compositeElement,
			Set<Entry<Port, Port>> proxyPortPairs, Function<Port, Collection<Event>> eventRetriever,
			String regionName, String initialStateName, String stateName) {
		val envrionmentModel = compositeElement.getSelfOrContainerOfType(StatechartDefinition)
		
		val internalLastState = compositeElement.createRegionWithState(
			regionName, initialStateName, stateName)
			
		val transitions = proxyPortPairs.createEventPassingTransitions(eventRetriever)
		for (transition : transitions) {
			envrionmentModel.transitions += transition
			
			transition.sourceState = internalLastState
			transition.targetState = internalLastState
		}
		
		return internalLastState
	}
	
	private def createEventPassingTransitions(Collection<? extends Entry<Port, Port>> portPairs,
			Function<Port, Collection<Event>> eventRetriever) {
		val transitions = newArrayList
		for (portPair : portPairs) {
			val sourcePort = portPair.key
			val targetPort = portPair.value
			
			val inEvents = eventRetriever.apply(sourcePort) // Input or output events are expected
			for (inEvent : inEvents) {
				transitions += inEvent.createEventPassingTransition(sourcePort, targetPort)
			}
		}
		return transitions
	}
	
	private def createEventPassingTransition(Event event, Port sourcePort, Port targetPort) {
		val transition = createTransition // transition handling by the caller
		// Mapping the input event into...
		transition.trigger = createEventTrigger => [
			it.eventReference = createPortEventReference => [
				it.port = sourcePort
				it.event = event
			]
		]
		// ... a raise event action				
		transition.effects += createRaiseEventAction => [
			it.port = targetPort
			it.event = event
			for (parameter : event.parameterDeclarations) {
				// Just passing through the parameter values...
				it.arguments += createEventParameterReferenceExpression => [
					it.port = sourcePort
					it.event = event
					it.parameter = parameter
				]
			}
		]
		return transition
	}
	
}