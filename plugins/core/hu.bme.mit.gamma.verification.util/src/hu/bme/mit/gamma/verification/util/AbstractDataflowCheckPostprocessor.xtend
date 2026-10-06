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

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.util.Collection
import java.util.Map
import java.util.Map.Entry
import org.eclipse.emf.ecore.EObject

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

abstract class AbstractDataflowCheckPostprocessor extends VerificationPostprocessor {
	//
	protected final Component originalTopComponent
	//
	public static final String EXECUTED_TRANSITION_VAR_BEGINNING = "__id_"
	public static final String INJECTED_VAR_END = "_"
	public static final String USE_DATAFLOW_VAR_BEGINNING = EXECUTED_TRANSITION_VAR_BEGINNING + "use_"
	//
	protected final Collection<
			Entry<ComponentInstanceElementReferenceExpression, Entry<EObject, EObject>>> defUses = newTreeSet([a, b | (a.key.instance.name + a.value.key.serialize + a.value.value.serialize).compareTo(b.key.instance.name + b.value.key.serialize + b.value.value.serialize)])
	protected final Collection<
			Entry<ComponentInstanceElementReferenceExpression, Entry<EObject, EObject>>> uncoveredDefUses = newTreeSet([a, b | (a.key.instance.name + a.value.key.serialize + a.value.value.serialize).compareTo(b.key.instance.name + b.value.key.serialize + b.value.value.serialize)])
	//
	
	new(Component originalTopComponent) {
		this.originalTopComponent = originalTopComponent
	}
	
	override execute(Result result) {
		val res = result.result
		
		val property = result.property
		val defUse = property.parseDefUse
		
		val unknownDefUses = newHashSet
		
		val map = (res == ThreeStateBoolean.TRUE) ? defUses :
				(res == ThreeStateBoolean.FALSE) ? uncoveredDefUses :
				unknownDefUses
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
		var allEffects = statechart.allEffects
		
		val assignmentStatements = allEffects.map[it.getSelfAndAllContentsOfType(AssignmentStatement)].flatten.toSet
		val executedUseActions = assignmentStatements.filter[it.lhs.declaration.helperEquals(useVariable)]
		if (executedUseActions.empty) {
			return null // TODO procedures
		}
		
		val executedUseAction = executedUseActions.onlyElement // 'use = def'
		val useRhs = executedUseAction.rhs
		val useStateOrTransition = executedUseAction.containingTransitionOrState
		
		val executedDefAction = statechart.filterDefAction(useRhs, id)  // 'def = id'
		if (executedDefAction === null) {
			return null
		}
		
		val defStateOrTransition = executedDefAction.containingTransitionOrState
		val defInstance = defStateOrTransition.containingStatechart.referencingComponentInstance as SynchronousComponentInstance
		val originalDefInstance = defInstance.getOriginalSimpleInstanceReference(originalTopComponent)
		
		val originalUseInstance = synchronousInstance.getOriginalSimpleInstanceReference(originalTopComponent)
		val originalDeclarationInstance = originalUseInstance.createDeclarationReference(statechart, useVariableName)
		
		val originalDef = originalDefInstance.getOriginalStateOrTransition(defStateOrTransition)
		val originalUse = originalUseInstance.getOriginalStateOrTransition(useStateOrTransition)
		
		return Map.entry(originalDeclarationInstance,
				Map.entry(originalDef, originalUse))
	}
	
	//
	
	protected abstract def Action filterDefAction(StatechartDefinition statechart, Expression useRhs, Expression id)
	protected abstract def ComponentInstanceElementReferenceExpression createDeclarationReference(ComponentInstanceReferenceExpression originalInstance, StatechartDefinition statechart, String useVariableName)
	
	//
	
	def getCoveredDefUses() {
		return defUses
	}
	
	def getUncoveredDefUses() {
		return uncoveredDefUses
	}
	
	//
	
	override toString() '''
		Coverable def-uses:
			«FOR defUse : defUses»
				«defUse.print»
			«ENDFOR»
		Uncoverable def-uses:
			«FOR defUse : uncoveredDefUses»
				«defUse.print»
			«ENDFOR»
	'''
	
	protected def print(Entry<ComponentInstanceElementReferenceExpression, Entry<EObject, EObject>> defUse) '''
		«defUse.key.printElementReference»: «defUse.value.key.serialize» -d-u-o) «defUse.value.value.serialize»
	'''
	
}