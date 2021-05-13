package hu.bme.mit.gamma.scenario.statechart.traversal

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.AddExpression
import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.ElseExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.LessEqualExpression
import hu.bme.mit.gamma.expression.model.LessExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.statechart.OnCycleTrigger
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import java.util.ArrayList
import java.util.HashMap
import java.util.List
import org.eclipse.emf.common.util.EList
import java.util.Set
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import java.util.HashSet

class StatechartTraversal {

	boolean acc = false
	boolean err = false
	int runningIndex = 0
	List<Path> paths = null
	List<Path> accepting = newArrayList
	List<Path> error = newArrayList
	VariableDeclaration variable = null
	StatechartDefinition sc

	new(VariableDeclaration v, boolean ac, boolean er, StatechartDefinition scd) {
		variable = v
		acc = ac
		err = er
		sc = scd
	}

	def TraversalResultObject traverseStatechart() {
		var boolean notDone = true
		if(!(acc || err)) return new TraversalResultObject;
		paths = new ArrayList<Path>()
		var Transition firstTransition = null
		var boolean found = false
		for (var int i = 0; i < sc.getTransitions().size() && !found; i++) {
			var Transition t = sc.getTransitions().get(i)
			if (t.getSourceState().getName().equals("init")) {
				firstTransition = t
				found = true
			}
		}

		var StateNode firstState = firstTransition.getTargetState()
		var StateNode currentState = firstTransition.getTargetState()
		var map = new HashMap
		map.put(variable, 0)
		var Path path = new Path(map, currentState)
		var List<Boolean> b = newArrayList
		path.visitedStates.add(firstState)
		path.scheduleIsNeeded = b
		paths.add(path)
		while (notDone) {
			if (paths.size() > runningIndex)
				currentState = paths.get(runningIndex).lastState
			else
				currentState = firstState

			var List<Transition> outgoings = StatechartModelDerivedFeatures::getOutgoingTransitions(currentState)
			var Transition elseT = null
			var boolean anySucceeds = false
			for (Transition t : outgoings) {
				if (t.getGuard() instanceof ElseExpression) {
					elseT = t
				} else {
					anySucceeds = processTransition(t) || anySucceeds
				}
			}
			if (elseT !== null && !anySucceeds) {
				anySucceeds = processTransition(elseT)
			}
			paths.remove(runningIndex)
			if(paths.size() === 0) notDone = false
		}

		var result = new TraversalResultObject
		result.accepting = accepting
		result.error = error
		return result
	}

	def protected boolean processTransition(Transition t) {
		var boolean transitionNeeded = false
		transitionNeeded = !isTransitionEmpty(t) && !(t.getTrigger() instanceof OnCycleTrigger && t.guard === null)
		var path = paths.get(runningIndex)
		var prev = path.lastState
		if (prev instanceof State) {
			var list = newArrayList
			for (a2 : prev.entryActions)
				if (a2 instanceof SetTimeoutAction)
					list.add(a2)

			if (path.transitions.last !== null)
				path.transitions.last.effects += list
		}
		var boolean anySucceeds = false
		if (t.getTargetState().getName().equals("AcceptingState") && acc && guardHolds(t.getGuard(), path)) {
			anySucceeds = true
			var copy = new Path(null, null)
			copy.transitions = copyTransitions(path.transitions)
			copy.scheduleIsNeeded = copySchedules(path.scheduleIsNeeded)
			if (transitionNeeded) { 
				handleScheduling(t, copy)
				copy.transitions += t
			}
			accepting += copy
		} else if (t.getTargetState().getName().equals("hotViolation") && err && guardHolds(t.getGuard(), path)) {
			anySucceeds = true
			var copy = new Path(null, null)
			copy.transitions = copyTransitions(path.transitions)
			copy.scheduleIsNeeded = copySchedules(path.scheduleIsNeeded)
			if (transitionNeeded) { 
				handleScheduling(t, copy)
				copy.transitions += t
			}
			error += copy
		} else if (t.getTargetState().getName().equals("coldViolation")) {
		} else if (guardHolds(t.getGuard(), path)) {
			var map = new HashMap
			map.put(variable, path.variableValues.get(variable))
			var copy = new Path(map, t.targetState)
			copy.transitions = copyTransitions(path.transitions)
			copy.scheduleIsNeeded = copySchedules(path.scheduleIsNeeded)
			copy.visitedStates = copyVisitedStates(path.visitedStates)
			if (transitionNeeded) { 
				handleScheduling(t, copy)
				copy.transitions += t
			}
			copy.visitedStates += t.targetState
			paths += copy
			processActions(t.getEffects(), copy)
		}
		return anySucceeds
	}

	def protected handleScheduling(Transition t, Path copy) {
		if (!copy.visitedStates.contains(t.targetState) && t.sourceState instanceof ChoiceState) {
			copy.scheduleIsNeeded += false
		} else {
			copy.scheduleIsNeeded += true
		}
	}

	def protected void processActions(EList<Action> effects, Path path) {
		for (Action a : effects) {
			if (a instanceof AssignmentStatement) {
				var int baseValue = path.variableValues.get(variable)
				var DirectReferenceExpression ref = a.getLhs() as DirectReferenceExpression
				baseValue = path.variableValues.get(ref.declaration as VariableDeclaration)
				var Expression r = a.getRhs()
				if (r instanceof IntegerLiteralExpression) {
					var ExpressionEvaluator evaluator = ExpressionEvaluator::INSTANCE
					baseValue = evaluator.evaluate(r)
					path.variableValues.replace(ref.declaration as VariableDeclaration, baseValue)
				} else if (r instanceof AddExpression) {
					var DirectReferenceExpression ref2 = null
					var IntegerLiteralExpression int2 = null
					var AddExpression add = r
					for (Expression e : add.getOperands()) {
						if (e instanceof IntegerLiteralExpression)
							int2 = e
						else if (e instanceof DirectReferenceExpression)
							ref2 = e
					}
					if (int2 !== null && ref2 !== null && ref2.declaration instanceof VariableDeclaration) {
						baseValue = path.variableValues.get(ref2.declaration)
						var ExpressionEvaluator evaluator = ExpressionEvaluator::INSTANCE
						baseValue = evaluator.evaluate(int2) + baseValue
						path.variableValues.replace(ref.declaration as VariableDeclaration, baseValue)
					}
				}
			}
		}
	}

	def protected Set<StateNode> copyVisitedStates(Set<StateNode> nodes) {
		var Set<StateNode> newSet = new HashSet
		for (t : nodes) {
			newSet.add(t)
		}
		return newSet
	}

	def protected List<Transition> copyTransitions(List<Transition> original) {
		var List<Transition> newList = newArrayList
		for (t : original) {
			newList.add(t)
		}
		return newList
	}

	def protected List<Boolean> copySchedules(List<Boolean> original) {
		var List<Boolean> newSchedules = newArrayList
		for (t : original) {
			newSchedules.add(t)
		}
		return newSchedules
	}

	def protected boolean isTransitionEmpty(Transition t) {
		return t.getGuard() === null && t.getTrigger() === null &&
			t.effects.filter[it instanceof RaiseEventAction].isEmpty
	}

	def protected boolean guardHolds(Expression guard, Path path) {
		if(guard === null) return true
		if (guard instanceof TrueExpression)
			return true
		var int value = 0
		if (guard instanceof AndExpression) {
			var boolean acc = true
			for (Expression e : guard.getOperands()) {
				if (e instanceof LessEqualExpression &&
					((e as LessEqualExpression)).getLeftOperand() instanceof DirectReferenceExpression &&
					((e as LessEqualExpression)).getRightOperand() instanceof IntegerLiteralExpression) {
					var ee = e as LessEqualExpression
					value = path.variableValues.get((ee.leftOperand as DirectReferenceExpression).declaration)
					var ExpressionEvaluator evaluator = ExpressionEvaluator::INSTANCE
					var int i = evaluator.evaluate(((e as LessEqualExpression)).getRightOperand())
					acc = acc && value <= i
				} else if (e instanceof GreaterEqualExpression &&
					((e as GreaterEqualExpression)).getLeftOperand() instanceof DirectReferenceExpression &&
					((e as GreaterEqualExpression)).getRightOperand() instanceof IntegerLiteralExpression) {
					var ee = e as GreaterEqualExpression
					value = path.variableValues.get((ee.leftOperand as DirectReferenceExpression).declaration)
					var ExpressionEvaluator evaluator = ExpressionEvaluator::INSTANCE
					var int i = evaluator.evaluate(((e as GreaterEqualExpression)).getRightOperand())
					acc = acc && value >= i
				}
			}
			return acc
		} else if (guard instanceof LessEqualExpression &&
			((guard as LessEqualExpression)).getLeftOperand() instanceof DirectReferenceExpression &&
			((guard as LessEqualExpression)).getRightOperand() instanceof IntegerLiteralExpression) {
			var ee = guard as LessEqualExpression
			value = path.variableValues.get((ee.leftOperand as DirectReferenceExpression).declaration)
			var ExpressionEvaluator evaluator = ExpressionEvaluator::INSTANCE
			var int i = evaluator.evaluate(((guard as LessEqualExpression)).getRightOperand())
			return value <= i
		} else if (guard instanceof ElseExpression) {
			return true
		} else if (guard instanceof LessExpression &&
			((guard as LessExpression)).getLeftOperand() instanceof DirectReferenceExpression &&
			((guard as LessExpression)).getRightOperand() instanceof IntegerLiteralExpression) {
			var ee = guard as LessExpression
			value = path.variableValues.get((ee.leftOperand as DirectReferenceExpression).declaration)
			var ExpressionEvaluator evaluator = ExpressionEvaluator::INSTANCE
			var int i = evaluator.evaluate(((guard as LessExpression)).getRightOperand())
			return value < i
		}
		return false
	}
}
