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
package hu.bme.mit.gamma.xsts.util;

import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.List;
import java.util.Map.Entry;
import java.util.stream.Collectors;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.ArrayAccessExpression;
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression;
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DefaultExpression;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression;
import hu.bme.mit.gamma.expression.model.IntegerRangeLiteralExpression;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.TypeDeclaration;
import hu.bme.mit.gamma.expression.model.TypeDefinition;
import hu.bme.mit.gamma.expression.model.TypeReference;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclarationAnnotation;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures;
import hu.bme.mit.gamma.xsts.model.AbstractAssignmentAction;
import hu.bme.mit.gamma.xsts.model.Action;
import hu.bme.mit.gamma.xsts.model.ActionAnnotation;
import hu.bme.mit.gamma.xsts.model.AssignmentAction;
import hu.bme.mit.gamma.xsts.model.AssumeAction;
import hu.bme.mit.gamma.xsts.model.CompositeAction;
import hu.bme.mit.gamma.xsts.model.EmptyAction;
import hu.bme.mit.gamma.xsts.model.GroupAnnotation;
import hu.bme.mit.gamma.xsts.model.HavocAction;
import hu.bme.mit.gamma.xsts.model.IfAction;
import hu.bme.mit.gamma.xsts.model.LoopAction;
import hu.bme.mit.gamma.xsts.model.MultiaryAction;
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction;
import hu.bme.mit.gamma.xsts.model.ParallelAction;
import hu.bme.mit.gamma.xsts.model.SequentialAction;
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction;
import hu.bme.mit.gamma.xsts.model.VariableGroup;
import hu.bme.mit.gamma.xsts.model.XSTS;
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory;
import hu.bme.mit.gamma.xsts.model.XTransition;

public class XstsActionUtil extends ExpressionUtil {
	// Singleton
	public static final XstsActionUtil INSTANCE = new XstsActionUtil();
	protected XstsActionUtil() {}
	//
	
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	protected final XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE;
	
	//
	
	public XSTS createXsts(String name) {
		XSTS xSts = xStsFactory.createXSTS();
		xSts.setName(name);
		fillNullTransitions(xSts);
		return xSts;
	}
	
	public void unrollLoopActions(XSTS xSts) {
		List<LoopAction> loopActions = ecoreUtil.getSelfAndAllContentsOfType(xSts, LoopAction.class);
		for (LoopAction loopAction : loopActions) {
			SequentialAction block = xStsFactory.createSequentialAction();
			
			IntegerRangeLiteralExpression range = loopAction.getRange();
			Expression leftExpression = ExpressionModelDerivedFeatures.getLeft(range, true);
			Expression rightExpression = ExpressionModelDerivedFeatures.getRight(range, false);
			
			int left = evaluator.evaluateInteger(leftExpression);
			int right = evaluator.evaluateInteger(rightExpression);
			
			ParameterDeclaration parameter = loopAction.getIterationParameterDeclaration();
			Action action = loopAction.getAction();
			
			for (int i = left; i < right; i++) {
				Action clonedAction = ecoreUtil.clone(action);
				List<DirectReferenceExpression> references = ecoreUtil.getAllContentsOfType(
						clonedAction, DirectReferenceExpression.class);
				for (DirectReferenceExpression reference : references) {
					if (reference.getDeclaration() == parameter) {
						IntegerLiteralExpression integerLiteral = toIntegerLiteral(i);
						ecoreUtil.replace(integerLiteral, reference);
					}
				}
				block.getActions().add(clonedAction);
			}
			
			ecoreUtil.replace(block, loopAction);
		}
	}
	
	public void removeVariableDeclarationAnnotations(XSTS xSts,
			Class<? extends VariableDeclarationAnnotation> annotationClass) {
		removeVariableDeclarationAnnotations(xSts.getVariableDeclarations(), annotationClass);
	}
	
	public void fillNullTransitions(XSTS xSts) {
		if (xSts.getVariableInitializingTransition() == null) {
			xSts.setVariableInitializingTransition(
					createEmptyTransition());
		}
		if (xSts.getConfigurationInitializingTransition() == null) {
			xSts.setConfigurationInitializingTransition(
					createEmptyTransition());
		}
		if (xSts.getEntryEventTransition() == null) {
			xSts.setEntryEventTransition(
					createEmptyTransition());
		}
		if (xSts.getTransitions().isEmpty()) {
			changeTransitions(xSts,
					createEmptyTransition());
		}
		if (xSts.getInEventTransition() == null) {
			xSts.setInEventTransition(
					createEmptyTransition());
		}
		if (xSts.getOutEventTransition() == null) {
			xSts.setOutEventTransition(
					createEmptyTransition());
		}
	}
	
	public void merge(XSTS pivot, XSTS mergable) {
		pivot.getTypeDeclarations().addAll(mergable.getTypeDeclarations());
		pivot.getPublicTypeDeclarations().addAll(mergable.getPublicTypeDeclarations());
		pivot.getVariableDeclarations().addAll(mergable.getVariableDeclarations());
		mergeVariableGroups(pivot, mergable);
	}
	
	public void mergeVariableGroups(XSTS pivot, XSTS mergable) {
		List<VariableGroup> variableGroups = pivot.getVariableGroups();
		variableGroups.addAll(
				mergable.getVariableGroups());
		List<VariableGroup> deletableGroups = new ArrayList<VariableGroup>();
		
		int size = variableGroups.size();
		for (int i = 0; i < size - 1; ++i) {
			VariableGroup lhs = variableGroups.get(i);
			GroupAnnotation lhsAnnotation = lhs.getAnnotation();
			for (int j = i + 1; j < size; ++j) {
				VariableGroup rhs = variableGroups.get(j);
				GroupAnnotation rhsAnnotation = rhs.getAnnotation();
				if (ecoreUtil.helperEquals(lhsAnnotation, rhsAnnotation)) {
					lhs.getVariables().addAll(
							rhs.getVariables());
					deletableGroups.add(rhs);
				}
			}
		}
		
		for (VariableGroup variableGroup : deletableGroups) {
			ecoreUtil.delete(variableGroup);
		}
	}

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
	
	public XTransition createEmptyTransition() {
		EmptyAction emptyAction = xStsFactory.createEmptyAction();
		return wrap(emptyAction);
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
	
	public void appendToAction(Action pivot, Collection<? extends Action> actions) {
		Action actualPivot = pivot;
		for (Action action : actions) {
			appendToAction(actualPivot, action);
			actualPivot = action;
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
	
	public void extractArrayLiteralAssignments(Action action) {
		List<AssignmentAction> assignmentActions = ecoreUtil
				.getSelfAndAllContentsOfType(action, AssignmentAction.class);
		assignmentActions.removeIf(it -> !(it.getRhs() instanceof ArrayLiteralExpression));
		
		if (!assignmentActions.isEmpty()) {
			SequentialAction block = xStsFactory.createSequentialAction();
			List<Action> actions = block.getActions();
			for (AssignmentAction assignmentAction : assignmentActions) {
				actions.addAll(extractArrayLiteralAssignments(assignmentAction));
			}
			ecoreUtil.replace(block, action);
		}
	}
	
	public List<AssignmentAction> extractArrayLiteralAssignments(AssignmentAction action) {
		List<AssignmentAction> arrayLiteralAssignments = new ArrayList<AssignmentAction>();
		
		ReferenceExpression lhs = action.getLhs();
		Expression rhs = action.getRhs();
		// Note that 'a := b' like assignments (a and b are array variables) are supported in UPPAAL 
		if (rhs instanceof ArrayLiteralExpression) {
			ArrayLiteralExpression literal = (ArrayLiteralExpression) rhs;
			List<Expression> operands = new ArrayList<Expression>(
					literal.getOperands()); // To prevent messing up containment and indexing
			int size = operands.size();
			for (int i = 0; i < size; i++) {
				ArrayAccessExpression newLhs = expressionFactory.createArrayAccessExpression();
				newLhs.setOperand(
						ecoreUtil.clone(lhs)); // Cloning is important
				newLhs.setIndex(
						toIntegerLiteral(i));
				
				Expression newRhs = ecoreUtil.clone(
						operands.get(i)); // Cloning is necessary if we want to keep the original XSTS
				
				AssignmentAction newAssignmentAction = createAssignmentAction(newLhs, newRhs);
				arrayLiteralAssignments.addAll(
						extractArrayLiteralAssignments(newAssignmentAction)); // Recursion for multiD arrays
			}
		}
		else {
			arrayLiteralAssignments.add(action);
		}
		// It does not contain assignments where the rhs is an array literal
		return arrayLiteralAssignments;
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
			Collection<? extends AbstractAssignmentAction> assignments) {
		return assignments.stream().filter(it -> getDeclaration(it.getLhs()) == variable)
				.collect(Collectors.toList());
	}
	
	public List<AbstractAssignmentAction> getAssignments(VariableDeclaration variable,
				EObject root) {
		List<AbstractAssignmentAction> assignments = ecoreUtil.getAllContentsOfType(
				root, AbstractAssignmentAction.class);
		return getAssignments(variable, assignments);
	}
	
	public List<AbstractAssignmentAction> getAssignments(
			Collection<? extends VariableDeclaration> variables,
			Collection<? extends AbstractAssignmentAction> assignments) {
		return assignments.stream().filter(it -> variables.contains(
				getDeclaration(it.getLhs()))).collect(Collectors.toList());
	}
	
	public List<AbstractAssignmentAction> getAssignments(
			Collection<? extends VariableDeclaration> variables, EObject root) {
		List<AbstractAssignmentAction> assignments = ecoreUtil.getAllContentsOfType(
				root, AbstractAssignmentAction.class);
		return getAssignments(variables, assignments);
	}
	
	public void changeAssignmentsToEmptyActions(
			Collection<? extends VariableDeclaration> variables, EObject root) {
		List<AbstractAssignmentAction> assignments = getAssignments(variables, root);
		changeAssignmentsToEmptyActions(assignments);
	}

	public void changeAssignmentsToEmptyActions(
			Collection<? extends AbstractAssignmentAction> assignments) {
		for (AbstractAssignmentAction assignmentAction : assignments) {
			EmptyAction emptyAction = xStsFactory.createEmptyAction();
			ecoreUtil.replace(emptyAction, assignmentAction);
		}
	}
	
	public List<AssignmentAction> getReadingAssignments(VariableDeclaration variable,
			Collection<? extends AssignmentAction> assignments) {
		return assignments.stream().filter(it ->
				getReferredVariables(it.getRhs()).contains(variable))
				.collect(Collectors.toList());
	}
	
	public List<AssignmentAction> getReadingAssignments(
			VariableDeclaration variable, EObject root) {
		List<AssignmentAction> assignments = ecoreUtil.getAllContentsOfType(
				root, AssignmentAction.class);
		return getReadingAssignments(variable, assignments);
	}
	
	public List<AssignmentAction> getReadingAssignments(
			Collection<? extends VariableDeclaration> variables,
			Collection<? extends AssignmentAction> assignments) {
		return assignments.stream().filter(it -> javaUtil.containsAny(
				variables, getReferredVariables(it.getRhs())))
				.collect(Collectors.toList());
	}
	
	public List<AssignmentAction> getReadingAssignments(
			Collection<? extends VariableDeclaration> variables, EObject root) {
		List<AssignmentAction> assignments = ecoreUtil.getAllContentsOfType(
				root, AssignmentAction.class);
		return getReadingAssignments(variables, assignments);
	}
	
	public void changeAssignmentsAndReadingAssignmentsToEmptyActions(
			Collection<? extends VariableDeclaration> variables, EObject root) {
		changeAssignmentsToEmptyActions(variables, root);
		
		List<AssignmentAction> readingAssignments = getReadingAssignments(variables, root);
		changeAssignmentsToEmptyActions(readingAssignments);
	}
	
	public VariableDeclarationAction extractExpressions(
			String name, List<? extends Expression> expressions) {
		Expression firstExpression = expressions.get(0);
		Type type = typeDeterminator.getType(firstExpression); // Assume: they have the same type
		VariableDeclarationAction variableDeclarationAction = extractExpression(
				type, name, firstExpression);
		VariableDeclaration variableDeclaration = variableDeclarationAction.getVariableDeclaration();
		for (int i = 1; i < expressions.size(); i++) {
			Expression expression = expressions.get(i);
			DirectReferenceExpression referenceExpression = createReferenceExpression(variableDeclaration);
			ecoreUtil.replace(referenceExpression, expression);
		}
		return variableDeclarationAction;
	}
	
	public VariableDeclarationAction extractExpression(
			Type type, String name, Expression expression) {
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
	
	public VariableDeclarationAction createVariableDeclarationAction(
			TypeDeclaration type, String name, Expression expression) {
		TypeReference typeReference = createTypeReference(type);
		return createVariableDeclarationAction(typeReference, name, expression);
	}
	
	public VariableDeclarationAction createVariableDeclarationAction(
			Type type, String name, Expression expression) {
		VariableDeclaration variableDeclaration = createVariableDeclaration(type, name, expression);
		VariableDeclarationAction action = xStsFactory.createVariableDeclarationAction();
		action.setVariableDeclaration(variableDeclaration);
		return action;
	}
	
	public AssignmentAction createAssignmentAction(VariableDeclaration variable, VariableDeclaration rhs) {
		return createAssignmentAction(variable, createReferenceExpression(rhs));
	}
	
	public AssignmentAction createAssignmentAction(VariableDeclaration variable, Expression rhs) {
		return createAssignmentAction(createReferenceExpression(variable), rhs);
	}
	
	public List<AssignmentAction> createAssignmentActions(
			List<? extends ReferenceExpression> lhss, List<Expression> rhss) {
		if (lhss.size() != rhss.size()) {
			throw new IllegalArgumentException("Lhs and rhs size are not the same: "
					+ lhss.size() + " " + rhss.size());
		}
		
		List<AssignmentAction> assignmentActions = new ArrayList<AssignmentAction>();
		for (int i = 0; i < lhss.size(); i++) { // Same size for both sides
			ReferenceExpression lhs = lhss.get(i);
			Expression rhs = rhss.get(i);
			assignmentActions.add(
					createAssignmentAction(lhs, rhs));
		}
		return assignmentActions;
	}
	
	public AssignmentAction createAssignmentAction(ReferenceExpression lhs, Expression rhs) {
		AssignmentAction assignmentAction = xStsFactory.createAssignmentAction();
		assignmentAction.setLhs(lhs);
		assignmentAction.setRhs(rhs);
		return assignmentAction;
	}
	
	public AssignmentAction createVariableResetAction(VariableDeclaration variable) {
		Expression defaultExpression = ExpressionModelDerivedFeatures.getDefaultExpression(variable);
		return createAssignmentAction(variable, defaultExpression);
	}
	
	public List<AssignmentAction> createVariableResetActions(Collection<? extends VariableDeclaration> variables) {
		List<AssignmentAction> actions = new ArrayList<AssignmentAction>(); 
		
		for (VariableDeclaration variable : variables) {
			actions.add(
					createVariableResetAction(variable));
		}
		
		return actions;
	}
	
	public HavocAction createHavocAction(VariableDeclaration variable) {
		HavocAction havocAction = xStsFactory.createHavocAction();
		havocAction.setLhs(createReferenceExpression(variable));
		return havocAction;
	}
	
	public Entry<VariableDeclarationAction, HavocAction> createHavocedVariableDeclarationAction(
			Type type, String name) {
		VariableDeclarationAction variableDeclarationAction = createVariableDeclarationAction(type, name);
		VariableDeclaration variableDeclaration = variableDeclarationAction.getVariableDeclaration();
		HavocAction havocAction = createHavocAction(variableDeclaration);
		return new SimpleEntry<VariableDeclarationAction, HavocAction>(variableDeclarationAction, havocAction);
	}
	
	public AssignmentAction increment(VariableDeclaration variable) {
		return createAssignmentAction(variable,
				createIncrementExpression(variable));
	}
	
	public AssignmentAction decrement(VariableDeclaration variable) {
		return createAssignmentAction(variable,
				createDecrementExpression(variable));
	}
	
	public SequentialAction createSequentialAction(Action action) {
		return createSequentialAction(
				Collections.singletonList(action));
	}
	
	public SequentialAction createSequentialAction(Collection<? extends Action> actions) {
		SequentialAction block = xStsFactory.createSequentialAction();
		block.getActions().addAll(actions);
		return block;
	}
	
	public LoopAction createLoopAction(String iterationVariableName,
			Expression start, Expression end) {
		return createLoopAction(iterationVariableName, start, true, end, false);
	}
	
	public LoopAction createLoopAction(String iterationVariableName,
			Expression start, boolean leftInclusive,
			Expression end, boolean rightIclusive) {
		LoopAction loopAction = xStsFactory.createLoopAction();
		ParameterDeclaration parameterDeclaration = createParameterDeclaration(
				factory.createIntegerTypeDefinition(), iterationVariableName);
		IntegerRangeLiteralExpression range = createIntegerRangeLiteralExpression(
				start, leftInclusive, end, rightIclusive);
		loopAction.setIterationParameterDeclaration(parameterDeclaration);
		loopAction.setRange(range);
		return loopAction;
	}
	
	public IfAction createIfAction(Expression condition, Action then) {
		return createIfAction(condition, then, xStsFactory.createEmptyAction());
	}
	
	public IfAction createIfAction(Expression condition, Action then, Action _else) {
		IfAction ifAction = xStsFactory.createIfAction();
		ifAction.setCondition(condition);
		ifAction.setThen(then);
		ifAction.setElse(_else);
		return ifAction;
	}
	
	public IfAction createIfAction(SequentialAction action) {
		SequentialAction _action = ecoreUtil.clone(action);
		
		List<Action> actions = _action.getActions();
		AssumeAction assumeAction = (AssumeAction) actions.remove(0);
		Expression assumption = assumeAction.getAssumption();
		
		return createIfAction(assumption, _action);
	}
	
	public IfAction createIfAction(List<SequentialAction> actions) {
		List<IfAction> ifActions = new ArrayList<IfAction>();
		
		for (SequentialAction sequentialAction : actions) {
			ifActions.add(createIfAction(sequentialAction));
		}
		
		return weave(ifActions);
	}
	
	public IfAction createIfAction(List<Expression> conditions, List<Action> actions) {
		int size = conditions.size();
		IfAction ifAction = null;
		int i = 0;
		for (; i < size; i++) {
			Expression condition = conditions.get(i);
			Action action = actions.get(i);
			if (ifAction == null) {
				// First iteration
				ifAction = createIfAction(condition, action);
			}
			else {
				// Additional iterations
				append(ifAction, condition, action);
			}
		}
		// If there is a final action for the else branch
		if (i < actions.size()) {
			IfAction lastIfAction = XstsDerivedFeatures.getLastIfAction(ifAction);
			Action _else = lastIfAction.getElse();
			if (!XstsDerivedFeatures.isNullOrEmptyAction(_else)) {
				throw new IllegalStateException("Not empty else branch: " + _else);
			}
			lastIfAction.setElse(actions.get(i));
		}
		return ifAction;
 	}
	
	public IfAction prepend(IfAction ifAction, Expression condition, Action then) {
		IfAction newIfAction = createIfAction(condition, then);
		newIfAction.setElse(ifAction);
		return newIfAction;
	}
	
	public void append(IfAction ifAction, Expression condition, Action then) {
		append(ifAction, condition, then, xStsFactory.createEmptyAction());
	}
	
	public void append(IfAction ifAction, Expression condition, Action then, Action _else) {
		Action elseAction = ifAction.getElse();
		if (ifAction.getCondition() == null &&
				XstsDerivedFeatures.isNullOrEmptyAction(ifAction.getThen()) &&
				XstsDerivedFeatures.isNullOrEmptyAction(elseAction)) {
			ifAction.setCondition(condition);
			ifAction.setThen(then);
			ifAction.setElse(_else);
			return; // ifAction is "empty", no need to create an additional one for the else branch
		}
		
		IfAction newIfAction = createIfAction(condition, then, _else);
		
		append(ifAction, newIfAction);
	}
	
	public void append(IfAction ifAction, Action action) {
		Action elseAction = ifAction.getElse();
		
		if (XstsDerivedFeatures.isNullOrEmptyAction(elseAction)) {
			ifAction.setElse(action);
		}
		else {
			if (elseAction instanceof IfAction) {
				IfAction _elseAction = (IfAction) elseAction;
				append(_elseAction, action);
			}
			else {
				throw new IllegalArgumentException("If action cannot be extended");
			}
		}
	}
	
	public void appendElse(IfAction ifAction, Action _else) {
		IfAction lastIfAction = XstsDerivedFeatures.getLastIfAction(ifAction);
		Action lastElse = lastIfAction.getElse();
		if (!XstsDerivedFeatures.isNullOrEmptyAction(lastElse)) {
			throw new IllegalArgumentException("Not empty else branch: " + ifAction);
		}
		lastIfAction.setElse(_else);
	}
	
	public IfAction weave(List<IfAction> ifActions) {
		IfAction previous = null;
		for (IfAction ifAction : ifActions) {
			if (previous == null) {
				previous = ifAction;
			}
			else {
				Action previousElse = previous.getElse();
				if (!XstsDerivedFeatures.isNullOrEmptyAction(previousElse)) {
					throw new IllegalArgumentException("Not empty else branch: " + previous);
				}
				previous.setElse(ifAction);
				previous = ifAction;
			}
		}
		return ifActions.get(0);
	}
	
	public IfAction createSwitchAction(
			Expression controlExpresion, List<Expression> conditions, List<Action> actions) {
		if (conditions.size() != actions.size() && conditions.size() + 1 != actions.size()) {
			throw new IllegalArgumentException("The two lists must be of same size or the size of"
				+ "the action list must be the size of the condition list + 1: "
					+ conditions + " " + actions);
		}
		List<Expression> newConditions = new ArrayList<Expression>();
		for (Expression condition : conditions) {
			EqualityExpression equalityExpression = createEqualityExpression(
					ecoreUtil.clone(controlExpresion), condition);
			newConditions.add(equalityExpression);
		}
		return createIfAction(newConditions, actions);
	}
	
	public AssumeAction createAssumeAction(Expression condition) {
		AssumeAction assumeAction = xStsFactory.createAssumeAction();
		assumeAction.setAssumption(condition);
		return assumeAction;
	}
	
	// IfActions have been introduced, double-check if you really need NonDeterministicAction
	
	public SequentialAction createChoiceSequentialAction(Expression condition, Action thenAction) {
		SequentialAction ifSequentialAction = xStsFactory.createSequentialAction();
		AssumeAction ifAssumeAction = createAssumeAction(condition);
		ifSequentialAction.getActions().add(ifAssumeAction);
		ifSequentialAction.getActions().add(thenAction);
		
		return ifSequentialAction;
	}
	
	public NonDeterministicAction createChoiceActionBranch(Expression condition, Action thenAction) {
		SequentialAction ifSequentialAction = createChoiceSequentialAction(condition, thenAction);
		// Merging into one
		NonDeterministicAction ifAction = xStsFactory.createNonDeterministicAction();
		ifAction.getActions().add(ifSequentialAction);
		return ifAction;
	}
	
	public NonDeterministicAction createChoiceAction(Expression condition, Action thenAction) {
		// If
		NonDeterministicAction choiceAction = createChoiceActionBranch(condition, thenAction);
		// Else
		NotExpression negatedCondition = expressionFactory.createNotExpression();
		negatedCondition.setOperand(ecoreUtil.clone(condition)); // Cloning needed
		return extendChoiceWithBranch(choiceAction, negatedCondition, xStsFactory.createEmptyAction());
	}
	
	public NonDeterministicAction createChoiceAction(
			Expression condition, Action thenAction, Action elseAction) {
		// If
		NonDeterministicAction choiceAction = createChoiceActionBranch(condition, thenAction);
		// Else
		NotExpression negatedCondition = expressionFactory.createNotExpression();
		negatedCondition.setOperand(ecoreUtil.clone(condition)); // Cloning needed
		return extendChoiceWithBranch(choiceAction, negatedCondition, elseAction);
	}

	public NonDeterministicAction extendChoiceWithBranch(NonDeterministicAction choiceAction, 
			Expression condition, Action elseAction) {
		SequentialAction elseSequentialAction = xStsFactory.createSequentialAction();
		AssumeAction elseAssumeAction = createAssumeAction(condition);
		elseSequentialAction.getActions().add(elseAssumeAction);
		elseSequentialAction.getActions().add(elseAction);
		// Merging into parent
		choiceAction.getActions().add(elseSequentialAction);
		return choiceAction;
	}
	
	public NonDeterministicAction createChoiceAction(List<Expression> conditions, List<Action> actions) {
		if (conditions.size() != actions.size() && conditions.size() + 1 != actions.size()) {
			throw new IllegalArgumentException("The two lists must be of same size or the size of"
				+ "the action list must be the size of the condition list + 1: "
					+ conditions + " " + actions);
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
	
	public NonDeterministicAction createChoiceAction(List<? extends Action> actions) {
		NonDeterministicAction switchAction = xStsFactory.createNonDeterministicAction();
		for (Action action : actions) {
			switchAction.getActions().add(action);
		}
		return switchAction;
	}
	
	public NonDeterministicAction createChoiceActionWithEmptyDefaultBranch(
			List<? extends Action> actions) {
		NonDeterministicAction switchAction = createChoiceAction(actions);
		// Else branch
		extendChoiceWithDefaultBranch(switchAction, xStsFactory.createEmptyAction());
		return switchAction;
	}
	
	public NonDeterministicAction createChoiceActionWithExclusiveBranches(
			List<? extends Action> actions) {
		NonDeterministicAction choiceAction = xStsFactory.createNonDeterministicAction();
		for (int i = 0; i < actions.size(); i++) {
			Action action = actions.get(i);
			if (i == 0) {
				choiceAction.getActions().add(action);
			}
			else {
				extendChoiceWithDefaultBranch(choiceAction, action);
			}
		}
		return choiceAction;
	}
	
	public NonDeterministicAction createChoiceActionWithExclusiveBranches(
			List<Expression> conditions, List<Action> actions) {
		int conditionsSize = conditions.size();
		if (conditionsSize != actions.size() && conditionsSize + 1 != actions.size()) {
			throw new IllegalArgumentException("The two lists must be of same size or the size of"
				+ "the action list must be the size of the condition list + 1: "
					+ conditions + " " + actions);
		}
		
		NonDeterministicAction switchAction = xStsFactory.createNonDeterministicAction();
		for (int i = 0; i < conditionsSize; ++i) {
			SequentialAction sequentialAction = xStsFactory.createSequentialAction();
			AndExpression andExpression = expressionFactory.createAndExpression();
			for (int j = 0; j < i; ++j) {
				// All previous expressions are false
				NotExpression notExpression = expressionFactory.createNotExpression();
				notExpression.setOperand(ecoreUtil.clone(conditions.get(j)));
				andExpression.getOperands().add(notExpression);
			}
			
			Expression actualCondition = conditions.get(i);
			if (actualCondition instanceof ElseExpression ||
					actualCondition instanceof DefaultExpression) {
				throw new IllegalArgumentException("Cannot process else expressions here");
			}
			andExpression.getOperands().add(actualCondition);
			
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
		
		return switchAction;
	}
	
	public List<Action> createChoiceActionWithExtractedPreconditionsAndEmptyDefaultBranch(
			Action action, String name) {
		List<Action> actions = new ArrayList<Action>();
		if (action instanceof SequentialAction) {
			SequentialAction sequentialAction = (SequentialAction) action;
			AssumeAction assumeAction = (AssumeAction) sequentialAction.getActions().get(0);
			Expression expression = assumeAction.getAssumption();
			VariableDeclarationAction variableDeclarationAction = extractExpression(
					expressionFactory.createBooleanTypeDefinition(), name, expression);
			actions.add(variableDeclarationAction);
			NonDeterministicAction switchAction = createChoiceActionWithEmptyDefaultBranch(
					List.of(action));
			actions.add(switchAction);
		}
		else {
			throw new IllegalArgumentException("Not known action: " + action);
		}
		return actions;
	}
	
	public Entry<Action, NonDeterministicAction> createChoiceActionForRandomValues(
			String name, int lowerBound, int upperBound) {
		// Inclusive-exclusive
		List<Action> actions = new ArrayList<Action>();
		
		Entry<VariableDeclarationAction, HavocAction> havocedVariableDeclarationActions =
				createHavocedVariableDeclarationAction(factory.createIntegerTypeDefinition(), name);
		VariableDeclarationAction variableDeclarationAction = havocedVariableDeclarationActions.getKey();
		VariableDeclaration randomVariable = variableDeclarationAction.getVariableDeclaration();
		HavocAction havocAction = havocedVariableDeclarationActions.getValue();
		
		actions.add(variableDeclarationAction);
		actions.add(havocAction);
		
		// Branches
		List<AssumeAction> assumeActions = new ArrayList<AssumeAction>();
		for (int i = lowerBound; i < upperBound /* exclusive */; i++) {
			EqualityExpression equalityExpression = createEqualityExpression(
					randomVariable, toIntegerLiteral(i));
			AssumeAction assumeAction = createAssumeAction(equalityExpression);
			assumeActions.add(assumeAction);
		}
		NonDeterministicAction choiceAction = createChoiceAction(assumeActions);
		actions.add(choiceAction);
		
		SequentialAction sequentialAction = createSequentialAction(actions);
		
		return new SimpleEntry<Action, NonDeterministicAction>(sequentialAction, choiceAction);
	}
	
	public void extendChoiceWithDefaultBranch(NonDeterministicAction choiceAction) {
		extendChoiceWithDefaultBranch(choiceAction, xStsFactory.createEmptyAction());
	}
	
	public void extendChoiceWithDefaultBranch(NonDeterministicAction choiceAction, Action action) {
		Expression defaultCondition = createDefaultCondition(choiceAction);
		if (defaultCondition != null) {
			extendChoiceWithBranch(choiceAction, defaultCondition, action);
		}
	}
	
	public Expression createDefaultCondition(NonDeterministicAction choiceAction) {
		List<Action> branches = choiceAction.getActions();
		return createDefaultCondition(branches);
	}
	
	public Expression createDefaultCondition(Collection<? extends Action> branches) {
		if (branches.isEmpty()) {
			return null;
		}
		
		List<Expression> conditions = new ArrayList<Expression>();
		for (Action branch : branches) {
			Expression condition = getPrecondition(branch); // Crucial - precondition is already cloned
			conditions.add(condition);
		}
		if (conditions.isEmpty()) {
			return null;
		}
		
		return createDefaultExpression(conditions);
	}
	
	//
	
	public boolean hasDefaultBranch(NonDeterministicAction choice) {
		List<Action> branches = new ArrayList<Action>(choice.getActions());
		int lastIndex = branches.size() - 1;
		
		Action lastBranch = branches.get(lastIndex);
		branches.remove(lastIndex);
		
		Expression defaultCondition = createDefaultCondition(branches);
		Expression lastCondition = getPrecondition(lastBranch);
		
		return ecoreUtil.helperEquals(defaultCondition, lastCondition);
	}
	
	public Expression getPrecondition(Action action) {
		if (action instanceof AssumeAction) {
			AssumeAction assumeAction = (AssumeAction) action;
			return ecoreUtil.clone(assumeAction.getAssumption());
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
	
	public void addOnDemandControlAnnotation(VariableDeclaration variable) {
		addAnnotation(variable, xStsFactory.createOnDemandControlVariableDeclarationAnnotation());
	}
	
	public void addStrictControlAnnotation(VariableDeclaration variable) {
		addAnnotation(variable, xStsFactory.createStrictControlVariableDeclarationAnnotation());
	}
	
	public void addEnvironmentalInvariantAnnotation(AssumeAction action) {
		addAnnotation(action, xStsFactory.createEnvironmentalInvariantAnnotation());
	}
	
	public void addInternalInvariantAnnotation(AssumeAction action) {
		addAnnotation(action, xStsFactory.createInternalInvariantAnnotation());
	}
	
	public void addAnnotation(Action action, ActionAnnotation annotation) {
		if (action != null) {
			List<ActionAnnotation> annotations = action.getAnnotations();
			annotations.add(annotation);
		}
	}
	
	public void replaceWithEmptyAction(Action action) {
		EObject container = action.eContainer();
		if (container != null) {
			EmptyAction emptyAction = xStsFactory.createEmptyAction();
			ecoreUtil.replace(emptyAction, action);
		}
	}
	
	public void deleteDeclaration(Declaration declaration) {
		EObject container = declaration.eContainer();
		if (container instanceof VariableDeclarationAction) {
			VariableDeclarationAction action = (VariableDeclarationAction) container;
			replaceWithEmptyAction(action);
		}
		ecoreUtil.delete(declaration);
	}
	
	// Message queue - array handling
	
	public VariableDeclarationAction createVariableDeclarationActionForArray(
			VariableDeclaration queue, String name) {
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(queue);
		if (typeDefinition instanceof ArrayTypeDefinition) {
			ArrayTypeDefinition arrayTypeDefinition = (ArrayTypeDefinition) typeDefinition;
			Type elementType = arrayTypeDefinition.getElementType();
			return createVariableDeclarationAction(
					ecoreUtil.clone(elementType), name);
		}
		throw new IllegalArgumentException("Not an array: " + queue);
	}
	 
	public Action pop(VariableDeclaration queue) {
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(queue);
		if (typeDefinition instanceof ArrayTypeDefinition) {
			ArrayTypeDefinition arrayTypeDefinition = (ArrayTypeDefinition) typeDefinition;
			Type elementType = arrayTypeDefinition.getElementType();
			int size = evaluator.evaluateInteger(arrayTypeDefinition.getSize());
			
			ArrayLiteralExpression arrayLiteral = factory.createArrayLiteralExpression();
			for (int i = 1; i < size; i++) {
				ArrayAccessExpression accessExpression = factory.createArrayAccessExpression();
				accessExpression.setOperand(
						createReferenceExpression(queue));
				accessExpression.setIndex(
						toIntegerLiteral(i));
				arrayLiteral.getOperands()
						.add(accessExpression);
			}
			// Shifting a default value at the end
			// Would not be necessary in Theta (but it is in UPPAAL) due to the default branch
			Expression defaultExpression = ExpressionModelDerivedFeatures.getDefaultExpression(elementType);
			arrayLiteral.getOperands().add(defaultExpression);
			
			Action popAction = createAssignmentAction(queue, arrayLiteral);
			return popAction;
		}
		throw new IllegalArgumentException("Not an array: " + queue);
	}
	
	public Action popAndDecrement(VariableDeclaration queue, VariableDeclaration sizeVariable) {
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(queue);
		if (typeDefinition instanceof ArrayTypeDefinition) {
			Action popAction = pop(queue);
			Action sizeDecrementAction = decrement(sizeVariable);
			
			SequentialAction block = xStsFactory.createSequentialAction();
			block.getActions().add(popAction);
			block.getActions().add(sizeDecrementAction);
			
			return block;
		}
		throw new IllegalArgumentException("Not an array: " + queue);
	}
	
	public Action popAndPotentiallyDecrement(VariableDeclaration queue, VariableDeclaration sizeVariable) {
		if (sizeVariable == null) {
			return pop(queue);
		}
		return popAndDecrement(queue, sizeVariable);
	}
	
	private SequentialAction popAll(Iterable<? extends VariableDeclaration> queues) {
		SequentialAction block = xStsFactory.createSequentialAction();
		for (VariableDeclaration queue : queues) {
			block.getActions().add(
					pop(queue));
		}
		return block;
	}
	
	public Action popAllAndDecrement(Iterable<? extends VariableDeclaration> queues,
			VariableDeclaration sizeVariable) {
		SequentialAction block = popAll(queues);
		block.getActions().add(
				decrement(sizeVariable));
		return block;
	}
	
	public Action popAllAndPotentiallyDecrement(Iterable<? extends VariableDeclaration> queues,
			VariableDeclaration sizeVariable) {
		if (sizeVariable == null) {
			return popAll(queues);
		}
		return popAllAndDecrement(queues, sizeVariable);
	}
	
	public Action add(VariableDeclaration queue, Expression index, Expression element) {
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(queue);
		if (typeDefinition instanceof ArrayTypeDefinition) {
			ArrayAccessExpression accessExpression = factory.createArrayAccessExpression();
			accessExpression.setOperand(
					createReferenceExpression(queue));
			accessExpression.setIndex(index);
			
			Action assignment = createAssignmentAction(accessExpression, element);
			return assignment;
		}
		throw new IllegalArgumentException("Not an array: " + queue);
	}
	
	public Action addAll(List<? extends VariableDeclaration> queues,
			Expression index, List<? extends Expression> elements) {
		SequentialAction block = xStsFactory.createSequentialAction();
		int queueSize = queues.size();
		for (int i = 0; i < queueSize; i++) {
			VariableDeclaration queue = queues.get(i);
			Expression clonedIndex = ecoreUtil.clone(index);
			Expression element = elements.get(i);
			block.getActions().add(
					add(queue, clonedIndex, element));
		}
		return block;
	}
	
	public Action add(VariableDeclaration queue, VariableDeclaration sizeVariable, Expression element) {
		return add(queue, createReferenceExpression(sizeVariable), element);
	}
	
	public Action addAndIncrement(VariableDeclaration queue,
			VariableDeclaration sizeVariable, Expression element) {
		TypeDefinition typeDefinition = ExpressionModelDerivedFeatures.getTypeDefinition(queue);
		if (typeDefinition instanceof ArrayTypeDefinition) {
			Action assignment = add(queue, sizeVariable, element);
			Action sizeIncrementAction = increment(sizeVariable);
			
			SequentialAction block = xStsFactory.createSequentialAction();
			block.getActions().add(assignment);
			block.getActions().add(sizeIncrementAction);
			
			return block;
		}
		throw new IllegalArgumentException("Not an array: " + queue);
	}
	
	public Action addAndPotentiallyIncrement(VariableDeclaration queue,
			VariableDeclaration sizeVariable, Expression element) {
		if (sizeVariable == null) {
			return add(queue, toIntegerLiteral(0), element);
		}
		return addAndIncrement(queue, sizeVariable, element);
	}
	
	public Action addAll(List<? extends VariableDeclaration> queues, VariableDeclaration sizeVariable,
			List<? extends Expression> elements) {
		return addAll(queues, createReferenceExpression(sizeVariable), elements);
	}
	
	public Action addAllAndIncrement(List<? extends VariableDeclaration> queues,
			VariableDeclaration sizeVariable, List<? extends Expression> elements) {
		SequentialAction block = xStsFactory.createSequentialAction();
		block.getActions().add(
				addAll(queues, sizeVariable, elements));
		block.getActions().add(
				increment(sizeVariable));
		return block;
	}
	
	public Action addAllAndPotentiallyIncrement(List<? extends VariableDeclaration> queues,
			VariableDeclaration sizeVariable, List<? extends Expression> elements) {
		if (sizeVariable == null) {
			return addAll(queues, toIntegerLiteral(0), elements);
		}
		return addAllAndIncrement(queues, sizeVariable, elements);
	}
	
}
