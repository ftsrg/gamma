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
package hu.bme.mit.gamma.statechart.util;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression;
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
	
	
	protected String _serialize(ComponentInstanceReferenceExpression instance) {
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

	// Component instance element references
	
	final String DELIMITER = ".";
	
	protected String _serialize(ComponentInstanceStateReferenceExpression expression) {
		ComponentInstanceReferenceExpression instance = expression.getInstance();
		return super.serialize(instance) + DELIMITER + expression.getRegion().getName() +
				DELIMITER + expression.getState().getName();
	}
	
	protected String _serialize(ComponentInstanceVariableReferenceExpression expression) {
		ComponentInstanceReferenceExpression instance = expression.getInstance();
		VariableDeclaration variableDeclaration = expression.getVariableDeclaration();
		return super.serialize(instance) + DELIMITER + variableDeclaration.getName();
	}
	
	protected String _serialize(ComponentInstanceEventReferenceExpression expression) {
		ComponentInstanceReferenceExpression instance = expression.getInstance();
		return super.serialize(instance) + DELIMITER + expression.getPort().getName() +
				DELIMITER + expression.getEvent().getName();
	}
	
	protected String _serialize(ComponentInstanceEventParameterReferenceExpression expression) {
		ComponentInstanceReferenceExpression instance = expression.getInstance();
		ParameterDeclaration parameterDeclaration = expression.getParameterDeclaration();
		return super.serialize(instance) + DELIMITER + expression.getPort().getName() +
				DELIMITER + expression.getEvent().getName() + "::" + parameterDeclaration.getName();
	}
	
	///
	public String serialize(Expression expression) {
		if (expression instanceof EventParameterReferenceExpression) {
			return _serialize((EventParameterReferenceExpression) expression);
		}
		if (expression instanceof StateReferenceExpression) {
			return _serialize((StateReferenceExpression) expression);
		}
		if (expression instanceof ComponentInstanceReferenceExpression) {
			return _serialize((ComponentInstanceReferenceExpression) expression);
		}
		if (expression instanceof ComponentInstanceStateReferenceExpression) {
			return _serialize((ComponentInstanceStateReferenceExpression) expression);
		}
		if (expression instanceof ComponentInstanceVariableReferenceExpression) {
			return _serialize((ComponentInstanceVariableReferenceExpression) expression);
		}
		if (expression instanceof ComponentInstanceEventReferenceExpression) {
			return _serialize((ComponentInstanceEventReferenceExpression) expression);
		}
		if (expression instanceof ComponentInstanceEventParameterReferenceExpression) {
			return _serialize((ComponentInstanceEventParameterReferenceExpression) expression);
		}
		return super.serialize(expression);
	}
	
}
