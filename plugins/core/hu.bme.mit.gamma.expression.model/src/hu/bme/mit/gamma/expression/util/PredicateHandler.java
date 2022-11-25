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
package hu.bme.mit.gamma.expression.util;

import java.util.ArrayList;
import java.util.List;
import java.util.SortedSet;
import java.util.TreeSet;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.BinaryExpression;
import hu.bme.mit.gamma.expression.model.Declaration;
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression;
import hu.bme.mit.gamma.expression.model.GreaterExpression;
import hu.bme.mit.gamma.expression.model.InequalityExpression;
import hu.bme.mit.gamma.expression.model.LessEqualExpression;
import hu.bme.mit.gamma.expression.model.LessExpression;
import hu.bme.mit.gamma.expression.model.PredicateExpression;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;

public class PredicateHandler {
	// Singleton
	public static final PredicateHandler INSTANCE = new PredicateHandler();
	protected PredicateHandler() {}
	//

	protected final ExpressionNegator expressionNegator = ExpressionNegator.INSTANCE;
	protected final ExpressionUtil expressionUtil = ExpressionUtil.INSTANCE;
	protected final ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final JavaUtil javaUtil = JavaUtil.INSTANCE;
	
	//
	
	protected int getIntegerValue(BinaryExpression predicate, VariableDeclaration variable) {
		Expression left = predicate.getLeftOperand();
		Expression right = predicate.getRightOperand();
		
		if (left instanceof ReferenceExpression) {
			Declaration declaration = expressionUtil.getDeclaration(left);
			if (declaration == variable) {
				return expressionEvaluator.evaluateInteger(right);
			}
		}
		else if (right instanceof ReferenceExpression) {
			Declaration declaration = expressionUtil.getDeclaration(right);
			if (declaration == variable) {
				return expressionEvaluator.evaluateInteger(left);
			}
		}
		
		throw new IllegalArgumentException("No referenced variable: " + variable);
	}
	
	// Should handle intervals, this is just an initial iteration
	
	protected int _calculateIntegerValue(InequalityExpression predicate, VariableDeclaration variable) {
		return getIntegerValue(predicate, variable) + 1;
	}
	
	protected int _calculateIntegerValue(EqualityExpression predicate, VariableDeclaration variable) {
		return getIntegerValue(predicate, variable);
	}
	
	protected int _calculateIntegerValue(LessEqualExpression predicate, VariableDeclaration variable) {
		return getIntegerValue(predicate, variable);
	}
	
	protected int _calculateIntegerValue(GreaterEqualExpression predicate, VariableDeclaration variable) {
		return getIntegerValue(predicate, variable);
	}
	
	protected int _calculateIntegerValue(LessExpression predicate, VariableDeclaration variable) {
		int value = getIntegerValue(predicate, variable);
		Expression left = predicate.getLeftOperand();
		return (left instanceof ReferenceExpression) ? value - 1 : value + 1;
	}
	
	protected int _calculateIntegerValue(GreaterExpression predicate, VariableDeclaration variable) {
		int value = getIntegerValue(predicate, variable);
		Expression left = predicate.getLeftOperand();
		return (left instanceof ReferenceExpression) ? value + 1 : value - 1;
	}
	
	// TODO methods for not assumed values
	
	///
	
	protected int calculateIntegerValue(Expression predicate, VariableDeclaration variable) {
		// No enclosing negation is expected anymore here (NNF - see calculateIntegerValues)
		if (predicate instanceof EqualityExpression) {
			return _calculateIntegerValue((EqualityExpression) predicate, variable);
		} else if (predicate instanceof GreaterEqualExpression) {
			return _calculateIntegerValue((GreaterEqualExpression) predicate, variable);
		} else if (predicate instanceof GreaterExpression) {
			return _calculateIntegerValue((GreaterExpression) predicate, variable);
		} else if (predicate instanceof InequalityExpression) {
			return _calculateIntegerValue((InequalityExpression) predicate, variable);
		} else if (predicate instanceof LessEqualExpression) {
			return _calculateIntegerValue((LessEqualExpression) predicate, variable);
		} else if (predicate instanceof LessExpression) {
			return _calculateIntegerValue((LessExpression) predicate, variable);
		} else {
			throw new IllegalArgumentException("Unhandled parameter types: " + predicate);
		}
	}
	
	///
	
	public SortedSet<Integer> calculateIntegerValues(EObject root, VariableDeclaration variable) {
		SortedSet<Integer> integerValues = new TreeSet<Integer>(
				(Integer l, Integer r) -> l.compareTo(r));
		
		// NNF creation
		EObject clonedRoot = ecoreUtil.clone(root); // Cloning, can be resource-intensive :(
		VariableDeclaration potentiallyClonedVariable = null;
		for (DirectReferenceExpression reference :
				ecoreUtil.getSelfAndAllContentsOfType(clonedRoot, DirectReferenceExpression.class)) {
			Declaration declaration = reference.getDeclaration();
			if (ecoreUtil.helperEquals(variable, declaration)) {
				potentiallyClonedVariable = (VariableDeclaration) declaration;
				break;
			}
		}
		if (potentiallyClonedVariable == null) {
			return integerValues;
		}
		// Handling enclosing negation expressions if there is any
		expressionNegator.transformTransformableNotExpressions(clonedRoot);
		//
		
		List<Expression> predicateExpressions = new ArrayList<Expression>();
		predicateExpressions.addAll(
				ecoreUtil.getAllContentsOfType(clonedRoot, PredicateExpression.class));
		List<BinaryExpression> predicates = javaUtil.filterIntoList(
				predicateExpressions, BinaryExpression.class);
		
		for (BinaryExpression predicate : predicates) {
			try {
				integerValues.add(
						calculateIntegerValue(predicate, potentiallyClonedVariable));
			} catch (IllegalArgumentException e) {
				// Predicate does not contain variable references
				// Note that inequality expressions can mess up things here
			}
		}
		
		return integerValues;
	}
	
}