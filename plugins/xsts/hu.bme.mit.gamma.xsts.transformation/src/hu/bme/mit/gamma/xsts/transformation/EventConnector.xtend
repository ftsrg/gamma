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

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class EventConnector {
	// Singleton
	public static final EventConnector INSTANCE =  new EventConnector
	protected new() {}
	// Auxiliary objects
	protected final extension GammaEcoreUtil expressionUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	
	// TODO Introduce EventReferenceToXstsVariableMapper
	
	def void connectEventsThroughChannels(XSTS xSts, CompositeComponent component) {
		val mapper = new ReferenceToXstsVariableMapper(xSts)
		// AssignmentAction not AbstractAssignmentAction as we do not use havoc in the system behavior
		val xStsAssignmentActions = xSts.getAllContentsOfType(AssignmentAction) // Caching
		xStsAssignmentActions -= xSts.inEventTransition.getAllContentsOfType(AssignmentAction)
		xStsAssignmentActions -= xSts.outEventTransition.getAllContentsOfType(AssignmentAction)
		// We do not connect event in in and out transitions, e.g., in the case of
		// "bound and channeled" broadcast ports, this would cause problems
		
		val xStsDeletableVariables = newHashSet
		val optimizableSimplePorts = newHashSet
		for (channel : component.channels) {
			val providedPort = channel.providedPort.port
			val requiredPorts = channel.requiredPorts.map[it.port]
			// Connection: keeping in-variables, deleting out-variables
			val providedSimplePorts = providedPort.allBoundSimplePorts
			checkState(providedSimplePorts.size == 1)
			val providedSimplePort = providedSimplePorts.head
			val providedStatechart = providedSimplePort.containingStatechart
			val providedInstance = providedStatechart.referencingComponentInstance
			for (requiredPort : requiredPorts) {
				for (requiredSimplePort : requiredPort.allBoundSimplePorts) {
					val requiredStatechart = requiredSimplePort.containingStatechart
					val requiredInstance = requiredStatechart.referencingComponentInstance
					// In events on required port
					for (event : requiredSimplePort.inputEvents) {
						val requiredInEventName = event.customizeInputName(requiredSimplePort, requiredInstance)
						val xStsInEventVariable = xSts.variableDeclarations.findFirst[it.name == requiredInEventName]
						if (xStsInEventVariable !== null) {
							val providedOutEventName = event.customizeOutputName(providedSimplePort, providedInstance)
							val xStsOutEventVariable = xSts.variableDeclarations.findFirst[it.name == providedOutEventName]
							if (xStsOutEventVariable !== null) { // Can be null due to XSTS optimization
								xStsOutEventVariable.connectEvents(xStsInEventVariable, xStsAssignmentActions)
								// In-parameters
								for (parameter : event.parameterDeclarations) {
									val requiredInParamaterNames = parameter.customizeInNames(requiredSimplePort, requiredInstance)
									val xStsInParameterVariables = xSts.variableDeclarations
											.filter[requiredInParamaterNames.contains(it.name)].toList
									if (!xStsInParameterVariables.nullOrEmpty) { // Can be null due to XSTS optimization
										val providedOutParamaterNames = parameter.customizeOutNames(providedSimplePort, providedInstance)
										val xStsOutParameterVariables = xSts.variableDeclarations
												.filter[providedOutParamaterNames.contains(it.name)].toList
										if (!xStsOutParameterVariables.nullOrEmpty) { // Can be null due to XSTS optimization
											xStsOutParameterVariables.connectEvents(xStsInParameterVariables, xStsAssignmentActions)
										}
									}
								}
							}
						}
					}
					// Out events on required port
					for (event : requiredSimplePort.outputEvents) {
						val requiredOutEventName = event.customizeOutputName(requiredSimplePort, requiredInstance)
						val xStsOutEventVariable = xSts.variableDeclarations.findFirst[it.name == requiredOutEventName]
						if (xStsOutEventVariable !== null) { // Can be null due to XSTS optimization
							val providedInEventName = event.customizeInputName(providedSimplePort, providedInstance)
							val xStsInEventVariable = xSts.variableDeclarations.findFirst[it.name == providedInEventName]
							if (xStsInEventVariable !== null) { // Can be null due to XSTS optimization
								xStsOutEventVariable.connectEvents(xStsInEventVariable, xStsAssignmentActions)
								// Out-parameters
								for (parameter : event.parameterDeclarations) {
									val requiredOutParamaterNames = parameter.customizeOutNames(requiredSimplePort, requiredInstance)
									val xStsOutParameterVariables = xSts.variableDeclarations
											.filter[requiredOutParamaterNames.contains(it.name)].toList
									if (!xStsOutParameterVariables.nullOrEmpty) { // Can be null due to XSTS optimization
										val providedInParamaterNames = parameter.customizeInNames(providedSimplePort, providedInstance)
										val xStsInParameterVariables = xSts.variableDeclarations
												.filter[providedInParamaterNames.contains(it.name)].toList
										if (!xStsInParameterVariables.nullOrEmpty) { // Can be null due to XSTS optimization
											xStsOutParameterVariables.connectEvents(xStsInParameterVariables, xStsAssignmentActions)
										}
									}
								}
							}
						}
					}
					optimizableSimplePorts += requiredSimplePort
				}
				if (providedSimplePort.isOptimizable(component)) {
					optimizableSimplePorts += providedSimplePort
				}
				optimizableSimplePorts += component.derivedComponents
					.map[it.unusedPorts].flatten.map[it.allBoundSimplePorts].flatten
			}
		}
		// Out-event optimization - maybe this should be moved to the SystemReducer?
		// Only optimizableSimplePorts as out events can trigger in-events upper in the hierarchy
		for (optimizableSimplePort : optimizableSimplePorts) {
			for (outEvent : optimizableSimplePort.outputEvents) {
				val xStsOutEventVariable = mapper.getOutputEventVariable(outEvent, optimizableSimplePort)
				if (xStsOutEventVariable !== null) {
					xStsDeletableVariables += xStsOutEventVariable
					for (outParameter : outEvent.parameterDeclarations) {
						val xStsOutParameterVariables = mapper.getOutputParameterVariables(outParameter, optimizableSimplePort)
						if (!xStsOutParameterVariables.nullOrEmpty) {
							xStsDeletableVariables += xStsOutParameterVariables
						}
					}
				}
			}
		}
		
		// Deletion
		for (xStsDeletableVariable : xStsDeletableVariables) {
			for (xStsDeletableAssignmentAction : xStsAssignmentActions
					.filter[it.lhs.accessedDeclaration === xStsDeletableVariable]) {
				xStsDeletableAssignmentAction.replaceWithEmptyAction
			}
			// Assignment removal before variable deletion!
			xStsDeletableVariable.delete // Delete needed due to e.g., transientVariables list
		}
	}
	
	protected def boolean isOptimizable(Port simplePort, Component component) {
		val allBoundSimplePorts = component.allBoundSimplePorts
		// "Bound and channeled" broadcast ports are not optimizable
		return !(simplePort.isBroadcast && allBoundSimplePorts.contains(simplePort))
	}
	
	protected def void connectEvents(VariableDeclaration xStsOutVariable,
			VariableDeclaration xStsInVariable, List<AssignmentAction> xStsAssignmentActions) {
		for (xStsAssignmentAction : xStsAssignmentActions) {
			val xStsDeclaration = xStsAssignmentAction.lhs.declaration // TODO Works for arrays?
			if (xStsDeclaration === xStsOutVariable) {
				val xStsNewAssignmentAction = xStsAssignmentAction.clone => [
					(it.lhs as DirectReferenceExpression).declaration = xStsInVariable
				]
				xStsAssignmentAction.appendToAction(xStsNewAssignmentAction)
			}
		}
	}
	
	protected def void connectEvents(List<VariableDeclaration> xStsOutVariables,
			List<VariableDeclaration> xStsInVariables, List<AssignmentAction> xStsAssignmentActions) {
		checkState(xStsOutVariables.size == xStsInVariables.size)
		val size = xStsOutVariables.size
		for (var i = 0; i < size; i++) {
			val xStsOutVariable = xStsOutVariables.get(i)
			val xStsInVariable = xStsInVariables.get(i)
			xStsOutVariable.connectEvents(xStsInVariable, xStsAssignmentActions)
		}
	}
	
}