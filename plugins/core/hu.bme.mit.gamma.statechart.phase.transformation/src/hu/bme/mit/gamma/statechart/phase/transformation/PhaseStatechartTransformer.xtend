/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.phase.transformation

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.statechart.composite.PortBinding
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateAnnotation
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateDefinition
import hu.bme.mit.gamma.statechart.phase.VariableBinding
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.phase.transformation.Namings.*
import static extension org.eclipse.emf.ecore.util.EcoreUtil.*

class PhaseStatechartTransformer {

	protected final StatechartDefinition statechart

	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	
	new(StatechartDefinition statechart) {
		// No cloning to save resources, we process the original model
		this.statechart = statechart
	}
	
	def execute() {
		val checkedAnnotations = newHashSet
		var annotations = statechart.allMissionPhaseStateAnnotations
		while (!checkedAnnotations.containsAll(annotations)) {
			for (annotation : annotations.reject[checkedAnnotations.contains(it)]) {
				val stateDefinitions = annotation.stateDefinitions
				for (stateDefinition : stateDefinitions) {
					val component = stateDefinition.component
					val inlineableStatechart = component.type.clone as StatechartDefinition
					for (portBinding : stateDefinition.portBindings) {
						portBinding.inlinePorts(inlineableStatechart)
					}
					for (variableBinding : stateDefinition.variableBindings) {
						variableBinding.inlineVariables(inlineableStatechart)
					}
					component.inlineParameters(inlineableStatechart)
					statechart.inlineRemainingStatechart(inlineableStatechart, stateDefinition)
				}
				checkedAnnotations += annotation
			}
			annotations = statechart.allMissionPhaseStateAnnotations
		}
		//
		for (annotation : annotations) {
			val stateDefinitions = annotation.stateDefinitions
			for (stateDefinition : stateDefinitions) {
				for (portBinding : stateDefinition.portBindings) {
					val port = portBinding.compositeSystemPort
					val removeablePort = portBinding.instancePortReference.port
					port.changeAndDelete(removeablePort, statechart)
				}
				for (variableBinding : stateDefinition.variableBindings) {
					val variable = variableBinding.statechartVariable
					val removeableVariable = variableBinding.instanceVariableReference.variable
					variable.changeAndDelete(removeableVariable, statechart)
				}
			}
			annotation.remove
		}
		return statechart
	}
	
	private def List<MissionPhaseStateAnnotation> getAllMissionPhaseStateAnnotations(StatechartDefinition statechart) {
		return statechart.getAllContents(true).filter(State).map[it.annotation]
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
	
	private def void inlineVariables(VariableBinding variableBinding, StatechartDefinition inlineableStatechart) {
		val statechart = variableBinding.containingStatechart
		val originalVariable = variableBinding.instanceVariableReference.variable
		val instance = variableBinding.instanceVariableReference.instance
		val variableCopies = inlineableStatechart.variableDeclarations.filter[it.helperEquals(originalVariable)]
		checkState(variableCopies.size == 1, variableCopies)
		val variableCopy = variableCopies.head
		variableCopy.name = variableCopy.getName(instance)
		variableBinding.instanceVariableReference.variable = variableCopy
		statechart.variableDeclarations += variableCopy
	}
	
	private def void inlineParameters(SynchronousComponentInstance instance, StatechartDefinition inlineableStatechart) {
		val parameters = inlineableStatechart.parameterDeclarations
		for (var i = 0; i < parameters.size; i++) {
			val parameter = parameters.get(i)
			for (reference : inlineableStatechart.getAllContents(true).filter(DirectReferenceExpression)
					.filter[it.declaration === parameter].toList) {
				val argument = instance.arguments.get(i)
				reference.replace(argument)
			}
		}
	}
	
	private def void inlineRemainingStatechart(StatechartDefinition statechart,
			StatechartDefinition inlineableStatechart, MissionPhaseStateDefinition stateDefinition) {
		val state = stateDefinition.eContainer.eContainer as State
		val instance = stateDefinition.component
		val history = stateDefinition.history
		val inlineableRegions = inlineableStatechart.regions
		for (inlineableRegion : inlineableRegions) {
			val newEntryState = switch (history) {
				case NO_HISTORY: {
					createInitialState => [it.name = history.getName(instance)]
				}
				case SHALLOW_HISTORY : {
					createShallowHistoryState => [it.name = history.getName(instance)]
				}
				case DEEP_HISTORY : {
					createDeepHistoryState => [it.name = history.getName(instance)]
				}
			}
			inlineableRegion.stateNodes += newEntryState
			val oldEntryState = inlineableRegion.entryState
			newEntryState.changeAndDelete(oldEntryState, inlineableStatechart)
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