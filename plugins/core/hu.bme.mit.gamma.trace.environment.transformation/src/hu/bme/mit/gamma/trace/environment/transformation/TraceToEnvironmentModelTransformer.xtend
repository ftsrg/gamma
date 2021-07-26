/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Reset
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.util.GammaEcoreUtil
import org.eclipse.xtend.lib.annotations.Data

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TraceToEnvironmentModelTransformer {
	
	protected final extension Namings namings
	
	protected final String environmentModelName
	protected final boolean considerOutEvents
	protected final ExecutionTrace executionTrace
	protected final EnvironmentModel environmentModel
	protected final Trace trace
	
	protected extension OriginalEnvironmentBehaviorCreator originalEnvironmentBehaviorCreator
	
	protected extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	
	protected extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	protected extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	
	new(String environmentModelName, boolean considerOutEvents,
			ExecutionTrace executionTrace, EnvironmentModel environmentModel) {
		this.environmentModelName = environmentModelName
		this.considerOutEvents = considerOutEvents
		this.executionTrace = executionTrace
		this.environmentModel = environmentModel
		this.namings = new Namings
		this.trace = new Trace
		this.originalEnvironmentBehaviorCreator = new OriginalEnvironmentBehaviorCreator(
			this.trace, this.environmentModel, this.namings, this.considerOutEvents)
	}
	
	def execute() {
		validate
		
		val statechart = createStatechartDefinition => [
			it.name = environmentModelName
		]
		
		statechart.transformPorts(trace)
		
		statechart.createRegionWithState(mainRegionName, initialStateName, stateName)
		var actualTransition = statechart.transitions.head
		
		val actions = executionTrace.steps.map[it.actions].flatten.toList
		// Resets are not handled; schedules are handled by introducing a new transition 
		actions.set(0, createComponentSchedule)
		for (action : actions) {
			actualTransition = action.transformTrigger(actualTransition)
		}
		// There is an unnecessary empty transition at the end
		val lastState = actualTransition.sourceState as State
		actualTransition.targetState.remove
		actualTransition.remove
		
		lastState.createOriginalEnvironmentBehavior
		
		return new Result(statechart, lastState)
	}
	
	protected def validate() {
		val firstStep = executionTrace.steps.head
		val act = firstStep.actions.head
		checkState(act instanceof Reset, "The first act in the execution trace must be a reset")
	}
	
	protected def transformPorts(StatechartDefinition environmentModel, Trace trace) {
		val component = executionTrace.component
		for (componentPort : component.ports) {
			// Environment ports: connected to the original ports
			val environmentPort = componentPort.clone
			val interfaceRealization = environmentPort.interfaceRealization
			
			environmentPort.name = componentPort.environmentPortName
			interfaceRealization.realizationMode = interfaceRealization.realizationMode.opposite
			
			environmentModel.ports += environmentPort
			trace.putComponentEnvironmentPort(componentPort, environmentPort)
			
			// Proxy ports: led out to the system
			if (this.environmentModel !== EnvironmentModel.OFF) { 
				val proxyPort = componentPort.clone
				
				proxyPort.name = componentPort.proxyPortName
				
				environmentModel.ports += proxyPort
				trace.putComponentProxyPort(componentPort, proxyPort)
				trace.putProxyEnvironmentPort(proxyPort, environmentPort)
			}
		}
	}
	
	// Transform triggers
	
	protected def dispatch transformTrigger(TimeElapse act, Transition transition) {
		val elapsedTime = act.elapsedTime
		
		val timeoutDeclaration = statechartModelFactory.createTimeoutDeclaration => [
			it.name = timeoutDeclarationName
		]
		val statechart = transition.containingStatechart
		statechart.timeoutDeclarations += timeoutDeclaration
	
		val source = transition.sourceState as State
		
		val setTimeoutActions = source.entryActions.filter(SetTimeoutAction)
		if (!setTimeoutActions.empty) {
			val setTimeoutAction = setTimeoutActions.head
			val value = setTimeoutAction.time.value
			setTimeoutAction.time.value = value.add(elapsedTime.intValue)
		}
		else {
			source.entryActions += createSetTimeoutAction => [
				it.timeoutDeclaration = timeoutDeclaration
				it.time = createTimeSpecification => [
					it.value = elapsedTime.toIntegerLiteral
					it.unit = TimeUnit.MILLISECOND
				]
			]
		}
		transition.extendTrigger(
			createEventTrigger => [
				it.eventReference = createTimeoutEventReference => [
					it.timeout = timeoutDeclaration
				]
			], BinaryType.AND
		)
		return transition
	}
	
	protected def dispatch transformTrigger(RaiseEventAct act, Transition transition) {
		val componentPort = act.port
		val environmentPort = trace.getComponentEnvironmentPort(componentPort)
		val event = act.event
		val arguments = act.arguments
		
		transition.effects += createRaiseEventAction => [
			it.port = environmentPort
			it.event = event
			for (argument : arguments) {
				it.arguments += argument.clone
			}
		]
		return transition
	}
	
	protected def dispatch transformTrigger(ComponentSchedule act, Transition transition) {
		if (transition.trigger === null && transition.sourceState instanceof State) {
			// The old transition has to have a trigger
			transition.trigger = createOnCycleTrigger
		}
		val target = transition.targetState
		val region = target.parentRegion
		val newTarget = createState => [
			it.name = stateName
		]
		region.stateNodes += newTarget
		val newTransition = target.createTransition(newTarget)
		return newTransition
	}
	
	///
	
	def getTrace() {
		return trace
	}
	
	///
	
	static class Namings {
	
		int timeoutId
		int stateId
		int mergeId
		int choiceId
		
		def String getEnvironmentPortName(Port port) '''_«port.name»_'''
		def String getProxyPortName(Port port) '''«port.name»'''
		
		def String getStateName() '''_«stateId++»'''
		def String getMergeName() '''Merge«mergeId++»'''
		def String getChoiceName() '''Choice«choiceId++»'''
		def String getTimeoutDeclarationName() '''Timeout«timeoutId++»'''
		def String getMainRegionName() '''MainRegion'''
		def String getInitialStateName() '''Initial'''
		
		def String getInputRegionName() '''InputRegion'''
		def String getOutputRegionName() '''OutputRegion'''
		def String getInputInitialStateName() '''InputInitialState'''
		def String getOutputInitialStateName() '''OutputInitialState'''
		def String getInputStateName() '''InputState'''
		def String getOutputStateName() '''OutputState'''
		
		def String getInOutCycleVariableName() '''inOutCycleVariable'''
		
		def String getInOutCycleRegionName() '''InOutCycleRegion'''
		def String getInOutCycleInitialStateName() '''InOutCycleInitialState'''
		def String getInOutCycleStateName() '''InOutCycleState'''
		
	}
	
	// Result class
	
	@Data
	static class Result {
		StatechartDefinition statechart
		State lastState
	}
	
}