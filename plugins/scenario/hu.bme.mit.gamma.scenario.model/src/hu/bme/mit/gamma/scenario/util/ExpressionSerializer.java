/********************************************************************************
 * Copyright (c) 2020-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.scenario.util;

import hu.bme.mit.gamma.expression.model.Expression;

public class ExpressionSerializer extends hu.bme.mit.gamma.statechart.util.ExpressionSerializer {
	
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer();
	protected ExpressionSerializer() {}
	//

	@Override
	public String serialize(Expression expression) {
		return super.serialize(expression);
	}

	
}
