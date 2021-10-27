package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.trace.model.AndAssert
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.InstanceSchedule
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.NegatedAssert
import hu.bme.mit.gamma.trace.model.OrAssert
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Reset
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.XorAssert
import hu.bme.mit.gamma.trace.testgeneration.java.util.TestGeneratorUtil
import hu.bme.mit.gamma.trace.util.TraceUtil

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ActAndAssertSerializer {
	
	protected final String TEST_INSTANCE_NAME
	protected final String TIMER_OBJECT_NAME
	
	protected final Component component
	protected final TestGeneratorUtil util
	
	protected final extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	
	new(Component component, String TEST_INSTANCE_NAME, String TIMER_OBJECT_NAME) {
		this.component = component
		this.TIMER_OBJECT_NAME = TIMER_OBJECT_NAME
		this.TEST_INSTANCE_NAME = TEST_INSTANCE_NAME
		this.util = new TestGeneratorUtil(component)
	}
	
	// Asserts
	
	protected def dispatch String serializeAssert(OrAssert assert)
		'''(«FOR operand : assert.asserts SEPARATOR " || "»«operand.serializeAssert»«ENDFOR»)'''

	protected def dispatch String serializeAssert(XorAssert assert)
		'''(«FOR operand : assert.asserts SEPARATOR " ^ "»«operand.serializeAssert»«ENDFOR»)'''

	protected def dispatch String serializeAssert(AndAssert assert)
		'''(«FOR operand : assert.asserts SEPARATOR " && "»«operand.serializeAssert»«ENDFOR»)'''

	protected def dispatch String serializeAssert(NegatedAssert assert)
		'''!(«assert.negatedAssert.serializeAssert»)'''

	protected def dispatch String serializeAssert(RaiseEventAct assert)
		'''«TEST_INSTANCE_NAME».isRaisedEvent("«assert.port.name»", "«assert.event.name»", new Object[] {«FOR parameter : assert.arguments BEFORE " " SEPARATOR ", " AFTER " "»«parameter.serialize»«ENDFOR»})'''

	protected def dispatch String serializeAssert(InstanceStateConfiguration assert)
		'''«TEST_INSTANCE_NAME».«util.getFullContainmentHierarchy(assert.instance)».isStateActive("«assert.state.parentRegion.name»", "«assert.state.name»")'''

	protected def dispatch String serializeAssert(InstanceVariableState assert)
		'''«TEST_INSTANCE_NAME».«util.getFullContainmentHierarchy(assert.instance)».checkVariableValue("«assert.declaration.name»", «assert.value.serialize»)'''
	
	// Acts
	
	protected def dispatch String serialize(Reset reset) '''
		«IF component.timed»«TIMER_OBJECT_NAME».reset(); // Timer before the system«ENDIF»
		«TEST_INSTANCE_NAME».reset();
	'''

	protected def dispatch String serialize(RaiseEventAct raiseEvent) '''
		«TEST_INSTANCE_NAME».raiseEvent("«raiseEvent.port.name»", "«raiseEvent.event.name»", new Object[] {«FOR param : raiseEvent.arguments BEFORE " " SEPARATOR ", " AFTER " "»«param.serialize»«ENDFOR»});
	'''

	protected def dispatch String serialize(TimeElapse elapse) '''
		«TIMER_OBJECT_NAME».elapse(«elapse.elapsedTime»);
	'''

	protected def dispatch serialize(InstanceSchedule schedule) '''
«««		Theoretically, we do not use such models
		«TEST_INSTANCE_NAME».«util.getFullContainmentHierarchy(schedule.scheduledInstance)».schedule(null);
	'''

	protected def dispatch String serialize(ComponentSchedule schedule) '''
«««		Theoretically, only asynchronous adapters and synchronous adapters are used
		«TEST_INSTANCE_NAME».schedule();
	'''

}