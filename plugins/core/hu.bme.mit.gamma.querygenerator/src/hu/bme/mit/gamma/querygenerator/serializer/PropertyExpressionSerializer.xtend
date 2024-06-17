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
package hu.bme.mit.gamma.querygenerator.serializer

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.ImplyExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer
import hu.bme.mit.gamma.util.GammaEcoreUtil

abstract class PropertyExpressionSerializer extends ExpressionSerializer {
	//
	protected extension AbstractReferenceSerializer referenceSerializer
	//
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	//
	new(AbstractReferenceSerializer referenceSerializer) {
		this.referenceSerializer = referenceSerializer
	}
	
	override String serialize(Expression expression) {
		if (expression instanceof IfThenElseExpression) {
			return expression.serializeIfThenElseExpression
		}
		else if (expression instanceof ComponentInstanceElementReferenceExpression) {
			return expression.serializeStateExpression
		}
		return super.serialize(expression)
	}
	
	//
	
	override _serialize(ImplyExpression expression) '''(!(«expression.leftOperand.serialize») || («expression.rightOperand.serialize»))'''
	
	protected def serializeIfThenElseExpression(IfThenElseExpression expression) {
		return super.serialize(expression)
	}
	
	//
	
	protected def dispatch serializeStateExpression(ComponentInstanceStateReferenceExpression expression) {
		val instance = expression.instance
		val region = expression.region
		val state = expression.state
		return '''«state.getId(region, instance)»'''
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceVariableReferenceExpression expression) {
		val instance = expression.instance
		val variable = expression.variableDeclaration
		// TODO record?
		return '''«variable.getId(instance).head»'''
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceEventReferenceExpression expression) {
		val instance = expression.instance
		val port = expression.port
		val event = expression.event
		// Could be extended with in-events too
		return '''«event.getId(port, instance)»'''
	}
	
	protected def dispatch serializeStateExpression(ComponentInstanceEventParameterReferenceExpression expression) {
		val instance = expression.instance
		val port = expression.port
		val event = expression.event
		val parameter = expression.parameterDeclaration
		// Could be extended with in-events too
		// TODO record?
		return '''«event.getId(port, parameter, instance).head»'''
	}
	
	//
	
	def getReferenceSerializer() {
		return this.referenceSerializer
	}
	
}