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
package hu.bme.mit.gamma.action.util;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.action.model.ActionModelFactory;
import hu.bme.mit.gamma.action.model.AssignmentStatement;
import hu.bme.mit.gamma.action.model.Block;
import hu.bme.mit.gamma.expression.model.AccessExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionUtil;

public class ActionUtil extends ExpressionUtil {
	// Singleton
	public static final ActionUtil INSTANCE = new ActionUtil();
	protected ActionUtil() {}
	//
	
	protected ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE;
	
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
	
	public AssignmentStatement createAssignment(VariableDeclaration variable,
			Expression expression) {
		AssignmentStatement assignmentStatement = actionFactory.createAssignmentStatement();
		DirectReferenceExpression reference = factory.createDirectReferenceExpression();
		reference.setDeclaration(variable);
		assignmentStatement.setLhs(reference);
		assignmentStatement.setRhs(expression);
		return assignmentStatement;
	}
	
}