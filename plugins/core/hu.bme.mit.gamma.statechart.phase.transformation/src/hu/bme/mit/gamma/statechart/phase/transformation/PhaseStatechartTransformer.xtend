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
package hu.bme.mit.gamma.statechart.phase.transformation

import hu.bme.mit.gamma.expression.util.ArgumentInliner
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.PortBinding
import hu.bme.mit.gamma.statechart.phase.History
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateAnnotation
import hu.bme.mit.gamma.statechart.phase.VariableBinding
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.phase.transformation.Namings.*
import static extension java.lang.Math.abs

class PhaseStatechartTransformer {
	
	protected final StatechartDefinition statechart
	
	protected final extension ArgumentInliner argumentInliner = ArgumentInliner.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	
	new(MissionPhaseStateAnnotation phaseStateAnnotation) {
		checkState(phaseStateAnnotation.eContainer === null)
		this.statechart = createSynchronousStatechartDefinition => [
			it.name = '''_«phaseStateAnnotation.hashCode.abs»'''
		]
		val systemPorts = phaseStateAnnotation.portBindings
				.map[it.compositeSystemPort].toSet
		for (systemPort : systemPorts) {
			val clonedSystemPort = systemPort.clone
			statechart.ports += clonedSystemPort
			clonedSystemPort.change(systemPort, phaseStateAnnotation)
		}
		
		val state = statechart.createRegionWithState("_", "__", "___")
		state.annotations += phaseStateAnnotation
	}
	
	new(StatechartDefinition statechart) {
		// No cloning to save resources, we process the original model
		this.statechart = statechart
	}
	
	def execute() {
		val checkedAnnotations = newHashSet
		var annotations = statechart.allMissionPhaseStateAnnotations
		while (!checkedAnnotations.containsAll(annotations)) {
			for (annotation : annotations.reject[checkedAnnotations.contains(it)]) {
				val component = annotation.component
				val originalType = component.derivedType
				
				// Imports here due to the cloning below
				val _package = statechart.containingPackage
				val inlineablePackage = originalType.containingPackage
				
				_package.imports += inlineablePackage.imports
				//
				
				val inlineableStatechart = originalType.clone as StatechartDefinition
				for (portBinding : annotation.portBindings) {
					portBinding.inlinePorts(inlineableStatechart)
				}
				for (variableBinding : annotation.variableBindings) {
					variableBinding.inlineVariables(inlineableStatechart)
				}
				component.inlineParameters(inlineableStatechart)
				statechart.inlineRemainingStatechart(inlineableStatechart, annotation)
				
				checkedAnnotations += annotation
			}
			annotations = statechart.allMissionPhaseStateAnnotations
		}
		//
		for (annotation : annotations) {
			for (portBinding : annotation.portBindings) {
				val port = portBinding.compositeSystemPort
				val removeablePort = portBinding.instancePortReference.port
				port.changeAndDelete(removeablePort, statechart)
			}
			for (variableBinding : annotation.variableBindings) {
				val variable = variableBinding.statechartVariable
				val removeableVariable = variableBinding.instanceVariableReference.variable
				variable.changeAndDelete(removeableVariable, statechart)
			}
			
			annotation.remove
		}
		return statechart
	}
	
	// Can be used if statechart is created based on MissionPhaseStateAnnotation
	def moveRegion() {
		val regions = statechart.regions
		checkState(regions.size == 1)
		val region = regions.head
		val states = region.states
		checkState(states.size == 1)
		val state = states.head
		
		statechart.regions.clear
		statechart.regions += state.regions
	}
	
	private def List<MissionPhaseStateAnnotation> getAllMissionPhaseStateAnnotations(
			StatechartDefinition statechart) {
		return statechart.getAllContentsOfType(State).map[it.annotations].flatten
				.filter(MissionPhaseStateAnnotation).toList
	}
	
	private def void inlinePorts(PortBinding portBinding, StatechartDefinition inlineableStatechart) {
		val statechart = portBinding.containingStatechart
		val originalPort = portBinding.instancePortReference.port
		val portCopies = inlineableStatechart.ports.filter[it.helperEquals(originalPort)]
		
		checkState(portCopies.size == 1, portCopies)
		
		val portCopy = portCopies.head
		portBinding.instancePortReference.port = portCopy
		statechart.ports += portCopy
	}
	
	private def void inlineVariables(
				VariableBinding variableBinding, StatechartDefinition inlineableStatechart) {
		val statechart = variableBinding.containingStatechart
		val originalVariable = variableBinding.instanceVariableReference.variable
		val instance = variableBinding.instanceVariableReference.instance
		val variableCopies = inlineableStatechart.variableDeclarations
				.filter[it.helperEquals(originalVariable)]
				
		checkState(variableCopies.size == 1, variableCopies)
		
		val variableCopy = variableCopies.head
		variableCopy.name = variableCopy.getName(instance)
		variableBinding.instanceVariableReference.variable = variableCopy
		statechart.variableDeclarations += variableCopy
	}
	
	private def void inlineParameters(
				ComponentInstance instance, StatechartDefinition inlineableStatechart) {
		val parameters = inlineableStatechart.parameterDeclarations
		val arguments = instance.arguments
		parameters.inlineParamaters(arguments)
	}
	
	private def void inlineRemainingStatechart(StatechartDefinition statechart,
			StatechartDefinition inlineableStatechart, MissionPhaseStateAnnotation annotation) {
		val state = annotation.getContainerOfType(State)
		val instance = annotation.component
		val history = annotation.history
		val inlineableRegions = inlineableStatechart.regions
		for (inlineableRegion : inlineableRegions) {
			val newEntryState = history.createEntryState
			newEntryState.name = history.getName(instance)
			val oldEntryState = inlineableRegion.entryState
			inlineableRegion.stateNodes += newEntryState
			newEntryState.changeAndDelete(oldEntryState, inlineableStatechart)
		}
		
		// If there is no history, we reset the variable values
		// Note that doing this on exit will reduce the state space
		if (history == History.NO_HISTORY) {
			val resettableVariables = inlineableStatechart.variableDeclarations
			// Note that the bound variables are already inlined into the statechart
			for (resettableVariable : resettableVariables) {
				val variableInitializationAction = resettableVariable.createAssignment(
						resettableVariable.initialValue)
				state.exitActions += variableInitializationAction
			}
		}
		
		// Renames
		for (inlineableRegion : inlineableRegions) {
			for (stateNode : inlineableRegion.allStateNodes) {
				stateNode.name = stateNode.getName(instance) // TODO name recursively
			}
		}
		
		for (inlineableRegion : inlineableRegions) {
			for (region : inlineableRegion.allRegions) {
				region.name = region.getName(instance)
			}
		}
		state.regions += inlineableRegions
		
		statechart.transitions += inlineableStatechart.transitions
		
		val ports = inlineableStatechart.ports
		for (port : ports) {
			port.name = port.getName(instance)
		}
		statechart.ports += ports
		
		val timeoutDeclarations = inlineableStatechart.timeoutDeclarations
		for (timeoutDeclaration : timeoutDeclarations) {
			timeoutDeclaration.name = timeoutDeclaration.getName(instance)
		}
		statechart.timeoutDeclarations += timeoutDeclarations
		
		val variableDeclarations = inlineableStatechart.variableDeclarations
		for (variableDeclaration : variableDeclarations) {
			variableDeclaration.name = variableDeclaration.getName(instance)
		}
		statechart.variableDeclarations += inlineableStatechart.variableDeclarations
	}
	
}