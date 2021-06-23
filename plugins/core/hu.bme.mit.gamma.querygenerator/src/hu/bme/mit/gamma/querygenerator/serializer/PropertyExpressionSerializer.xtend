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
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.property.model.ComponentInstanceEventParameterReference
import hu.bme.mit.gamma.property.model.ComponentInstanceEventReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateExpression
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer
import hu.bme.mit.gamma.property.model.ActivityDeclarationInstanceNodeReference
import hu.bme.mit.gamma.property.model.ActivityDeclarationInstanceExpression

class PropertyExpressionSerializer extends ExpressionSerializer {
	
	protected extension AbstractReferenceSerializer referenceSerializer
	
	new(AbstractReferenceSerializer referenceSerializer) {
		this.referenceSerializer = referenceSerializer
	}
	
	override String serialize(Expression expression) {
		if (expression instanceof ComponentInstanceStateExpression) {
			return expression.serializeStateExpression
		}
		if (expression instanceof ActivityDeclarationInstanceExpression) {
			return expression.serializeActivityExpression
		}
		return super.serialize(expression)
	}
	
	protected def dispatch serializeActivityExpression(ActivityDeclarationInstanceNodeReference expression) {
		val instance = expression.instance
		val activityNode = expression.activityNode
		return '''«activityNode.getId(instance)»'''
	}
	
	protected def dispatch serializeActivityExpression(ActivityDeclarationInstanceExpression expression) {
		throw new IllegalArgumentException("Unknown expression")
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceStateConfigurationReference expression) {
		val instance = expression.instance
		val region = expression.region
		val state = expression.state
		return '''«state.getId(region, instance)»'''
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceVariableReference expression) {
		val instance = expression.instance
		val variable = expression.variable
		// TODO record?
		return '''«variable.getId(instance).head»'''
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceEventReference expression) {
		val instance = expression.instance
		val port = expression.port
		val event = expression.event
		// Could be extended with in-events too
		return '''«event.getId(port, instance)»'''
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceEventParameterReference expression) {
		val instance = expression.instance
		val port = expression.port
		val event = expression.event
		val parameter = expression.parameter
		// Could be extended with in-events too
		// TODO record?
		return '''«event.getId(port, parameter, instance).head»'''
	}
	
}