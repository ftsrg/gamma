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

import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.ArithmeticExpression
import hu.bme.mit.gamma.expression.model.BooleanExpression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.AtomicAction
import hu.bme.mit.gamma.xsts.model.CompositeAction
import hu.bme.mit.gamma.xsts.model.EmptyAction
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.MultiaryAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.OrthogonalAction
import hu.bme.mit.gamma.xsts.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.model.XTransition
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection
import java.util.List
import org.eclipse.emf.ecore.EObject

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class ActionOptimizer {
	// Singleton
	public static final ActionOptimizer INSTANCE =  new ActionOptimizer
	protected new() {}
	// Auxiliary objects
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	// Model factories
	protected final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected final extension XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE
	
	def optimize(Iterable<? extends XTransition> transitions) {
		val optimizedTransitions = newArrayList
		for (transition : transitions) {
			optimizedTransitions += transition.optimize
		}
		return optimizedTransitions
	}
	
	def optimize(XTransition transition) {
		if (transition === null) {
			return null // Can be null, if. e.g., there are no out-events
		}
		val action = transition.action
		return createXTransition => [
			it.action = action?.optimize
		]
	}
	
	def optimize(Action action) {
		var Action oldXStsAction
		var Action newXStsAction = action
		// Until the action cannot be optimized any more
		while (!oldXStsAction.helperEquals(newXStsAction)) {
			oldXStsAction = newXStsAction.clone
			newXStsAction = newXStsAction
				/* Cannot use "clone" as local variable actions contain variable declarations and
				   cloning would break the references: they would be set to the "old" declaration */
				.simplifyCompositeActions
				.simplifySequentialActions
				.simplifyParallelActions
				.simplifyOrthogonalActions
				.simplifyNonDeterministicActions
				
				.optimizeIfActions
				
			newXStsAction.optimizeAssignmentActions
			newXStsAction.deleteTrivialNonDeterministicActions
			newXStsAction = newXStsAction.optimizeParallelActions // Might be resource intensive
			newXStsAction.deleteUnnecessaryAssumeActions // Not correct in other transformation implementations
			newXStsAction.deleteDefinitelyFalseBranches
			newXStsAction.optimizeExpressions // Could be extracted to the expression metamodel?
		}
		return newXStsAction
	}
	
	// Composite actions
	
	// Deleting composite actions with less than two actions 
	protected def dispatch Action simplifyCompositeActions(AtomicAction action) {
		return action
	}
	
	protected def dispatch Action simplifyCompositeActions(LoopAction action) {
		val xStsSubaction = action.action
		val simplifiedXStsSubaction = xStsSubaction.simplifyCompositeActions
		if (simplifiedXStsSubaction instanceof EmptyAction) {
			return simplifiedXStsSubaction
		}
		return action => [ // Parameter and range are still needed
			it.action = simplifiedXStsSubaction
		]
	}
	
	protected def dispatch Action simplifyCompositeActions(IfAction action) {
		val simplifiedXStsThenAction = action.then.simplifyCompositeActions
		val simplifiedXStsElseAction = action.^else.simplifyCompositeActions
		
		if (simplifiedXStsThenAction.nullOrEmptyAction &&
				simplifiedXStsElseAction.nullOrEmptyAction) {
			return createEmptyAction
		}
		return action => [
			it.then = simplifiedXStsThenAction
			it.^else = simplifiedXStsElseAction
		]
	}
	
	protected def dispatch Action simplifyCompositeActions(MultiaryAction action) {
		var xStsActionList = newLinkedList
		xStsActionList += action.actions
		if (xStsActionList.size > 1) {
			val remainingXStsActions = newLinkedList
			// Sequence order must be reserved
			xStsActionList.removeIf[it instanceof EmptyAction || 
				it instanceof MultiaryAction && (it as MultiaryAction).actions.forall[it instanceof EmptyAction] ||
				it instanceof LoopAction && ((it as LoopAction).action === null || (it as LoopAction).action instanceof EmptyAction)]
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
			if (newXStsAction instanceof MultiaryAction) {
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
			val newXStsCompositeAction = create(action.eClass) as MultiaryAction
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
	
	protected def dispatch List<Action> simplifySequentialActions(LoopAction action, boolean isTop) {
		val xStsSubaction = action.action
		val newXStsSubactions = xStsSubaction.simplifySequentialActions(true)
		checkState(newXStsSubactions.size == 1)
		return #[
			action => [ // Parameter and range are still needed
				it.action = newXStsSubactions.head
			]
		]
	}
	
	protected def dispatch List<Action> simplifySequentialActions(IfAction action, boolean isTop) {
		val xStsThenAction = action.then
		val xStsElseAction = action.^else
		val newXStsThenAction = xStsThenAction.simplifySequentialActions(true)
		val newXStsElseAction = xStsElseAction.simplifySequentialActions(true)
		checkState(newXStsThenAction.size == 1)
		checkState(newXStsElseAction.size == 1)
		return #[
			action => [
				it.then = newXStsThenAction.head
				it.^else = newXStsElseAction.head
			]
		]
	}
	
	protected def dispatch List<Action> simplifySequentialActions(MultiaryAction action, boolean isTop) {
		val xStsSubactions = newArrayList
		xStsSubactions += action.actions
		val newXStsCompositeAction = create(action.eClass) as MultiaryAction
		for (xStsSubaction : xStsSubactions) {
			newXStsCompositeAction.actions += xStsSubaction.simplifySequentialActions(true)
		}
		return #[newXStsCompositeAction]
	}
	
	/**
	 * The isTop flag specifies whether the given action should be preserved (true) or deleted (false).
	 */
	protected def dispatch List<Action> simplifySequentialActions(SequentialAction action, boolean isTop) {
		val xStsSubactions = newArrayList
		xStsSubactions += action.actions
		val newXStsActions = newLinkedList
		// Additional checks - is a definitely false assumption there
		if (xStsSubactions.filter(AssumeAction).exists[it.assumption.definitelyFalseExpression]) {
			// This action cannot be executed
			if (isTop) {
				return #[createSequentialAction => [it.actions += createEmptyAction]]
			}
			return newXStsActions
		}
		// The assumptions can be true
		for (xStsSubaction : xStsSubactions) {
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
	
	protected def dispatch List<Action> simplifyParallelActions(LoopAction action, boolean isTop) {
		val xStsSubaction = action.action
		val newXStsSubactions = xStsSubaction.simplifyParallelActions(true)
		checkState(newXStsSubactions.size == 1)
		return #[
			action => [ // Parameter and range are still needed
				it.action = newXStsSubactions.head
			]
		]
	}
	
	protected def dispatch List<Action> simplifyParallelActions(IfAction action, boolean isTop) {
		val xStsThenAction = action.then
		val xStsElseAction = action.^else
		val newXStsThenAction = xStsThenAction.simplifyParallelActions(true)
		val newXStsElseAction = xStsElseAction.simplifyParallelActions(true)
		checkState(newXStsThenAction.size == 1)
		checkState(newXStsElseAction.size == 1)
		return #[
			action => [
				it.then = newXStsThenAction.head
				it.^else = newXStsElseAction.head
			]
		]
	}
	
	protected def dispatch List<Action> simplifyParallelActions(MultiaryAction action, boolean isTop) {
		val xStsSubactions = newArrayList
		xStsSubactions += action.actions
		val newXStsCompositeAction = create(action.eClass) as MultiaryAction
		for (xStsSubaction : xStsSubactions) {
			newXStsCompositeAction.actions += xStsSubaction.simplifyParallelActions(true)
		}
		return #[newXStsCompositeAction]
	}
	
	/**
	 * The isTop flag specifies whether the given action should be preserved (true) or deleted (false).
	 */
	protected def dispatch List<Action> simplifyParallelActions(ParallelAction action, boolean isTop) {
		val xStsSubactions = newArrayList
		xStsSubactions += action.actions
		val newXStsActions = newLinkedList
		for (xStsSubaction : xStsSubactions) {
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
	
	protected def dispatch List<Action> simplifyOrthogonalActions(LoopAction action, boolean isTop) {
		val xStsSubaction = action.action
		val newXStsSubactions = xStsSubaction.simplifyOrthogonalActions(true)
		checkState(newXStsSubactions.size == 1)
		return #[
			action => [ // Parameter and range are still needed
				it.action = newXStsSubactions.head
			]
		]
	}
	
	protected def dispatch List<Action> simplifyOrthogonalActions(IfAction action, boolean isTop) {
		val xStsThenAction = action.then
		val xStsElseAction = action.^else
		val newXStsThenAction = xStsThenAction.simplifyOrthogonalActions(true)
		val newXStsElseAction = xStsElseAction.simplifyOrthogonalActions(true)
		checkState(newXStsThenAction.size == 1)
		checkState(newXStsElseAction.size == 1)
		return #[
			action => [
				it.then = newXStsThenAction.head
				it.^else = newXStsElseAction.head
			]
		]
	}
	
	protected def dispatch List<Action> simplifyOrthogonalActions(MultiaryAction action, boolean isTop) {
		val xStsSubactions = newArrayList
		xStsSubactions += action.actions
		val newXStsCompositeAction = create(action.eClass) as MultiaryAction
		for (xStsSubaction : xStsSubactions) {
			newXStsCompositeAction.actions += xStsSubaction.simplifyOrthogonalActions(true)
		}
		return #[newXStsCompositeAction]
	}
	
	/**
	 * The isTop flag specifies whether the given action should be preserved (true) or deleted (false).
	 */
	protected def dispatch List<Action> simplifyOrthogonalActions(OrthogonalAction action, boolean isTop) {
		val xStsSubactions = newArrayList
		xStsSubactions += action.actions
		val newXStsActions = newLinkedList
		for (xStsSubaction : xStsSubactions) {
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
	
	protected def dispatch List<Action> simplifyNonDeterministicActions(LoopAction action, boolean isTop) {
		val xStsSubaction = action.action
		val newXStsSubactions = xStsSubaction.simplifyNonDeterministicActions(true)
		checkState(newXStsSubactions.size == 1)
		return #[
			action => [ // Parameter and range are still needed
				it.action = newXStsSubactions.head
			]
		]
	}
	
	protected def dispatch List<Action> simplifyNonDeterministicActions(IfAction action, boolean isTop) {
		val xStsThenAction = action.then
		val xStsElseAction = action.^else
		val newXStsThenAction = xStsThenAction.simplifyNonDeterministicActions(true)
		checkState(newXStsThenAction.size == 1)
		val newXStsElseAction = xStsElseAction.simplifyNonDeterministicActions(true)
		checkState(newXStsElseAction.size == 1)
		// Neither definitely true nor false
		return #[
			action => [
				it.then = newXStsThenAction.head
				it.^else = newXStsElseAction.head
			]
		]
	}
	
	protected def dispatch List<Action> simplifyNonDeterministicActions(MultiaryAction action, boolean isTop) {
		val xStsSubactions = newArrayList
		xStsSubactions += action.actions
		val newXStsCompositeAction = create(action.eClass) as MultiaryAction
		for (xStsSubaction : xStsSubactions) {
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
		for (xStsSubaction : actions.reject[coveredXStsActions.contains(it)]) {
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
		val xStsSubactions = newArrayList
		xStsSubactions += action.actions
		// Now all parallel actions are optimized to sequential actions
		if (true || action.isOptimizableToSequentialAction) {
			return createSequentialAction => [
				for (xStsSubaction : xStsSubactions) {
					it.actions += xStsSubaction.optimizeParallelActions
				}
			]
		}
		// This particular parallel action cannot be optimized
		return createParallelAction => [
			for (xStsSubaction : xStsSubactions) {
				it.actions += xStsSubaction.optimizeParallelActions
			}
		]
	}
	
	protected def dispatch Action optimizeParallelActions(LoopAction action) {
		val xStsSubaction = action.action
		return action => [ // Parameter and range are still needed
			it.action = xStsSubaction.optimizeParallelActions
		]
	}
	
	protected def dispatch Action optimizeParallelActions(IfAction action) {
		val xStsThenAction = action.then
		val xStsElseAction = action.^else
		return action => [
			it.then = xStsThenAction.optimizeParallelActions
			it.^else = xStsElseAction.optimizeParallelActions
		]
	}
	
	protected def dispatch Action optimizeParallelActions(MultiaryAction action) {
		val xStsSubactions = newArrayList
		xStsSubactions += action.actions
		return create(action.eClass) as MultiaryAction => [
			for (xStsSubaction : xStsSubactions) {
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
	
	protected def dispatch void optimizeAssignmentActions(LoopAction action) {
		val xStsSubaction = action.action
		xStsSubaction.optimizeAssignmentActions
	}
	
	protected def dispatch void optimizeAssignmentActions(IfAction action) {
		val xStsThenAction = action.then
		val xStsElseAction = action.^else
		xStsThenAction.optimizeAssignmentActions
		xStsElseAction.optimizeAssignmentActions
	}
	
	protected def dispatch void optimizeAssignmentActions(MultiaryAction action) {
		// Recursion
		for (xStsAction : action.actions) {
			xStsAction.optimizeAssignmentActions
		}
	}
	
	protected def dispatch void optimizeAssignmentActions(SequentialAction action) {
		val xStsActions = action.actions
		val removeableXStsActions = <AbstractAssignmentAction>newLinkedList
		for (var i = 0; i < xStsActions.size; i++) {
			val xStsFirstAction = xStsActions.get(i)
			if (xStsFirstAction instanceof AbstractAssignmentAction) {
				val lhs = xStsFirstAction.lhs
				var foundAssignmentToTheSameVariable = false
				for (var j = i + 1; j < xStsActions.size && !foundAssignmentToTheSameVariable; j++) {
					val xStsSecondAction = xStsActions.get(j)
					if (xStsSecondAction instanceof AbstractAssignmentAction) {
						if (xStsSecondAction.lhs.helperEquals(lhs)) {
							foundAssignmentToTheSameVariable = true
							var isVariableRead = false
							for (var k = i + 1; k <= j && !isVariableRead; k++) {
								val xStsInBetweenAction = xStsActions.get(k)
								val variable = lhs.accessedDeclaration
								// Not perfect for arrays: a[0] := 1; b := a[2]; a[0] := 2;
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
	
	protected def optimizeIfActions(Action action) {
		val block = action.createSequentialAction // Due to replacement issues
		
		val xStsIfActions = action.getSelfAndAllContentsOfType(IfAction)
		for (xStsIfAction : xStsIfActions) {
			val xStsCondition = xStsIfAction.condition
			val xStsThenAction = xStsIfAction.then
			val xStsElseAction = xStsIfAction.^else
			
			if (xStsThenAction.nullOrEmptyAction && xStsElseAction.nullOrEmptyAction) {
				xStsIfAction.remove
			}
			else if (xStsCondition.definitelyTrueExpression) {
				xStsThenAction.replace(xStsIfAction)
			}
			else if (xStsCondition.definitelyFalseExpression) {
				xStsElseAction.replace(xStsIfAction)
			}
			else if (xStsThenAction.nullOrEmptyAction) {
				// Else branch is not empty due to first condition of this if-else
				// if (a) {} else {...} === if (!a) {...} else {}
				xStsIfAction.condition = xStsCondition.createNotExpression
				xStsIfAction.then = xStsElseAction
				xStsIfAction.^else = createEmptyAction
			}
		}
		return block
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
	
	protected def dispatch void deleteTrivialNonDeterministicActions(LoopAction action) {
		val xStsSubaction = action.action
		xStsSubaction.deleteTrivialNonDeterministicActions
	}
	
	protected def dispatch void deleteTrivialNonDeterministicActions(IfAction action) {
		val xStsThenAction = action.then
		val xStsElseAction = action.^else
		xStsThenAction.deleteTrivialNonDeterministicActions
		xStsElseAction.deleteTrivialNonDeterministicActions
	}
	
	protected def dispatch void deleteTrivialNonDeterministicActions(MultiaryAction action) {
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
	
	protected def dispatch void deleteDefinitelyFalseBranches(LoopAction action) {
		val xStsSubaction = action.action
		xStsSubaction.deleteDefinitelyFalseBranches
	}
	
	protected def dispatch void deleteDefinitelyFalseBranches(IfAction action) {
		val xStsThenAction = action.then
		val xStsElseAction = action.^else
		xStsThenAction.deleteDefinitelyFalseBranches
		xStsElseAction.deleteDefinitelyFalseBranches
	}
	
	protected def dispatch void deleteDefinitelyFalseBranches(MultiaryAction action) {
		for (xStsAction : action.actions) {
			xStsAction.deleteDefinitelyFalseBranches
		}
	}
	
	protected def dispatch void deleteDefinitelyFalseBranches(NonDeterministicAction action) {
		val xStsSubactions = newArrayList
		xStsSubactions += action.actions
		for (branch : xStsSubactions) {
			val firstAction = branch.firstAtomicAction
			if (firstAction instanceof AssumeAction) {
				if (firstAction.isDefinitelyFalseAssumeAction) {
					branch.remove
				}
				else {
					branch.deleteDefinitelyFalseBranches
				}
			}
		}
	}
	
	//
	
	protected def void optimizeExpressions(Action action) {
		val eObjects = action.getAllContentsOfType(EObject)
		
		val booleanExpressions = eObjects.filter(BooleanExpression)
		for (booleanExpression : booleanExpressions) {
			if (booleanExpression.definitelyFalseExpression) {
				expressionFactory.createFalseExpression.replace(booleanExpression)
			}
			else if (booleanExpression.definitelyTrueExpression) {
				expressionFactory.createTrueExpression.replace(booleanExpression)
			}
			else {
				if (booleanExpression instanceof OrExpression) {
					booleanExpression.operands.removeIf[it instanceof FalseExpression]
				}
				else if (booleanExpression instanceof AndExpression) {
					booleanExpression.operands.removeIf[it instanceof TrueExpression]
				}
			}
		}
		
		val multiaryExpressions = newArrayList
		multiaryExpressions += eObjects.filter(ArithmeticExpression).filter(MultiaryExpression) // Add, Mul
		multiaryExpressions += booleanExpressions.filter(MultiaryExpression) // And, Xor, Or
		
		for (multiaryExpression : multiaryExpressions) {
			val operands = multiaryExpression.operands
			val container = multiaryExpression.eContainer
			if (container !== null) {
				if (container.eClass == multiaryExpression.eClass) {
					val _container = container as MultiaryExpression
					_container.operands += operands
					multiaryExpression.remove
				}
				else {
					val operandSize = operands.size
					if (operandSize == 0) {
						multiaryExpression.remove
					}
					else if (operandSize == 1) {
						val operand = operands.head
						operand.replace(multiaryExpression)
					}
				}
			}
		}
	}
	
}