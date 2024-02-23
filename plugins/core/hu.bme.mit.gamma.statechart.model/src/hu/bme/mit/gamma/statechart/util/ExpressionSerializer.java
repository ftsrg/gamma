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
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.interface_.TimeUnit;
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference;
import hu.bme.mit.gamma.statechart.statechart.ClockTickReference;
import hu.bme.mit.gamma.statechart.statechart.PortEventReference;
import hu.bme.mit.gamma.statechart.statechart.StateReferenceExpression;
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference;
import hu.bme.mit.gamma.statechart.statechart.TimeoutReferenceExpression;

public class ExpressionSerializer extends hu.bme.mit.gamma.expression.util.ExpressionSerializer {
	// Singleton
	public static final ExpressionSerializer INSTANCE = new ExpressionSerializer();
	protected ExpressionSerializer() {}
	//
	
	//
	
	protected String _serialize(AnyPortEventReference expression) {
		return expression.getPort().getName() + ".any";
	}
	
	protected String _serialize(PortEventReference expression) {
		return expression.getPort().getName() + "." + expression.getEvent().getName();
	}
	
	protected String _serialize(ClockTickReference expression) {
		return expression.getClock().getName() + ".tick";
	}
	
	protected String _serialize(TimeoutEventReference expression) {
		return "timeout " + expression.getTimeout().getName();
	}
	
	protected String _serialize(TimeoutReferenceExpression expression) {
		return expression.getTimeout().getName();
	}
	
	protected String _serialize(TimeSpecification timeSpecification) {
		return serialize(timeSpecification.getValue()) + " " + _serialize(timeSpecification.getUnit());
	}
	
	protected String _serialize(TimeUnit timeUnit) {
		switch (timeUnit) {
		case SECOND:
			return "s";
		case MILLISECOND:
			return "ms";
		default:
			throw new IllegalArgumentException("Not known time unit: " + timeUnit);
		}
	}
	
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
		if (expression instanceof AnyPortEventReference anyPortEventReference) {
			return _serialize(anyPortEventReference);
		}
		if (expression instanceof PortEventReference portEventReference) {
			return _serialize(portEventReference);
		}
		if (expression instanceof ClockTickReference clockTickReference) {
			return _serialize(clockTickReference);
		}
		if (expression instanceof TimeoutEventReference timeoutEventReference) {
			return _serialize(timeoutEventReference);
		}
		if (expression instanceof EventParameterReferenceExpression eventParameterReferenceExpression) {
			return _serialize(eventParameterReferenceExpression);
		}
		if (expression instanceof StateReferenceExpression stateReferenceExpression) {
			return _serialize(stateReferenceExpression);
		}
		if (expression instanceof ComponentInstanceReferenceExpression componentInstanceReferenceExpression) {
			return _serialize(componentInstanceReferenceExpression);
		}
		if (expression instanceof ComponentInstanceStateReferenceExpression componentInstanceStateReferenceExpression) {
			return _serialize(componentInstanceStateReferenceExpression);
		}
		if (expression instanceof ComponentInstanceVariableReferenceExpression componentInstanceVariableReferenceExpression) {
			return _serialize(componentInstanceVariableReferenceExpression);
		}
		if (expression instanceof ComponentInstanceEventReferenceExpression componentInstanceEventReferenceExpression) {
			return _serialize(componentInstanceEventReferenceExpression);
		}
		if (expression instanceof ComponentInstanceEventParameterReferenceExpression componentInstanceEventParameterReferenceExpression) {
			return _serialize(componentInstanceEventParameterReferenceExpression);
		}
		if (expression instanceof TimeoutReferenceExpression timeoutReferenceExpression) {
			return _serialize(timeoutReferenceExpression);
		}
		if (expression instanceof TimeSpecification timeSpecification) {
			return _serialize(timeSpecification);
		}
		return super.serialize(expression);
	}
	
}
