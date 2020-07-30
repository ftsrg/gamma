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
package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Persistency
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.CompositeAction
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XSTSActionUtil
import java.util.Set

import static hu.bme.mit.gamma.xsts.transformation.util.Namings.*

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XSTSDerivedFeatures.*

class EnvironmentalActionFilter {
	// Singleton
	public static final EnvironmentalActionFilter INSTANCE =  new EnvironmentalActionFilter
	protected new() {}
	// Auxiliary objects
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension XSTSModelFactory xStsModelFactory = XSTSModelFactory.eINSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XSTSActionUtil xStsActionUtil = XSTSActionUtil.INSTANCE
	
	def void deleteEverythingExceptSystemEventsAndParameters(CompositeAction action, Component component) {
		val necessaryNames = newHashSet
		// Input and output events and parameters
		for (port : component.allConnectedSimplePorts) {
			val statechart = port.containingStatechart
			val instance = statechart.referencingComponentInstance
			for (eventDeclaration : port.allEventDeclarations) {
				val event = eventDeclaration.event
				necessaryNames += customizeInputName(event, port, instance)
				necessaryNames += customizeOutputName(event, port, instance)
				for (parameter : event.parameterDeclarations) {
					necessaryNames += customizeInName(parameter, port, instance)
					if (event.persistency == Persistency.PERSISTENT) {
						necessaryNames += customizeOutName(parameter, port, instance)
					}
				}
			}
		}
		// Clock variable settings are retained too - not necessary as the timeouts are in the merged action now
//		for (simpleInstance : component.allSimpleInstances) {
//			val statechart = simpleInstance.type as StatechartDefinition
//			for (timeoutDelcaration : statechart.timeoutDeclarations) {
//				necessaryNames += customizeName(timeoutDelcaration, simpleInstance)
//			}
//		}
		action.delete(necessaryNames)
	}
	
	def Action resetEverythingExceptPersistentParameters(CompositeAction action, Component component) {
		val necessaryNames = newHashSet
		for (port : component.allConnectedSimplePorts) {
			val statechart = port.containingStatechart
			val instance = statechart.referencingComponentInstance
			for (eventDeclaration : port.allEventDeclarations) {
				val event = eventDeclaration.event
				if (event.persistency == Persistency.PERSISTENT) {
					for (parameter : event.parameterDeclarations) {
						necessaryNames += customizeInName(parameter, port, instance)
						necessaryNames += customizeOutName(parameter, port, instance)
					}
				}
			}
		}
		return action.reset(necessaryNames)
	}
	
	def bindEventsBoundToTheSameSystemPort(Action action, Component component) {
		val xSts = action.containingXSTS
		val xStsAssignmentActions = action.getAllContentsOfType(AssignmentAction)
		for (systemPort : component.allPorts) {
			val connectedSimplePorts = systemPort.allConnectedSimplePorts
			val size = connectedSimplePorts.size
			if (size > 1) {
				// More than one bound simple port
				val orderedPorts = newHashMap
				for (port : connectedSimplePorts) {
					val statechart = port.containingStatechart
					val instance = statechart.referencingComponentInstance
					val index = instance.index
					orderedPorts.put(index, port)
				}
				// Ports are ordered now, and the algorithm is based on the fact that the in-event actions of components are in ORDER 
				val firstPort = orderedPorts.get(0)
				val firstSatechart = firstPort.containingStatechart
				val firstInstance = firstSatechart.referencingComponentInstance
				val firstEvents = firstPort.allEvents
				for (boundPort : orderedPorts.entrySet.reject[it.key == 0].map[it.value]) {
					val boundSatechart = boundPort.containingStatechart
					val boundInstance = boundSatechart.referencingComponentInstance
					val boundEvents = boundPort.inputEvents
					for (boundEvent : boundEvents) {
						val i = boundEvent.containingEventDeclaration.index
						val event = firstEvents.get(i)
						val xStsEventName = customizeInputName(event, firstPort, firstInstance)
						val xStsEventVariable = xSts.getVariable(xStsEventName)
						val parameters = event.parameterDeclarations
						val xStsBoundEventName = customizeInputName(boundEvent, boundPort, boundInstance)
						val xStsBoundEventVariable = xSts.getVariable(xStsBoundEventName)
						for (xStsAssignment : xStsAssignmentActions
								.filter[it.lhs.declaration === xStsBoundEventVariable]) {
							// "Binding" the variable 
							xStsAssignment.rhs = createReferenceExpression => [it.declaration = xStsEventVariable]
						}
						val boundParameters = boundEvent.parameterDeclarations
						for (var j = 0; j < boundParameters.size; j++) {
							val parameter = parameters.get(j)
							val xStsParameterName = customizeInName(parameter, firstPort, firstInstance)
							val xStsParameterVariable = xSts.getVariable(xStsParameterName)
							val boundParameter = boundParameters.get(j)
							val xStsBoundParameterName = customizeInName(boundParameter, boundPort, boundInstance)
							val xStsBoundParameterVariable = xSts.getVariable(xStsBoundParameterName)
							for (xStsAssignment : xStsAssignmentActions
									.filter[it.lhs.declaration === xStsBoundParameterVariable]) {
								// "Binding" the variable 
								xStsAssignment.rhs = createReferenceExpression => [it.declaration = xStsParameterVariable]
							}
						}
					}
				}
			}
		}
	}
	
	private def Action reset(CompositeAction action, Set<String> necessaryNames) {
		val xStsAssignments = newHashSet
		for (xStsAssignment : action.getAllContentsOfType(AssignmentAction)) {
			val declaration = xStsAssignment.lhs.declaration
			val name = declaration.name
			if (!necessaryNames.contains(name)) {
				// Resetting the variable if it is not led out to the system port
				val defaultExpression = declaration.type.defaultExpression
				xStsAssignment.rhs = defaultExpression
				xStsAssignments += xStsAssignment
			}
		}
		return createSequentialAction => [
			it.actions += xStsAssignments
		]
	}
	
	private def void delete(CompositeAction action, Set<String> necessaryNames) {
		val xStsSubactions = action.actions
		val copyXStsSubactions = newArrayList
		copyXStsSubactions += xStsSubactions
		for (xStsSubaction : copyXStsSubactions) {
			if (xStsSubaction instanceof AssignmentAction) {
				val name = xStsSubaction.lhs.declaration.name
				if (!necessaryNames.contains(name)) {
					// Deleting
					xStsSubactions -= xStsSubaction
				}
			}
			else if (xStsSubaction instanceof AssumeAction) {
				val variables = xStsSubaction.assumption.referredVariables
				if (!variables.exists[necessaryNames.contains(it.name)]) {
					// Deleting the assume action
					xStsSubactions -= xStsSubaction
				}
			}
			else if (xStsSubaction instanceof CompositeAction) {
				xStsSubaction.delete(necessaryNames)
			}
		}
	}
	
}