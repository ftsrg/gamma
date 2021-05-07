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
import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference;
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference;

public class ExpressionSerializer extends hu.bme.mit.gamma.statechart.util.ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer();
	protected ExpressionSerializer() {}
	//
	final String DELIMITER = ".";
	
	protected String _serialize(ComponentInstanceStateConfigurationReference expression) {
		ComponentInstanceReference instance = expression.getInstance();
		return super.serialize(instance) + DELIMITER + expression.getRegion().getName() +
				DELIMITER + expression.getState().getName();
	}
	
	protected String _serialize(ComponentInstanceVariableReference expression) {
		ComponentInstanceReference instance = expression.getInstance();
		return super.serialize(instance) + DELIMITER + expression.getVariable().getName();
	}
	
	protected String _serialize(ComponentInstanceEventReference expression) {
		ComponentInstanceReference instance = expression.getInstance();
		return super.serialize(instance) + DELIMITER + expression.getPort().getName() +
				DELIMITER + expression.getEvent().getName();
	}
	
	protected String _serialize(ComponentInstanceEventParameterReference expression) {
		ComponentInstanceReference instance = expression.getInstance();
		return super.serialize(instance) + DELIMITER + expression.getPort().getName() +
				DELIMITER + expression.getEvent().getName() + "::" + expression.getParameter().getName();
	}

	public String serialize(Expression expression) {
		if (expression instanceof ComponentInstanceStateConfigurationReference) {
			return _serialize((ComponentInstanceStateConfigurationReference) expression);
		}
		if (expression instanceof ComponentInstanceVariableReference) {
			return _serialize((ComponentInstanceVariableReference) expression);
		}
		if (expression instanceof ComponentInstanceEventReference) {
			return _serialize((ComponentInstanceEventReference) expression);
		}
		if (expression instanceof ComponentInstanceEventParameterReference) {
			return _serialize((ComponentInstanceEventParameterReference) expression);
		}
		return super.serialize(expression);
	}
	
}
