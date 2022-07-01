/********************************************************************************
 * Copyright (c) 2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.util;

import java.util.Collection;
import java.util.HashSet;
import java.util.SortedSet;
import java.util.TreeSet;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.xsts.model.AssignmentAction;

public class PredicateHandler extends hu.bme.mit.gamma.expression.util.PredicateHandler {
	// Singleton
	public static final PredicateHandler INSTANCE = new PredicateHandler();
	protected PredicateHandler() {}
	//
	protected final XstsActionUtil xStsUtil = XstsActionUtil.INSTANCE;
	//
	
	protected SortedSet<Integer> calculateIntegerValues(EObject root, VariableDeclaration variable,
				Collection<VariableDeclaration> checkedVariables, Collection<? extends AssignmentAction> assignmentStatements) {
		SortedSet<Integer> integerValues = new TreeSet<Integer>();
		
		if (!checkedVariables.contains(variable)) {
			checkedVariables.add(variable);
			// Basic function
			integerValues.addAll(
					super.calculateIntegerValues(root, variable));
			//
			for (AssignmentAction assignmentStatement : assignmentStatements) {
				ReferenceExpression lhs = assignmentStatement.getLhs();
				VariableDeclaration lhsVariable = (VariableDeclaration) xStsUtil.getDeclaration(lhs);
				Expression rhs = assignmentStatement.getRhs();
				if (rhs instanceof ReferenceExpression) {
					Declaration rhsDeclaration = xStsUtil.getDeclaration(rhs);
					if (rhsDeclaration instanceof VariableDeclaration) {
						VariableDeclaration rhsVariable = (VariableDeclaration) rhsDeclaration;
						if (lhsVariable == variable) {
							integerValues.addAll(
									calculateIntegerValues(root, rhsVariable,
											checkedVariables, assignmentStatements));
						}
						else if (rhsVariable == variable) {
							integerValues.addAll(
									calculateIntegerValues(root, lhsVariable,
											checkedVariables, assignmentStatements));
						}
					}
				}
			}
		}
		
		return integerValues;
	}
	
	public SortedSet<Integer> calculateIntegerValues(EObject root, VariableDeclaration variable) {
		return calculateIntegerValues(root, variable,
				new HashSet<VariableDeclaration>(), 
				ecoreUtil.getSelfAndAllContentsOfType(root, AssignmentAction.class)); // Caching
	}
	
}
