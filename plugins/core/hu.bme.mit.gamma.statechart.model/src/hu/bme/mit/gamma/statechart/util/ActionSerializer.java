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

import hu.bme.mit.gamma.action.model.Action;
import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.interface_.TimeUnit;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction;

public class ActionSerializer extends hu.bme.mit.gamma.action.util.ActionSerializer {
	// Singleton
	public static final ActionSerializer INSTANCE = new ActionSerializer();

	protected ActionSerializer() {
		super.expressionSerializer = ExpressionSerializer.INSTANCE;
	}
	//

	protected String _serialize(SetTimeoutAction action) {
		final TimeSpecification time = action.getTime();
		return action.getTimeoutDeclaration().getName() + " := "
				+ expressionSerializer.serialize(time.getValue()) + " " + serialize(time.getUnit());
	}

	protected String serialize(TimeUnit timeUnit) {
		return ((ExpressionSerializer) expressionSerializer)._serialize(timeUnit);
	}

	protected String _serialize(RaiseEventAction raiseEventAction) {
		StringBuilder builder = new StringBuilder(
				raiseEventAction.getPort().getName() + "." + raiseEventAction.getEvent().getName() + "(");
		boolean isFirst = true;
		for (Expression argument : raiseEventAction.getArguments()) {
			if (isFirst) {
				isFirst = false;
			} else {
				builder.append(", ");
			}
			builder.append(expressionSerializer.serialize(argument));
		}
		builder.append(")");
		return builder.toString();
	}

	public String serialize(Action action) {
		if (action instanceof SetTimeoutAction) {
			return _serialize((SetTimeoutAction) action);
		} else if (action instanceof RaiseEventAction) {
			return _serialize((RaiseEventAction) action);
		}
		return super.serialize(action);
	}
}
