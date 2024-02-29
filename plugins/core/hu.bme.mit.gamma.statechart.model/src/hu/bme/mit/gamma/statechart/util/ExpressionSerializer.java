/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.util;

import java.util.List;

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
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
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
	
	protected String _serialize(RaiseEventAction expression) {
		StringBuilder builder = new StringBuilder();
		List<Expression> arguments = expression.getArguments();
		if (!arguments.isEmpty()) {
			builder.append("(");
			for (Expression argument : arguments) {
				builder.append(
						serialize(argument) + ", ");
			}
			builder.setLength(builder.length() - 2);
			builder.append(")");
		}
		return expression.getPort().getName() + "." + expression.getEvent().getName() + builder.toString();
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
		
		if (instance == null) {
			return "null"; // To be flexibly callable
		}
		
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
		return _serialize(instance) + DELIMITER + expression.getRegion().getName() +
				DELIMITER + expression.getState().getName();
	}
	
	protected String _serialize(ComponentInstanceVariableReferenceExpression expression) {
		ComponentInstanceReferenceExpression instance = expression.getInstance();
		VariableDeclaration variableDeclaration = expression.getVariableDeclaration();
		return _serialize(instance) + DELIMITER + variableDeclaration.getName();
	}
	
	protected String _serialize(ComponentInstanceEventReferenceExpression expression) {
		ComponentInstanceReferenceExpression instance = expression.getInstance();
		return _serialize(instance) + DELIMITER + expression.getPort().getName() +
				DELIMITER + expression.getEvent().getName();
	}
	
	protected String _serialize(ComponentInstanceEventParameterReferenceExpression expression) {
		ComponentInstanceReferenceExpression instance = expression.getInstance();
		ParameterDeclaration parameterDeclaration = expression.getParameterDeclaration();
		return _serialize(instance) + DELIMITER + expression.getPort().getName() +
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
		if (expression instanceof RaiseEventAction raiseEventAction) {
			return _serialize(raiseEventAction);
		}
		if (expression instanceof EventParameterReferenceExpression eventParameterReferenceExpression) {
			return _serialize(eventParameterReferenceExpression);
		}
		if (expression instanceof StateReferenceExpression reference) {
			return _serialize(reference);
		}
		if (expression instanceof ComponentInstanceReferenceExpression reference) {
			return _serialize(reference);
		}
		if (expression instanceof ComponentInstanceStateReferenceExpression reference) {
			return _serialize(reference);
		}
		if (expression instanceof ComponentInstanceVariableReferenceExpression reference) {
			return _serialize(reference);
		}
		if (expression instanceof ComponentInstanceEventReferenceExpression reference) {
			return _serialize(reference);
		}
		if (expression instanceof ComponentInstanceEventParameterReferenceExpression reference) {
			return _serialize(reference);
		}
		return super.serialize(expression);
	}
	
}
