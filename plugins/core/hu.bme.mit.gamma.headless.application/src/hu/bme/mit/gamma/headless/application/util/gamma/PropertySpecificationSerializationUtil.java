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
package hu.bme.mit.gamma.headless.application.util.gamma;

import java.util.stream.Collectors;

import hu.bme.mit.gamma.expression.util.ExpressionSerializer;
import hu.bme.mit.gamma.statechart.statechart.State;

public abstract class PropertySpecificationSerializationUtil {

	public static String serialize(PropertySpecification specification) {
		StringBuilder sb = new StringBuilder("{\n");
		sb.append(String.format("Temporal operator: %s\n", specification.getOperator()));
		sb.append(String.format("is negated: %s\n", specification.isNegated()));
		sb.append(String.format("states: %s\n",
				specification.getStates().stream().map(State::getName).collect(Collectors.joining(", "))));

		sb.append(String.format("expressions: %s\n", specification.getExpressions().stream()
				.map(ExpressionSerializer.INSTANCE::serialize).collect(Collectors.joining(", "))));
		sb.append("}\n");
		return sb.toString();
	}
}
