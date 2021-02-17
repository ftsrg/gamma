/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import java.util.List
import java.util.Map
import org.eclipse.xtend.lib.annotations.Data

class VariableInliner {
	// Singleton
	public static final VariableInliner INSTANCE =  new VariableInliner
	protected new() {}
	//
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE

	def inline(Action action) {
		action.inline(newHashMap, newHashMap)
	}
	
	// The concreteValues and symbolicValues sets are disjunct!
	
	protected def dispatch void inline(Action action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		throw new IllegalArgumentException
	}
	
	protected def dispatch void inline(EmptyAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		// Nop
	}
	
	protected def dispatch void inline(SequentialAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val subactions = newArrayList
		subactions += action.actions
		for (subaction : subactions) {
			subaction.inline(concreteValues, symbolicValues)
		}
	}
	
	protected def dispatch void inline(NonDeterministicAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val branchConcreteValueList = newArrayList
		val branchSymbolicValueList = newArrayList
		val subactions = newArrayList
		subactions += action.actions
		for (branch : subactions) {
			val branchConcreteValues = newHashMap
			branchConcreteValues += concreteValues
			// The action removing approach for symbolic maps CAN be used via choices,
			// as the oldAssignment in 'inline(AssignmentAction ...' is NOT removed
			val branchSymbolicValues = newHashMap
//			branchSymbolicValues += symbolicValues
			// The action removing approach for symbolic maps CANNOT be used via choices,
			// e.g., 'a := 1; if (...) { a := a + 1; } else { b := 2; } c := a + 3;'

			// New maps
			branch.inline(branchConcreteValues, branchSymbolicValues)
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
	
	protected def dispatch void inline(AssignmentAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val rhs = action.rhs
		rhs.inlineVariables(concreteValues)
		val lhs = action.lhs
		if (lhs instanceof DirectReferenceExpression) {
			val declaration = lhs.declaration
			if (declaration instanceof VariableDeclaration) {
				val references = rhs.getSelfAndAllContentsOfType(ReferenceExpression)
				if (references.empty) { // So it is evaluable
					// If the oldAssignment is NOT removed, then concrete maps can 
					// fall through validly through different choices???
//					if (concreteValues.containsKey(declaration)) {
//						val oldEntry = concreteValues.get(declaration)
//						val oldAssignment = oldEntry.getLastValueGivingAction
//						oldAssignment.remove
//					}
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
						val oldAssignment = oldSymbolicEntry.getLastValueGivingAction
						oldAssignment.remove
					}
					// Removing read variables - if a variable is read, then the
					// oldAssignment (see previous if) must not be removed
					symbolicValues.deleteReferencedVariables(rhs)
					
					symbolicValues += declaration -> new InlineEntry(rhs, action)
					concreteValues -= declaration
				}
			}
		}
	}
	
	protected def dispatch void inline(AssumeAction action,
			Map<VariableDeclaration, InlineEntry> concreteValues,
			Map<VariableDeclaration, InlineEntry> symbolicValues) {
		val assumption = action.assumption
		assumption.inlineVariables(concreteValues) // Only concrete values
		// Removing read variables - if a variable is read, then the
		// oldAssignment (see AssignmentAction inline) must not be removed
		symbolicValues.deleteReferencedVariables(assumption)
					
	}
	
	// Auxiliary
	
	protected def commonizeMaps(List<? extends Map<VariableDeclaration, InlineEntry>> branchValueList) {
		// Calculating variables present in all branches
		val commonVariables = newHashSet
		for (branchValues : branchValueList) {
			val branchVariables = branchValues.keySet
			if (commonVariables.empty) {
				commonVariables += branchVariables
			}
			else {
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
		return newBranchValues
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
	
	protected def deleteReferencedVariables(Map<? super VariableDeclaration, InlineEntry> values,
			Expression expression) {
		val references = expression.getSelfAndAllContentsOfType(DirectReferenceExpression)
		val variables = references.map[it.declaration]
		values.keySet -= variables
	}
	
	@Data
	static class InlineEntry {
		Expression value
		AssignmentAction lastValueGivingAction
	}
	
}