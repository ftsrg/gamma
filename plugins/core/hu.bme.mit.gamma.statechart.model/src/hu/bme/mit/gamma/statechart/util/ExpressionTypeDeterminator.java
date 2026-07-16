/********************************************************************************
 * Copyright (c) 2018-2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.util;

import hu.bme.mit.gamma.expression.model.AbstractDirectReferenceExpression;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ParameterReferenceExpression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.expression.model.VariableReferenceExpression;
import hu.bme.mit.gamma.expression.util.ExpressionTypeDeterminator2;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceQueueSizeReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.OccurrenceReferenceExpression;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.statechart.StateReferenceExpression;
import hu.bme.mit.gamma.statechart.statechart.TimeoutReferenceExpression;

public class ExpressionTypeDeterminator extends ExpressionTypeDeterminator2 {
	// Singleton
	public static final ExpressionTypeDeterminator INSTANCE = new ExpressionTypeDeterminator();
	protected ExpressionTypeDeterminator() {}
	//
	
	@Override
	public Type getType(Expression expression) {
		if (expression instanceof StateReferenceExpression) {
			return factory.createBooleanTypeDefinition();
		}
		else if (expression instanceof OccurrenceReferenceExpression) {
			return factory.createBooleanTypeDefinition();
		}
		else if (expression instanceof TimeoutReferenceExpression) {
			return factory.createIntegerTypeDefinition();
		}
		else if (expression instanceof TimeSpecification) {
			return factory.createIntegerTypeDefinition();
		}
		else if (expression instanceof AbstractDirectReferenceExpression ||
				expression instanceof ParameterReferenceExpression ||
				expression instanceof VariableReferenceExpression) {
			return super.getType(expression);
		}
		else if (expression instanceof ComponentInstanceQueueSizeReferenceExpression) {
			return factory.createIntegerTypeDefinition();
		}
		else if (expression instanceof ComponentInstanceElementReferenceExpression) {
			return factory.createBooleanTypeDefinition();
		}
		
		return super.getType(expression);
	}
	
}
