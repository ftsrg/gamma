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

import hu.bme.mit.gamma.activity.util.ActivityExpressionTypeDeterminator;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.statechart.StateReferenceExpression;

public class ExpressionTypeDeterminator extends ActivityExpressionTypeDeterminator {
	// Singleton
	public static final ExpressionTypeDeterminator INSTANCE = new ExpressionTypeDeterminator();
	protected ExpressionTypeDeterminator() {}
	//
	
	@Override
	public Type getType(Expression expression) {
		if (expression instanceof StateReferenceExpression) {
			return factory.createBooleanTypeDefinition();
		}
		if (expression instanceof EventParameterReferenceExpression) {
			EventParameterReferenceExpression referenceExpression = (EventParameterReferenceExpression) expression;
			ParameterDeclaration parameter = referenceExpression.getParameter();
			Type type = parameter.getType();
			return ecoreUtil.clone(type);
		}
		return super.getType(expression);
	}
	
}
