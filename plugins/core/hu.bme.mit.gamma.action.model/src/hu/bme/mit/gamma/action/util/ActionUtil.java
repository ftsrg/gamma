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
package hu.bme.mit.gamma.action.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EReference;

import hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures;
import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.ActionModelFactory;
import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.model.Block;
import hu.bme.mit.gamma.action.model.Branch;
import hu.bme.mit.gamma.action.model.EmptyStatement;
import hu.bme.mit.gamma.action.model.ExpressionStatement;
import hu.bme.mit.gamma.action.model.IfStatement;
import hu.bme.mit.gamma.action.model.SwitchStatement;
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement;
import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DefaultExpression;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.ElseExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.InitializableElement;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.ValueDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;

public class ActionUtil extends ExpressionUtil {
	// Singleton
	public static final ActionUtil INSTANCE = new ActionUtil();
	protected ActionUtil() {}
	//
	
	protected ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE;
	
	// Lhs of initializable elements and assignment statements
	
	public Declaration getLhsDeclaration(EObject context) {
		AssignmentStatement assignment = ecoreUtil.getSelfOrContainerOfType(context, AssignmentStatement.class);
		if (assignment != null) {
			ReferenceExpression lhs = assignment.getLhs();
			return getDeclaration(lhs);
		}
		return (Declaration) ecoreUtil.getSelfOrContainerOfType(context, InitializableElement.class);
	}
	
	//
	
	public void removeEmptyStatements(Action action) {
		if (action == null) {
			return;
		}
		List<EmptyStatement> emptyStatements = ecoreUtil
				.getSelfAndAllContentsOfType(action, EmptyStatement.class);
		for (EmptyStatement emptyStatement : emptyStatements) {
			ecoreUtil.remove(emptyStatement);
		}
	}
	
	public void removeEffectlessActions(Collection<? extends Action> actions) {
		List<Action> actionList = new ArrayList<Action>(actions);
		for (Action action : actionList) {
			removeEffectlessActions(action);
		}
	}
	
	public void removeEffectlessActions(Action action) {
		if (action == null) {
			return;
		}
		if (ActionModelDerivedFeatures.isEffectlessAction(action)) {
			ecoreUtil.remove(action);
			return;
		}
		
		boolean needMoreIteration = true;
		while (needMoreIteration) {
			needMoreIteration = false;
			List<Action> actions = ecoreUtil
					.getSelfAndAllContentsOfType(action, Action.class);
			
			for (Action subaction : actions) {
				if (ActionModelDerivedFeatures.isEffectlessAction(subaction)) {
					ecoreUtil.remove(subaction);
					needMoreIteration = true;
				}
			}
		}
		// Branch actions must not be null though
		List<Branch> branches = ecoreUtil
				.getSelfAndAllContentsOfType(action, Branch.class);
		for (Branch branch : branches) {
			if (branch.getAction() == null) {
				branch.setAction(
						actionFactory.createEmptyStatement());
			}
		}
	}
	
	//
	
	public Block wrap(Collection<? extends Action> actions) {
		Block block = actionFactory.createBlock();
		block.getActions().addAll(actions);
		return block;
	}
	
	public Action prepend(Action action, Action pivot) {
		if (action == null) {
			return pivot;
		}
		else if (pivot == null) {
			return action;
		}
		else if (pivot instanceof Block) {
			Block block = (Block) pivot;
			block.getActions().add(0, action);
			return block;
		}
		else {
			Block block = actionFactory.createBlock();
			// Replacing the pivot element
			ecoreUtil.replace(block, pivot);
			block.getActions().add(action);
			block.getActions().add(pivot);
			return block;
		}
	}
	
	public Action append(Action pivot, Action action) {
		if (pivot == null) {
			return action;
		}
		else if (action == null) {
			return pivot;
		}
		else if (pivot instanceof Block) {
			Block block = (Block) pivot;
			block.getActions().add(action);
			return block;
		}
		else {
			Block block = actionFactory.createBlock();
			// Replacing the pivot element
			ecoreUtil.replace(block, pivot);
			block.getActions().add(pivot);
			block.getActions().add(action);
			return block;
		}
	}
	
	public Action append(Action pivot, Collection<? extends Action> actions) {
		Action extensibleAction = pivot;
		for (Action action : actions) {
			extensibleAction = append(extensibleAction, action);
		}
		return extensibleAction;
	}
	
	//
	

	public Block createBlock(Collection<? extends Action> actions) {
		Block block = actionFactory.createBlock();
		
		block.getActions().addAll(actions);
		
		return block;
	}
	
	public Block getOrCreateBlock(Collection<? extends Action> actions) {
		if (actions.size() == 1) {
			Action action = actions.iterator().next();
			if (action instanceof Block block) {
				return block;
			}
		}
		return createBlock(actions);
	}
	
	public IfStatement createIfStatement(Expression condition, Action then, Action _else) {
		IfStatement ifStatement = actionFactory.createIfStatement();
		ifStatement.getConditionals().add(
			createBranch(condition, then)
		);
		if (_else != null) {
			Branch elseBranch = getOrCreateElseBranch(ifStatement);
			elseBranch.setAction(_else);
		}
		
		return ifStatement;
	}
	
	public Branch createBranch(Expression expression, Action action) {
		Branch branch = actionFactory.createBranch();
		branch.setGuard(expression);
		branch.setAction(action);
		return branch;
	}
	
	public Branch getOrCreateElseBranch(IfStatement statement) {
		List<Branch> conditionals = statement.getConditionals();
		for (Branch conditional : conditionals) {
			Expression guard = conditional.getGuard();
			if (guard instanceof ElseExpression) {
				return conditional;
			}
		}
		Branch elseBranch = createBranch(factory.createElseExpression(),
				actionFactory.createBlock());
		statement.getConditionals().add(elseBranch);
		return elseBranch;
	}
	
	public Branch getOrCreateDefaultBranch(SwitchStatement statement) {
		List<Branch> conditionals = statement.getCases();
		for (Branch conditional : conditionals) {
			Expression guard = conditional.getGuard();
			if (guard instanceof DefaultExpression) {
				return conditional;
			}
		}
		Branch defaultBranch = createBranch(factory.createDefaultExpression(),
				actionFactory.createBlock());
		statement.getCases().add(defaultBranch);
		return defaultBranch;
	}
	
	public void extendThisAndNextBranches(Branch branch, Action action) {
		int index = ecoreUtil.getIndex(branch);
		EObject container = branch.eContainer();
		EReference containingReference = branch.eContainmentFeature();
		@SuppressWarnings("unchecked")
		List<Branch> branches = (List<Branch>) container.eGet(containingReference);
		for (int i = index; i < branches.size(); ++i) {
			Branch actualBranch = branches.get(i);
			Action branchAction = actualBranch.getAction();
			Action clonedAction = ecoreUtil.clone(action);
			if (branchAction == null) {
				actualBranch.setAction(clonedAction);
			}
			else {
				prepend(clonedAction, branchAction); // Does not matter if prepend or extend
			}
		}
	}
	
	//
	
	public ExpressionStatement createExpressionStatement(Expression expression) {
		ExpressionStatement statement = actionFactory.createExpressionStatement();
		statement.setExpression(expression);
		return statement;
	}
	
	public VariableDeclarationStatement createDeclarationStatement(Type type, String name) {
		return createDeclarationStatement(type, name, // Otherwise, the variable is "havoced"
				ExpressionModelDerivedFeatures.getDefaultExpression(type));
	}
	
	public VariableDeclarationStatement createDeclarationStatement(Type type,
			String name, Expression initialExpression) {
		VariableDeclarationStatement statement = actionFactory.createVariableDeclarationStatement();
		VariableDeclaration variable = factory.createVariableDeclaration();
		statement.setVariableDeclaration(variable);
		variable.setType(type);
		variable.setName(name);
		variable.setExpression(initialExpression);
		return statement;
	}
	
	//
	
	public List<AssignmentStatement> getAssignments(VariableDeclaration variable,
			Collection<AssignmentStatement> assignments) {
		List<AssignmentStatement> assignmentsOfVariable = new ArrayList<>();
		for (AssignmentStatement assignment : assignments) {
			ReferenceExpression lhs = assignment.getLhs();
			if (lhs instanceof DirectReferenceExpression) {
				DirectReferenceExpression reference = (DirectReferenceExpression) lhs;
				Declaration declaration = reference.getDeclaration();
				if (declaration == variable) {
					assignmentsOfVariable.add(assignment);
				}
			}
			else if (lhs instanceof AccessExpression) {
				//TODO handle access expressions
			}
		}
		return assignmentsOfVariable;
	}
	
	public AssignmentStatement createAssignment(ReferenceExpression reference,
			Expression expression) {
		AssignmentStatement assignmentStatement = actionFactory.createAssignmentStatement();
		assignmentStatement.setLhs(reference);
		assignmentStatement.setRhs(expression);
		return assignmentStatement;
	}
	
	public AssignmentStatement createAssignment(VariableDeclaration variable,
			Expression expression) {
		return createAssignment(createReferenceExpression(variable), expression);
	}
	
	public AssignmentStatement createAssignment(VariableDeclaration variable,
			ValueDeclaration declaration) {
		return createAssignment(variable, createReferenceExpression(declaration));
	}
	
	public List<AssignmentStatement> createAssignments(List<? extends ReferenceExpression> left,
			List<Expression> right) {
		List<AssignmentStatement> assignments = new ArrayList<AssignmentStatement>();
		int size = left.size();
		if (size != right.size()) {
			throw new IllegalArgumentException("Different number of arguments: " + size + " " + right.size());
		}
		for (int i = 0; i < size; i++) {
			ReferenceExpression lhs = left.get(i);
			Expression rhs = right.get(i);
			assignments.add(createAssignment(lhs, rhs));
		}
		return assignments;
	}
	
	public AssignmentStatement createVariableResetAction(VariableDeclaration variable) {
		Expression defaultExpression = ExpressionModelDerivedFeatures.getDefaultExpression(variable);
		return createAssignment(variable, defaultExpression);
	}
	
	public AssignmentStatement createIncrementation(VariableDeclaration variable) {
		return createAssignment(variable,
				createIncrementExpression(variable));
	}
	
}