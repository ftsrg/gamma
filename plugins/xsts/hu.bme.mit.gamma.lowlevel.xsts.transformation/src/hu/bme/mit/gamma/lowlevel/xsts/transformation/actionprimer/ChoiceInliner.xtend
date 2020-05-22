package hu.bme.mit.gamma.lowlevel.xsts.transformation.actionprimer

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.xsts.model.model.Action
import hu.bme.mit.gamma.xsts.model.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.model.ParallelAction
import hu.bme.mit.gamma.xsts.model.model.SequentialAction
import java.util.List
import java.util.Map

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.xsts.model.derivedfeatures.XSTSDerivedFeatures.*

class ChoiceInliner extends ActionPrimer {
	
	new() {
		super(true)
	}
	
	new(boolean inlinePrimedVariables) {
		super(inlinePrimedVariables)
	}
	
	override Action transform(Action action) {
		// Inlining
		action.inlineNonDeterministicActions
		action.primeAction(newHashMap, newHashMap, newHashMap)
		// Deleting 'assume Normal == Normal' kind of assumptions
		action.deleteUnnecessaryAssumeActions
		// Getting the expressions and actions for separated branches
		val branches = action.separateNonDeterministicBranches(null, newLinkedList)
		// Creating the topmost nondeterministic action
		val List<Expression> branchExpressions = branches.key
		val branchActions = branches.value
		checkState(branchExpressions.size == branchActions.size)
		val size = branchExpressions.size
		val topmostNonDeterministicAction = createNonDeterministicAction
		for (var i = 0; i < size; i++) {
			val branchExpression = branchExpressions.get(i)
			// Another optimization on the top, as new expressions have been composed from distinct ones
			if (!branchExpression.definitelyFalseExpression) {
				val branchActionList = branchActions.get(i)
				val nonNullBranchExpression = if (branchExpression === null) {
					createTrueExpression
				} else {
					branchExpression.clone // Due to lower-level bug, this has to be cloned to
				}
				topmostNonDeterministicAction.actions += createSequentialAction => [
					it.actions += nonNullBranchExpression.createAssumeAction
					it.actions += branchActionList
				]
			}
		}
		if (inlinePrimedVariables) {
			// In case of inline, assignments to intermediate prime variables (on a particular branch) 
			// are not needed due to the inlining of the right hand side values during the priming operation
			topmostNonDeterministicAction.deleteAssignmentActionsToNotHighestPrimeVariables
		}
		return topmostNonDeterministicAction
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
	}
	
	protected def dispatch void primeAction(ParallelAction action,
			Map<VariableDeclaration, List<VariableDeclaration>> primedVariables,
			Map<VariableDeclaration, Integer> indexes, Map<VariableDeclaration, Expression> values) {
		throw new UnsupportedOperationException("Parallel actions are not yet supported")
	}
	
	// NonDeterminisctic action inline transformations
	
	protected def dispatch void inlineNonDeterministicActions(Action action) {
		// No operation
	}
	
	protected def dispatch void inlineNonDeterministicActions(ParallelAction action) {
		throw new UnsupportedOperationException("Parallel actions are not yet supported: " + action)
	}
	
	protected def dispatch void inlineNonDeterministicActions(SequentialAction action) {
		val xStsSubactions = action.actions
		for (var i = 0; i < xStsSubactions.size; i++) {
			val xStsSubaction = xStsSubactions.get(i)
			if (xStsSubaction instanceof NonDeterministicAction) {
				for (var j = i + 1; j < xStsSubactions.size; /*Remaining on the same index*/) {
					val xStsSubsequentAction = xStsSubactions.get(j)
					xStsSubactions.remove(j) // Removing from the original list
					xStsSubaction.extendEachBranch(xStsSubsequentAction)
				}
				// xStsSubaction is now the last action
				checkState(xStsSubactions.indexOf(xStsSubaction) == xStsSubactions.size - 1)
				xStsSubaction.inlineNonDeterministicActions
			}
		}
		// Single NonDeterministic action before it
		checkState(xStsSubactions.filter(NonDeterministicAction).size <= 1, "Multiple " 
			+ "NonDeterministicAction remained in the SequentialAction: " + xStsSubactions)
	}
	
	protected def dispatch void inlineNonDeterministicActions(NonDeterministicAction action) {
		for (xStsSubaction : action.actions) {
			xStsSubaction.inlineNonDeterministicActions
		}
	}
	
	protected def void extendEachBranch(NonDeterministicAction nonDeterministicAction, Action newAction) {
		val xStsSubactions = nonDeterministicAction.actions
		for (var i = 0; i < xStsSubactions.size; i++) {
			val xStsSubaction = xStsSubactions.get(i)
			val xStsNewAction = newAction.clone
			if (xStsSubaction instanceof SequentialAction) {
				xStsSubaction.actions += xStsNewAction // Extending with new action
			}
			else {
				// Operation add instead of set as the original xStsSubaction is taken from the original list
				xStsSubactions.add(i,
					// The new action has to be executed after the original ones in each branch
					createSequentialAction => [
						it.actions += xStsSubaction // Original action
						it.actions += xStsNewAction // New action
					]
				)			
			}
		}
	}
	
	// Separating the branches	
	protected def dispatch Pair<List<Expression>, List<List<Action>>> separateNonDeterministicBranches(
			AssumeAction action, Expression expression, List<Action> actions) {
		if (action.isDefinitelyFalseAssumeAction) {
			// This branch is unreachable, aborting the process on this branch
			throw new UnreachableBranchException(action.assumption.clone)
		}
		val Expression branchAssumption = if (expression === null) {
			action.assumption.clone  // Cloning is important
		}
		else if (action.isDefinitelyTrueAssumeAction) {
			// Big optimization
			expression.clone
		}
		else {
			createAndExpression => [
				it.operands += expression.clone  // Cloning is important
				it.operands += action.assumption.clone  // Cloning is important
			]
		}
		// The branch assumption is finished, action list need not be adjusted
		return #[branchAssumption] -> #[actions]
	}
	
	protected def dispatch Pair<List<Expression>, List<List<Action>>> separateNonDeterministicBranches(
			AssignmentAction action, Expression expression, List<Action> actions) {
		val List<Action> newActionList = newLinkedList
		newActionList += actions.map[it.clone] // Cloning is important
		newActionList += action.clone // Cloning is important
		// The branch assumption need not be adjusted, action list is completed
		return #[expression] -> #[newActionList]
	}
	
	protected def dispatch Pair<List<Expression>, List<List<Action>>> separateNonDeterministicBranches(
			SequentialAction action, Expression expression, List<Action> actions) {
		val xStsSubactions = action.actions		
		var branchAssumption = expression
		var List<Action> branchActions = newLinkedList
		branchActions += actions
		for (var i = 0; i < xStsSubactions.size; i++) {
			val xStsSubaction = xStsSubactions.get(i)
			if (xStsSubaction instanceof AssumeAction || 
					xStsSubaction instanceof AssignmentAction ||
					xStsSubaction instanceof SequentialAction) {
				val branchLists = xStsSubaction.separateNonDeterministicBranches(branchAssumption, branchActions)
				// As a SequentialAction cannot contain NonDeterministicActions, a single
				// expression is expected in addition to the completed action list
				val expressionList = branchLists.key
				checkState(expressionList.size == 1)
				branchAssumption = expressionList.head
				val actionList = branchLists.value
				checkState(actionList.size == 1)
				branchActions = actionList.head
			}
			else if (xStsSubaction instanceof NonDeterministicAction) {
				checkState(i == xStsSubactions.size - 1, "A NonDeterministicAction can be positioned "
					+ "only in the final index: " + i + " " + xStsSubactions.size)
				return xStsSubaction.separateNonDeterministicBranches(branchAssumption, branchActions)
			}
			else {
				throw new IllegalStateException("Not handled action type: " + xStsSubaction)
			}
		}
		return #[branchAssumption] -> #[branchActions]
	}
	
	protected def dispatch Pair<List<Expression>, List<List<Action>>> separateNonDeterministicBranches(
			NonDeterministicAction action, Expression expression, List<Action> actions) {
		val xStsSubactions = action.actions		
		var branchAssumptions = newLinkedList
		var branchActions = newLinkedList
		for (xStsSubaction : xStsSubactions) {
			try {
				val branchLists = xStsSubaction.separateNonDeterministicBranches(expression, actions)
				branchAssumptions += branchLists.key
				branchActions += branchLists.value
			} catch (UnreachableBranchException exception) {
				// This branch is unreachable, not storing its condition and actions in the lists
				// Note that we remain in the loop
			}
		}
		return branchAssumptions -> branchActions
	}
	
	// Action optimizer if only the assignments giving value to variables with the highest prime are needed,
	// but the height of primes are counted in each separate branch
	
	protected def dispatch void deleteAssignmentActionsToNotHighestPrimeVariables(Action action) {
		// No op
	}
	
	protected def dispatch void deleteAssignmentActionsToNotHighestPrimeVariables(SequentialAction action) {
		val highestPrimeVariables = newHashSet
		val xStsActions = action.actions
		for (var i = xStsActions.size - 1; i >= 0; i--) {
			val xStsSubaction = xStsActions.get(i)
			if (xStsSubaction instanceof AssignmentAction) {
				val variable = xStsSubaction.lhs.declaration as VariableDeclaration
				val originalVariable = variable.originalVariable
				if (highestPrimeVariables.contains(originalVariable)) {
					// An assignment to a variable with a higher prime is present later
					xStsActions.remove(i)
				}
				else {
					// We found the highest prime variable on this branch
					highestPrimeVariables += originalVariable
				}
			}
			// Note that we do not check recursively, as SequentialActions are the leafs in this transformation mode
		}
	}
	
	protected def dispatch void deleteAssignmentActionsToNotHighestPrimeVariables(NonDeterministicAction action) {
		val xStsActions = action.actions
		for (var i = 0; i < xStsActions.size; i++) {
			val xStsSubaction = xStsActions.get(i)
			xStsSubaction.deleteAssignmentActionsToNotHighestPrimeVariables
		}
	}
	
}

class UnreachableBranchException extends Exception {
	// The expression due to which the given branch is unreachable, and the exception is raised
	Expression unsatisfiableExpression
	
	new(Expression unsatisfiableExpression) {
		this.unsatisfiableExpression = unsatisfiableExpression
	}
	
	def getUnsatisfiableExpression() {
		return unsatisfiableExpression
	}
	
}