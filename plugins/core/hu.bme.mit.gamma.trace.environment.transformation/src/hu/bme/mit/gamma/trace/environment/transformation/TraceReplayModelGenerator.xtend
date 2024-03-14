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

import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.SchedulableCompositeComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.util.GammaEcoreUtil
import org.eclipse.xtend.lib.annotations.Data

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.environment.transformation.TraceReplayModelGenerator.Namings.*

class TraceReplayModelGenerator {
	
	protected final ExecutionTrace executionTrace
	protected final Component testModel
	protected final String systemName
	protected final String envrionmentModelName
	protected final EnvironmentModel environmentModel
	protected final boolean considerOutEvents
	protected final boolean handleOutEventPassing
	
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(ExecutionTrace executionTrace, String systemName,
			String envrionmentModelName, EnvironmentModel environmentModel, boolean considerOutEvents) {
		this.executionTrace = executionTrace
		this.testModel = executionTrace.component
		this.systemName = systemName
		this.envrionmentModelName = envrionmentModelName
		this.environmentModel = environmentModel
		this.considerOutEvents = considerOutEvents
		this.handleOutEventPassing = considerOutEvents &&
				testModel.ports.reject[it.internal]
					.reject[it.broadcast]
					.exists[it.hasOutputEvents] // Only if there is a valid out-event on a non-broadcast port
	}
	
	/**
	 * Returns the resulting environment model and system model wrapped into Packages.
	 * Both have to be serialized.
	 */
	def execute() {
		val transformer = new TraceToEnvironmentModelTransformer(envrionmentModelName,
				handleOutEventPassing, executionTrace, environmentModel)
		val result = transformer.execute
		
		val environmentModel = result.statechart
		val lastState = result.lastState
		val trace = transformer.getTrace
		
		val testModelPackage = testModel.containingPackage
		val systemModel = testModel.wrapComponent => [
			it.name = systemName
		]
		val componentInstance = systemModel.derivedComponents.head => [
			it.name = systemModel.instanceName
		]
		
		val environmentInstance = environmentModel.instantiateComponent
		environmentInstance.name = environmentInstance.name.toFirstLower
		systemModel.prependComponentInstance(environmentInstance)
		
		if (considerOutEvents) {
			if (handleOutEventPassing) {
				// Special scheduling for not broadcast port handling
				systemModel.initialExecutionList += environmentInstance.createInstanceReference // Initial out-raises
				
				systemModel.executionList += environmentInstance.createInstanceReference // In
				systemModel.executionList += componentInstance.createInstanceReference
				systemModel.executionList += environmentInstance.createInstanceReference  // Out
			}
			else {
				// Optimization: if every out port is broadcast the "proxy" environment ports are unnecessary
				environmentModel.regions.removeAllButFirst
				environmentModel.transitions.filter[!it.sourceState.hasContainerOfType(StatechartDefinition)]
						.toList.removeAll
				environmentModel.transitions.map[it.guard].filter(ReferenceExpression)
						.toList.removeAll
			}
		}
		
		// Tending to the system and proxy ports
		val portBindings = newArrayList
		portBindings += systemModel.portBindings
		if (this.environmentModel === EnvironmentModel.OFF) {
			if (!considerOutEvents) {
				systemModel.ports.removeAll
				systemModel.portBindings.removeAll
			}
			else {
				for (portBinding : portBindings) {
					val systemPort = portBinding.compositeSystemPort
					if (!systemPort.broadcast) {
						portBinding.remove
						systemPort.remove
					}
				}
			}
			// To allow for triggering the execution of async environment statechart
			if (environmentModel.asynchronous) {
				val asyncInputPort = environmentModel.ports.findFirst[it.hasInputEvents] // Must not be null
				val systemAsyncInputPort = asyncInputPort.clone
				systemModel.ports += systemAsyncInputPort
				
				systemModel.portBindings += systemAsyncInputPort.createPortBinding(
					environmentInstance.createInstancePortReference(asyncInputPort))
			}
			//
		}
		else {
			for (portBinding : portBindings) {
				val instancePortReference = portBinding.instancePortReference
				
				val componentPort = instancePortReference.port
				if (!componentPort.broadcast) {
					val proxyPort = trace.getComponentProxyPort(componentPort)
					
					instancePortReference.instance = environmentInstance
					instancePortReference.port = proxyPort
				}
				else if (!considerOutEvents) {
					val systemPort = portBinding.compositeSystemPort
					portBinding.remove
					systemPort.remove
				}
			}
		}
		
		// Tending to the environment and component ports
		for (portPair : trace.componentEnvironmentPortPairs) {
			val componentPort = portPair.key
			val environmentPort = portPair.value
			
			if (!componentPort.internal) { // Not connecting internal ports
				systemModel.channels += connectPortsViaChannels(
						componentInstance, componentPort, environmentInstance, environmentPort)
			}
		}
		
		// Wrapping the resulting packages
		val environmentPackage = environmentModel.wrapIntoPackage
		val systemPackage = systemModel.wrapIntoPackage
		systemPackage.name = testModelPackage.name // So test generation remains simple
		
		environmentPackage.imports += testModelPackage.componentImports // E.g., interfaces and types
		environmentPackage.imports += environmentModel.importableInterfacePackages
		systemPackage.imports += environmentPackage
		systemPackage.imports += testModelPackage
		systemPackage.imports += systemModel.importableInterfacePackages // If ports were not cleared
				
		return new Result(environmentInstance, systemModel, lastState)
	}
	
	///
	
	static class Namings {
	
		def static String getInstanceName(Component system) '''«system.name.replace('_', '').toFirstLower»'''
		
	}
	
	@Data
	static class Result {
		ComponentInstance environmentModelIntance
		SchedulableCompositeComponent systemModel
		State lastState
	}
	
}