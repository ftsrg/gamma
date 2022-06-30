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
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.lowlevel.xsts.transformation.VariableGroupRetriever
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class SystemReducer {
	// Singleton
	public static final SystemReducer INSTANCE =  new SystemReducer
	protected new() {}
	// Auxiliary objects
	protected final extension VariableGroupRetriever variableGroupRetriever = VariableGroupRetriever.INSTANCE
	protected final extension GammaEcoreUtil expressionUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE
	protected final extension XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE
	
	// TODO Introduce EventReferenceToXstsVariableMapper
	
	def void deleteUnusedPorts(XSTS xSts, CompositeComponent component) {
		// In theory, only AssignmentAction would be enough, still we use AbstractAssignmentAction to be sure
		val xStsAssignmentActions = xSts.getAllContentsOfType(AbstractAssignmentAction) // Caching
		val xStsDefaultableVariables = newHashSet
		val xStsDeletableVariables = newHashSet
		val xStsDeletableAssignmentActions = newHashSet
		for (instance : component.derivedComponents) {
			for (instancePort : instance.unusedPorts) {
				// In events on required port
				for (inputEvent : instancePort.inputEvents) {
					val inEventName = inputEvent.customizeInputName(instancePort, instance)
					val xStsInEventVariable = xSts.getVariable(inEventName)
					if (xStsInEventVariable !== null) {
						xStsDefaultableVariables += xStsInEventVariable
						xStsDeletableVariables += xStsInEventVariable
						xStsDeletableAssignmentActions += xStsInEventVariable.getAssignments(xStsAssignmentActions)
						// In-parameters
						for (parameter : inputEvent.parameterDeclarations) {
							val inParamaterNames = parameter.customizeInNames(instancePort, instance)
							val xStsInParameterVariables = xSts.getVariables(inParamaterNames)
							if (!xStsInParameterVariables.nullOrEmpty) {
								xStsDefaultableVariables += xStsInParameterVariables
								xStsDeletableVariables += xStsInParameterVariables
								xStsDeletableAssignmentActions += xStsInParameterVariables
										.getAssignments(xStsAssignmentActions)
							}
						}
					}
				}
				for (outputEvent : instancePort.outputEvents) {
					val outEventName = outputEvent.customizeOutputName(instancePort, instance)
					val xStsOutEventVariable = xSts.getVariable(outEventName)
					if (xStsOutEventVariable !== null) {
						xStsDeletableVariables += xStsOutEventVariable
						xStsDeletableAssignmentActions += xStsOutEventVariable.getAssignments(xStsAssignmentActions)
						// Out-parameters
						for (parameter : outputEvent.parameterDeclarations) {
							val outParamaterNames = parameter.customizeOutNames(instancePort, instance)
							val xStsOutParameterVariables = xSts.getVariables(outParamaterNames)
							if (!xStsOutParameterVariables.nullOrEmpty) {
								xStsDeletableVariables += xStsOutParameterVariables
								xStsDeletableAssignmentActions += xStsOutParameterVariables.getAssignments(xStsAssignmentActions)
							}
						}
					}
				}
			}
		}
		// Assignment removal is before falsification, as ReferenceExpressions
		// can be placed inside assignment actions, and the other way around,
		// cast exceptions are thrown!
		for (xStsDeletableAssignmentAction : xStsDeletableAssignmentActions) {
			xStsDeletableAssignmentAction.remove // To speed up the process
		}
		// Deleting references to the input event variables in guards
		// before variable removal as references must be present here
		val xStsDirectReferenceExpressions = xSts.getAllContentsOfType(DirectReferenceExpression)
		for (xStsDefaultableVariable : xStsDefaultableVariables) {
			val references = xStsDirectReferenceExpressions
					.filter[it.declaration === xStsDefaultableVariable]
			for (reference : references) {
				val defaultExpression = xStsDefaultableVariable.defaultExpression
				defaultExpression.replace(reference)
			}
		}
		for (xStsDeletableVariable : xStsDeletableVariables) {
			xStsDeletableVariable.delete // Delete needed due to e.g., transientVariables list
		}
	}
	
	def void deleteUnusedWrittenOnlyVariables(XSTS xSts,
			Collection<? extends VariableDeclaration> keepableVariables) { // Unfolded Gamma variables
		val mapper = new ReferenceToXstsVariableMapper(xSts)
		
		val xStsKeepableVariables = newLinkedList
		for (keepableVariable : keepableVariables) {
			xStsKeepableVariables += mapper.getVariableVariables(keepableVariable)
		}
		
		for (var i = 0; i < 2; i++) { // Twice, to support transition-pair coverage
			val xStsPlainVariables = xSts.plainVariableGroup.variables
			val xStsDeleteableWrittenOnlyVariables = xSts.writtenOnlyVariables
			xStsDeleteableWrittenOnlyVariables.retainAll(
					xStsPlainVariables) // So that only plain variables are deleted, not out events
			xStsDeleteableWrittenOnlyVariables -= xStsKeepableVariables
			val xStsDeletableAssignments = xStsDeleteableWrittenOnlyVariables.getAssignments(xSts)
			
			for (xStsDeletableAssignmentAction : xStsDeletableAssignments) {
				createEmptyAction.replace(
					xStsDeletableAssignmentAction) // To avoid nullptrs
			}
			
			for (xStsDeletableVariable : xStsDeleteableWrittenOnlyVariables) {
				xStsDeletableVariable.delete // Delete needed due to e.g., transientVariables list
			}
		}
	}
	
}