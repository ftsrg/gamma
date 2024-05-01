/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.codegeneration.java.util.TypeSerializer
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.trace.model.AssignmentAct
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.InstanceSchedule
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Reset
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TimeUnitAnnotation
import hu.bme.mit.gamma.trace.util.ExpressionTypeDeterminator
import hu.bme.mit.gamma.trace.util.TraceUtil

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class ActAndAssertSerializer {
	
	protected final String TEST_INSTANCE_NAME
	protected final String TIMER_OBJECT_NAME
	
	protected final TimeUnit IMPLEMENTATION_TIME_UNIT = TimeUnit.NANOSECOND
		
	protected final Component component
	
	protected final extension ExpressionSerializer expressionSerializer
	
	protected final extension ExpressionTypeDeterminator typeDeterminator = ExpressionTypeDeterminator.INSTANCE
	protected final extension TypeSerializer typeSerializer = TypeSerializer.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	
	new(Component component, String TEST_INSTANCE_NAME, String TIMER_OBJECT_NAME) {
		this.component = component
		this.TIMER_OBJECT_NAME = TIMER_OBJECT_NAME
		this.TEST_INSTANCE_NAME = TEST_INSTANCE_NAME
		this.expressionSerializer = new ExpressionSerializer(component, TEST_INSTANCE_NAME)
	}
	
	// Asserts
	
	def String serializeAssert(Expression assert) {
		expressionSerializer.serialize(assert)
	}

//	protected def dispatch String serializeAssert(XorAssert assert)
//		'''(«FOR operand : assert.asserts SEPARATOR " ^ "»«operand.serializeAssert»«ENDFOR»)'''
//
//	protected def dispatch String serializeAssert(AndAssert assert)
//		'''(«FOR operand : assert.asserts SEPARATOR " && "»«operand.serializeAssert»«ENDFOR»)'''
//
//	protected def dispatch String serializeAssert(NegatedAssert assert)
//		'''!(«assert.negatedAssert.serializeAssert»)'''
//
//	protected def dispatch String serializeAssert(RaiseEventAct assert)
//		'''«TEST_INSTANCE_NAME».isRaisedEvent("«assert.port.name»", "«assert.event.name»", new Object[] {«FOR parameter : assert.arguments BEFORE " " SEPARATOR ", " AFTER " "»«parameter.serialize»«ENDFOR»})'''
//
//	protected def dispatch String serializeAssert(InstanceStateConfiguration assert) {
//		val instance = assert.instance
//		val separator = (instance === null) ? '' : '.'
//		'''«TEST_INSTANCE_NAME»«separator»«util.getFullContainmentHierarchy(instance)».isStateActive("«assert.state.parentRegion.name»", "«assert.state.name»")'''
//	}
//	protected def dispatch String serializeAssert(InstanceVariableState assert) {
//		val instance = assert.variableReference.instance
//		val separator = (instance === null) ? '' : '.'
//		'''«TEST_INSTANCE_NAME»«separator»«util.getFullContainmentHierarchy(instance)».checkVariableValue("«assert.variableReference.variableDeclaration.name»", «assert.value.serialize»)'''
//	}
	
	// Acts
	
	def dispatch String serialize(Reset reset) '''
		«IF component.timed»«TIMER_OBJECT_NAME».reset(); // Timer before the system«ENDIF»
		«TEST_INSTANCE_NAME».reset();
	'''

	def dispatch String serialize(RaiseEventAct raiseEvent) '''
		«TEST_INSTANCE_NAME».raiseEvent("«raiseEvent.port.name»", "«raiseEvent.event.name»"«IF
				!raiseEvent.arguments.empty», new Object[] {«FOR param : raiseEvent.arguments BEFORE " " SEPARATOR ", " AFTER " "»«param.serialize»«ENDFOR»}«ENDIF»);
	'''

	def dispatch String serialize(TimeElapse elapse) {
		val trace = elapse.containingExecutionTrace
		var timeUnit = TimeUnit.MILLISECOND // Default model time unit
		
		if (trace.hasAnnotation(TimeUnitAnnotation)) {
			val timeUnitAnnotation = trace.timeUnitAnnotation
			timeUnit = timeUnitAnnotation.timeUnit
		}
		
		val multplicator = timeUnit.getMultiplicator(IMPLEMENTATION_TIME_UNIT)
		val multiplicatorString = (multplicator == 1) ? "" : ''' * «multplicator»l'''
		
		return '''«IF component.timed»«TIMER_OBJECT_NAME».elapse(«elapse.elapsedTime.serialize»«multiplicatorString»);«ENDIF»'''
	}
	
	def dispatch String serialize(AssignmentAct assignment) '''
		«assignment.lhs.serialize» = («assignment.lhs.type.serialize») «assignment.rhs.serialize»;
	'''

	def dispatch serialize(InstanceSchedule schedule) '''
		«schedule.instanceReference.serializeInstanceReference».schedule();
	'''

	def dispatch String serialize(ComponentSchedule schedule) '''
«««		Theoretically, only asynchronous adapters and synchronous adapters are used
		«TEST_INSTANCE_NAME».schedule();
	'''

}