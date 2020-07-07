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
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression;

public class ExpressionSerializer extends hu.bme.mit.gamma.expression.util.ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer();
	protected ExpressionSerializer() {}
	//
	
	protected String _serialize(EventParameterReferenceExpression expression) {
		return expression.getPort().getName() + "." + expression.getEvent().getName() + "::"
				+ expression.getParameter().getName();
	}

	public String serialize(Expression expression) {
		try {
			return super.serialize(expression);
		} catch (IllegalArgumentException e) {
			if (expression instanceof EventParameterReferenceExpression) {
				return _serialize((EventParameterReferenceExpression) expression);
			}
		}
		throw new IllegalArgumentException("Unhandled parameter types: " + expression);
	}

}
