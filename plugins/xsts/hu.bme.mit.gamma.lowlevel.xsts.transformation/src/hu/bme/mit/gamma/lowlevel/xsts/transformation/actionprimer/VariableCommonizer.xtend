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
package hu.bme.mit.gamma.lowlevel.xsts.transformation.actionprimer

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.MultiaryAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import java.util.Collection
import java.util.List
import java.util.Map

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class VariableCommonizer extends ActionPrimer {
	
	new() {
		super(true)
	}
	
	new(boolean inlinePrimedVariables) {
		super(inlinePrimedVariables)
	}
	
	override Action transform(Action action) {
		// Storing primed variables:
		// For each variable declaration in the map a list is stored which stores the primed variables.
		// At index "i" the variable declaration primed "i" times is stored. 
		// At index 0 the original variable is stored.
		val Map<VariableDeclaration, List<VariableDeclaration>> primedVariables = newHashMap
		action.primeAction(primedVariables, newHashMap, newHashMap)
		if (inlinePrimedVariables) {
			// In case of inline, assignments to intermediate prime variables are not needed
			// due to the inlining of the right hand side values during the priming operation
			action.deleteAssignmentActionsToNotAbsoluteHighestPrimeVariables(primedVariables)
		}
		// Deleting 'assume Normal == Normal' kind of assumptions
		action.deleteUnnecessaryAssumeActions
		// Deleting 'assume Normal == NotNormal' kind of branches
		action.deleteDeadBranches
		return action
	}
	
	// The index map stores the highest prime index of the variables on the particular branch, e.g.,
	// (var -> 3) means that variable var has been primed 3 times on the particular branch.
	// The values map stores the value (right hand side) of the highest prime variable.
	protected def dispatch void primeAction(AssignmentAction action,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			Map<VariableDeclaration, Integer> index, Map<VariableDeclaration, Expression> values) {
		action.primeVariable(primedVariables, index, values)
	}
	
	protected def dispatch void primeAction(AssumeAction action,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			Map<VariableDeclaration, Integer> index, Map<VariableDeclaration, Expression> values) {
		action.assumption = action.assumption.primeExpression(primedVariables, index, values)
	}
	
	protected def dispatch void primeAction(SequentialAction action,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			Map<VariableDeclaration, Integer> index, Map<VariableDeclaration, Expression> values) {
		val xStsSubactions = action.actions
		for (var i = 0; i < xStsSubactions.size; i++) {
			val xStsSubaction = xStsSubactions.get(i)
			xStsSubaction.primeAction(primedVariables, index, values)
		}
	}
	
	protected def dispatch void primeAction(NonDeterministicAction action,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			Map<VariableDeclaration, Integer> index, Map<VariableDeclaration, Expression> value) {
		val xStsSubactions = action.actions
		val indexes = newLinkedList
		val values = newLinkedList
		for (var i = 0; i < xStsSubactions.size; i++) {
			val Map<VariableDeclaration, Integer> indexSavings = newHashMap
			indexSavings += index // Saving the index map for each branch
			val Map<VariableDeclaration, Expression> valueSavings = newHashMap
			valueSavings += value // Saving the values map for each branch
			val xStsSubaction = xStsSubactions.get(i)
			xStsSubaction.primeAction(primedVariables, indexSavings, valueSavings)
			indexes += indexSavings
			values += valueSavings
		}
		// Commonizing based on the indexes in the maps
		val newMappings = action.commonizeNonDeterministicBranches(primedVariables, indexes, values)
		// Updating the index map with the new, commonized set of variables
		index += newMappings.key
		value += newMappings.value
	}
	
	protected def dispatch void primeAction(ParallelAction action,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			Map<VariableDeclaration, Integer> indexes, Map<VariableDeclaration, Expression> values) {
		throw new UnsupportedOperationException("Parallel actions are not yet supported")
	}
	
	
	/** Calculates the highest prime variables of the branches of the given NonDeterministicAction,
	 * creates and assignment action on every branch where it is needed, e.g., test' := 424; test'''' := test';
	 * (if test'''' is the highest prime variable) and returns the index and value maps that have to be
	 * used after the given NonDeterministicAction.
	 */
	protected def commonizeNonDeterministicBranches(NonDeterministicAction action,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			List<Map<VariableDeclaration, Integer>> indexes, List<Map<VariableDeclaration, Expression>> values) {
		checkState(indexes.size == values.size)
		val xStsSubactions = action.actions
		checkState(xStsSubactions.size == indexes.size)
		val size = xStsSubactions.size
		val maxIndex = newHashMap
		maxIndex += indexes.head
		val maxValue = newHashMap
		maxValue += values.head
		// Going from 1, as the initial values (head) have been added to the max maps
		for (var i = 1 ; i < size; i++) {
			val index = indexes.get(i)
			val value = values.get(i)
			checkState(index.size == value.size)
			for (entry : index.entrySet) {
				val variable = entry.key
				val primeCount = entry.value
				if (maxIndex.containsKey(variable)) {
					if (maxIndex.get(variable) < primeCount) {
						maxIndex.put(variable, primeCount)
						maxValue.put(variable, value.get(variable))
					}
				}
				else {
					maxIndex.put(variable, primeCount)
					maxValue.put(variable, value.get(variable))
				}
			}
		}
		// Max indexes and values have been calculated
		// Time for the commonization
		for (var i = 0; i < xStsSubactions.size; i++) {
			val index = indexes.get(i)
			val value = values.get(i)
			// Iterating through maxIndex instead of index, as ALL variables in each branch must be commonized
			for (variable : maxIndex.keySet) {
				// xStsSubaction needs to be retrieved in every iteration as a
				// xStsSubactions.set(i, newXStsAction) might set it again at the end of an iteration
				val xStsSubaction = xStsSubactions.get(i)
				val branchPrimeCount = if (index.containsKey(variable)) index.get(variable) else 0
				val maxPrimeCount = maxIndex.get(variable)
				val valueOfPrimedVariable = if (value.containsKey(variable)) {
						value.get(variable)
					}
					else {
						// No stored right hand side value in this branch, we refer to the original variable
						createDirectReferenceExpression => [it.declaration = variable]
					}
				if (branchPrimeCount < maxPrimeCount) {
					// Commonization action
					val newXStsAction = xStsSubaction.commonizeNonDeterministicBranch(variable, primedVariables,
						maxPrimeCount, branchPrimeCount, valueOfPrimedVariable)
					xStsSubactions.set(i, newXStsAction)
				}
			}
		}
		// Setting the right hand side values of the max values map to the max prime variable
		for (index : maxIndex.entrySet) {
			val variable = index.key
			val maxPrimeCount = index.value
			val primedVariable = primedVariables.get(variable).get(maxPrimeCount)
			maxValue.put(variable, createDirectReferenceExpression => [it.declaration = primedVariable])
		}
		// Returning the maps as the following actions have to be transformed based on these data
		return maxIndex -> maxValue
	}
	
	protected def dispatch commonizeNonDeterministicBranch(SequentialAction action, VariableDeclaration variable,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			int maxPrimeCount, int branchPrimeCount, Expression value) {
		// It is important for the later optimization that if xStsSubaction is a SequentialAction, then
		// we do not create another SequentialAction inside it but we add the new actions to the end
		action.actions += variable.createCommonizationAssignment(primedVariables, maxPrimeCount, branchPrimeCount, value)
		return action
	}
	
	protected def dispatch commonizeNonDeterministicBranch(Action action, VariableDeclaration variable,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			int maxPrimeCount, int branchPrimeCount, Expression value) {
		return createSequentialAction => [
			it.actions += action.clone // Clone is needed so the original list is not modified (see the set operation)
			it.actions += variable.createCommonizationAssignment(primedVariables, maxPrimeCount, branchPrimeCount, value)
		]
	}
	
	protected def createCommonizationAssignment(VariableDeclaration variable,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			int maxPrimeCount, int branchPrimeCount, Expression value) {
		return createAssignmentAction => [
			it.lhs = createDirectReferenceExpression => [
				it.declaration = primedVariables.get(variable).get(maxPrimeCount)
			]
			// Choice upon setting
			if (inlinePrimedVariables) {
				// In case of inline, we return the actual value of the given variable
				checkState(value !== null)
				it.rhs = value.clone
			}
			else {
				// We simply return a reference to the primed variable
				it.rhs = createDirectReferenceExpression => [
					it.declaration = primedVariables.get(variable).get(branchPrimeCount)
				]
			}
		]
	}
	
	// Deleting dead branches
	
	protected def dispatch void deleteDeadBranches(Action action) {
		// No operation
	}
	
	protected def dispatch void deleteDeadBranches(LoopAction action) {
		val xStsSubaction = action.action
		xStsSubaction.deleteDeadBranches
	}
	
	protected def dispatch void deleteDeadBranches(MultiaryAction action) {
		val xStsSubactions = action.actions
		for (var i = 0; i < xStsSubactions.size; i++) {
			val xStsSubaction = xStsSubactions.get(i)
			xStsSubaction.deleteDeadBranches
		}
	}
	
	protected def dispatch void deleteDeadBranches(NonDeterministicAction action) {
		val xStsSubactions = action.actions
		for (var i = 0; i < xStsSubactions.size; i++) {
			val xStsSubaction = xStsSubactions.get(i)
			if (xStsSubaction instanceof AssumeAction){
				if (xStsSubaction.definitelyFalseAssumeAction) {
					xStsSubactions.remove(i)
					i--
				}
			}
			else if (xStsSubaction instanceof SequentialAction) {
				if (xStsSubaction.actions.filter(AssumeAction)
						.exists[it.definitelyFalseAssumeAction]) {
					xStsSubactions.remove(i)
					i--
				}
				else {
					xStsSubaction.deleteDeadBranches
				}
			}
			else {
				xStsSubaction.deleteDeadBranches
			}
		}
	}
	
	// Action optimizer if only the assignments giving value to variables with the absolute highest prime are needed
	
	protected def void deleteAssignmentActionsToNotAbsoluteHighestPrimeVariables(Action action, 
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables) {
		val highestPrimeVariables = newHashSet
		for (primeVariableList : primedVariables.values) {
			highestPrimeVariables += primeVariableList.lastOrNull
		}
		action.deleteUnnecessaryAssignmentActions(highestPrimeVariables)
	}
	
	protected def dispatch void deleteUnnecessaryAssignmentActions(Action action,
			Collection<VariableDeclaration> readVariables) {
		// No operation
	}
	
	protected def dispatch void deleteUnnecessaryAssignmentActions(ParallelAction action,
			Collection<VariableDeclaration> readVariables) {
		throw new UnsupportedOperationException("Parallel actions are not yet supported: " + action)
	}
	
	protected def dispatch void deleteUnnecessaryAssignmentActions(NonDeterministicAction action,
			Collection<VariableDeclaration> readVariables) {
		val xStsSubactions = action.actions
		val newReadVariables = newHashSet
		for (var i = 0; i < xStsSubactions.size; i++) {
			val savedReadVariables = newHashSet
			savedReadVariables += readVariables
			// Saving the read variable set for each branch separately
			val xStsSubaction = xStsSubactions.get(i)
			xStsSubaction.deleteUnnecessaryAssignmentActions(savedReadVariables)
			// Collecting all read variables in each branch of the NonDeterministicAction
			newReadVariables += savedReadVariables
		}
		// Joining the read variable sets of each branch
		readVariables += newReadVariables
	}
	
	protected def dispatch void deleteUnnecessaryAssignmentActions(SequentialAction action,
			Collection<VariableDeclaration> readVariables) {
		val xStsSubactions = action.actions
		// Going from the end of the sequential action as the highest prime variables are at the end
		for (var i = xStsSubactions.size - 1; i >= 0; i--) {
			val xStsSubaction = xStsSubactions.get(i)
			if (xStsSubaction instanceof AssignmentAction) {
				// Assignment, if it does not give value the highest prime variable, it has to be deleted
				val declaration = (xStsSubaction.lhs as DirectReferenceExpression).declaration
				checkState(declaration instanceof VariableDeclaration)
				val variable = declaration as VariableDeclaration
				if (readVariables.contains(variable)) {
					// This assignment action cannot be deleted as the variable is referred
					// The variables on the right hand side of the assignment are given to read variables
					readVariables += xStsSubaction.rhs.referredVariables
				}
				else {
					// Not a referred variable, assignment is unnecessary
					xStsSubactions.remove(i)
				}
			}
			else {
				// Not an assignment action, delegating
				xStsSubaction.deleteUnnecessaryAssignmentActions(readVariables)
			}
		}
	}
	
}