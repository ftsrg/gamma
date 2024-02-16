/********************************************************************************
 * Copyright (c) 2022-2023 Contributors to the Gamma project
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
import java.util.HashSet;
import java.util.List;
import java.util.Map.Entry;
import java.util.Set;
import java.util.SortedSet;
import java.util.TreeSet;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.xsts.model.AssignmentAction;
import hu.bme.mit.gamma.xsts.model.VariableDeclarationAction;

public class PredicateHandler extends hu.bme.mit.gamma.expression.util.PredicateHandler {
	// Singleton
	public static final PredicateHandler INSTANCE = new PredicateHandler();
	protected PredicateHandler() {}
	//
	protected final XstsActionUtil xStsUtil = XstsActionUtil.INSTANCE;
	//
	
	protected SortedSet<Integer> calculateIntegerValues(EObject root, VariableDeclaration variable,
				Collection<EObject> checkedRoots,
				Collection<VariableDeclaration> checkedVariables,
				Collection<AssignmentAction> assignmentStatements,
				Collection<VariableDeclarationAction> localVariables) {
		SortedSet<Integer> integerValues = new TreeSet<Integer>();
		
		if (!checkedVariables.contains(variable)) {
			// Root change (due to context changes: local var -> global var)
			root = ecoreUtil.getRoot(variable);
			if (!checkedRoots.contains(root)) { // Only if needed
				assignmentStatements.addAll(
					ecoreUtil.getSelfAndAllContentsOfType(root, AssignmentAction.class));
				
				List<VariableDeclarationAction> localVariableActions = ecoreUtil
						.getSelfAndAllContentsOfType(root, VariableDeclarationAction.class);
				localVariableActions.removeIf(it -> it.getVariableDeclaration().getExpression() == null);
				localVariables.addAll(localVariableActions);
				
				checkedRoots.add(root);
			}
			
			checkedVariables.add(variable);
			// Basic function
			integerValues.addAll(
					super.calculateIntegerValues(root, variable));
			//
			List<Entry<VariableDeclaration, Expression>> assignments = new ArrayList<>();
			
			for (AssignmentAction assignmentStatement : assignmentStatements) {
				ReferenceExpression lhs = assignmentStatement.getLhs();
				VariableDeclaration lhsVariable = (VariableDeclaration) xStsUtil.getDeclaration(lhs);
				Expression rhs = assignmentStatement.getRhs();
				
				assignments.add(
					new SimpleEntry<VariableDeclaration, Expression>(lhsVariable, rhs));
			}
			
			for (VariableDeclarationAction localVariableAction : localVariables) {
				VariableDeclaration lhsVariable = localVariableAction.getVariableDeclaration();
				Expression rhs = lhsVariable.getExpression();
				
				// rhs != null -> see the filter above
				assignments.add(
					new SimpleEntry<VariableDeclaration, Expression>(lhsVariable, rhs));
			}
			//
			
			for (Entry<VariableDeclaration, Expression> assignment : assignments) {
				VariableDeclaration lhsVariable = assignment.getKey();
				Expression rhs = assignment.getValue();
				if (rhs instanceof ReferenceExpression) {
					Declaration rhsDeclaration = xStsUtil.getDeclaration(rhs);
					if (rhsDeclaration instanceof VariableDeclaration) {
						VariableDeclaration rhsVariable = (VariableDeclaration) rhsDeclaration;
						if (lhsVariable == variable) {
							integerValues.addAll(
								calculateIntegerValues(root, rhsVariable,
										checkedRoots, checkedVariables, assignmentStatements, localVariables));
						}
						else if (rhsVariable == variable) {
							integerValues.addAll(
								calculateIntegerValues(root, lhsVariable,
										checkedRoots, checkedVariables, assignmentStatements, localVariables));
						}
					}
				}
			}
		}
		
		return integerValues;
	}
	
	public SortedSet<Integer> calculateIntegerValues(EObject root, VariableDeclaration variable) {
		Set<EObject> checkedRoots = new HashSet<EObject>();
		checkedRoots.add(root);
		return calculateIntegerValues(root, variable,
				checkedRoots,
				new HashSet<VariableDeclaration>(),
				new HashSet<AssignmentAction>(
						ecoreUtil.getSelfAndAllContentsOfType(root, AssignmentAction.class)),
				new HashSet<VariableDeclarationAction>(
						ecoreUtil.getSelfAndAllContentsOfType(root, VariableDeclarationAction.class)));
	}
	
}
