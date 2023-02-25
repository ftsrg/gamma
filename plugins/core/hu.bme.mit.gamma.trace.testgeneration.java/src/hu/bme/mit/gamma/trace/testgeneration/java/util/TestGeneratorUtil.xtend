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
package hu.bme.mit.gamma.trace.testgeneration.java.util

import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.testgeneration.java.ExpressionSerializer
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.transformation.util.annotations.AnnotationNamings

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class TestGeneratorUtil {
	// Resources
	protected final Component component
	
	protected final String[] NOT_HANDLED_STATE_NAME_PATTERNS = #['LocalReactionState[0-9]*','FinalState[0-9]*']

	protected final extension ExpressionSerializer expressionSerializer
	
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE

	new(Component component) {
		this.component = component
		this.expressionSerializer = new ExpressionSerializer(component, "")
	}
	
	def filterAsserts(Step step) {
		val asserts = newArrayList
		for (assertion : step.asserts) {
			val lowermostAssert = assertion.lowermostAssert
			if (lowermostAssert instanceof ComponentInstanceStateReferenceExpression) {
				if (lowermostAssert.state.handled) {
					asserts += assertion
				}
			}
			else if (lowermostAssert instanceof EqualityExpression) {
				if (lowermostAssert.hasOperandOfType(ComponentInstanceVariableReferenceExpression)) {
					val variableReference = lowermostAssert.getOperandOfType(ComponentInstanceVariableReferenceExpression)
					if (variableReference.variableDeclaration.handled) {
						asserts += assertion
					}
				}
				else {
					asserts += assertion
				}
			}
			else {
				asserts += assertion
			}
		}
		return asserts
	}
	
	/**
	 * Returns whether the given Gamma State is a state that is not present in Yakindu.
	 */
	protected def boolean isHandled(State state) {
		val stateName = state.name
		for (notHandledStateNamePattern : NOT_HANDLED_STATE_NAME_PATTERNS) {
			if (stateName.matches(notHandledStateNamePattern)) {
				return false
			}
		}
		return true
	}
	
	protected def boolean isHandled(Declaration declaration) {
		// Not perfect as other variables can be named liked this, but works 99,99% of the time
		val name = declaration.name
		if (name.startsWith(AnnotationNamings.PREFIX) &&
				name.endsWith(AnnotationNamings.POSTFIX) ||
				component.allSimpleInstances.map[it.type].filter(StatechartDefinition)
						.map[it.transitions].flatten.exists[it.id == name] /*Transition id*/) {
			return false
		}
		return true
	}
}
