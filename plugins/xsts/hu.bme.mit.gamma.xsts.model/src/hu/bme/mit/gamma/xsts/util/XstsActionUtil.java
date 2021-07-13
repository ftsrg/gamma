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
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DefaultExpression;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction;
import hu.bme.mit.gamma.xsts.model.Action;
import hu.bme.mit.gamma.xsts.model.AssignmentAction;
import hu.bme.mit.gamma.xsts.model.AssumeAction;
import hu.bme.mit.gamma.xsts.model.CompositeAction;
import hu.bme.mit.gamma.xsts.model.MultiaryAction;
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction;
import hu.bme.mit.gamma.xsts.model.ParallelAction;
import hu.bme.mit.gamma.xsts.model.SequentialAction;
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction;
import hu.bme.mit.gamma.xsts.model.XSTS;
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory;
import hu.bme.mit.gamma.xsts.model.XTransition;

public class XstsActionUtil extends ExpressionUtil {
	// Singleton
	public static final XstsActionUtil INSTANCE = new XstsActionUtil();
	protected XstsActionUtil() {}
	//
	
	protected GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	protected XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE;
	
	public void changeTransitions(XSTS xSts, XTransition newAction) {
		changeTransitions(xSts, Collections.singletonList(newAction));
	}
	
	public void changeTransitions(XSTS xSts, Collection<XTransition> newActions) {
		Collection<XTransition> savedActions = new ArrayList<XTransition>();
		savedActions.addAll(newActions); // If newActions == xSts.getActions()
		xSts.getTransitions().clear();
		xSts.getTransitions().addAll(savedActions);
	}
	
	public XTransition wrap(Action action) {
		XTransition transition = xStsFactory.createXTransition();
		transition.setAction(action);
		return transition;
	}
	
	public void prependToAction(Collection<? extends Action> actions, Action pivot) {
		for (Action action : actions) {
			prependToAction(action, pivot);
		}
	}
	
	public void prependToAction(Action action, Action pivot) {
		if (pivot instanceof SequentialAction) {
			SequentialAction sequentialAction = (SequentialAction) pivot;
			sequentialAction.getActions().add(0, action);
			return;
		}
		// Pivot is not a sequential action
		EObject container = pivot.eContainer();
		if (!(container instanceof SequentialAction)) {
			SequentialAction sequentialAction = xStsFactory.createSequentialAction();
			ecoreUtil.replace(sequentialAction, pivot);
			sequentialAction.getActions().add(pivot);
		}
		ecoreUtil.prependTo(action, pivot);
	}
	
	public void appendToAction(Collection<? extends Action> actions, Action pivot) {
		for (Action action : actions) {
			appendToAction(action, pivot);
		}
	}
	
	public void appendToAction(Action pivot, Action action) {
		if (pivot instanceof SequentialAction) {
			SequentialAction sequentialAction = (SequentialAction) pivot;
			sequentialAction.getActions().add(action);
			return;
		}
		// Pivot is not a sequential action
		EObject container = pivot.eContainer();
		if (!(container instanceof SequentialAction)) {
			SequentialAction sequentialAction = xStsFactory.createSequentialAction();
			ecoreUtil.replace(sequentialAction, pivot);
			sequentialAction.getActions().add(pivot);
		}
		ecoreUtil.appendTo(pivot, action);
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
	
	public List<VariableDeclaration> getVariables(XSTS xSts, Collection<String> names) {
		List<VariableDeclaration> variables = new ArrayList<VariableDeclaration>();
		for (String name : names) {
			variables.add(getVariable(xSts, name));
		}
		return variables;
	}
	
	public List<AbstractAssignmentAction> getAssignments(VariableDeclaration variable,
			Collection<AbstractAssignmentAction> assignments) {
		return assignments.stream().filter(it -> getDeclaration(it.getLhs()) == variable)
				.collect(Collectors.toList());
	}
	
	public List<AbstractAssignmentAction> getAssignments(Collection<VariableDeclaration> variables,
			Collection<AbstractAssignmentAction> assignments) {
		return assignments.stream().filter(it -> variables.contains(getDeclaration(it.getLhs())))
				.collect(Collectors.toList());
	}
	
	public VariableDeclarationAction extractExpressions(String name, List<? extends Expression> expressions) {
		Expression firstExpression = expressions.get(0);
		Type type = typeDeterminator.getType(firstExpression); // Assume: they have the same type
		VariableDeclarationAction variableDeclarationAction = extractExpression(type, name, firstExpression);
		VariableDeclaration variableDeclaration = variableDeclarationAction.getVariableDeclaration();
		for (int i = 1; i < expressions.size(); i++) {
			Expression expression = expressions.get(i);
			DirectReferenceExpression referenceExpression = createReferenceExpression(variableDeclaration);
			ecoreUtil.replace(referenceExpression, expression);
		}
		return variableDeclarationAction;
	}
	
	public VariableDeclarationAction extractExpression(Type type, String name, Expression expression) {
		VariableDeclarationAction variableDeclarationAction = createVariableDeclarationAction(type, name);
		VariableDeclaration variableDeclaration = variableDeclarationAction.getVariableDeclaration();
		DirectReferenceExpression referenceExpression = createReferenceExpression(variableDeclaration);
		
		ecoreUtil.replace(referenceExpression, expression);
		variableDeclaration.setExpression(expression);
		
		return variableDeclarationAction;
	}
	
	public VariableDeclarationAction createVariableDeclarationAction(Type type, String name) {
		return createVariableDeclarationAction(type, name, null);
	}
	
	public VariableDeclarationAction createVariableDeclarationAction(Type type, String name, Expression expression) {
		VariableDeclaration variableDeclaration = createVariableDeclaration(type, name, expression);
		VariableDeclarationAction action = xStsFactory.createVariableDeclarationAction();
		action.setVariableDeclaration(variableDeclaration);
		return action;
	}
	
	public AssignmentAction createAssignmentAction(VariableDeclaration variable, VariableDeclaration rhs) {
		DirectReferenceExpression rhsReference = expressionFactory.createDirectReferenceExpression();
		rhsReference.setDeclaration(rhs);
		return createAssignmentAction(variable, rhsReference);
	}
	
	public AssignmentAction createAssignmentAction(VariableDeclaration variable, Expression rhs) {
		AssignmentAction assignmentAction = xStsFactory.createAssignmentAction();
		DirectReferenceExpression lhsReference = expressionFactory.createDirectReferenceExpression();
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
	
	public List<Action> createChoiceActionWithExtractedPreconditionsAndEmptyDefaultBranch(Action action, String name) {
		List<Action> actions = new ArrayList<Action>();
		if (action instanceof SequentialAction) {
			SequentialAction sequentialAction = (SequentialAction) action;
			AssumeAction assumeAction = (AssumeAction) sequentialAction.getActions().get(0);
			Expression expression = assumeAction.getAssumption();
			VariableDeclarationAction variableDeclarationAction = extractExpression(
					expressionFactory.createBooleanTypeDefinition(), name, expression);
			actions.add(variableDeclarationAction);
			NonDeterministicAction switchAction = createChoiceActionFromActions(List.of(action));
			// Else branch
			extendChoiceWithDefaultBranch(switchAction, xStsFactory.createEmptyAction());
			actions.add(switchAction);
		}
		else {
			throw new IllegalArgumentException("Not known action: " + action);
		}
		return actions;
	}
	
	public NonDeterministicAction createIfElseAction(List<Expression> conditions, List<Action> actions) {
		int conditionsSize = conditions.size();
		if (conditionsSize != actions.size() && conditionsSize + 1 != actions.size()) {
			throw new IllegalArgumentException("The two lists must be of same size or the size of"
				+ "the action list must be the size of the condition list + 1: " + conditions + " " + actions);
		}
//		boolean foundElseBranch = false;
		NonDeterministicAction switchAction = xStsFactory.createNonDeterministicAction();
		for (int i = 0; i < conditionsSize; ++i) {
			SequentialAction sequentialAction = xStsFactory.createSequentialAction();
			AndExpression andExpression = expressionFactory.createAndExpression();
			for (int j = 0; j < i; ++j) {
				// All previous expressions are false
				NotExpression notExpression = expressionFactory.createNotExpression();
				notExpression.setOperand(clone(conditions.get(j)));
				andExpression.getOperands().add(notExpression);
			}
			Expression actualCondition = conditions.get(i);
			if (actualCondition instanceof ElseExpression ||
					actualCondition instanceof DefaultExpression) {
				throw new IllegalArgumentException("Cannot process else expressions here");
			}
			andExpression.getOperands().add(actualCondition);
//			else {
//				if (i != conditionsSize - 1) {
//					throw new IllegalArgumentException("The else branch is not in the last index!");
//				}
//				foundElseBranch = true;
//			}
			AssumeAction assumeAction = createAssumeAction(unwrapIfPossible(andExpression));
			sequentialAction.getActions().add(assumeAction);
			sequentialAction.getActions().add(actions.get(i));
			// Merging into the main action
			switchAction.getActions().add(sequentialAction);
		}
		// Else branch if needed
		if (conditionsSize + 1 == actions.size()) {
			extendChoiceWithDefaultBranch(switchAction, actions.get(actions.size() - 1));
		}
//		else if (!foundElseBranch) {
//			// Otherwise a deadlock could happen if no branch is true
//			extendChoiceWithDefaultBranch(switchAction, xStsFactory.createEmptyAction());
//		}
		return switchAction;
	}
	
	public NonDeterministicAction createSwitchAction(
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
		return createIfElseAction(newConditions, actions);
	}

	public void extendChoiceWithDefaultBranch(NonDeterministicAction switchAction, Action action) {
		if (switchAction.getActions().isEmpty()) {
			return;
		}
		NotExpression negatedCondition = expressionFactory.createNotExpression();
		OrExpression orExpression = expressionFactory.createOrExpression();
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
			.map(it -> ((AssumeAction) it).getAssumption())
			.forEach(it -> conditions.add(it));
		if (conditions.isEmpty()) {
			return;
		}
		for (Expression condition : conditions) {
			orExpression.getOperands().add(clone(condition));
		}
		negatedCondition.setOperand(unwrapIfPossible(orExpression));
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
			if (action instanceof MultiaryAction) {
				MultiaryAction multiaryAction = (MultiaryAction) action;
				if (multiaryAction.getActions().isEmpty()) {
					throw new IllegalArgumentException("Empty multiary action");
				}
			}
			else {
				throw new IllegalArgumentException("Not supported action: " + action);
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
		throw new IllegalArgumentException("Not supported action: " + action);
	}
	
	public void deleteDeclaration(Declaration declaration) {
		EObject container = declaration.eContainer();
		if (container instanceof VariableDeclarationAction) {
			VariableDeclarationAction action = (VariableDeclarationAction) container;
			ecoreUtil.remove(action);
		}
		ecoreUtil.delete(declaration);
	}
	
	private <T extends EObject> T clone(T element) {
		return ecoreUtil.clone(element);
	}
	
}
