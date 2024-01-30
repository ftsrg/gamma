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

import hu.bme.mit.gamma.trace.model.Act
import hu.bme.mit.gamma.trace.model.AssignmentAct
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.InstanceSchedule
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Reset
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.xsts.codegeneration.c.serializer.ExpressionSerializer

class ActSerializer {
	
	val ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	
	def dispatch String serialize(Act act, String name) {
		throw new IllegalArgumentException("Illegal Type: " + act)
	}
	
	def dispatch String serialize(RaiseEventAct act, String name) {
		return '''«act.port.name»_«act.event.name»_In(&statechart, true«FOR param : act.arguments», «expressionSerializer.serialize(param)»«ENDFOR»);'''
	}
	
	def dispatch String serialize(TimeElapse act, String name) {
		return '''statechart.getElapsed = &getElapsed«expressionSerializer.serialize(act.elapsedTime)»;'''
	}
	
	def dispatch String serialize(InstanceSchedule act, String name) {
		return '''runCycle«name.toFirstUpper»Wrapper(&statechart);'''
	}
	
	def dispatch String serialize(ComponentSchedule act, String name) {
		return '''runCycle«name.toFirstUpper»Wrapper(&statechart);'''
	}
	
	def dispatch String serialize(AssignmentAct act, String name) {
		return '''«expressionSerializer.serialize(act.lhs)» = «expressionSerializer.serialize(act.rhs)»;'''
	}
	
	def dispatch String serialize(Reset act, String name) {
		return '''initialize«name.toFirstUpper»Wrapper(&statechart);'''
	}
	
}