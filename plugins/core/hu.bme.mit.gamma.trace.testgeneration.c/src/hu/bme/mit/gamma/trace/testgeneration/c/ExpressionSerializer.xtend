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
package hu.bme.mit.gamma.trace.testgeneration.c

import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.trace.model.RaiseEventAct

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.testgeneration.c.util.TestGeneratorUtil.*

class ExpressionSerializer {
	
	val ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	
	def dispatch String serialize(Expression expression, String name) {
		return expressionEvaluator.evaluate(expression).toString
	}
	
	def dispatch String serialize(RaiseEventAct expression, String name) {
		return '''«expression.port.name»_«expression.event.name»_«expression.port.realization»(&statechart)'''
	}
	
	def dispatch String serialize(NotExpression expression, String name) {
		return '''!(«expression.operand.serialize(name)»)'''
	}
	
	def dispatch String serialize(EqualityExpression expression, String name) {
		if (expression.containsArray)
			return '''«expression.leftOperand.serialize(name)», «expression.rightOperand.serialize(name)»'''
		return '''(«expression.leftOperand.serialize(name)» == «expression.rightOperand.serialize(name)»)'''
	}
	
	def dispatch String serialize(ComponentInstanceStateReferenceExpression expression, String name) {
		val state_name = expression.region.name + "_"+ expression.instance.componentInstance.name
		val state_type = expression.region.name.toLowerCase + "_"+ expression.instance.componentInstance.derivedType.name.toLowerCase
		return '''(statechart.«name.toLowerCase»statechart.«state_name.toFirstLower» == «expression.state.name»_«state_type»)'''
	}
	
	def dispatch String serialize(ComponentInstanceVariableReferenceExpression expression, String name) {
		return '''statechart.«name.toLowerCase»statechart.«expression.variableDeclaration.name»_«expression.instance.componentInstance.name»'''
	}
	
	def dispatch String serialize(ArrayLiteralExpression expression, String name) {
		val prefix = expression.arrayType + expression.arraySize
		return '''«IF !prefix.isEmpty && !(expression.isComplexArray)»((«prefix») «ENDIF»{«expression.operands.map[it.serialize(name)].join(', ')»}«IF !prefix.isEmpty && !(expression.isComplexArray)»)«ENDIF»'''
	}
	
}