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
package hu.bme.mit.gamma.property.util;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator2;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression;

public class ExpressionTypeDeterminator extends ExpressionTypeDeterminator2 {
	// Singleton
	public static final ExpressionTypeDeterminator INSTANCE = new ExpressionTypeDeterminator();
	protected ExpressionTypeDeterminator() {}
	//
	
	@Override
	public Type getType(Expression expression) {
		if (expression instanceof ComponentInstanceVariableReferenceExpression) {
			ComponentInstanceVariableReferenceExpression reference =
					(ComponentInstanceVariableReferenceExpression) expression;
			VariableDeclaration variable = reference.getVariableDeclaration();
			Type declarationType = variable.getType();
			return ecoreUtil.clone(declarationType);
		}
		else if (expression instanceof ComponentInstanceEventParameterReferenceExpression) {
			ComponentInstanceEventParameterReferenceExpression reference =
					(ComponentInstanceEventParameterReferenceExpression) expression;
			ParameterDeclaration parameter = reference.getParameterDeclaration();
			Type declarationType = parameter.getType();
			return ecoreUtil.clone(declarationType);
		}
		else if (expression instanceof ComponentInstanceElementReferenceExpression) {
			return factory.createBooleanTypeDefinition();
		}
		return super.getType(expression);
	}	
	
}