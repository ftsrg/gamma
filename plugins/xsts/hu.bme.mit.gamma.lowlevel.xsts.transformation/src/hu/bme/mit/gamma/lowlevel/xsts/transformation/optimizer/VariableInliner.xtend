/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer

import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction
import hu.bme.mit.gamma.xsts.model.XTransition
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.List
import java.util.Map
import org.eclipse.xtend.lib.annotations.Data

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class VariableInliner {
	// Singleton
	public static final VariableInliner INSTANCE =  new VariableInliner
	protected new() {}
	//
	
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	//

	def inline(Iterable<? extends XTransition> transitions) {
		for (transition : transitions) {
			transition.inline
		}
	}

	def inline(XTransition transition) {
		transition.action.inline
	}
	
	def inline(Action action) {
		action.inline(null)
	}

	def inline(Action action, Action context) {
		val concreteValues = newHashMap
		val symbolicValues = newHashMap
		
		if (!context.nullOrEmptyAction) {
			// Filling the maps with the context
			context.inline(concreteValues, symbolicValues)
		}
		
		action.inline(concreteValues, symbolicValues)
	}
	
	// The concreteValues and symbolicValues sets are disjunct!
	
	protected def dispatch void inline(Action action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		throw new IllegalArgumentException("Not supported action: " + action)
	}
	
	protected def dispatch void inline(EmptyAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		// Nop
	}
	
	protected def dispatch void inline(HavocAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val writtenVariables = action.writtenVariables
				
		concreteValues.keySet -= writtenVariables
		symbolicValues.keySet -= writtenVariables
	}
	
	protected def dispatch void inline(LoopAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val subaction = action.action
		val writtenVariables = subaction.writtenVariables // 
		concreteValues.keySet -= writtenVariables
		symbolicValues.keySet -= writtenVariables
		// Due to the iterations, we do not know the values for variables written inside the loop
		
		val newConcreteValues = newHashMap
		val newSymbolicValues = newHashMap
		newConcreteValues += concreteValues
		newSymbolicValues += symbolicValues
		
		subaction.inline(newConcreteValues, newSymbolicValues)
		// Returning the original maps from which the written variables were removed
	}
	
	protected def dispatch void inline(IfAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val conditions = action.conditions
		val size = conditions.size
		val actions = action.branches
		
		val branches = newArrayList
		
		var i = 0
		for (; i < size; i++) {
			branches += conditions.get(i) -> actions.get(i)
		}
		if (i < actions.size) {
			checkState(i + 1 == actions.size)
			branches += null -> actions.get(i)
		}
		
		branches.inlineBranches(concreteValues, symbolicValues)
	}
	
	protected def dispatch void inline(SequentialAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val subactions = newArrayList
		subactions += action.actions
		
		// "Ad hoc" inline for symbolic values to tackle the following pattern
		// local var a : integer = b + 1;
		// c := a; "or" local var c := a; // Unnecessary 'a' local variable if it is not referenced later
		subactions.inlineLocalVariablesAndAssignmentsIntoSubsequentAssignments
		//
		
		for (subaction : subactions) {
			subaction.inline(concreteValues, symbolicValues)
		}
	}
	
	protected def dispatch void inline(ParallelAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val writtenVariables = action.writtenVariables
		
		concreteValues.keySet -= writtenVariables
		symbolicValues.keySet -= writtenVariables
		
		val subactions = newArrayList
		subactions += action.actions
		for (subaction : subactions) {
			subaction.inline(concreteValues, symbolicValues)
		}
		
		concreteValues.keySet -= writtenVariables
		symbolicValues.keySet -= writtenVariables
	}
	
	protected def dispatch void inline(NonDeterministicAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val branches = <Pair<Expression, Action>>newArrayList
		for (branch : action.actions) {
			branches += null -> branch // Branch contains the conditions
		}
		
		branches.inlineBranches(concreteValues, symbolicValues)
	}
	
	protected def dispatch void inline(AssumeAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val assumption = action.assumption
		assumption.inlineExpression(concreteValues, symbolicValues)
	}
	
	protected def dispatch void inline(AssignmentAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val rhs = action.rhs
		rhs.inlineVariables(concreteValues)
		val lhs = action.lhs
		if (lhs instanceof DirectReferenceExpression) {
			val declaration = lhs.declaration
			if (declaration instanceof VariableDeclaration) {
				declaration.handleMaps(action, rhs, concreteValues, symbolicValues)
			}
		}
		else if (lhs instanceof ArrayAccessExpression) {
			val index = lhs.index
			index.inlineExpression(concreteValues, symbolicValues)
		}
	}
	
	protected def dispatch void inline(VariableDeclarationAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val variable = action.variableDeclaration
		val rhs = variable.expression
		rhs?.inlineVariables(concreteValues)
		if (rhs !== null) {
			variable.handleMaps(action, rhs, concreteValues, symbolicValues)
		}
	}
	
	private def handleMaps(VariableDeclaration declaration,
			Action action, Expression rhs,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		if (rhs.isEvaluable) { // So it is evaluable
			// If the oldAssignment is NOT removed, then concrete maps can fall through
			// validly through different choices. So oldAssignment must NOT be removed.
			
			// Adding this new value
			concreteValues += declaration -> new InlineEntry(rhs, action)
			symbolicValues -= declaration
		}
		else {
			if (symbolicValues.containsKey(declaration)) {
				val oldSymbolicEntry = symbolicValues.get(declaration)
				// Only this single value can be inlined
				val singletonMap = #{declaration -> oldSymbolicEntry}
				rhs.inlineVariables(singletonMap)
				// Removing old assignment action due to the priming problem
				// Can be removed as in the NonDet branch, symbolic maps are cleared
				
				val oldAssignment = oldSymbolicEntry.getLastValueGivingAction
				if (oldAssignment instanceof AssignmentAction) {
					// Local variable declarations actions cannot be deleted 
					oldAssignment.replaceWithEmptyAction
				}
			}
			// Removing read variables - if a variable is read, then the
			// oldAssignment (see previous if) must not be removed
			symbolicValues.deleteReferencedVariableKeys(rhs)
			
			symbolicValues += declaration -> new InlineEntry(rhs, action)
			concreteValues -= declaration
		}
	}
	
	//
	
	protected def inlineLocalVariablesAndAssignmentsIntoSubsequentAssignments(List<? extends Action> actions) {
		val removableActions = newArrayList
		// The remaining local VariableDeclarationActions are not removed;
		// it is done separately by RemovableVariableRemover.removeTransientVariables
		for (var i = 0; i < actions.size - 1; i++) {
			val first = actions.get(i)
			val second = actions.get(i + 1) // Subsequent actions
			
			if (first instanceof VariableDeclarationAction) {
				val localVariable = first.variableDeclaration
				val localVariableValue = localVariable.expression
				
				if (second instanceof AssignmentAction || second instanceof VariableDeclarationAction) {
					val rhs = (second instanceof AssignmentAction) ? second.rhs : 
						(second instanceof VariableDeclarationAction) ? second.variableDeclaration.expression : null
					if (rhs !== null) { // Can be null e.g., in function call return objects
						for (reference : rhs.getSelfAndAllContentsOfType(DirectReferenceExpression)) {
							val rhsDeclaration = reference.declaration
							
							if (rhsDeclaration === localVariable) {
								val clonedValue = localVariableValue.clone
								clonedValue.replace(reference)
							}
						}
					}
				}
			}
			
			else if (first instanceof AssignmentAction) {
				val firstLhs = first.lhs
				if (second instanceof AssignmentAction) {
					val secondLhs = second.lhs
					if (firstLhs.helperEquals(secondLhs)) {
						val secondRhs = second.rhs
						for (rhsContent : secondRhs.getSelfAndAllContentsOfType(firstLhs.class)) {
							if (rhsContent.helperEquals(firstLhs)) {
								val firstRhs = first.rhs
								val firstRhsClone = firstRhs.clone
								firstRhsClone.replace(rhsContent)
							}
						}
						// Remove first
						removableActions += first
					}
				}
			}
		}
		//
		removableActions.forEach[it.replaceWithEmptyAction]
	}
	
	// Auxiliary
	
	protected def commonizeMaps(List<? extends Map<VariableDeclaration, InlineEntry>> branchValueList) {
		// Calculating variables present in all branches
		val commonVariables = newHashSet
		for (var i = 0; i < branchValueList.size; i++) {
			val branchValues = branchValueList.get(i)
			val branchVariables = branchValues.keySet
			if (i <= 0) { // First addition
				commonVariables += branchVariables
			}
			else { // Then only retains
				commonVariables.retainAll(branchVariables)
			}
		}
		
		val newBranchValues = newHashMap
		val contradictingVariables = newHashSet
		for (branchValues : branchValueList) {
			for (variable : branchValues.keySet) {
				val entry = branchValues.get(variable)
				val value = entry.value
				if (commonVariables.contains(variable)) {
					if (!newBranchValues.containsKey(variable)) {
						// First entry
						newBranchValues += variable -> entry
					}
					else {
						val newEntry = newBranchValues.get(variable)
						val newValue = newEntry.value
						if (!value.helperEquals(newValue)) {
							// "Contradiction" in different branches
							contradictingVariables += variable
						}
					}
				}
			}
		}
		// Removing variables whose value is unknown
		newBranchValues.keySet -= contradictingVariables
		// Removing variables referring to variables whose value is unknown
		val newEntries = newBranchValues.entrySet
		newEntries.removeIf[
			val referredVariables = newHashSet
			val expression = it.value.value
			referredVariables += expression.referredVariables
			referredVariables.retainAll(contradictingVariables)
			!referredVariables.isEmpty
		]
		
		return newBranchValues
	}
	
	protected def void inlineBranches(List<Pair<Expression, Action>> branches,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val branchConcreteValueList = newArrayList
		val branchSymbolicValueList = newArrayList
		for (branch : branches) {
			val branchConcreteValues = newHashMap
			branchConcreteValues += concreteValues
			// The action removing approach for concrete maps CAN be used via choices,
			// as the oldAssignment in 'inline(AssignmentAction ...' is NOT removed
			val branchSymbolicValues = newHashMap
			// The action removing approach for symbolic maps CANNOT be used via choices,
			// e.g., 'a := 1; if (...) { a := a + 1; } else { b := 2; } c := a + 3;'

			// New maps
			val condition = branch.key
			if (condition !== null) { // NonDet branches do not contain explicit conditions
				condition.inlineExpression(concreteValues, symbolicValues)
			}
			val action = branch.value
			action.inline(branchConcreteValues, branchSymbolicValues)
			// Saving the new maps
			branchConcreteValueList += branchConcreteValues
			branchSymbolicValueList += branchSymbolicValues
		}
		
		// "Commonizing" the values into a new map, that is,
		// deleting the values that we are not aware of anymore
		val commonizedConcreteValues = branchConcreteValueList.commonizeMaps
		val commonizedSymbolicValues = branchSymbolicValueList.commonizeMaps
		
		// Setting the maps
		concreteValues.clear
		concreteValues += commonizedConcreteValues
		symbolicValues.clear
		symbolicValues += commonizedSymbolicValues
	}
	
	protected def void inlineExpression(Expression expression,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		expression.inlineVariables(concreteValues) // Only concrete values
		// Removing read variables - if a variable is read, then the
		// oldAssignment (see AssignmentAction inline) must not be removed
		symbolicValues.deleteReferencedVariableKeys(expression)
	}
	
	protected def inlineVariables(Expression expression, Map<VariableDeclaration, InlineEntry> values) {
		val references = expression.getSelfAndAllContentsOfType(DirectReferenceExpression)
		for (variable : values.keySet) {
			val entry = values.get(variable)
			val value = entry.value
			for (reference : references.filter[it.declaration === variable]) {
				val clonedValue = value.clone // Cloning is important
				clonedValue.replace(reference)
			}
		}
	}
	
	protected def deleteReferencedVariableKeys(Map<? super VariableDeclaration, InlineEntry> values,
			Expression expression) {
		val references = expression.getSelfAndAllContentsOfType(DirectReferenceExpression)
		val variables = references.map[it.declaration]
		values.keySet -= variables
	}
	
	@Data
	static class InlineEntry {
		Expression value
		Action lastValueGivingAction
	}
	
}