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
package hu.bme.mit.gamma.action.derivedfeatures;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.eclipse.emf.common.util.EList;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.model.Block;
import hu.bme.mit.gamma.action.model.Branch;
import hu.bme.mit.gamma.action.model.ChoiceStatement;
import hu.bme.mit.gamma.action.model.EmptyStatement;
import hu.bme.mit.gamma.action.model.ForStatement;
import hu.bme.mit.gamma.action.model.IfStatement;
import hu.bme.mit.gamma.action.model.ProcedureDeclaration;
import hu.bme.mit.gamma.action.model.ReturnStatement;
import hu.bme.mit.gamma.action.model.SwitchStatement;
import hu.bme.mit.gamma.action.model.VariableDeclarationStatement;
import hu.bme.mit.gamma.action.util.ActionUtil;
import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression;
import hu.bme.mit.gamma.expression.model.FunctionDeclaration;
import hu.bme.mit.gamma.expression.model.LambdaDeclaration;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;

public class ActionModelDerivedFeatures extends ExpressionModelDerivedFeatures {
	
	protected static final ActionUtil actionUtil = ActionUtil.INSTANCE;
	
	//
	
	public static boolean isLocal(VariableDeclaration variableDeclaration) {
		EObject container = variableDeclaration.eContainer();
		return container instanceof VariableDeclarationStatement;
	}
	
	public static boolean isLambda(FunctionDeclaration function) {
		return isLambda(function, new HashSet<FunctionDeclaration>());
	}
	
	public static boolean isLambda(FunctionDeclaration function,
			Set<FunctionDeclaration> visitedFunctions) {
		if (function instanceof LambdaDeclaration) {
			return true;
		}
		//
		ProcedureDeclaration procedure = (ProcedureDeclaration) function;
		Block block = procedure.getBody();
		List<Action> actions = block.getActions();
		if (actions.size() == 1) {
			Action action = actions.get(0);
			if (action instanceof ReturnStatement) {
				if (visitedFunctions.contains(procedure)) {
					return true; // Already checked - possible recursion
				}
				visitedFunctions.add(procedure);
				Expression expression = getLambdaExpression(procedure);
				// Checking potential function calls
				for (FunctionAccessExpression functionCall :
						ecoreUtil.getSelfAndAllContentsOfType(expression, FunctionAccessExpression.class)) {
					FunctionDeclaration accessedFunction = (FunctionDeclaration)
							actionUtil.getAccessedDeclaration(functionCall.getOperand());
					if (!isLambda(accessedFunction, visitedFunctions)) {
						return false;
					}
				}
				return true;
			}
		}
		return false;
	}
	
	//
	
	public static boolean isContainedByChoiceStatement(Branch branch) {
		return branch.eContainer() instanceof ChoiceStatement;
	}
	
	public static boolean isContainedBySwitchStatement(Branch branch) {
		return branch.eContainer() instanceof SwitchStatement;
	}
	
	public static boolean isContainedByIfStatement(Branch branch) {
		return branch.eContainer() instanceof IfStatement;
	}
	
	//
	
	public static List<VariableDeclarationStatement> getVariableDeclarationStatements(
			Block block) {
		EList<Action> subactions = block.getActions();
		List<VariableDeclarationStatement> variableDeclarationStatements =
				new ArrayList<VariableDeclarationStatement>();
		for (Action subaction : subactions) {
			if (subaction instanceof VariableDeclarationStatement) {
				VariableDeclarationStatement statement =
						(VariableDeclarationStatement) subaction;
				variableDeclarationStatements.add(statement);
			}
		}
		return variableDeclarationStatements;
	}
	
	public static List<VariableDeclaration> getVariableDeclarations(Block block) {
		List<VariableDeclarationStatement> variableDeclarationStatements =
				getVariableDeclarationStatements(block);
		List<VariableDeclaration> variableDeclarations = new ArrayList<VariableDeclaration>();
		for (VariableDeclarationStatement variableDeclarationStatement :
				variableDeclarationStatements) {
			variableDeclarations.add(variableDeclarationStatement.getVariableDeclaration());
		}
		return variableDeclarations;
	}
	
	public static List<VariableDeclarationStatement> getPrecedingVariableDeclarationStatements(
			Block block, Action action) {
		EList<Action> subactions = block.getActions();
		int index = subactions.indexOf(action);
		List<VariableDeclarationStatement> localVariableDeclarations =
				new ArrayList<VariableDeclarationStatement>();
		for (int i = 0; i < index; ++i) {
			EObject subaction = subactions.get(i);
			if (subaction instanceof VariableDeclarationStatement) {
				VariableDeclarationStatement statement =
						(VariableDeclarationStatement) subaction;
				localVariableDeclarations.add(statement);
			}
		}
		return localVariableDeclarations;
	}
	
	public static List<VariableDeclaration> getPrecedingVariableDeclarations(
			Block block, Action action) {
		List<VariableDeclarationStatement> precedingVariableDeclarationStatements =
				getPrecedingVariableDeclarationStatements(block, action);
		List<VariableDeclaration> localVariableDeclarations =
				new ArrayList<VariableDeclaration>();
		for (VariableDeclarationStatement precedingVariableDeclarationStatement :
				precedingVariableDeclarationStatements) {
			localVariableDeclarations.add(
					precedingVariableDeclarationStatement.getVariableDeclaration());
		}
		return localVariableDeclarations;
	}
	
	public static boolean isFinalAction(Action action) {
		EObject container = action.eContainer();
		if (container instanceof Block) {
			Block block = (Block) container;
			int size = block.getActions().size();
			int actionIndex = ecoreUtil.getIndex(action);
			return actionIndex == size - 1;
		}
		return true;
	}
	
	public static boolean isRecursivelyFinalAction(Action action) {
		EObject container = action.eContainer();
		if (!isFinalAction(action)) {
			return false;
		}
		if (container != null) {
			if (container instanceof Action) {
				Action block = (Action) container;
				return isRecursivelyFinalAction(block);
			}
			else if (container instanceof Branch) {
				Action brancher = (Action) container.eContainer();
				return isRecursivelyFinalAction(brancher);
			}
		}
		return true;
	}
	
	public static boolean isNullOrEmptyStatement(Action action) {
		return action == null || action instanceof EmptyStatement;
	}
	
	public static boolean isEffectlessBranch(Branch branch) {
		Action action = branch.getAction();
		return isEffectlessAction(action);
	}
	
	public static boolean isEffectlessAction(Action action) {
		if (isNullOrEmptyStatement(action)) {
			return true;
		}
		if (action instanceof AssignmentStatement) {
			AssignmentStatement assignmentStatement = (AssignmentStatement) action;
			ReferenceExpression lhs = assignmentStatement.getLhs();
			Expression rhs = assignmentStatement.getRhs();
			return ecoreUtil.helperEquals(lhs, rhs);
		}
		if (action instanceof ForStatement) {
			ForStatement forStatement = (ForStatement) action;
			Action body = forStatement.getBody();
			return isEffectlessAction(body);
		}
		if (action instanceof Block) {
			Block block = (Block) action;
			return block.getActions().stream().allMatch(it -> isEffectlessAction(it));
		}
		if (action instanceof IfStatement) {
			IfStatement ifStatement = (IfStatement) action;
			return ifStatement.getConditionals().stream().allMatch(it -> isEffectlessBranch(it));
		}
		if (action instanceof ChoiceStatement) {
			ChoiceStatement choiceStatement = (ChoiceStatement) action;
			return choiceStatement.getBranches().stream().allMatch(it -> isEffectlessBranch(it));
		}
		if (action instanceof SwitchStatement) {
			SwitchStatement switchStatement = (SwitchStatement) action;
			return switchStatement.getCases().stream().allMatch(it -> isEffectlessBranch(it));
		}
		return false;
	}
	
}