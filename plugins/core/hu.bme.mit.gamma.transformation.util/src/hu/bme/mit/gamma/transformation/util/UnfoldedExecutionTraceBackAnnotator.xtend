package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.Assert
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.Cycle
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.MultiaryAssert
import hu.bme.mit.gamma.trace.model.NegatedAssert
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Reset
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class UnfoldedExecutionTraceBackAnnotator {
	
	protected final ExecutionTrace trace
	protected final Component originalTopComponent
	
	protected final extension TraceModelFactory traceModelFactory = TraceModelFactory.eINSTANCE
	protected final extension SimpleInstanceHandler instanceHandler = SimpleInstanceHandler.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(ExecutionTrace trace, Component originalTopComponent) {
		this.trace = trace
		this.originalTopComponent = originalTopComponent
	}
	
	def execute() {
		val originalExecutionTrace = createExecutionTrace => [
			it.import = originalTopComponent.containingPackage
			it.annotations += trace.annotations.map[it.clone] // References not expected
			it.name = trace.name
			it.component = originalTopComponent
			it.arguments += trace.arguments.map[it.clone]
		]
		
		val steps = trace.steps
		for (step : steps) {
			originalExecutionTrace.steps != step.transformStep
		}
		
		// Potential cycle at the end
		val cycle = trace.cycle
		if (cycle !== null) {
			originalExecutionTrace.cycle = cycle.transformCycle		
		}
		
		return originalExecutionTrace
	}
	
	
	// Step
	
	protected def transformStep(Step step) {
		val newStep = createStep
		
		for (act : step.actions) {
			newStep.actions += act.transformAct
		}
		
		for (assert : step.asserts) {
			newStep.asserts += assert.transformAssert
		}
		
		return newStep
	}
	
	protected def transformCycle(Cycle cycle) {
		val newCycle = createCycle
		
		for (step : cycle.steps) {
			newCycle.steps += step.transformStep
		}
		
		return newCycle
	}
	
	// Acts
	
	protected def dispatch transformAct(RaiseEventAct act) {
		return createRaiseEventAct => [
			it.port = originalTopComponent.getOriginalPort(act.port)
			it.event = act.event
			it.arguments += act.arguments.map[it.clone]
		]
	}
	
	protected def dispatch transformAct(Reset act) {
		return createReset
	}
	
	protected def dispatch transformAct(ComponentSchedule act) {
		return createComponentSchedule
	}
	
	protected def dispatch transformAct(TimeElapse act) {
		return createTimeElapse => [
			it.elapsedTime = act.elapsedTime
		]
	}
	
	// Asserts
	
	protected def dispatch Assert transformAssert(InstanceStateConfiguration assert) {
		val instance = assert.instance.lastInstance as SynchronousComponentInstance
		val originalInstance = instance.getOriginalSimpleInstanceReference(originalTopComponent)
		val originalState = originalInstance.getOriginalState(assert.state)
		return createInstanceStateConfiguration => [
			it.instance = originalInstance
			it.state = originalState
		]
	}
	
	protected def dispatch Assert transformAssert(InstanceVariableState assert) {
		val instance = assert.instance.lastInstance as SynchronousComponentInstance
		val variable = assert.declaration as VariableDeclaration
		val originalInstance = instance.getOriginalSimpleInstanceReference(originalTopComponent)
		val originalVariable = originalInstance.getOriginalVariable(variable)
		return createInstanceVariableState => [
			it.instance = originalInstance
			it.declaration = originalVariable
			it.value = assert.value.clone
		]
	}
	
	protected def dispatch Assert transformAssert(RaiseEventAct assert) {
		return assert.transformAct as RaiseEventAct // Same as act
	}
	
	protected def dispatch Assert transformAssert(MultiaryAssert assert) {
		val multiaryAssert = assert.eClass.create as MultiaryAssert
		for (operand : assert.asserts) {
			multiaryAssert.asserts += operand.transformAssert
		}
		return multiaryAssert
	}
	
	protected def dispatch Assert transformAssert(NegatedAssert act) {
		return createNegatedAssert => [
			it.negatedAssert = act.negatedAssert.transformAssert
		]
	}
	
}