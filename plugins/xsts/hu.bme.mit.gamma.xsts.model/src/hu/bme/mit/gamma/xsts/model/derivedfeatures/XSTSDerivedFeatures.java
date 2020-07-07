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
package hu.bme.mit.gamma.xsts.model.derivedfeatures;

import java.util.Collection;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.xsts.model.model.Action;
import hu.bme.mit.gamma.xsts.model.model.AssignmentAction;
import hu.bme.mit.gamma.xsts.model.model.AssumeAction;
import hu.bme.mit.gamma.xsts.model.model.EmptyAction;
import hu.bme.mit.gamma.xsts.model.model.NonDeterministicAction;
import hu.bme.mit.gamma.xsts.model.model.ParallelAction;
import hu.bme.mit.gamma.xsts.model.model.PrimedVariable;
import hu.bme.mit.gamma.xsts.model.model.SequentialAction;
import hu.bme.mit.gamma.xsts.model.model.XSTS;
import hu.bme.mit.gamma.xsts.model.model.XSTSModelFactory;

public class XSTSDerivedFeatures extends ExpressionModelDerivedFeatures {

	protected static XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE;
	
	public static XSTS getContainingXSTS(EObject object) {
		return (XSTS) EcoreUtil.getRootContainer(object);
	}
	
	public static SequentialAction getInitializingAction(XSTS xSts) {
		SequentialAction sequentialAction = xStsFactory.createSequentialAction();
		final Action variableInitializingAction = xSts.getVariableInitializingAction();
		if (!(variableInitializingAction instanceof EmptyAction)) {
			sequentialAction.getActions().add(ecoreUtil.clone(variableInitializingAction, true, true));
		}
		final Action configurationInitializingAction = xSts.getConfigurationInitializingAction();
		if (!(configurationInitializingAction instanceof EmptyAction)) {
			sequentialAction.getActions().add(ecoreUtil.clone(configurationInitializingAction, true, true));
		}
		final Action entryEventAction = xSts.getEntryEventAction();
		if (!(entryEventAction instanceof EmptyAction)) {
			sequentialAction.getActions().add(ecoreUtil.clone(entryEventAction, true, true));
		}
		return sequentialAction;
	}
	
	public static SequentialAction getEnvironmentalAction(XSTS xSts) {
		SequentialAction sequentialAction = xStsFactory.createSequentialAction();
		sequentialAction.getActions().add(ecoreUtil.clone(xSts.getInEventAction(), true, true));
		sequentialAction.getActions().add(ecoreUtil.clone(xSts.getOutEventAction(), true, true));
		return sequentialAction;
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
				.noneMatch(it -> it instanceof PrimedVariable && ((PrimedVariable) it).getPrimedVariable() == variable);
	}

	public static int getPrimeCount(VariableDeclaration variable) {
		if (!(variable instanceof PrimedVariable)) {
			return 0;
		}
		PrimedVariable primedVariable = (PrimedVariable) variable;
		return getPrimeCount(primedVariable.getPrimedVariable()) + 1;
	}

	public static boolean isTrivialAssignment(SequentialAction action) {
		List<Action> xStsSubactions = action.getActions();
		if (xStsSubactions.stream().filter(it -> it instanceof AssumeAction).count() == 1
				&& xStsSubactions.stream().filter(it -> it instanceof AssignmentAction).count() == 1) {
			return isTrivialAssignment(
					(AssumeAction) xStsSubactions.stream().filter(it -> it instanceof AssumeAction).findFirst().get(),
					(AssignmentAction) xStsSubactions.stream().filter(it -> it instanceof AssignmentAction).findFirst()
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

	private static boolean isTrivialAssignment(EqualityExpression expression, AssignmentAction action) {
		Expression xStsLeftOperand = expression.getLeftOperand();
		Expression xStsRightOperand = expression.getRightOperand();
		Declaration xStsDeclaration = action.getLhs().getDeclaration();
		Expression xStsAssignmentRhs = action.getRhs();
		// region_name == state_name
		if (xStsLeftOperand instanceof ReferenceExpression) {
			if (((ReferenceExpression) xStsLeftOperand).getDeclaration() == xStsDeclaration
					&& ecoreUtil.helperEquals(xStsRightOperand, xStsAssignmentRhs)) {
				return true;
			}
		}
		// state_name == region_name
		if (xStsRightOperand instanceof ReferenceExpression) {
			if (((ReferenceExpression) xStsRightOperand).getDeclaration() == xStsDeclaration
					&& ecoreUtil.helperEquals(xStsLeftOperand, xStsAssignmentRhs)) {
				return true;
			}
		}
		return false;
	}

	public static boolean isDefinitelyTrueAssumeAction(AssumeAction action) {
		Expression expression = action.getAssumption();
		return expressionUtil.isDefinitelyTrueExpression(expression);
	}

	public static boolean isDefinitelyFalseAssumeAction(AssumeAction action) {
		Expression expression = action.getAssumption();
		return expressionUtil.isDefinitelyFalseExpression(expression);
	}

	// Read-write

	private static Set<VariableDeclaration> _getReadVariables(final AssumeAction action) {
		return expressionUtil.getReferredVariables(action.getAssumption());
	}

	private static Set<VariableDeclaration> _getReadVariables(final AssignmentAction action) {
		return expressionUtil.getReferredVariables(action.getRhs());
	}

	private static Set<VariableDeclaration> _getReadVariables(final EmptyAction action) {
		return Collections.emptySet();
	}

	private static Set<VariableDeclaration> _getReadVariables(final NonDeterministicAction action) {
		final HashSet<VariableDeclaration> variableList = new HashSet<VariableDeclaration>();
		EList<Action> _actions = action.getActions();
		for (final Action containedAction : _actions) {
			Collection<VariableDeclaration> _readVariables = getReadVariables(containedAction);
			variableList.addAll(_readVariables);
		}
		return variableList;
	}

	private static Set<VariableDeclaration> _getReadVariables(final ParallelAction action) {
		final HashSet<VariableDeclaration> variableList = new HashSet<VariableDeclaration>();
		EList<Action> _actions = action.getActions();
		for (final Action containedAction : _actions) {
			Collection<VariableDeclaration> _readVariables = getReadVariables(containedAction);
			variableList.addAll(_readVariables);
		}
		return variableList;
	}

	private static Set<VariableDeclaration> _getReadVariables(final SequentialAction action) {
		final HashSet<VariableDeclaration> variableList = new HashSet<VariableDeclaration>();
		EList<Action> _actions = action.getActions();
		for (final Action containedAction : _actions) {
			Collection<VariableDeclaration> _readVariables = getReadVariables(containedAction);
			variableList.addAll(_readVariables);
		}
		return variableList;
	}

	private static Set<VariableDeclaration> _getWrittenVariables(final AssumeAction action) {
		return Collections.emptySet();
	}

	private static Set<VariableDeclaration> _getWrittenVariables(final AssignmentAction action) {
		return expressionUtil.getReferredVariables(action.getLhs());
	}

	private static Set<VariableDeclaration> _getWrittenVariables(final EmptyAction action) {
		return Collections.emptySet();
	}

	private static Set<VariableDeclaration> _getWrittenVariables(final NonDeterministicAction action) {
		final HashSet<VariableDeclaration> variableList = new HashSet<VariableDeclaration>();
		EList<Action> _actions = action.getActions();
		for (final Action containedAction : _actions) {
			Collection<VariableDeclaration> _writtenVariables = getWrittenVariables(containedAction);
			variableList.addAll(_writtenVariables);
		}
		return variableList;
	}

	private static Set<VariableDeclaration> _getWrittenVariables(final ParallelAction action) {
		final HashSet<VariableDeclaration> variableList = new HashSet<VariableDeclaration>();
		EList<Action> _actions = action.getActions();
		for (final Action containedAction : _actions) {
			Collection<VariableDeclaration> _writtenVariables = getWrittenVariables(containedAction);
			variableList.addAll(_writtenVariables);
		}
		return variableList;
	}

	private static Set<VariableDeclaration> _getWrittenVariables(final SequentialAction action) {
		final HashSet<VariableDeclaration> variableList = new HashSet<VariableDeclaration>();
		EList<Action> _actions = action.getActions();
		for (final Action containedAction : _actions) {
			Collection<VariableDeclaration> _writtenVariables = getWrittenVariables(containedAction);
			variableList.addAll(_writtenVariables);
		}
		return variableList;
	}

	public static Set<VariableDeclaration> getReadVariables(final Action action) {
		if (action instanceof AssignmentAction) {
			return _getReadVariables((AssignmentAction) action);
		} else if (action instanceof AssumeAction) {
			return _getReadVariables((AssumeAction) action);
		} else if (action instanceof EmptyAction) {
			return _getReadVariables((EmptyAction) action);
		} else if (action instanceof NonDeterministicAction) {
			return _getReadVariables((NonDeterministicAction) action);
		} else if (action instanceof ParallelAction) {
			return _getReadVariables((ParallelAction) action);
		} else if (action instanceof SequentialAction) {
			return _getReadVariables((SequentialAction) action);
		} else {
			throw new IllegalArgumentException("Unhandled action type: " + action);
		}
	}

	public static Set<VariableDeclaration> getWrittenVariables(final Action action) {
		if (action instanceof AssignmentAction) {
			return _getWrittenVariables((AssignmentAction) action);
		} else if (action instanceof AssumeAction) {
			return _getWrittenVariables((AssumeAction) action);
		} else if (action instanceof EmptyAction) {
			return _getWrittenVariables((EmptyAction) action);
		} else if (action instanceof NonDeterministicAction) {
			return _getWrittenVariables((NonDeterministicAction) action);
		} else if (action instanceof ParallelAction) {
			return _getWrittenVariables((ParallelAction) action);
		} else if (action instanceof SequentialAction) {
			return _getWrittenVariables((SequentialAction) action);
		} else {
			throw new IllegalArgumentException("Unhandled action type: " + action);
		}
	}
	
	public static Set<VariableDeclaration> getReferredVariables(final Action action) {
		Set<VariableDeclaration> referredVariables = getReadVariables(action);
		referredVariables.addAll(getWrittenVariables(action));
		return referredVariables;
	}

}
