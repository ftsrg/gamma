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
package hu.bme.mit.gamma.xsts.model.util;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil.Copier;

import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.DefaultExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.xsts.model.model.Action;
import hu.bme.mit.gamma.xsts.model.model.AssumeAction;
import hu.bme.mit.gamma.xsts.model.model.NonDeterministicAction;
import hu.bme.mit.gamma.xsts.model.model.SequentialAction;
import hu.bme.mit.gamma.xsts.model.model.XSTSModelFactory;

public class XSTSActionUtil {

	private ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	private XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE;
	
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
	
	@SuppressWarnings("unchecked")
	private <T extends EObject> T clone(T element) {
		// A new copier should be used every time, otherwise anomalies happen (references are changed without asking)
		Copier copier = new Copier(true, true);
		T clone = (T) copier.copy(element);
		copier.copyReferences();
		return clone;
	}
	
}
