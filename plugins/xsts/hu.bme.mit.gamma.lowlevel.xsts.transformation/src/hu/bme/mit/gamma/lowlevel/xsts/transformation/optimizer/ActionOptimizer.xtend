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
package hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.AtomicAction
import hu.bme.mit.gamma.xsts.model.CompositeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.OrthogonalAction
import hu.bme.mit.gamma.xsts.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import java.util.Collection
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XSTSDerivedFeatures.*
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction

class ActionOptimizer {
	// Singleton
	public static final ActionOptimizer INSTANCE =  new ActionOptimizer
	protected new() {}
	// Auxiliary objects
	protected final extension ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	// Model factories
	protected final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected final extension XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE
	
	def optimize(Action action) {
		var Action oldXStsAction
		var Action newXStsAction = action
		// Until the action cannot be optimized any more
		while (!oldXStsAction.helperEquals(newXStsAction)) {
			oldXStsAction = newXStsAction
			newXStsAction = newXStsAction
				.simplifyCompositeActions
				.simplifySequentialActions
				.simplifyParallelActions
				.simplifyOrthogonalActions
				.simplifyNonDeterministicActions
			newXStsAction.optimizeAssignmentActions
			newXStsAction.deleteTrivialNonDeterministicActions
			newXStsAction = newXStsAction.optimizeParallelActions // Might be resource intensive
			newXStsAction.deleteUnnecessaryAssumeActions // Not correct in other transformation implementations
			newXStsAction.deleteDefinitelyFalseBranches
		}
		return newXStsAction
	}
	
	// Composite actions
	
	// Deleting composite actions with less than two actions 
	protected def dispatch Action simplifyCompositeActions(AtomicAction action) {
		return action
	}
	
	protected def dispatch Action simplifyCompositeActions(CompositeAction action) {
		var xStsActionList = newLinkedList
		xStsActionList += action.actions.map[if (it.mustNotBeCloned) {it} else (it.clone)] /* Cloning the action so the original
		 * does not change, which is a necessary quality in the optimization process */
		if (xStsActionList.size > 1) {
			val remainingXStsActions = newLinkedList
			// Sequence order must be reserved
			xStsActionList.removeIf[it instanceof EmptyAction || 
				it instanceof CompositeAction && (it as CompositeAction).actions.empty]
			for (xStsSubaction : xStsActionList) {
				remainingXStsActions += xStsSubaction.simplifyCompositeActions
			}
			remainingXStsActions.removeIf[it instanceof EmptyAction] // Important
			xStsActionList = remainingXStsActions
			// Very important that we check the size of xStsActionList again
		}
		// No "else" here
		if (xStsActionList.size == 1) {
			val xStsSubaction = xStsActionList.head
			val newXStsAction = xStsSubaction.simplifyCompositeActions
			if (newXStsAction instanceof CompositeAction) {
				checkState(newXStsAction.actions.size > 1 && !newXStsAction.actions.exists[it instanceof EmptyAction])
			}
			return newXStsAction
		}
		else if (xStsActionList.empty) {
			// Will be either removed in previous recursive call or single top action
			return createEmptyAction
		}
		else {
			// 1 < Size, even after clearing
			checkState(xStsActionList.size > 1)
			val newXStsCompositeAction = create(action.eClass) as CompositeAction
			newXStsCompositeAction.actions += xStsActionList
			checkState(newXStsCompositeAction.actions.size > 1 &&
				!newXStsCompositeAction.actions.exists[it instanceof EmptyAction])
			return newXStsCompositeAction
		}
	}
	
	// Sequential actions
	
	/**
	 * Deletes sequential actions contained by other sequential actions (parent) and moves its children
	 * one level higher.
	 */
	protected def simplifySequentialActions(Action action) {
		val simplifiedXStsActions = action.simplifySequentialActions(true)
		checkState(simplifiedXStsActions.size == 1) // A single top level element each time
		return simplifiedXStsActions.head
	}
	
	protected def dispatch List<Action> simplifySequentialActions(AtomicAction action, boolean isTop) {
		return #[action]
	}
	
	protected def dispatch List<Action> simplifySequentialActions(CompositeAction action, boolean isTop) {
		val newXStsCompositeAction = create(action.eClass) as CompositeAction
		val subactions = newArrayList
		subactions += action.actions
		for (xStsSubaction : subactions.map[if (it.mustNotBeCloned) {it} else (it.clone)]) {
			newXStsCompositeAction.actions += xStsSubaction.simplifySequentialActions(true)
		}
		return #[newXStsCompositeAction]
	}
	
	/**
	 * The isTop flag specifies whether the given action should be preserved (true) or deleted (false).
	 */
	protected def dispatch List<Action> simplifySequentialActions(SequentialAction action, boolean isTop) {
		val newXStsActions = newLinkedList
		// Additional checks - is a definitely false assumption there
		if (action.actions.filter(AssumeAction).exists[it.assumption.definitelyFalseExpression]) {
			// This action cannot be executed
			if (isTop) {
				return #[createSequentialAction => [it.actions += createEmptyAction]]
			}
			return newXStsActions
		}
		// The assumptions can be true
		val subactions = newArrayList
		subactions += action.actions
		for (xStsSubaction : subactions.map[if (it.mustNotBeCloned) {it} else (it.clone)]) {
			if (xStsSubaction instanceof SequentialAction) {
				// Subactions of a SequentialAction
				for (xStsSequentialSubaction : xStsSubaction.actions) {
					newXStsActions += xStsSequentialSubaction.simplifySequentialActions(false)
				}
			}
			else {
				newXStsActions += xStsSubaction.simplifySequentialActions(true)
			}
		}
		// Top call, this sequential action must be preserved
		if (isTop) {
			return #[createSequentialAction => [it.actions += newXStsActions]]
		}
		// Not top call, this sequential action must be deleted 
		return newXStsActions
	}
	
	// Parallel actions
	
	/**
	 * Deletes parallel actions contained by other parallel actions (parent) and moves its children
	 * one level higher.
	 */
	protected def simplifyParallelActions(Action action) {
		val simplifiedXStsActions = action.simplifyParallelActions(true)
		checkState(simplifiedXStsActions.size == 1) // A single top level element each time
		return simplifiedXStsActions.head
	}
	
	protected def dispatch List<Action> simplifyParallelActions(AtomicAction action, boolean isTop) {
		return #[action]
	}
	
	protected def dispatch List<Action> simplifyParallelActions(CompositeAction action, boolean isTop) {
		val newXStsCompositeAction = create(action.eClass) as CompositeAction
		val subactions = newArrayList
		subactions += action.actions
		for (xStsSubaction : subactions.map[if (it.mustNotBeCloned) {it} else (it.clone)]) {
			newXStsCompositeAction.actions += xStsSubaction.simplifyParallelActions(true)
		}
		return #[newXStsCompositeAction]
	}
	
	/**
	 * The isTop flag specifies whether the given action should be preserved (true) or deleted (false).
	 */
	protected def dispatch List<Action> simplifyParallelActions(ParallelAction action, boolean isTop) {
		val newXStsActions = newLinkedList
		val subactions = newArrayList
		subactions += action.actions
		for (xStsSubaction : subactions.map[if (it.mustNotBeCloned) {it} else (it.clone)]) {
			if (xStsSubaction instanceof ParallelAction) {
				// Subactions of a ParallelAction
				for (xStsParallelSubaction : xStsSubaction.actions) {
					newXStsActions += xStsParallelSubaction.simplifyParallelActions(false)
				}
			}
			else {
				newXStsActions += xStsSubaction.simplifyParallelActions(true)
			}
		}
		// Top call, this parallel action must be preserved
		if (isTop) {
			return #[createParallelAction => [it.actions += newXStsActions]]
		}
		// Not top call, this parallel action must be deleted 
		return newXStsActions
	}
	
	// Orthogonal actions
	
	/**
	 * Deletes orthogonal actions contained by other orthogonal actions (parent) and moves its children
	 * one level higher.
	 */
	protected def simplifyOrthogonalActions(Action action) {
		val simplifiedXStsActions = action.simplifyOrthogonalActions(true)
		checkState(simplifiedXStsActions.size == 1) // A single top level element each time
		return simplifiedXStsActions.head
	}
	
	protected def dispatch List<Action> simplifyOrthogonalActions(AtomicAction action, boolean isTop) {
		return #[action]
	}
	
	protected def dispatch List<Action> simplifyOrthogonalActions(CompositeAction action, boolean isTop) {
		val newXStsCompositeAction = create(action.eClass) as CompositeAction
		val subactions = newArrayList
		subactions += action.actions
		for (xStsSubaction : subactions.map[if (it.mustNotBeCloned) {it} else (it.clone)]) {
			newXStsCompositeAction.actions += xStsSubaction.simplifyOrthogonalActions(true)
		}
		return #[newXStsCompositeAction]
	}
	
	/**
	 * The isTop flag specifies whether the given action should be preserved (true) or deleted (false).
	 */
	protected def dispatch List<Action> simplifyOrthogonalActions(OrthogonalAction action, boolean isTop) {
		val newXStsActions = newLinkedList
		val subactions = newArrayList
		subactions += action.actions
		for (xStsSubaction : subactions.map[if (it.mustNotBeCloned) {it} else (it.clone)]) {
			if (xStsSubaction instanceof OrthogonalAction) {
				// Subactions of a OrthogonalAction
				for (xStsOrthogonalSubaction : xStsSubaction.actions) {
					newXStsActions += xStsOrthogonalSubaction.simplifyOrthogonalActions(false)
				}
			}
			else {
				newXStsActions += xStsSubaction.simplifyOrthogonalActions(true)
			}
		}
		// Top call, this orthogonal action must be preserved
		if (isTop) {
			return #[createOrthogonalAction => [it.actions += newXStsActions]]
		}
		// Not top call, this orthogonal action must be deleted 
		return newXStsActions
	}
	
	// NonDeterministic actions
	
	/**
	 * Deletes nondeterministic actions contained by other nondeterministic actions (parent) and moves its children
	 * one level higher.
	 */
	protected def simplifyNonDeterministicActions(Action action) {
		val simplifiedXStsActions = action.simplifyNonDeterministicActions(true)
		checkState(simplifiedXStsActions.size == 1) // A single top level element each time
		return simplifiedXStsActions.head
	}
	
	protected def dispatch List<Action> simplifyNonDeterministicActions(AtomicAction action, boolean isTop) {
		return #[action]
	}
	
	protected def dispatch List<Action> simplifyNonDeterministicActions(CompositeAction action, boolean isTop) {
		val newXStsCompositeAction = create(action.eClass) as CompositeAction
		val subactions = newArrayList
		subactions += action.actions
		for (xStsSubaction : subactions.map[if (it.mustNotBeCloned) {it} else (it.clone)]) {
			newXStsCompositeAction.actions += xStsSubaction.simplifyNonDeterministicActions(true)
		}
		return #[newXStsCompositeAction]
	}
	
	/**
	 * The isTop flag specifies whether the given action should be preserved (true) or deleted (false).
	 */
	protected def dispatch List<Action> simplifyNonDeterministicActions(NonDeterministicAction action, boolean isTop) {
		val actions = action.actions
		val newXStsActions = newLinkedList
		// Removing same branches
		val coveredXStsActions = newArrayList
		for (var i = 0; i < actions.size - 1; i++) {
			val lhs = actions.get(i)
			for (var j = i + 1; j < actions.size; j++) {
				val rhs = actions.get(j)
				if (lhs.helperEquals(rhs)) {
					coveredXStsActions += lhs
				}
			}
		}
		for (xStsSubaction : actions.reject[coveredXStsActions.contains(it)].map[if (it.mustNotBeCloned) {it} else (it.clone)]) {
			if (xStsSubaction instanceof NonDeterministicAction) {
				// Subactions of a NonDeterministicAction
				for (xStsNonDeterministicSubaction : xStsSubaction.actions) {
					newXStsActions += xStsNonDeterministicSubaction.simplifyNonDeterministicActions(false)
				}
			}
			else {
				newXStsActions += xStsSubaction.simplifyNonDeterministicActions(true)
			}
		}
		// Top call, this non deterministic action must be preserved
		if (isTop) {
			return #[createNonDeterministicAction => [it.actions += newXStsActions]]
		}
		// Not top call, this nondeterministic action must be deleted 
		return newXStsActions
	}	
	
	// Transforming parallel actions to sequential actions when possible
	
	protected def dispatch Action optimizeParallelActions(ParallelAction action) {
		val xStsSubactions = action.actions
		// TODO Now all parallel actions are optimized to sequential actions
		if (true || action.isOptimizableToSequentialAction) {
			return createSequentialAction => [
				for (xStsSubaction : xStsSubactions.map[if (it.mustNotBeCloned) {it} else (it.clone)]) {
					it.actions += xStsSubaction.optimizeParallelActions
				}
			]
		}
		// This particular parallel action cannot be optimized
		return createParallelAction => [
			for (xStsSubaction : xStsSubactions.map[if (it.mustNotBeCloned) {it} else (it.clone)]) {
				it.actions += xStsSubaction.optimizeParallelActions
			}
		]
	}
	
	protected def dispatch Action optimizeParallelActions(CompositeAction action) {
		val subactions = newArrayList
		subactions += action.actions
		return create(action.eClass) as CompositeAction => [
			for (xStsSubaction : subactions.map[if (it.mustNotBeCloned) {it} else (it.clone)]) {
				it.actions += xStsSubaction.optimizeParallelActions
			}
		]
	}
	
	protected def dispatch Action optimizeParallelActions(AtomicAction action) {
		return action
	}
	
	protected def boolean isOptimizableToSequentialAction(ParallelAction action) {
		val List<Collection<VariableDeclaration>> readVariables = newLinkedList
		val List<Collection<VariableDeclaration>> writtenVariables = newLinkedList
		for (var i = 0; i < action.actions.size; i++) {
			val xStsSubaction = action.actions.get(i)
			val newlyWrittenVariables = xStsSubaction.writtenVariables
			writtenVariables += newlyWrittenVariables
			val newlyReadVariables = newHashSet
			newlyReadVariables += xStsSubaction.readVariables
			newlyReadVariables -= newlyWrittenVariables
			readVariables += newlyReadVariables
			for (var j = 0; j < i; j++) {
				val previouslyReadVariables = readVariables.get(j)
				val previouslyWrittenVariables = writtenVariables.get(j)
				// If a written variable is read or written somewhere, the parallel action cannot be optimized
				if (previouslyReadVariables.exists[newlyWrittenVariables.contains(it)] ||
						previouslyWrittenVariables.exists[newlyWrittenVariables.contains(it)] ||
						previouslyWrittenVariables.exists[newlyReadVariables.contains(it)]) {
					return false
				}
			}
		}
		return true
	}
	
	// Assignment actions
	
	protected def dispatch void optimizeAssignmentActions(Action action) {
		// No op
	}
	
	protected def dispatch void optimizeAssignmentActions(CompositeAction action) {
		// Recursion
		for (xStsAction : action.actions) {
			xStsAction.optimizeAssignmentActions
		}
	}
	
	protected def dispatch void optimizeAssignmentActions(SequentialAction action) {
		val xStsActions = action.actions
		val removeableXStsActions = <AssignmentAction>newLinkedList
		for (var i = 0; i < xStsActions.size; i++) {
			val xStsFirstAction = xStsActions.get(i)
			if (xStsFirstAction instanceof AssignmentAction) {
				val variable = (xStsFirstAction.lhs as DirectReferenceExpression).declaration
				var foundAssignmentToTheSameVariable = false
				for (var j = i + 1; j < xStsActions.size && !foundAssignmentToTheSameVariable; j++) {
					val xStsSecondAction = xStsActions.get(j)
					if (xStsSecondAction instanceof AssignmentAction) {
						if ((xStsSecondAction.lhs as DirectReferenceExpression).declaration == variable) {
							foundAssignmentToTheSameVariable = true
							var isVariableRead = false
							for (var k = i + 1; k <= j && !isVariableRead; k++) {
								val xStsInBetweenAction = xStsActions.get(k)
								if (xStsInBetweenAction.readVariables.contains(variable)) {
									isVariableRead = true
								}
							}
							if (!isVariableRead) {
								removeableXStsActions += xStsFirstAction
							}
						}
					}
				}
			}
		}
		// Removing unnecessary assignments
		xStsActions -= removeableXStsActions
		// Recursion
		for (xStsAction : action.actions.filter(CompositeAction)) {
			xStsAction.optimizeAssignmentActions
		}
	}
	
	// Assume actions
	
	protected def void deleteUnnecessaryAssumeActions(Action action) {
		for (assumeAction : action.getAllContentsOfType(AssumeAction)) {
			if (assumeAction.isUnnecessary) {
				assumeAction.delete
			}
		}
	}
	
	/**
	 * Note that this "unnecessary" definition comes from the characteristics of the Gamma transformation:
	 * every assume action in a sequential action is placed at index 0. If this is not the case, then
	 * it must come from a not thorough enough optimization (e.g., empty entry/exit action).
	 * In other transformations this "unnecessary" definition might not hold.
	 */
	protected def isUnnecessary(AssumeAction action) {
		val container = action.eContainer
		if (container instanceof SequentialAction) {
			val actions = container.actions
			return actions.indexOf(action) != 0
		}
		return false
	}
	
	// Non deterministic actions
	
	protected def dispatch void deleteTrivialNonDeterministicActions(Action action) {
		// No op
	}
	
	protected def dispatch void deleteTrivialNonDeterministicActions(CompositeAction action) {
		val copiedXStsActions = newLinkedList
		copiedXStsActions += action.actions
		for (copiedXStsAction : copiedXStsActions) {
			if (copiedXStsAction instanceof NonDeterministicAction) {
				if (copiedXStsAction.unnecessaryNonDeterministicAction) {
					 action.actions -= copiedXStsAction
				}
			}
		}
		// Recursion
		for (xStsAction : action.actions.filter(CompositeAction)) {
			xStsAction.deleteTrivialNonDeterministicActions
		}
	}
	
	protected def isUnnecessaryNonDeterministicAction(NonDeterministicAction action) {
		val xStsNonDeterministicSubactions = action.actions
		if (xStsNonDeterministicSubactions.forall[it instanceof AssumeAction]) {
			/* This way assertions inside non deterministic actions cannot be used. This is needed
				to delete the remaining nondet actions of not existing state entry and exit action:
				choice { assume (normal == Yellow); } or { assume (normal == Red); }
				Needed for optimization only, the program would work correctly functionally without this. */
			return true
			// choice { assume (expression); } { assume (!expression); } formulations are also covered by this.
		}
		// choice { assume (a = b); a := b; } { assume (!(a = b)); }
		else if (xStsNonDeterministicSubactions.size == 2 &&
				xStsNonDeterministicSubactions.filter(SequentialAction).size == 1 && 
				xStsNonDeterministicSubactions.filter(AssumeAction).size == 1) {
			val xStsSequentialAction = xStsNonDeterministicSubactions.filter(SequentialAction).head
			val xStsRhsAssumeAction = xStsNonDeterministicSubactions.filter(AssumeAction).head
			val xStsRhsAssumption = xStsRhsAssumeAction.assumption
			val xStsSequentialSubactions = xStsSequentialAction.actions
			if (xStsSequentialSubactions.size == 2 &&
					xStsSequentialSubactions.filter(AssumeAction).size == 1 &&
					xStsSequentialSubactions.filter(AssignmentAction).size == 1) {
				val xStsLhsAssumeAction = xStsSequentialSubactions.filter(AssumeAction).head
				val xStsLhsAssumption = xStsLhsAssumeAction.assumption
				val xStsAssignmentAction = xStsSequentialSubactions.filter(AssignmentAction).head
				if (isCertainEvent(xStsLhsAssumption, xStsRhsAssumption)) {
					return xStsLhsAssumeAction.isTrivialAssignment(xStsAssignmentAction)
				}
			}
		}
		return false
	}
	
	// Deletion of false branches
	
	protected def dispatch void deleteDefinitelyFalseBranches(Action action) {
		// No op
	}
	
	protected def dispatch void deleteDefinitelyFalseBranches(CompositeAction action) {
		for (xStsAction : action.actions) {
			xStsAction.deleteDefinitelyFalseBranches
		}
	}
	
	protected def dispatch void deleteDefinitelyFalseBranches(NonDeterministicAction action) {
		val subactions = newArrayList
		subactions += action.actions
		for (branch : subactions) {
			val firstAction = branch.firstAtomicAction
			if (firstAction instanceof AssumeAction) {
				if (firstAction.isDefinitelyFalseAssumeAction) {
					val falseAssume = createAssumeAction => [
						it.assumption = expressionFactory.createFalseExpression
					]
					branch.replace(falseAssume)
				}
				else {
					branch.deleteDefinitelyFalseBranches
				}
			}
		}
	}
	
	// Must not be cloned
	
	def mustNotBeCloned(Action action) {
		return action instanceof VariableDeclarationAction
	}
	
}