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

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Persistency
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.CompositeAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.MultiaryAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import java.util.Set

import static hu.bme.mit.gamma.xsts.transformation.util.Namings.*

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class EnvironmentalActionFilter {
	// Singleton
	public static final EnvironmentalActionFilter INSTANCE =  new EnvironmentalActionFilter
	protected new() {}
	// Auxiliary objects
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension XSTSModelFactory xStsModelFactory = XSTSModelFactory.eINSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	
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
					necessaryNames += customizeInNames(parameter, port, instance)
					if (event.persistency == Persistency.TRANSIENT) {
						// If event is transient, than the original resetting of the variable has to be KEPT
						necessaryNames += customizeOutNames(parameter, port, instance)
					}
				}
			}
		}
		// Clock variable settings are retained too - not necessary as the timeouts are in the merged action now
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
						necessaryNames += customizeInNames(parameter, port, instance)
						necessaryNames += customizeOutNames(parameter, port, instance)
					}
				}
			}
		}
		return action.reset(necessaryNames)
	}
	
	def createEventAndParameterAssignmentsBoundToTheSameSystemPort(XSTS xSts, Component component) {
		val xStsAssignments = newArrayList
		xStsAssignments += xSts.createEventAssignmentsBoundToTheSameSystemPort(component)
		xStsAssignments += xSts.createParameterAssignmentsBoundToTheSameSystemPort(component)
		return xStsAssignments
	}
	
	def createEventAssignmentsBoundToTheSameSystemPort(XSTS xSts, Component component) {
		val extension EventReferenceToXstsVariableMapper mapper = new EventReferenceToXstsVariableMapper(xSts)
		val xStsAssignments = newArrayList
		for (systemPort : component.allPorts) {
			for (inEvent : systemPort.inputEvents) {
				val xStsInEventVariables = inEvent.getInputEventVariables(systemPort)
				if (xStsInEventVariables.size > 1) {
					val firstXStsInEventVariable = xStsInEventVariables.head
					for (otherXStsInEventVariable : xStsInEventVariables.reject[it === firstXStsInEventVariable]) {
						xStsAssignments += createAssignmentAction => [
							it.lhs = otherXStsInEventVariable.createReferenceExpression
							it.rhs = firstXStsInEventVariable.createReferenceExpression
						]
					}
				}
			}
		}
		return xStsAssignments
	}
	
	def createParameterAssignmentsBoundToTheSameSystemPort(XSTS xSts, Component component) {
		val extension EventReferenceToXstsVariableMapper mapper = new EventReferenceToXstsVariableMapper(xSts)
		val xStsAssignments = newArrayList
		for (systemPort : component.allPorts) {
			for (inEvent : systemPort.inputEvents) {
				val xStsInEventVariables = inEvent.getInputEventVariables(systemPort)
				if (xStsInEventVariables.size > 1) {
					for (parameter : inEvent.parameterDeclarations) {
						val xStsParameterVariables = parameter.getInputParameterVariables(systemPort)
						val firstXStsParameterVariable = xStsParameterVariables.head
						for (otherXStsParameterVariable : xStsParameterVariables
								.reject[it === firstXStsParameterVariable]) {
							xStsAssignments += createAssignmentAction => [
								it.lhs = otherXStsParameterVariable.createReferenceExpression
								it.rhs = firstXStsParameterVariable.createReferenceExpression
							]
						}
					}
				}
			}
		}
		return xStsAssignments
	}
	
	def void removeNonDeterministicActionsReferencingAssignedVariables(
			Collection<AssignmentAction> variables, Action root) {
		val assignedVariables = variables.map[(it.lhs as DirectReferenceExpression).declaration]
			.filter(VariableDeclaration).toSet
		assignedVariables.removeNonDeterministicActionsReferencingVariables(root)
	}
	
	def void removeNonDeterministicActionsReferencingVariables(
			Collection<VariableDeclaration> variables, Action root) {
		val references = root.getAllContentsOfType(DirectReferenceExpression).filter[
				variables.contains(it.declaration)]
		val choices = references.map[it.getContainerOfType(NonDeterministicAction)]
				.filterNull // If something is not contained by NonDeterministicAction
				.toSet
		for (choice : choices) {
			choice.remove
		}
	}
	
	private def Action reset(CompositeAction action, Set<String> necessaryNames) {
		val xStsAssignments = newHashSet
		for (xStsAssignment : action.getAllContentsOfType(AbstractAssignmentAction)) {
			val declaration = (xStsAssignment.lhs as DirectReferenceExpression).declaration as VariableDeclaration
			val name = declaration.name
			if (!necessaryNames.contains(name)) {
				// Resetting the variable
				val defaultExpression = declaration.defaultExpression
				xStsAssignments += declaration.createAssignmentAction(defaultExpression)
			}
		}
		return createSequentialAction => [
			it.actions += xStsAssignments
		]
	}
	
	private def void delete(CompositeAction action, Set<String> necessaryNames) {
		val copyXStsSubactions = newArrayList
		if (action instanceof LoopAction) {
			copyXStsSubactions += action.action
		}
		else {
			val xStsMultiaryAction = action as MultiaryAction
			copyXStsSubactions += xStsMultiaryAction.actions
		}
		for (xStsSubaction : copyXStsSubactions) {
			if (xStsSubaction instanceof AbstractAssignmentAction) {
				val name = (xStsSubaction.lhs as DirectReferenceExpression).declaration.name
				if (!necessaryNames.contains(name)) {
					// Deleting
					createEmptyAction.replace(xStsSubaction) // Remove might leave a null in LoopAction
				}
			}
			else if (xStsSubaction instanceof AssumeAction) {
				val assumption = xStsSubaction.assumption
				val variables = assumption.referredVariables
				if (!variables.exists[necessaryNames.contains(it.name)]) {
					// Deleting the assume action
					createEmptyAction.replace(xStsSubaction)
				}
			}
			else if (xStsSubaction instanceof CompositeAction) {
				xStsSubaction.delete(necessaryNames)
			}
		}
	}
	
}