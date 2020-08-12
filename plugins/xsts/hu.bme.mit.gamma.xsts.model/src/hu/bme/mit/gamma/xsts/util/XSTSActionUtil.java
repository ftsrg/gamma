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
package hu.bme.mit.gamma.xsts.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.DefaultExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.xsts.model.Action;
import hu.bme.mit.gamma.xsts.model.AssignmentAction;
import hu.bme.mit.gamma.xsts.model.AssumeAction;
import hu.bme.mit.gamma.xsts.model.CompositeAction;
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction;
import hu.bme.mit.gamma.xsts.model.ParallelAction;
import hu.bme.mit.gamma.xsts.model.SequentialAction;
import hu.bme.mit.gamma.xsts.model.XSTS;
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory;

public class XSTSActionUtil {
	// Singleton
	public static final XSTSActionUtil INSTANCE = new XSTSActionUtil();
	protected XSTSActionUtil() {}
	//
	
	protected GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE;
	protected ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	protected XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE;
	
	public void appendToAction(Action pivot, Action action) {
		EObject container = pivot.eContainer();
		if (!(container instanceof SequentialAction)) {
			SequentialAction sequentialAction = xStsFactory.createSequentialAction();
			gammaEcoreUtil.replace(sequentialAction, pivot);
			sequentialAction.getActions().add(pivot);
		}
		gammaEcoreUtil.appendTo(pivot, action);
	}
	
	public VariableDeclaration checkVariable(XSTS xSts, String name) {
		VariableDeclaration variable = getVariable(xSts, name);
		if (variable == null) {
			throw new IllegalArgumentException("No variable for " + name);
		}
		return variable;
	}
	
	public VariableDeclaration getVariable(XSTS xSts, String name) {
		List<VariableDeclaration> variables = xSts.getVariableDeclarations().stream()
				.filter(it -> it.getName().equals(name)).collect(Collectors.toList());
		if (variables.size() > 1) {
			throw new IllegalArgumentException("Not one variable: " + variables);
		}
		if (variables.size() < 1) {
			return null;
		}
		return variables.get(0);
	}
	
	public List<AssignmentAction> getAssignments(VariableDeclaration variable,
			Collection<AssignmentAction> assignments) {
		return assignments.stream().filter(it -> it.getLhs().getDeclaration() == variable)
				.collect(Collectors.toList());
	}
	
	public AssignmentAction createAssignmentAction(VariableDeclaration variable, VariableDeclaration rhs) {
		ReferenceExpression rhsReference = expressionFactory.createReferenceExpression();
		rhsReference.setDeclaration(rhs);
		return createAssignmentAction(variable, rhsReference);
	}
	
	public AssignmentAction createAssignmentAction(VariableDeclaration variable, Expression rhs) {
		AssignmentAction assignmentAction = xStsFactory.createAssignmentAction();
		ReferenceExpression lhsReference = expressionFactory.createReferenceExpression();
		lhsReference.setDeclaration(variable);
		assignmentAction.setLhs(lhsReference);
		assignmentAction.setRhs(rhs);
		return assignmentAction;
	}
	
	public AssumeAction createAssumeAction(Expression condition) {
		AssumeAction assumeAction = xStsFactory.createAssumeAction();
		assumeAction.setAssumption(condition);
		return assumeAction;
	}
	
	public NonDeterministicAction createIfActionBranch(Expression condition, Action thenAction) {
		SequentialAction ifSequentialAction = xStsFactory.createSequentialAction();
		AssumeAction ifAssumeAction = createAssumeAction(condition);
		ifSequentialAction.getActions().add(ifAssumeAction);
		ifSequentialAction.getActions().add(thenAction);
		// Merging into one
		NonDeterministicAction ifAction = xStsFactory.createNonDeterministicAction();
		ifAction.getActions().add(ifSequentialAction);
		return ifAction;
	}
	
	public NonDeterministicAction createIfAction(Expression condition, Action thenAction) {
		// If
		NonDeterministicAction choiceAction = createIfActionBranch(condition, thenAction);
		// Else
		NotExpression negatedCondition = expressionFactory.createNotExpression();
		negatedCondition.setOperand(clone(condition)); // Cloning needed
		return extendChoiceWithBranch(choiceAction, negatedCondition, xStsFactory.createEmptyAction());
	}
	
	public NonDeterministicAction createIfElseAction(Expression condition, Action thenAction, Action elseAction) {
		// If
		NonDeterministicAction choiceAction = createIfActionBranch(condition, thenAction);
		// Else
		NotExpression negatedCondition = expressionFactory.createNotExpression();
		negatedCondition.setOperand(clone(condition)); // Cloning needed
		return extendChoiceWithBranch(choiceAction, negatedCondition, elseAction);
	}

	public NonDeterministicAction extendChoiceWithBranch(NonDeterministicAction choiceAction, 
			Expression condition, Action elseAction) {
		SequentialAction elseSequentialAction = xStsFactory.createSequentialAction();
		AssumeAction elseAssumeAction = createAssumeAction(condition);
		elseSequentialAction.getActions().add(elseAssumeAction);
		elseSequentialAction.getActions().add(elseAction);
		// Merging into one
		choiceAction.getActions().add(elseSequentialAction);
		return choiceAction;
	}
	
	public NonDeterministicAction createChoiceAction(List<Expression> conditions, List<Action> actions) {
		if (conditions.size() != actions.size() && conditions.size() + 1 != actions.size()) {
			throw new IllegalArgumentException("The two lists must be of same size or the size of"
				+ "the action list must be the size of the condition list + 1: " + conditions + " " + actions);
		}
		NonDeterministicAction choiceAction = xStsFactory.createNonDeterministicAction();
		for (int i = 0; i < conditions.size(); ++i) {
			SequentialAction sequentialAction = xStsFactory.createSequentialAction();
			AssumeAction assumeAction = createAssumeAction(conditions.get(i));
			sequentialAction.getActions().add(assumeAction);
			sequentialAction.getActions().add(actions.get(i));
			// Merging into the main action
			choiceAction.getActions().add(sequentialAction);
		}
		// Else branch if needed
		if (conditions.size() + 1 == actions.size()) {
			extendChoiceWithDefaultBranch(choiceAction, actions.get(actions.size() - 1));
		}
		return choiceAction;
	}
	
	public NonDeterministicAction createChoiceActionFromActions(List<Action> actions) {
		NonDeterministicAction switchAction = xStsFactory.createNonDeterministicAction();
		for (Action action : actions) {
			switchAction.getActions().add(action);
		}
		return switchAction;
	}
	
	public NonDeterministicAction createChoiceActionWithEmptyDefaultBranch(List<Action> actions) {
		NonDeterministicAction switchAction = createChoiceActionFromActions(actions);
		// Else branch
		extendChoiceWithDefaultBranch(switchAction, xStsFactory.createEmptyAction());
		return switchAction;
	}
	
	public NonDeterministicAction createSwitchAction(List<Expression> conditions, List<Action> actions) {
		if (conditions.size() != actions.size() && conditions.size() + 1 != actions.size()) {
			throw new IllegalArgumentException("The two lists must be of same size or the size of"
				+ "the action list must be the size of the condition list + 1: " + conditions + " " + actions);
		}
		NonDeterministicAction switchAction = xStsFactory.createNonDeterministicAction();
		for (int i = 0; i < conditions.size(); ++i) {
			SequentialAction sequentialAction = xStsFactory.createSequentialAction();
			AndExpression andExpression = expressionFactory.createAndExpression();
			for (int j = 0; j < i; ++j) {
				// All previous expressions are false
				NotExpression notExpression = expressionFactory.createNotExpression();
				notExpression.setOperand(clone(conditions.get(j)));
				andExpression.getOperands().add(notExpression);
			}
			Expression actualCondition = conditions.get(i);
			if (!(actualCondition instanceof ElseExpression ||
					actualCondition instanceof DefaultExpression)) {
				// This condition is true
				andExpression.getOperands().add(actualCondition);
			}
			AssumeAction assumeAction = createAssumeAction(andExpression);
			sequentialAction.getActions().add(assumeAction);
			sequentialAction.getActions().add(actions.get(i));
			// Merging into the main action
			switchAction.getActions().add(sequentialAction);
		}
		// Else branch if needed
		if (conditions.size() + 1 == actions.size()) {
			extendChoiceWithDefaultBranch(switchAction, actions.get(actions.size() - 1));
		}
		return switchAction;
	}
	
	public NonDeterministicAction createSwitchActionWithControlExpression(
			Expression controlExpresion, List<Expression> conditions, List<Action> actions) {
		if (conditions.size() != actions.size() && conditions.size() + 1 != actions.size()) {
			throw new IllegalArgumentException("The two lists must be of same size or the size of"
				+ "the action list must be the size of the condition list + 1: " + conditions + " " + actions);
		}
		List<Expression> newConditions = new ArrayList<Expression>();
		for (Expression condition : conditions) {
			EqualityExpression equalityExpression = expressionFactory.createEqualityExpression();
			equalityExpression.setLeftOperand(clone(controlExpresion));
			equalityExpression.setRightOperand(condition);
			newConditions.add(equalityExpression);
		}
		return createSwitchAction(newConditions, actions);
	}

	public void extendChoiceWithDefaultBranch(NonDeterministicAction switchAction, Action action) {
		if (switchAction.getActions().isEmpty()) {
			return;
		}
		NotExpression negatedCondition = expressionFactory.createNotExpression();
		OrExpression orExpression = expressionFactory.createOrExpression();
		negatedCondition.setOperand(orExpression);
		List<SequentialAction> sequentialActions = switchAction.getActions().stream()
				.filter(it -> it instanceof SequentialAction)
				.map(it -> (SequentialAction) it)
				.collect(Collectors.toList());
		List<Expression> conditions = sequentialActions.stream()
				.filter(it -> it.getActions().get(0) instanceof AssumeAction)
				.map(it -> ((AssumeAction) it.getActions().get(0)).getAssumption())
				.collect(Collectors.toList());
		// Collecting atomic assumptions too
		switchAction.getActions().stream()
			.filter(it -> it instanceof AssumeAction)
			.map(it -> ((AssumeAction) it).getAssumption()).
			forEach(it -> conditions.add(it));
		if (conditions.isEmpty()) {
			return;
		}
		for (Expression condition : conditions) {
			orExpression.getOperands().add(clone(condition));
		}
		SequentialAction sequentialAction = xStsFactory.createSequentialAction();
		AssumeAction assumeAction = createAssumeAction(negatedCondition);
		sequentialAction.getActions().add(assumeAction);
		sequentialAction.getActions().add(action); // Last action
		// Merging into the parent
		switchAction.getActions().add(sequentialAction);
	}
	
	public Expression getPrecondition(Action action) {
		if (action instanceof AssumeAction) {
			AssumeAction assumeAction = (AssumeAction) action;
			return clone(assumeAction.getAssumption());
		}
		// Checking for all composite actions: if it is empty,
		// we return null, and the caller decides what needs to be done
		if (action instanceof CompositeAction) {
			CompositeAction compositeAction = (CompositeAction) action;
			if (compositeAction.getActions().isEmpty()) {
				return null;
			}
		}
		//
		if (action instanceof SequentialAction) {
			SequentialAction sequentialAction = (SequentialAction) action;
			return getPrecondition(sequentialAction.getActions().get(0));
		}
		if (action instanceof ParallelAction) {
			ParallelAction parallelAction = (ParallelAction) action;
			AndExpression andExpression = expressionFactory.createAndExpression();
			for (Action subaction : parallelAction.getActions()) {
				andExpression.getOperands().add(getPrecondition(subaction));
			}
			return andExpression;
		}
		if (action instanceof NonDeterministicAction) {
			NonDeterministicAction nonDeterministicAction = (NonDeterministicAction) action;
			OrExpression orExpression = expressionFactory.createOrExpression();
			for (Action subaction : nonDeterministicAction.getActions()) {
				orExpression.getOperands().add(getPrecondition(subaction));
			}
			return orExpression;
		}
		throw new IllegalArgumentException("Not supported aciton: " + action);
	}
	
	private <T extends EObject> T clone(T element) {
		return gammaEcoreUtil.clone(element, true, true);
	}
	
}
