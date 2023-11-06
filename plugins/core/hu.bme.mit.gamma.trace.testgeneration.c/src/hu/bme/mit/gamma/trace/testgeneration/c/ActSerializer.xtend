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
		return '''«act.port.name»_«act.event.name»_In(&statechart, true);'''
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
		return '''/* UNHANDLED TYPE : «act.lhs» «act.rhs» */'''
	}
	
	def dispatch String serialize(Reset act, String name) {
		return '''initialize«name.toFirstUpper»Wrapper(&statechart);'''
	}
	
}