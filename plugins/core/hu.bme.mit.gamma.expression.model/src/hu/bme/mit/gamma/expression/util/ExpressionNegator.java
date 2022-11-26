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
package hu.bme.mit.gamma.expression.util;

import java.util.List;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.AndExpression;
import hu.bme.mit.gamma.expression.model.EqualityExpression;
import hu.bme.mit.gamma.expression.model.EquivalenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.expression.model.FalseExpression;
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression;
import hu.bme.mit.gamma.expression.model.GreaterExpression;
import hu.bme.mit.gamma.expression.model.ImplyExpression;
import hu.bme.mit.gamma.expression.model.InequalityExpression;
import hu.bme.mit.gamma.expression.model.LessEqualExpression;
import hu.bme.mit.gamma.expression.model.LessExpression;
import hu.bme.mit.gamma.expression.model.NotExpression;
import hu.bme.mit.gamma.expression.model.OrExpression;
import hu.bme.mit.gamma.expression.model.ReferenceExpression;
import hu.bme.mit.gamma.expression.model.TrueExpression;
import hu.bme.mit.gamma.expression.model.XorExpression;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class ExpressionNegator {
	// Singleton
	public static final ExpressionNegator INSTANCE = new ExpressionNegator();
	protected ExpressionNegator() {}
	//
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final ExpressionModelFactory factory = ExpressionModelFactory.eINSTANCE;
	
	public Expression _negate(TrueExpression expression) {
		return factory.createFalseExpression();
	}
	
	public Expression _negate(FalseExpression expression) {
		return factory.createTrueExpression();
	}
	
	public Expression _negate(NotExpression expression) {
		return ecoreUtil.clone(expression.getOperand());
	}
	
	public Expression _negate(ReferenceExpression expression) {
		NotExpression notExpression = factory.createNotExpression();
		notExpression.setOperand(ecoreUtil.clone(expression));
		return notExpression;
	}
	
	public Expression _negate(AndExpression expression) {
		OrExpression orExpression = factory.createOrExpression();
		for (Expression operand : expression.getOperands()) {
			orExpression.getOperands().add(negate(operand));
		}
		return orExpression;
	}
	
	public Expression _negate(XorExpression expression) {
//		AddExpression addExpression = factory.createAddExpression();
//		for (Expression operand : expression.getOperands()) {
//			IfThenElseExpression ifThenElseExpression = factory.createIfThenElseExpression();
//			ifThenElseExpression.setCondition(
//					ecoreUtil.clone(operand));
//			
//			IntegerLiteralExpression one = factory.createIntegerLiteralExpression();
//			one.setValue(BigInteger.ONE);
//			ifThenElseExpression.setThen(one);
//			
//			IntegerLiteralExpression zero = factory.createIntegerLiteralExpression();
//			zero.setValue(BigInteger.ZERO);
//			ifThenElseExpression.setElse(zero);
//			
//			addExpression.getOperands().add(
//					ifThenElseExpression);
//		}
//		ModExpression modExpression = factory.createModExpression();
//		modExpression.setLeftOperand(addExpression);
//		
//		IntegerLiteralExpression two = factory.createIntegerLiteralExpression();
//		two.setValue(BigInteger.TWO);
//		modExpression.setRightOperand(two);
//		
//		EqualityExpression equalityExpression = factory.createEqualityExpression();
//		equalityExpression.setLeftOperand(modExpression);
//		
//		IntegerLiteralExpression zero = factory.createIntegerLiteralExpression();
//		zero.setValue(BigInteger.ZERO);
//		equalityExpression.setRightOperand(zero);
//		
//		return equalityExpression;
		// Xnor = equivalence
		
		EqualityExpression firstEqualityExpression = factory.createEqualityExpression();
		EquivalenceExpression equivalence = firstEqualityExpression;
		
		for (Expression operand : expression.getOperands()) {
			Expression clonedOperand = ecoreUtil.clone(operand);
			if (equivalence == firstEqualityExpression) {
				// 1.
				equivalence.setLeftOperand(clonedOperand);
			}
			else if (equivalence.getRightOperand() == null) {
				// 2.
				equivalence.setRightOperand(clonedOperand);
			}
			else {
				// 3. and others
				Expression rightOperand = equivalence.getRightOperand();
				InequalityExpression inequality = factory.createInequalityExpression();
				inequality.setLeftOperand(rightOperand);
				inequality.setRightOperand(clonedOperand);
				
				equivalence.setRightOperand(inequality);
				
				equivalence = inequality;
			}
		}
		
		return firstEqualityExpression;
	}
	
	public Expression _negate(OrExpression expression) {
		AndExpression andExpression = factory.createAndExpression();
		for (Expression operand : expression.getOperands()) {
			andExpression.getOperands().add(negate(operand));
		}
		return andExpression;
	}
	
	public Expression _negate(ImplyExpression expression) {
		AndExpression andExpression = factory.createAndExpression();
		andExpression.getOperands().add(ecoreUtil.clone(expression.getLeftOperand()));
		andExpression.getOperands().add(negate(expression.getRightOperand()));
		return andExpression;
	}
	
	public Expression _negate(EqualityExpression expression) {
		InequalityExpression inequalityExpression = factory.createInequalityExpression();
		inequalityExpression.setLeftOperand(ecoreUtil.clone(expression.getLeftOperand()));
		inequalityExpression.setRightOperand(ecoreUtil.clone(expression.getRightOperand()));
		return inequalityExpression;
	}
	
	public Expression _negate(InequalityExpression expression) {
		EqualityExpression equalityExpression = factory.createEqualityExpression();
		equalityExpression.setLeftOperand(ecoreUtil.clone(expression.getLeftOperand()));
		equalityExpression.setRightOperand(ecoreUtil.clone(expression.getRightOperand()));
		return equalityExpression;
	}
	
	public Expression _negate(GreaterExpression expression) {
		LessEqualExpression predicateExpression = factory.createLessEqualExpression();
		predicateExpression.setLeftOperand(ecoreUtil.clone(expression.getLeftOperand()));
		predicateExpression.setRightOperand(ecoreUtil.clone(expression.getRightOperand()));
		return predicateExpression;
	}
	
	public Expression _negate(GreaterEqualExpression expression) {
		LessExpression predicateExpression = factory.createLessExpression();
		predicateExpression.setLeftOperand(ecoreUtil.clone(expression.getLeftOperand()));
		predicateExpression.setRightOperand(ecoreUtil.clone(expression.getRightOperand()));
		return predicateExpression;
	}
	
	public Expression _negate(LessExpression expression) {
		GreaterEqualExpression predicateExpression = factory.createGreaterEqualExpression();
		predicateExpression.setLeftOperand(ecoreUtil.clone(expression.getLeftOperand()));
		predicateExpression.setRightOperand(ecoreUtil.clone(expression.getRightOperand()));
		return predicateExpression;
	}
	
	public Expression _negate(LessEqualExpression expression) {
		GreaterExpression predicateExpression = factory.createGreaterExpression();
		predicateExpression.setLeftOperand(ecoreUtil.clone(expression.getLeftOperand()));
		predicateExpression.setRightOperand(ecoreUtil.clone(expression.getRightOperand()));
		return predicateExpression;
	}
	
	public Expression negate(Expression expression) {
		if (expression instanceof TrueExpression) {
			return _negate((TrueExpression) expression);
		}
		else if (expression instanceof FalseExpression) {
			return _negate((FalseExpression) expression);
		}
		else if (expression instanceof NotExpression) {
			return _negate((NotExpression) expression);
		}
		else if (expression instanceof ReferenceExpression) {
			return _negate((ReferenceExpression) expression);
		}
		else if (expression instanceof AndExpression) {
			return _negate((AndExpression) expression);
		}
		else if (expression instanceof XorExpression) {
			return _negate((XorExpression) expression);
		}
		else if (expression instanceof OrExpression) {
			return _negate((OrExpression) expression);
		}
		else if (expression instanceof ImplyExpression) {
			return _negate((ImplyExpression) expression);
		}
		else if (expression instanceof EqualityExpression) {
			return _negate((EqualityExpression) expression);
		}
		else if (expression instanceof InequalityExpression) {
			return _negate((InequalityExpression) expression);
		}
		else if (expression instanceof GreaterExpression) {
			return _negate((GreaterExpression) expression);
		}
		else if (expression instanceof GreaterEqualExpression) {
			return _negate((GreaterEqualExpression) expression);
		}
		else if (expression instanceof LessExpression) {
			return _negate((LessExpression) expression);
		}
		else if (expression instanceof LessEqualExpression) {
			return _negate((LessEqualExpression) expression);
		}
		else {
			throw new IllegalArgumentException("Unhandled parameter types: " + expression);
		}
	}
	
	//
	
	public void transformTransformableNotExpressions(EObject root) {
		List<NotExpression> negations = ecoreUtil.getSelfAndAllContentsOfType(
				root, NotExpression.class);
		
		int size = 0;
		while (size != negations.size()) {
			size = negations.size();
			
			for (NotExpression notExpression : negations) {
				Expression negatedExpression = negate(
						notExpression.getOperand());
				ecoreUtil.replace(negatedExpression, notExpression);
			}
			
			negations = ecoreUtil.getSelfAndAllContentsOfType(
					root, NotExpression.class);
		}
	}
	
}
