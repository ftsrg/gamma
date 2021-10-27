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
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.statechart.StateReferenceExpression;

public class ExpressionSerializer extends hu.bme.mit.gamma.expression.util.ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer();
	protected ExpressionSerializer() {}
	//
	
	protected String _serialize(EventParameterReferenceExpression expression) {
		return expression.getPort().getName() + "." + expression.getEvent().getName() + "::"
				+ expression.getParameter().getName();
	}
	
	protected String _serialize(StateReferenceExpression expression) {
		return "in-state(" + expression.getRegion().getName() + "."
				+ expression.getState().getName() + ")";
	}
	
	
	protected String _serialize(ComponentInstanceReference instance) {
		final String DELIMITER = ".";
		StringBuilder builder = new StringBuilder();
		boolean isFirst = true;
		for (ComponentInstance componentInstance :
				StatechartModelDerivedFeatures.getComponentInstanceChain(instance)) {
			if (isFirst) {
				isFirst = false;
			}
			else {
				builder.append(DELIMITER);
			}
			builder.append(componentInstance.getName());
		}
		return builder.toString();
	}


	public String serialize(Expression expression) {
		if (expression instanceof EventParameterReferenceExpression) {
			return _serialize((EventParameterReferenceExpression) expression);
		}
		if (expression instanceof StateReferenceExpression) {
			return _serialize((StateReferenceExpression) expression);
		}
		if (expression instanceof ComponentInstanceReference) {
			return _serialize((ComponentInstanceReference) expression);
		}
		return super.serialize(expression);
	}
	
}
