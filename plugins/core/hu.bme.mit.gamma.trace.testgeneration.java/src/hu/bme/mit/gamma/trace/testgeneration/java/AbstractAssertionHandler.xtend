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
package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.Schedule
import java.util.List

import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

abstract class AbstractAssertionHandler {
	
	protected final int min
	protected final int max
	protected String schedule
	protected final ExecutionTrace trace
	
	protected final ActAndAssertSerializer serializer
	protected final ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE
	
	new(ExecutionTrace trace, ActAndAssertSerializer serializer) {
		this.trace = trace
		if (trace.hasAllowedWaitingAnnotation) {
			val waitingAnnotation = trace.allowedWaitingAnnotation
			this.min = evaluator.evaluateInteger(waitingAnnotation.lowerLimit)
			this.max = evaluator.evaluateInteger(waitingAnnotation.upperLimit)
		}
		else {
			this.min = -1
			this.max = -1
		}
		this.serializer = serializer
		val firstInstance = trace.steps.flatMap[it.actions]
				.findFirst[it instanceof Schedule]
		if (firstInstance !== null) {
			this.schedule = serializer.serialize(firstInstance).toString
		} 
	}

	def abstract String generateAssertBlock(List<Expression> asserts)

}
