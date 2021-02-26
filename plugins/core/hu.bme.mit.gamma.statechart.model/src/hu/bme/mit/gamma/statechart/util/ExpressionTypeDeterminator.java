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
package hu.bme.mit.gamma.statechart.util;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.util.ExpressionType;
import hu.bme.mit.gamma.statechart.statechart.StateReferenceExpression;

public class ExpressionTypeDeterminator extends hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator {
	// Singleton
	public static final ExpressionTypeDeterminator INSTANCE = new ExpressionTypeDeterminator();
	protected ExpressionTypeDeterminator() {}
	//
	
	/**
	 * Collector of extension methods.
	 */
	public ExpressionType getType(Expression expression) {
		if (expression instanceof StateReferenceExpression) {
			return ExpressionType.BOOLEAN;
		}
		return super.getType(expression);
	}
	
	public boolean isBoolean(Expression	expression) {
		if (expression instanceof StateReferenceExpression) {
			return true;
		}
		return super.isBoolean(expression);
	}
	
}
