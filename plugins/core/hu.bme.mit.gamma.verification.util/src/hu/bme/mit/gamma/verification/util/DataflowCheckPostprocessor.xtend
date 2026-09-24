/********************************************************************************
 * Copyright (c) 2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.util.Collection
import java.util.List
import java.util.Map.Entry
import org.eclipse.emf.ecore.EObject

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class DataflowCheckPostprocessor extends VerificationPostprocessor {
	//
	protected final Component originalTopComponent
	//
	public static final String metadataBeginning = "Variable "
	public static final String metadataUsedBy = "used by"
	public static final String metadataDefBy = "as last defined by"
	public static final String OF = "of"
	//
	protected final List<Collection<? extends
			Entry<ComponentInstanceVariableReferenceExpression, Entry<EObject, EObject>>>> defUses = newArrayList
	protected final List<Collection<? extends
			Entry<ComponentInstanceVariableReferenceExpression, Entry<EObject, EObject>>>> uncoveredDefUses = newArrayList
	
	//
	
	new(Component originalTopComponent) {
		this.originalTopComponent = originalTopComponent
	}
	
	override execute(Result result) {
		val res = result.result
		
		var ComponentInstanceVariableReferenceExpression defUse = null
		if (res == ThreeStateBoolean.TRUE) {
//			// Knowing the structure of the property
//			val property = result.property
//			state = property.parseDefUse
//			
//			val originalState = state.getOriginal(originalTopComponent)
//			
//			defUses += originalState
		}
		
		return null
	}
	
	override execute(ExecutionTrace trace) {
		return null // Nothing to process at this point
	}
	
	//
	
	protected def parseDefUse(ExecutionTrace trace, StateFormula property) {
		val equalExpressions = property.getAllContentsOfType(EqualityExpression)
		val useExpression = equalExpressions.last
		
		val variableInstance = useExpression.leftOperand as ComponentInstanceVariableReferenceExpression
		val id = useExpression.rightOperand
		
		val instance = variableInstance.instance
		val instanceName = instance.name
		val useVariable = variableInstance.variableDeclaration
		
		val statechart = instance.lastInstance.getStatechart
		var allStates = statechart.allStates
		var allTransitions = statechart.transitions
		var actions = allStates.map[it.entryActions + it.exitActions].flatten +
				allTransitions.map[it.effects].flatten
				
		val assignmentStatements = actions.map[it.getSelfAndAllContentsOfType(AssignmentStatement)].flatten.toSet
		
		val executedUseActions = assignmentStatements.filter[it.lhs.declaration.helperEquals(useVariable)]
		val executedUseAction = executedUseActions.onlyElement // 'use = def'
		val useRhs = executedUseAction.rhs
		val useStateOrTransition = executedUseAction.containingTransitionOrState
		
		val executedDefActions = assignmentStatements.filter[it.lhs.helperEquals(useRhs) && rhs.helperEquals(id)]
		val executedDefAction = executedDefActions.onlyElement // 'def = id'
		val defStateOrTransition = executedUseAction.containingTransitionOrState
		
		val defAction = executedDefAction.previous as AssignmentStatement
		val declaration = defAction.lhs.declaration
		
		// Back-annotation
		
		val originalInstances = trace.steps.map[it.asserts].flatten
				.filter(ComponentInstanceElementReferenceExpression)
				.map[it.instance]
		
		val originalInstance = originalInstances.findFirst[it.name == instanceName].clone
		val originalStatechart = originalInstance.lastInstance.getStatechart
		val originalVariable = originalStatechart.variables.findFirst[it.name == declaration.name]
		
		val checkVariableInstance = originalInstance.createVariableReference(originalVariable)
	}
	
	//
	
	def getCoveredDefUses() {
		return defUses
	}
	
	def getAllCoveredDefUses() {
		return defUses.flatten
	}
	
	def getUncoveredDefUses() {
		return uncoveredDefUses
	}
	
	def getAllUncoveredDefUses() {
		return uncoveredDefUses.flatten
	}
	
}