/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
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
import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference;

public class ExpressionTypeDeterminator extends ExpressionTypeDeterminator2 {
	// Singleton
	public static final ExpressionTypeDeterminator INSTANCE = new ExpressionTypeDeterminator();
	protected ExpressionTypeDeterminator() {}
	//
	
	@Override
	public Type getType(Expression expression) {
		if (expression instanceof ComponentInstanceStateConfigurationReference || 
				expression instanceof ComponentInstanceEventReference) {
			return factory.createBooleanTypeDefinition();
		}
		if (expression instanceof ComponentInstanceVariableReference) {
			ComponentInstanceVariableReference reference = (ComponentInstanceVariableReference) expression;
			VariableDeclaration variable = reference.getVariable();
			Type declarationType = variable.getType();
			return ecoreUtil.clone(declarationType);
		}
		if (expression instanceof ComponentInstanceEventParameterReference) {
			ComponentInstanceEventParameterReference reference = (ComponentInstanceEventParameterReference) expression;
			ParameterDeclaration parameter = reference.getParameter();
			Type declarationType = parameter.getType();
			return ecoreUtil.clone(declarationType);
		}
		return super.getType(expression);
	}	
	
}