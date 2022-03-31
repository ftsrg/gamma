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

import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.SchedulableCompositeComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.ExecutionTrace
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
	
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	
	new(ExecutionTrace executionTrace, String systemName,
			String envrionmentModelName, EnvironmentModel environmentModel, boolean considerOutEvents) {
		this.executionTrace = executionTrace
		this.testModel = executionTrace.component
		this.systemName = systemName
		this.envrionmentModelName = envrionmentModelName
		this.environmentModel = environmentModel
		this.considerOutEvents = considerOutEvents
	}
	
	/**
	 * Returns the resulting environment model and system model wrapped into Packages.
	 * Both have to be serialized.
	 */
	def execute() {
		val transformer = new TraceToEnvironmentModelTransformer(envrionmentModelName,
				considerOutEvents, executionTrace, environmentModel)
		val result = transformer.execute
		// Now only synchronous statecharts are supported - could be extended to asynchronous ones, too
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
		systemModel.prependComponentInstance(environmentInstance)
		systemModel.initialExecutionList += environmentInstance.createInstanceReference // Initial out-raises
		if (considerOutEvents) {
			systemModel.executionList += environmentInstance.createInstanceReference // In
			systemModel.executionList += componentInstance.createInstanceReference 
			systemModel.executionList += environmentInstance.createInstanceReference  // Out
		}
		
		// Tending to the system and proxy ports
		if (this.environmentModel === EnvironmentModel.OFF) {
			systemModel.ports.clear
			systemModel.portBindings.clear
		}
		else {
			for (portBinding : systemModel.portBindings) {
				val instancePortReference = portBinding.instancePortReference
				
				val componentPort = instancePortReference.port
				val proxyPort = trace.getComponentProxyPort(componentPort)
				
				instancePortReference.instance = environmentInstance
				instancePortReference.port = proxyPort
			}
		}
		
		// Tending to the environment and component ports
		for (portPair : trace.componentEnvironmentPortPairs) {
			val componentPort = portPair.key
			val environmentPort = portPair.value
			
			systemModel.channels += connectPortsViaChannels(
				componentInstance, componentPort, environmentInstance, environmentPort)
		}
		
		// Wrapping the resulting packages
		val environmentPackage = environmentModel.wrapIntoPackage
		val systemPackage = systemModel.wrapIntoPackage
		systemPackage.name = testModelPackage.name // So test generation remains simple
		
		environmentPackage.imports += testModelPackage.componentImports // E.g., interfaces and types
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