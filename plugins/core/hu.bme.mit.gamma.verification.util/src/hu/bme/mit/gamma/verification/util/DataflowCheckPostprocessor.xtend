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
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.util.Collection
import java.util.Map
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
	public static final String EXECUTED_TRANSITION_VAR_BEGINNING = "__id_"
	public static final String INJECTED_VAR_END = "_"
	public static final String DEF_DATAFLOW_VAR_BEGINNING = EXECUTED_TRANSITION_VAR_BEGINNING + "def_"
	public static final String USE_DATAFLOW_VAR_BEGINNING = EXECUTED_TRANSITION_VAR_BEGINNING + "use_"
	//
	protected final Collection<
			Entry<ComponentInstanceVariableReferenceExpression, Entry<EObject, EObject>>> defUses = newTreeSet([a, b | (a.key.instance.name + a.value.key.serialize + a.value.value.serialize).compareTo(b.key.instance.name + b.value.key.serialize + b.value.value.serialize)])
	protected final Collection<
			Entry<ComponentInstanceVariableReferenceExpression, Entry<EObject, EObject>>> uncoveredDefUses = newTreeSet([a, b | (a.key.instance.name + a.value.key.serialize + a.value.value.serialize).compareTo(b.key.instance.name + b.value.key.serialize + b.value.value.serialize)])
	//
	
	new(Component originalTopComponent) {
		this.originalTopComponent = originalTopComponent
	}
	
	override execute(Result result) {
		val res = result.result
		
		val property = result.property
		val defUse = property.parseDefUse
		
		val map = (res == ThreeStateBoolean.TRUE) ? defUses : uncoveredDefUses
		if (defUse !== null) {
			map += defUse
		}
		
		return null
	}
	
	override execute(ExecutionTrace trace) {
		return null // Nothing to process at this point
	}
	
	//
	
	protected def parseDefUse(StateFormula property) {
		val equalExpressions = property.getAllContentsOfType(EqualityExpression)
		val useExpression = equalExpressions.last
		
		val variableInstance = useExpression.leftOperand as ComponentInstanceVariableReferenceExpression
		val id = useExpression.rightOperand
		
		val instance = variableInstance.instance
		val synchronousInstance = instance.lastInstance as SynchronousComponentInstance
		val useVariable = variableInstance.variableDeclaration
		val useVariableName = useVariable.name
		
		val statechart = instance.lastInstance.getStatechart
		var allStates = statechart.allStates
		var allTransitions = statechart.transitions
		var actions = allStates.map[it.entryActions + it.exitActions].flatten +
				allTransitions.map[it.effects].flatten
			
		val assignmentStatements = actions.map[it.getSelfAndAllContentsOfType(AssignmentStatement)].flatten.toSet
		val executedUseActions = assignmentStatements.filter[it.lhs.declaration.helperEquals(useVariable)]
		if (executedUseActions.empty) {
			return null
		}
		
		val executedUseAction = executedUseActions.onlyElement // 'use = def'
		val useRhs = executedUseAction.rhs
		val useStateOrTransition = executedUseAction.containingTransitionOrState
		
		val executedDefActions = assignmentStatements.filter[it.lhs.helperEquals(useRhs) && it.rhs.helperEquals(id)]
		if (executedDefActions.empty) {
			return null
		}
		
		val executedDefAction = executedDefActions.onlyElement // 'def = id'
		val defStateOrTransition = executedDefAction.containingTransitionOrState
				
//		val defAction = executedDefAction?.previous as AssignmentStatement
//		val declaration = defAction?.lhs.declaration

		val lastI = javaUtil.lastBeforeLastIndexOf(useVariableName, INJECTED_VAR_END)
		val variableName = useVariableName.substring(USE_DATAFLOW_VAR_BEGINNING.length, lastI)
		val variable = statechart.variableDeclarations.findFirst[it.name == variableName]
		
		// Back-annotation
		
		val originalInstance = synchronousInstance.getOriginalSimpleInstanceReference(originalTopComponent)
		val originalVariable = originalInstance.getOriginalVariable(variable)
		val originalVariableInstance = originalInstance.createVariableReference(originalVariable)
		val originalDef = originalInstance.getOriginalStateOrTransition(defStateOrTransition)
		val originalUse = originalInstance.getOriginalStateOrTransition(useStateOrTransition)
		
		return Map.entry(originalVariableInstance,
				Map.entry(originalDef, originalUse))
	}
	
	//
	
	def getCoveredDefUses() {
		return defUses
	}
	
	def getUncoveredDefUses() {
		return uncoveredDefUses
	}
	
}