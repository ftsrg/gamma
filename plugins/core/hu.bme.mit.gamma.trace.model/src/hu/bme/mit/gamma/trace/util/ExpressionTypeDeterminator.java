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
package hu.bme.mit.gamma.trace.util;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.Type;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;

public class ExpressionTypeDeterminator extends hu.bme.mit.gamma.statechart.util.ExpressionTypeDeterminator {
	// Singleton
	public static final ExpressionTypeDeterminator INSTANCE = new ExpressionTypeDeterminator();
	protected ExpressionTypeDeterminator() {}
	//
	
	@Override
	public Type getType(Expression expression) {
		if (expression instanceof RaiseEventAct) {
			return factory.createBooleanTypeDefinition();
		}
		return super.getType(expression);
	}
	
}
