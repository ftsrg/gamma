/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.derivedfeatures;

import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction;
import hu.bme.mit.gamma.xsts.model.Action;
import hu.bme.mit.gamma.xsts.model.AssignmentAction;
import hu.bme.mit.gamma.xsts.model.AssumeAction;
import hu.bme.mit.gamma.xsts.model.AtomicAction;
import hu.bme.mit.gamma.xsts.model.EmptyAction;
import hu.bme.mit.gamma.xsts.model.HavocAction;
import hu.bme.mit.gamma.xsts.model.IfAction;
import hu.bme.mit.gamma.xsts.model.LoopAction;
import hu.bme.mit.gamma.xsts.model.MultiaryAction;
import hu.bme.mit.gamma.xsts.model.PrimedVariable;
import hu.bme.mit.gamma.xsts.model.SequentialAction;
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction;
import hu.bme.mit.gamma.xsts.model.XSTS;
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory;
import hu.bme.mit.gamma.xsts.model.XTransition;
import hu.bme.mit.gamma.xsts.model.XstsAnnotation;

public class XstsDerivedFeatures extends ExpressionModelDerivedFeatures {

	protected static XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE;
	
	public static XSTS getContainingXsts(EObject object) {
		return ecoreUtil.getSelfOrContainerOfType(object, XSTS.class);
	}
	
	public static boolean hasAnnotation(XSTS xSts, Class<? extends XstsAnnotation> annotation) {
		return xSts.getAnnotations().stream().anyMatch(it -> annotation.isInstance(it));
	}
	
	public static boolean hasClockVariable(XSTS xSts) {
		return xSts.getVariableDeclarations().stream().anyMatch(it -> isClock(it));
	}
	
	public static List<VariableDeclaration> getClockVariables(XSTS xSts) {
		return filterVariablesByAnnotation(xSts.getVariableDeclarations(),
				ClockVariableDeclarationAnnotation.class);
	}
	
	public static boolean isLocal(Declaration variable) {
		EObject container = variable.eContainer();
		return container instanceof VariableDeclarationAction;
	}
	
	public static List<Action> getAllActions(XSTS xSts) {
		List<Action> actions = new ArrayList<Action>();
		// Reference to the original actions
		actions.add(xSts.getVariableInitializingTransition().getAction());
		actions.add(xSts.getConfigurationInitializingTransition().getAction());
		actions.add(xSts.getEntryEventTransition().getAction());
		actions.add(xSts.getInEventTransition().getAction());
		actions.add(xSts.getOutEventTransition().getAction());
		actions.add(getMergedAction(xSts));
		return actions;
	}
	
	public static SequentialAction getInitializingAction(XSTS xSts) {
		SequentialAction sequentialAction = xStsFactory.createSequentialAction();
		Action variableInitializingAction = xSts.getVariableInitializingTransition().getAction();
		if (!(variableInitializingAction instanceof EmptyAction)) {
			sequentialAction.getActions().add(ecoreUtil.clone(variableInitializingAction));
		}
		Action configurationInitializingAction =
				xSts.getConfigurationInitializingTransition().getAction();
		if (!(configurationInitializingAction instanceof EmptyAction)) {
			sequentialAction.getActions().add(ecoreUtil.clone(configurationInitializingAction));
		}
		Action entryEventAction = xSts.getEntryEventTransition().getAction();
		if (!(entryEventAction instanceof EmptyAction)) {
			sequentialAction.getActions().add(ecoreUtil.clone(entryEventAction));
		}
		return sequentialAction;
	}
	
	public static SequentialAction getEnvironmentalAction(XSTS xSts) {
		SequentialAction sequentialAction = xStsFactory.createSequentialAction();
		sequentialAction.getActions().add(ecoreUtil.clone(xSts.getInEventTransition().getAction()));
		sequentialAction.getActions().add(ecoreUtil.clone(xSts.getOutEventTransition().getAction()));
		return sequentialAction;
	}
	
	public static XTransition getMergedTransition(XSTS xSts) {
		List<XTransition> transitions = xSts.getTransitions();
		if (transitions.size() != 1) {
			throw new IllegalArgumentException("Not one transition: " + transitions);
		}
		return transitions.get(0);
	}
	
	public static Action getMergedAction(XSTS xSts) {
		return getMergedTransition(xSts).getAction();
	}
	
	public static Declaration getOriginalVariable(Declaration variable) {
		if (variable instanceof PrimedVariable) {
			VariableDeclaration primedVariable = ((PrimedVariable) variable).getPrimedVariable();
			return getOriginalVariable(primedVariable);
		} else {
			return variable;
		}
	}

	public static boolean isFinalPrimedVariable(VariableDeclaration variable) {
		XSTS xSts = (XSTS) variable.eContainer();
		return xSts.getVariableDeclarations().stream()
				.noneMatch(it -> it instanceof PrimedVariable &&
						((PrimedVariable) it).getPrimedVariable() == variable);
	}

	public static int getPrimeCount(VariableDeclaration variable) {
		if (!(variable instanceof PrimedVariable)) {
			return 0;
		}
		PrimedVariable primedVariable = (PrimedVariable) variable;
		return getPrimeCount(primedVariable.getPrimedVariable()) + 1;
	}
	
	//
	
	public static List<Action> getBranches(IfAction action) {
		List<Action> branches = new ArrayList<Action>();
		branches.add(action.getThen());
		Action _else = action.getElse();
		if (_else instanceof IfAction) {
			IfAction elseIfAction = (IfAction) _else;
			branches.addAll(getBranches(elseIfAction));
		}
		else if (_else != null) {
			branches.add(_else);
		}
		else {
			// Necessary for variable inline
			branches.add(xStsFactory.createEmptyAction());
		}
		return branches;
	}
	
	public static List<Expression> getConditions(IfAction action) {
		List<Expression> conditions = new ArrayList<Expression>();
		conditions.add(action.getCondition());
		Action _else = action.getElse();
		if (_else instanceof IfAction) {
			IfAction elseIfAction = (IfAction) _else;
			conditions.addAll(getConditions(elseIfAction));
		}
		// Else is not If - no more conditions
		return conditions;
	}
	
	public static IfAction getLastIfAction(IfAction action) {
		Action _else = action.getElse();
		if (_else instanceof IfAction) {
			IfAction elseIfAction = (IfAction) _else;
			return getLastIfAction(elseIfAction);
		}
		return action;
	}
	
	//
	
	public static boolean isTrivialAssignment(SequentialAction action) {
		List<Action> xStsSubactions = action.getActions();
		if (xStsSubactions.stream().filter(it -> it instanceof AssumeAction).count() == 1
				&& xStsSubactions.stream().filter(it -> it instanceof AssignmentAction).count() == 1) {
			return isTrivialAssignment(
					(AssumeAction) xStsSubactions.stream()
						.filter(it -> it instanceof AssumeAction).findFirst().get(),
					(AssignmentAction) xStsSubactions.stream()
						.filter(it -> it instanceof AssignmentAction).findFirst()
							.get());
		}
		return false;
	}
	
	public static boolean isTrivialAssignment(AssumeAction assumeAction, AssignmentAction action) {
		Expression xStsAssumption = assumeAction.getAssumption();
		if (xStsAssumption instanceof EqualityExpression) {
			return isTrivialAssignment((EqualityExpression) xStsAssumption, action);
		}
		return false;
	}
	
	public static AtomicAction getFirstAtomicAction(Action action) {
		if (action instanceof AtomicAction) {
			return (AtomicAction) action;
		}
		if (action instanceof MultiaryAction) {
			MultiaryAction multiaryAction = (MultiaryAction) action;
			List<Action> actions = multiaryAction.getActions();
			if (actions.isEmpty()) {
				throw new IllegalArgumentException("Empty action list");
			}
			Action firstAction = actions.get(0);
			return getFirstAtomicAction(firstAction);
		}
		throw new IllegalArgumentException("Not supported action: " + action);
	}

	private static boolean isTrivialAssignment(EqualityExpression expression, AssignmentAction action) {
		Expression xStsLeftOperand = expression.getLeftOperand();
		Expression xStsRightOperand = expression.getRightOperand();
		DirectReferenceExpression directReferenceExpression = (DirectReferenceExpression) action.getLhs();
		Declaration xStsDeclaration = directReferenceExpression.getDeclaration();
		Expression xStsAssignmentRhs = action.getRhs();
		// region_name == state_name
		if (xStsLeftOperand instanceof DirectReferenceExpression) {
			if (expressionUtil.getDeclaration(xStsLeftOperand) == xStsDeclaration
					&& ecoreUtil.helperEquals(xStsRightOperand, xStsAssignmentRhs)) {
				return true;
			}
		}
		// state_name == region_name
		if (xStsRightOperand instanceof DirectReferenceExpression) {
			if (expressionUtil.getDeclaration(xStsRightOperand) == xStsDeclaration
					&& ecoreUtil.helperEquals(xStsLeftOperand, xStsAssignmentRhs)) {
				return true;
			}
		}
		return false;
	}

	public static boolean isDefinitelyTrueAssumeAction(AssumeAction action) {
		Expression expression = action.getAssumption();
		return evaluator.isDefinitelyTrueExpression(expression);
	}

	public static boolean isDefinitelyFalseAssumeAction(AssumeAction action) {
		Expression expression = action.getAssumption();
		return evaluator.isDefinitelyFalseExpression(expression);
	}
	
	public static boolean isNullOrEmptyAction(Action action) {
		return action == null || action instanceof EmptyAction;
	}
	
	public static boolean isEffectlessAction(Action action) {
		if (isNullOrEmptyAction(action)) {
			return true;
		}
		if (action instanceof AssignmentAction) {
			AssignmentAction assignmentAction = (AssignmentAction) action;
			ReferenceExpression lhs = assignmentAction.getLhs();
			Expression rhs = assignmentAction.getRhs();
			return ecoreUtil.helperEquals(lhs, rhs);
		}
		if (action instanceof IfAction) {
			IfAction ifAction = (IfAction) action;
			Action then = ifAction.getThen();
			Action _else = ifAction.getElse();
			return isEffectlessAction(then) && isEffectlessAction(_else);
		}
		if (action instanceof LoopAction) {
			LoopAction loopAction = (LoopAction) action;
			Action forAction = loopAction.getAction();
			// Range could be examined, too
			return isEffectlessAction(forAction);
		}
		if (action instanceof MultiaryAction) {
			MultiaryAction multiaryAction = (MultiaryAction) action;
			return multiaryAction.getActions().stream().allMatch(it -> isEffectlessAction(it));
		}
		return false;
	}

	// Read-write

	private static Set<VariableDeclaration> _getReadVariables(AssumeAction action) {
		return expressionUtil.getReferredVariables(action.getAssumption());
	}
	
	private static Set<VariableDeclaration> _getReadVariables(HavocAction action) {
		return Collections.emptySet();
	}

	private static Set<VariableDeclaration> _getReadVariables(AssignmentAction action) {
		return expressionUtil.getReferredVariables(action.getRhs());
	}
	
	private static Set<VariableDeclaration> _getReadVariables(VariableDeclarationAction action) {
		VariableDeclaration variable = action.getVariableDeclaration();
		Expression initialValue = variable.getExpression();
		if (initialValue != null) {
			return expressionUtil.getReferredVariables(initialValue);
		}
		return Collections.emptySet();
	}

	private static Set<VariableDeclaration> _getReadVariables(EmptyAction action) {
		return Collections.emptySet();
	}
	
	private static Set<VariableDeclaration> _getReadVariables(LoopAction action) {
		Action subAction = action.getAction();
		return getReadVariables(subAction);
	}
	
	private static Set<VariableDeclaration> _getReadVariables(IfAction action) {
		Set<VariableDeclaration> readVariables = new HashSet<VariableDeclaration>();
		readVariables.addAll(expressionUtil.getReferredVariables(action.getCondition()));
		readVariables.addAll(getReadVariables(action.getThen()));
		Action _else = action.getElse();
		if (_else != null) {
			readVariables.addAll(getReadVariables(_else));
		}
		return readVariables;
	}

	private static Set<VariableDeclaration> _getReadVariables(MultiaryAction action) {
		Set<VariableDeclaration> variableList = new HashSet<VariableDeclaration>();
		List<Action> _actions = action.getActions();
		for (Action containedAction : _actions) {
			Set<VariableDeclaration> _readVariables = getReadVariables(containedAction);
			variableList.addAll(_readVariables);
		}
		return variableList;
	}

	private static Set<VariableDeclaration> _getWrittenVariables(AssumeAction action) {
		return Collections.emptySet();
	}

	private static Set<VariableDeclaration> _getWrittenVariables(AbstractAssignmentAction action) {
		return expressionUtil.getReferredVariables(
				action.getLhs());
	}
	
	private static Set<VariableDeclaration> _getWrittenVariables(VariableDeclarationAction action) {
		return Collections.emptySet(); // Empty, as this is a declaration, not a "writing"
	}

	private static Set<VariableDeclaration> _getWrittenVariables(EmptyAction action) {
		return Collections.emptySet();
	}
	
	private static Set<VariableDeclaration> _getWrittenVariables(LoopAction action) {
		Action subAction = action.getAction();
		return getWrittenVariables(subAction);
	}
	
	private static Set<VariableDeclaration> _getWrittenVariables(IfAction action) {
		Set<VariableDeclaration> writtenVariables = new HashSet<VariableDeclaration>();
		writtenVariables.addAll(getWrittenVariables(action.getThen()));
		Action _else = action.getElse();
		if (_else != null) {
			writtenVariables.addAll(getWrittenVariables(_else));
		}
		return writtenVariables;
	}

	private static Set<VariableDeclaration> _getWrittenVariables(MultiaryAction action) {
		Set<VariableDeclaration> variableList = new HashSet<VariableDeclaration>();
		List<Action> _actions = action.getActions();
		for (Action containedAction : _actions) {
			Set<VariableDeclaration> _writtenVariables = getWrittenVariables(containedAction);
			variableList.addAll(_writtenVariables);
		}
		return variableList;
	}

	public static Set<VariableDeclaration> getReadVariables(Action action) {
		if (action instanceof AssignmentAction) {
			return _getReadVariables((AssignmentAction) action);
		} else if (action instanceof HavocAction) {
			return _getReadVariables((HavocAction) action);
		} else if (action instanceof VariableDeclarationAction) {
			return _getReadVariables((VariableDeclarationAction) action);
		} else if (action instanceof AssumeAction) {
			return _getReadVariables((AssumeAction) action);
		} else if (action instanceof EmptyAction) {
			return _getReadVariables((EmptyAction) action);
		} else if (action instanceof LoopAction) {
			return _getReadVariables((LoopAction) action);
		} else if (action instanceof IfAction) {
			return _getReadVariables((IfAction) action);
		} else if (action instanceof MultiaryAction) {
			return _getReadVariables((MultiaryAction) action);
		} else {
			throw new IllegalArgumentException("Unhandled action type: " + action);
		}
	}

	public static Set<VariableDeclaration> getWrittenVariables(Action action) {
		if (action instanceof AbstractAssignmentAction) {
			return _getWrittenVariables((AbstractAssignmentAction) action);
		} else if (action instanceof VariableDeclarationAction) {
			return _getWrittenVariables((VariableDeclarationAction) action);
		} else if (action instanceof AssumeAction) {
			return _getWrittenVariables((AssumeAction) action);
		} else if (action instanceof EmptyAction) {
			return _getWrittenVariables((EmptyAction) action);
		} else if (action instanceof LoopAction) {
			return _getWrittenVariables((LoopAction) action);
		} else if (action instanceof IfAction) {
			return _getWrittenVariables((IfAction) action);
		} else if (action instanceof MultiaryAction) {
			return _getWrittenVariables((MultiaryAction) action);
		} else {
			throw new IllegalArgumentException("Unhandled action type: " + action);
		}
	}
	
	public static Set<VariableDeclaration> getReferredVariables(Action action) {
		Set<VariableDeclaration> referredVariables =
				new HashSet<VariableDeclaration>(getReadVariables(action));
		referredVariables.addAll(getWrittenVariables(action));
		return referredVariables;
	}
	
	public static Set<VariableDeclaration> getWrittenOnlyVariables(Action action) {
		Set<VariableDeclaration> writtenOnlyVariables =
				new HashSet<VariableDeclaration>(getWrittenVariables(action));
		writtenOnlyVariables.removeAll(getReadVariables(action));
		return writtenOnlyVariables;
	}

	public static Set<VariableDeclaration> getWrittenOnlyVariables(
			Collection<? extends Action> actions) {
		Set<VariableDeclaration> writtenOnlyVariables = new HashSet<VariableDeclaration>();
		
		for (Action action : actions) {
			writtenOnlyVariables.addAll(getWrittenVariables(action));
		}
		for (Action action : actions) {
			writtenOnlyVariables.removeAll(getReadVariables(action));
		}
		
		return writtenOnlyVariables;
	}

	public static Set<VariableDeclaration> getWrittenOnlyVariables(XSTS xSts) {
		return getWrittenOnlyVariables(
				getAllActions(xSts));
	}
	
	public static Map<Action, Entry<Set<VariableDeclaration>, Set<VariableDeclaration>>>
			getReadAndWrittenVariablesOfActions(MultiaryAction action) {
		Map<Action, Entry<Set<VariableDeclaration>, Set<VariableDeclaration>>> readAndWrittenVariables =
				new HashMap<Action, Entry<Set<VariableDeclaration>, Set<VariableDeclaration>>>();
		
		for (Action subaction : action.getActions()) {
			readAndWrittenVariables.put(subaction,
					new SimpleEntry<Set<VariableDeclaration>, Set<VariableDeclaration>>(
							getReadVariables(subaction), getWrittenVariables(subaction))
			);
		}
		
		return readAndWrittenVariables;
	}
	
}
