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
package hu.bme.mit.gamma.xsts.derivedfeatures;

import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.ClockVariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression;
import hu.bme.mit.gamma.expression.model.LiteralExpression;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.util.Triple;
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction;
import hu.bme.mit.gamma.xsts.model.Action;
import hu.bme.mit.gamma.xsts.model.ActionAnnotation;
import hu.bme.mit.gamma.xsts.model.AssignmentAction;
import hu.bme.mit.gamma.xsts.model.AssumeAction;
import hu.bme.mit.gamma.xsts.model.AtomicAction;
import hu.bme.mit.gamma.xsts.model.EmptyAction;
import hu.bme.mit.gamma.xsts.model.EnvironmentalInvariantAnnotation;
import hu.bme.mit.gamma.xsts.model.HavocAction;
import hu.bme.mit.gamma.xsts.model.IfAction;
import hu.bme.mit.gamma.xsts.model.InternalInvariantAnnotation;
import hu.bme.mit.gamma.xsts.model.InvariantAnnotation;
import hu.bme.mit.gamma.xsts.model.LoopAction;
import hu.bme.mit.gamma.xsts.model.MultiaryAction;
import hu.bme.mit.gamma.xsts.model.PrimedVariable;
import hu.bme.mit.gamma.xsts.model.SequentialAction;
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction;
import hu.bme.mit.gamma.xsts.model.XSTS;
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory;
import hu.bme.mit.gamma.xsts.model.XTransition;
import hu.bme.mit.gamma.xsts.model.XstsAnnotation;
import hu.bme.mit.gamma.xsts.util.XstsActionUtil;

public class XstsDerivedFeatures extends ExpressionModelDerivedFeatures {

	protected static final XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE;
	protected static final XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE;
	
	//
	
	public static boolean isContainedByXsts(EObject object) {
		return getContainingXsts(object) != null;
	}
	
	public static XSTS getContainingXsts(EObject object) {
		return ecoreUtil.getSelfOrContainerOfType(object, XSTS.class);
	}
	
	public static boolean hasAnnotation(XSTS xSts, Class<? extends XstsAnnotation> annotation) {
		List<XstsAnnotation> annotations = xSts.getAnnotations();
		return annotations.stream().anyMatch(it -> annotation.isInstance(it));
	}
	
	public static boolean hasAnnotation(Action action, Class<? extends ActionAnnotation> annotation) {
		List<ActionAnnotation> annotations = action.getAnnotations();
		return annotations.stream().anyMatch(it -> annotation.isInstance(it));
	}
	
	public static boolean hasClockVariable(XSTS xSts) {
		List<VariableDeclaration> variableDeclarations = xSts.getVariableDeclarations();
		return variableDeclarations.stream().anyMatch(it -> isClock(it));
	}
	
	public static boolean hasInvariants(XSTS xSts) {
		List<AssumeAction> actions = ecoreUtil.getAllContentsOfType(xSts, AssumeAction.class);
		return actions.stream().anyMatch(it -> isInvariant(it));
	}
	
	public static boolean isInvariant(Action action) {
		return hasAnnotation(action, InvariantAnnotation.class);
	}
	
	public static boolean isEnvironmentalInvariant(Action action) {
		return hasAnnotation(action, EnvironmentalInvariantAnnotation.class);
	}
	
	public static boolean isInternalInvariant(Action action) {
		return hasAnnotation(action, InternalInvariantAnnotation.class);
	}
	
	public static List<VariableDeclaration> getClockVariables(XSTS xSts) {
		return filterVariablesByAnnotation(xSts.getVariableDeclarations(),
				ClockVariableDeclarationAnnotation.class);
	}
	
	public static boolean isTimed(XSTS xSts) {
		List<VariableDeclaration> clockVariables = getClockVariables(xSts);
		return !clockVariables.isEmpty();
	}
	
	public static boolean isLocal(Declaration variable) {
		EObject container = variable.eContainer();
		return container instanceof VariableDeclarationAction;
	}
	
	public static boolean isGlobal(Declaration variable) {
		return !isLocal(variable);
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
			sequentialAction.getActions().add(
					ecoreUtil.clone(variableInitializingAction));
		}
		Action configurationInitializingAction =
				xSts.getConfigurationInitializingTransition().getAction();
		if (!(configurationInitializingAction instanceof EmptyAction)) {
			sequentialAction.getActions().add(
					ecoreUtil.clone(configurationInitializingAction));
		}
		Action entryEventAction = xSts.getEntryEventTransition().getAction();
		if (!(entryEventAction instanceof EmptyAction)) {
			sequentialAction.getActions().add(
					ecoreUtil.clone(entryEventAction));
		}
		return sequentialAction;
	}
	
	public static SequentialAction getEnvironmentalAction(XSTS xSts) {
		SequentialAction sequentialAction = xStsFactory.createSequentialAction();
		sequentialAction.getActions().add(
				ecoreUtil.clone(
						xSts.getInEventTransition().getAction()));
		sequentialAction.getActions().add(
				ecoreUtil.clone(
						xSts.getOutEventTransition().getAction()));
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
		if (variable instanceof PrimedVariable newPrimedVariable) {
			VariableDeclaration primedVariable = newPrimedVariable.getPrimedVariable();
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
	
	public static List<PrimedVariable> getFinalPrimedVariables(XSTS xSts) {
		List<PrimedVariable> primedVariables = new ArrayList<PrimedVariable>();
		for (VariableDeclaration variableDeclaration : xSts.getVariableDeclarations()) {
			if (variableDeclaration instanceof PrimedVariable primedVariable) {
				primedVariables.add(primedVariable);
			}
		}
		
		List<PrimedVariable> finalPrimedVariables = getGreatestPrimedVariables(primedVariables);
		
		return finalPrimedVariables;
	}
	
	public static List<PrimedVariable> getGreatestPrimedVariables(
			Collection<? extends PrimedVariable> primedVariables) {
		List<PrimedVariable> greatestPrimedVariables = new ArrayList<PrimedVariable>(primedVariables);
		
		for (PrimedVariable primedVariable : primedVariables) {
			VariableDeclaration previousPrimedVariable = primedVariable.getPrimedVariable();
			greatestPrimedVariables.remove(previousPrimedVariable);
		}
		
		return greatestPrimedVariables;
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
	
	public static List<Action> getActions(MultiaryAction action, int from, int to) {
		List<Action> subactions = action.getActions();
		return subactions.subList(from, to);
	}
	
	public static List<Action> getActionsToLast(MultiaryAction action, int from) {
		List<Action> subactions = action.getActions();
		return getActions(action, from, subactions.size());
	}
	
	public static List<Action> getActionsSkipFirst(MultiaryAction action) {
		return getActionsToLast(action, 1);
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
		DirectReferenceExpression reference = (DirectReferenceExpression) action.getLhs();
		Declaration xStsDeclaration = reference.getDeclaration();
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
	
	public static boolean isLhs(Expression expression) {
		EObject container = expression.eContainer();
		if (container instanceof AbstractAssignmentAction action) {
			return action.getLhs() == expression;
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
			// Examining range
			IntegerRangeLiteralExpression range = loopAction.getRange();
			Expression leftOperand = ExpressionModelDerivedFeatures.getLeft(range, true);
			Expression rightOperand = ExpressionModelDerivedFeatures.getRight(range, true);
			int left = evaluator.evaluateInteger(leftOperand);
			int right = evaluator.evaluateInteger(rightOperand);
			if (right - left <= 0) {
				return true;
			}
			// Range is good, examining action
			return isEffectlessAction(forAction);
		}
		if (action instanceof MultiaryAction) {
			MultiaryAction multiaryAction = (MultiaryAction) action;
			return multiaryAction.getActions().stream().allMatch(it -> isEffectlessAction(it));
		}
		return false;
	}
	
	public static boolean isFirstActionAssume(Action action) {
		try {
			AtomicAction firstAtomicAction = getFirstAtomicAction(action);
			return firstAtomicAction instanceof AssumeAction;
		} catch (IllegalArgumentException e) {
			return false;
		}
	}
	
	public static AssumeAction getFirstActionAssume(Action action) {
		AtomicAction firstAtomicAction = getFirstAtomicAction(action);
		return (AssumeAction) firstAtomicAction;
	}

	// Read-write

	private static Set<VariableDeclaration> _getReadVariables(AssumeAction action) {
		return expressionUtil.getReferredVariables(
				action.getAssumption());
	}
	
	private static Set<VariableDeclaration> _getReadVariables(HavocAction action) {
		return Collections.emptySet();
	}

	private static Set<VariableDeclaration> _getReadVariables(AssignmentAction action) {
		Set<VariableDeclaration> readVariables = new HashSet<VariableDeclaration>();

		Set<VariableDeclaration> writtenVariables = getWrittenVariables(action); 
		readVariables.addAll(
				expressionUtil.getReferredVariables(
						action.getLhs())); // Needed for array indexes
		readVariables.removeAll(writtenVariables); // Removing the written array
		readVariables.addAll(
				expressionUtil.getReferredVariables(
						action.getRhs()));
		
		return readVariables;
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
		Set<VariableDeclaration> readVariables = new HashSet<VariableDeclaration>();
		
		IntegerRangeLiteralExpression range = action.getRange();
		readVariables.addAll(
				expressionUtil.getReferredVariables(
						range.getLeftOperand()));
		readVariables.addAll(
				expressionUtil.getReferredVariables(
						range.getRightOperand()));
		
		Action subAction = action.getAction();
		readVariables.addAll(
				getReadVariables(subAction));
		
		return readVariables;
	}
	
	private static Set<VariableDeclaration> _getReadVariables(IfAction action) {
		Set<VariableDeclaration> readVariables = new HashSet<VariableDeclaration>();
		
		readVariables.addAll(
				expressionUtil.getReferredVariables(
						action.getCondition()));
		readVariables.addAll(
				getReadVariables(
						action.getThen()));
		Action _else = action.getElse();
		if (_else != null) {
			readVariables.addAll(
					getReadVariables(_else));
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
	
	private static Set<VariableDeclaration> _getExternallyReadVariables(AssignmentAction action) {
		Set<VariableDeclaration> readVariables = new HashSet<VariableDeclaration>();
		
		readVariables.addAll(
				getReadVariables(action));
		readVariables.removeAll(
				getWrittenVariables(action));
		
		return readVariables;
	}
	
	private static Set<VariableDeclaration> _getExternallyReadVariables(LoopAction action) {
		Set<VariableDeclaration> readVariables = new HashSet<VariableDeclaration>();
		
		IntegerRangeLiteralExpression range = action.getRange();
		readVariables.addAll(
				expressionUtil.getReferredVariables(
						range.getLeftOperand()));
		readVariables.addAll(
				expressionUtil.getReferredVariables(
						range.getRightOperand()));
		
		Action subAction = action.getAction();
		readVariables.addAll(
				getExternallyReadVariables(subAction));
		
		return readVariables;
	}
	
	private static Set<VariableDeclaration> _getExternallyReadVariables(IfAction action) {
		Set<VariableDeclaration> readVariables = new HashSet<VariableDeclaration>();
		
		readVariables.addAll(
				expressionUtil.getReferredVariables(
						action.getCondition()));
		readVariables.addAll(
				getExternallyReadVariables(
						action.getThen()));
		Action _else = action.getElse();
		if (_else != null) {
			readVariables.addAll(
					getExternallyReadVariables(_else));
		}
		
		return readVariables;
	}

	private static Set<VariableDeclaration> _getExternallyReadVariables(MultiaryAction action) {
		Set<VariableDeclaration> variableList = new HashSet<VariableDeclaration>();
		
		List<Action> _actions = action.getActions();
		for (Action containedAction : _actions) {
			Set<VariableDeclaration> _readVariables = getExternallyReadVariables(containedAction);
			variableList.addAll(_readVariables);
		}
		
		return variableList;
	}
	
	private static Set<VariableDeclaration> _getWrittenVariables(AssumeAction action) {
		return Collections.emptySet();
	}

	private static Set<VariableDeclaration> _getWrittenVariables(AbstractAssignmentAction action) {
		VariableDeclaration accessedDeclaration = (VariableDeclaration)
				xStsActionUtil.getAccessedDeclaration(
						action.getLhs()); // Not every variable, just the access
		return Set.of(accessedDeclaration);
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
		
		writtenVariables.addAll(
				getWrittenVariables(
						action.getThen()));
		Action _else = action.getElse();
		if (_else != null) {
			writtenVariables.addAll(
					getWrittenVariables(_else));
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
	
	public static Set<VariableDeclaration> getExternallyReadVariables(Action action) {
		if (action instanceof AssignmentAction) {
			return _getExternallyReadVariables((AssignmentAction) action);
		} else if (action instanceof HavocAction) {
			return _getReadVariables((HavocAction) action);
		} else if (action instanceof VariableDeclarationAction) {
			return _getReadVariables((VariableDeclarationAction) action);
		} else if (action instanceof AssumeAction) {
			return _getReadVariables((AssumeAction) action);
		} else if (action instanceof EmptyAction) {
			return _getReadVariables((EmptyAction) action);
		} else if (action instanceof LoopAction) {
			return _getExternallyReadVariables((LoopAction) action);
		} else if (action instanceof IfAction) {
			return _getExternallyReadVariables((IfAction) action);
		} else if (action instanceof MultiaryAction) {
			return _getExternallyReadVariables((MultiaryAction) action);
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
				new HashSet<VariableDeclaration>(
						getReadVariables(action));
		referredVariables.addAll(
				getWrittenVariables(action));
		return referredVariables;
	}
	
	public static Set<VariableDeclaration> getWrittenOnlyVariables(Action action) {
		Set<VariableDeclaration> writtenOnlyVariables =
				new HashSet<VariableDeclaration>(
						getWrittenVariables(action));
		writtenOnlyVariables.removeAll(
				getReadVariables(action));
		return writtenOnlyVariables;
	}

	public static Set<VariableDeclaration> getWrittenOnlyVariables(
			Collection<? extends Action> actions) {
		Set<VariableDeclaration> writtenOnlyVariables = new LinkedHashSet<VariableDeclaration>(
				getWrittenVariables(actions));
		
		for (Action action : actions) {
			writtenOnlyVariables.removeAll(
					getReadVariables(action));
		}
		
		return writtenOnlyVariables;
	}
	
	public static Set<VariableDeclaration> getWrittenVariables(
			Collection<? extends Action> actions) {
		Set<VariableDeclaration> writtenVariables = new LinkedHashSet<VariableDeclaration>();
		
		for (Action action : actions) {
			writtenVariables.addAll(
					getWrittenVariables(action));
		}
		
		return writtenVariables;
	}
	
	public static Set<VariableDeclaration> getReadVariables(
			Collection<? extends Action> actions) {
		Set<VariableDeclaration> readVariables = new LinkedHashSet<VariableDeclaration>();
		
		for (Action action : actions) {
			readVariables.addAll(
					getReadVariables(action));
		}
		
		return readVariables;
	}
	
	public static Set<VariableDeclaration> getReadOnlyVariables(
			Collection<? extends Action> actions) {
		Set<VariableDeclaration> readOnlyVariables = new LinkedHashSet<VariableDeclaration>(
				getReadVariables(actions));
		
		for (Action action : actions) {
			readOnlyVariables.removeAll(
					getWrittenVariables(action));
		}
		
		return readOnlyVariables;
	}
	
	public static Set<VariableDeclaration> getExternallyReadVariables(
			Collection<? extends Action> actions) {
		Set<VariableDeclaration> externallyReadVariables = new LinkedHashSet<VariableDeclaration>();
		
		for (Action action : actions) {
			externallyReadVariables.addAll(
					getExternallyReadVariables(action));
		}
		
		return externallyReadVariables;
	}
	
	public static Set<VariableDeclaration> getReadVariables(XSTS xSts) {
		return getReadVariables(
				getAllActions(xSts));
	}
	
	public static Set<VariableDeclaration> getReadOnlyVariables(XSTS xSts) {
		Action action = xSts.getVariableInitializingTransition().getAction();
		// Removing variable initialization action, as every variable is written here
		List<Action> allActionsExceptVariableInit = getAllActions(xSts);
		allActionsExceptVariableInit.remove(action);
		
		return getReadOnlyVariables(allActionsExceptVariableInit);
	}
	
	public static Set<VariableDeclaration> getExternallyReadVariables(XSTS xSts) {
		return getExternallyReadVariables(
				getAllActions(xSts));
	}
	
	public static Set<VariableDeclaration> getWrittenVariables(XSTS xSts) {
		return getWrittenVariables(
				getAllActions(xSts));
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
							getReadVariables(subaction), getWrittenVariables(subaction)));
		}
		
		return readAndWrittenVariables;
	}
	
	//
	
	public static Set<VariableDeclaration> getAllReaderVariables(
			Collection<? extends VariableDeclaration> variables) {
		Set<VariableDeclaration> writtenVariables = new HashSet<VariableDeclaration>();
		
		for (VariableDeclaration variable : variables) {
			writtenVariables.addAll(
					getAllReaderVariables(variable));
		}
		
		return writtenVariables;
	}
	
	public static Set<VariableDeclaration> getAllReaderVariables(VariableDeclaration variable) {
		Set<VariableDeclaration> writtenVariables = new HashSet<VariableDeclaration>();
		
		EObject root = ecoreUtil.getRoot(variable);
		List<AssignmentAction> assignmentActions = ecoreUtil.getSelfAndAllContentsOfType(
				root, AssignmentAction.class);
		
		int size = -1;
		while (size != writtenVariables.size()) {
			size = writtenVariables.size();
			
			for (AssignmentAction assignmentAction : assignmentActions) {
				Set<VariableDeclaration> readVariables = getReadVariables(assignmentAction);
				if (readVariables.contains(variable) ||
						javaUtil.containsAny(readVariables, writtenVariables)) {
					Set<VariableDeclaration> writtenVariablesOfAction =
							getWrittenVariables(assignmentAction); // Only one
					
					writtenVariables.addAll(writtenVariablesOfAction);
				}
			}
		}
		
		return writtenVariables;
	}
	
	//
	
	public static Set<VariableDeclaration> getVariablesReferencedFromConditions(XSTS xSts) {
		Set<VariableDeclaration> variablesReferencedFromConditions = new HashSet<VariableDeclaration>();
		
		List<Expression> conditions = new ArrayList<Expression>();
		
		List<AssumeAction> assumeActions = ecoreUtil.getAllContentsOfType(xSts, AssumeAction.class);
		List<IfAction> ifActions = ecoreUtil.getAllContentsOfType(xSts, IfAction.class);
		List<LoopAction> loopActions = ecoreUtil.getAllContentsOfType(xSts, LoopAction.class);
		
		conditions.addAll(
				assumeActions.stream()
				.map(it -> it.getAssumption())
				.collect(Collectors.toList()));
		
		conditions.addAll(
				ifActions.stream()
				.map(it -> it.getCondition())
				.collect(Collectors.toList()));
		
		conditions.addAll(
				loopActions.stream()
				.map(it -> it.getRange())
				.collect(Collectors.toList()));
		
		for (Expression condition : conditions) {
			variablesReferencedFromConditions.addAll(
					xStsActionUtil.getReferredVariables(condition));
		}
		
		return variablesReferencedFromConditions;
	}
	
	//

	public static boolean areSubactionsOrthogonal(MultiaryAction action) {
		List<Collection<VariableDeclaration>> readVariables =
				new ArrayList<Collection<VariableDeclaration>>();
		List<Collection<VariableDeclaration>> writtenVariables =
				new ArrayList<Collection<VariableDeclaration>>();
		List<Action> subactions = action.getActions();
		for (int i = 0; i < subactions.size(); i++) {
			var xStsSubaction = subactions.get(i);
			
			var newlyWrittenVariables = getWrittenVariables(xStsSubaction);
			writtenVariables.add(newlyWrittenVariables);
			
			var newlyReadVariables = new HashSet<VariableDeclaration>();
			newlyReadVariables.addAll(
					getReadVariables(xStsSubaction));
			newlyReadVariables.removeAll(newlyWrittenVariables);
			readVariables.add(newlyReadVariables);
			
			for (int j = 0; j < i; j++) {
				Collection<VariableDeclaration> previouslyReadVariables = readVariables.get(j);
				Collection<VariableDeclaration> previouslyWrittenVariables = writtenVariables.get(j);
				// If a written variable is read or written somewhere, the
				// parallel or unordered action cannot be optimized
				if (previouslyReadVariables.stream().anyMatch(it -> newlyWrittenVariables.contains(it)) ||
						previouslyWrittenVariables.stream().anyMatch(it -> newlyWrittenVariables.contains(it)) ||
						previouslyWrittenVariables.stream().anyMatch(it -> newlyReadVariables.contains(it))) {
					return false;
				}
			}
		}
		
		return true;
	}
	
	//
	
	public static Map<VariableDeclaration, Entry<Integer, Integer>>
			getIntegerVariableCodomains(XSTS xSts) {
		
		Triple<Map<VariableDeclaration, List<LiteralExpression>>, Map<VariableDeclaration, List<VariableDeclaration>>,
			Set<VariableDeclaration>> variableAssignmentGroups = getVariableAssignmentGroups(xSts);
		
		Map<VariableDeclaration, List<LiteralExpression>> integerVariableAssignments = variableAssignmentGroups.getFirst();
		Map<VariableDeclaration, List<VariableDeclaration>> variableVariableAssignments = variableAssignmentGroups.getSecond();
		Set<VariableDeclaration> notIntegerLiteralVariables = variableAssignmentGroups.getThird();
		
		Map<VariableDeclaration, List<LiteralExpression>> integerLiteralVariableAssignments =
				new HashMap<VariableDeclaration, List<LiteralExpression>>(integerVariableAssignments);
		Set<VariableDeclaration> integerLiteralVariables = integerLiteralVariableAssignments.keySet();
		Set<VariableDeclaration> variableVariables = variableVariableAssignments.keySet();
		integerLiteralVariables.removeAll(variableVariables);
		integerLiteralVariables.removeAll(notIntegerLiteralVariables);
		// Every variable in this collection now has only integer value assignments
		
		// 1: Calculating precise domains based on these values
		Map<VariableDeclaration, Entry<Integer, Integer>> integerVariableMinMax = calculatePresiceCodomains(
				integerLiteralVariableAssignments, integerLiteralVariables);
		
		// 2: Extending min/max values for variables that need to hold low/large values
		// e.g., a := 70.000
		extendCodomainsForLiteralAssignments(integerVariableAssignments, integerVariableMinMax);
		
		// 3: Checking 'var := var2' assignments - note that this is done after the 'extension'
		extendCodomainsForVariableAssignments(integerVariableAssignments, variableVariableAssignments,
				notIntegerLiteralVariables, variableVariables, integerVariableMinMax);
		
		return integerVariableMinMax;
	}
	
	public static Map<VariableDeclaration, LiteralExpression>
			getOneValueVariableCodomains(XSTS xSts) {
				
		Triple<Map<VariableDeclaration, List<LiteralExpression>>, Map<VariableDeclaration, List<VariableDeclaration>>,
			Set<VariableDeclaration>> variableAssignmentGroups = getVariableAssignmentGroups(xSts);
		
		Map<VariableDeclaration, List<LiteralExpression>> integerVariableAssignments = variableAssignmentGroups.getFirst();
		Map<VariableDeclaration, List<VariableDeclaration>> variableVariableAssignments = variableAssignmentGroups.getSecond();
		Set<VariableDeclaration> notIntegerLiteralVariables = variableAssignmentGroups.getThird();
		
		Map<VariableDeclaration, List<LiteralExpression>> integerLiteralVariableAssignments =
				new HashMap<VariableDeclaration, List<LiteralExpression>>(integerVariableAssignments);
		Set<VariableDeclaration> integerLiteralVariables = integerLiteralVariableAssignments.keySet();
		Set<VariableDeclaration> variableVariables = variableVariableAssignments.keySet();
		integerLiteralVariables.removeAll(variableVariables);
		integerLiteralVariables.removeAll(notIntegerLiteralVariables);
		// Every variable in this collection now has only integer value assignments
		
		// 1: Calculating precise domains based on these values
		Map<VariableDeclaration, Entry<Integer, Integer>> integerVariableMinMax = calculatePresiceCodomains(
				integerLiteralVariableAssignments, integerLiteralVariables);
		
		// Creating literal expressions
		Map<VariableDeclaration, LiteralExpression> variableLiterals =
				new HashMap<VariableDeclaration, LiteralExpression>();
		for (VariableDeclaration variableDeclaration : integerVariableMinMax.keySet()) {
			Entry<Integer, Integer> values = integerVariableMinMax.get(variableDeclaration);
			Integer min = values.getKey();
			Integer max = values.getValue();
			if (min == max) { // If min == max -> there is only one valid value 
				variableLiterals.put(variableDeclaration,
						literalCreator.of(variableDeclaration, min));
			}
		}
		
		return variableLiterals;
	}

	public static void extendCodomainsForVariableAssignments(
			Map<VariableDeclaration, List<LiteralExpression>> integerVariableAssignments,
			Map<VariableDeclaration, List<VariableDeclaration>> variableVariableAssignments,
			Set<VariableDeclaration> notIntegerLiteralVariables,
			Set<VariableDeclaration> variableVariables,
			Map<VariableDeclaration, Entry<Integer, Integer>> integerVariableMinMax) {
		variableVariables.removeAll(notIntegerLiteralVariables);
		// Every variable in this collection now has only integer value assignments
		// or 'var := var2' assignments
		int size = 0;
		while (size != variableVariableAssignments.size()) {
			size = variableVariableAssignments.size(); // While we can remove vars from here
			
			for (VariableDeclaration assignedVariable :
						new ArrayList<VariableDeclaration>(variableVariables)) {
				List<VariableDeclaration> rhsVariables = variableVariableAssignments.get(assignedVariable);
				if (rhsVariables.stream()
						.allMatch(it ->
							integerVariableMinMax.keySet().contains(it))) {
					List<Integer> mins = new ArrayList<Integer>();
					List<Integer> maxs = new ArrayList<Integer>();
					
					// Rhs variables
					for (VariableDeclaration rhsVariable : rhsVariables) {
						VariableDeclaration container = rhsVariable;
						Entry<Integer, Integer> minMax = integerVariableMinMax.get(container);
						mins.add(
								minMax.getKey());
						maxs.add(
								minMax.getValue());
					}
					
					// Rhs integer literals
					if (integerVariableAssignments.containsKey(assignedVariable)) {
						for (LiteralExpression integerLiteral :
								integerVariableAssignments.get(assignedVariable)) {
							mins.add(
									xStsActionUtil.toInteger(integerLiteral));
							maxs.add(
									xStsActionUtil.toInteger(integerLiteral));
						}
					}
					
					int min = mins.stream()
							.min((o1, o2) -> o1.compareTo(o2)).get();
					int max = maxs.stream()
							.max((o1, o2) -> o1.compareTo(o2)).get();
					
					// Now the codomain of the assigned variable is "known"
					variableVariables.remove(assignedVariable);
					// So we move it to the other map
					integerVariableMinMax.put(assignedVariable,
							new SimpleEntry<Integer, Integer>(min, max));
				}
			}
		}
	}

	public static void extendCodomainsForLiteralAssignments(Map<VariableDeclaration, List<LiteralExpression>> integerVariableAssignments,
			Map<VariableDeclaration, Entry<Integer, Integer>> integerVariableMinMax) {
		List<VariableDeclaration> additionalIntegerVariables =
				new ArrayList<VariableDeclaration>(integerVariableAssignments.keySet());
		additionalIntegerVariables.removeIf(
				it -> integerVariableMinMax.containsKey(it));
		for (VariableDeclaration integerVariable : additionalIntegerVariables) {
			List<LiteralExpression> integerLiterals =
					integerVariableAssignments.get(integerVariable);
			Integer min = integerLiterals.stream()
					.map(it -> xStsActionUtil.toInteger(it))
					.min((o1, o2) -> o1.compareTo(o2)).get();
			Integer max = integerLiterals.stream()
					.map(it -> xStsActionUtil.toInteger(it))
					.max((o1, o2) -> o1.compareTo(o2)).get();
			
			min = Integer.min(Short.MIN_VALUE, min);
			max = Integer.max(Short.MAX_VALUE, max);
			
			if (min < Short.MIN_VALUE || Short.MAX_VALUE < max) {
				integerVariableMinMax.put(integerVariable,
						new SimpleEntry<Integer, Integer>(min, max));
			}
		}
	}

	public static Map<VariableDeclaration, Entry<Integer, Integer>> calculatePresiceCodomains(
			Map<VariableDeclaration, List<LiteralExpression>> integerLiteralVariableAssignments,
			Set<VariableDeclaration> integerLiteralVariables) {
		Map<VariableDeclaration, Entry<Integer, Integer>> integerVariableMinMax =
				new HashMap<VariableDeclaration, Entry<Integer, Integer>>();
		for (VariableDeclaration integerLiteralVariable : integerLiteralVariables) {
			List<LiteralExpression> integerLiterals =
					integerLiteralVariableAssignments.get(integerLiteralVariable);
			// Mapping into integers and computing min and max
			Integer min = integerLiterals.stream()
					.map(it -> xStsActionUtil.toInteger(it))
					.min((o1, o2) -> o1.compareTo(o2)).get();
			Integer max = integerLiterals.stream()
					.map(it -> xStsActionUtil.toInteger(it))
					.max((o1, o2) -> o1.compareTo(o2)).get();
			
			integerVariableMinMax.put(integerLiteralVariable,
					new SimpleEntry<Integer, Integer>(min, max));
		}
		return integerVariableMinMax;
	}
	
	public static Triple<
			Map<VariableDeclaration, List<LiteralExpression>>, Map<VariableDeclaration, List<VariableDeclaration>>, Set<VariableDeclaration>>
				getVariableAssignmentGroups(XSTS xSts) {
		List<AbstractAssignmentAction> abstractAssignments = ecoreUtil.getAllContentsOfType(
				xSts, AbstractAssignmentAction.class);
		
		Map<VariableDeclaration, List<LiteralExpression>> integerVariableAssignments =
				new HashMap<VariableDeclaration, List<LiteralExpression>>();
		Map<VariableDeclaration, List<VariableDeclaration>> variableVariableAssignments =
				new HashMap<VariableDeclaration, List<VariableDeclaration>>();
		Set<VariableDeclaration> notIntegerLiteralVariables = new HashSet<VariableDeclaration>();
		for (AbstractAssignmentAction abstractAssignment : abstractAssignments) {
			Expression firstExpr = abstractAssignment.getLhs();
			if (firstExpr instanceof DirectReferenceExpression identifierExpression) {
				Declaration element = identifierExpression.getDeclaration();
				if (element instanceof VariableDeclaration variable) {
					if (abstractAssignment instanceof AssignmentAction assignment) {
						Expression secondExpr = assignment.getRhs();
						if (secondExpr instanceof LiteralExpression literalExpression &&
								isNativeLiteral(literalExpression)) {
							List<LiteralExpression> integerLiterals =
									javaUtil.getOrCreateList(integerVariableAssignments, variable);
							integerLiterals.add(literalExpression);
						}
						else if (isNative(element) && isEvaluable(secondExpr)) {
							int value = evaluator.evaluate(secondExpr);
							LiteralExpression literalExpression = literalCreator.of(element, value);
							List<LiteralExpression> integerLiterals =
									javaUtil.getOrCreateList(integerVariableAssignments, variable);
							integerLiterals.add(literalExpression);
						}
						else if (secondExpr instanceof DirectReferenceExpression rhsIdentifierExpression) {
							Declaration rhsNamedElement = rhsIdentifierExpression.getDeclaration();
							if (rhsNamedElement instanceof VariableDeclaration rhsVariable) {
								List<VariableDeclaration> variables = javaUtil
										.getOrCreateList(variableVariableAssignments, variable);
								variables.add(rhsVariable);
							}
						}
						else {
							// Not an 'integer literal' or 'var = var2'
							notIntegerLiteralVariables.add(variable);
						}
					}
					else {
						// Havoc
						notIntegerLiteralVariables.add(variable);
					}
				}
			}
		}
		
		List<VariableDeclarationAction> variableDeclarationActions = ecoreUtil.getAllContentsOfType(
				xSts, VariableDeclarationAction.class);
		for (VariableDeclarationAction variableDeclarationAction : variableDeclarationActions) {
			VariableDeclaration localVariable = variableDeclarationAction.getVariableDeclaration();
			Expression initialValue = xStsActionUtil.getInitialValue(localVariable);
			if (isEvaluable(initialValue)) {
				int value = evaluator.evaluate(initialValue);
				LiteralExpression literalExpression = literalCreator.of(localVariable, value);
				List<LiteralExpression> integerLiterals =
						javaUtil.getOrCreateList(integerVariableAssignments, localVariable);
				integerLiterals.add(literalExpression);
			}
			else {
				// Not evaluable so we do not know what it is
				notIntegerLiteralVariables.add(localVariable);
			}
		}
		
		return new Triple<Map<VariableDeclaration, List<LiteralExpression>>, Map<VariableDeclaration, List<VariableDeclaration>>, Set<VariableDeclaration>>(
				integerVariableAssignments, variableVariableAssignments, notIntegerLiteralVariables);
	}
	
}
