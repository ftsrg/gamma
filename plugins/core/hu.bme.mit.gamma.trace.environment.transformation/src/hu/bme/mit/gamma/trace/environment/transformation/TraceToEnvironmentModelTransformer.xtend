package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Schedule
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TraceToEnvironmentModelTransformer {
	
	protected final ExecutionTrace executionTrace
	protected final Trace trace
	
	protected extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	
	
	new(ExecutionTrace executionTrace) {
		this.executionTrace = executionTrace
		this.trace = new Trace
	}
	
	def execute() {
		val statechart = createStatechartDefinition
		statechart.transformPorts(trace)
		val mainRegion = createRegion
		statechart.regions += mainRegion
		var StateNode actualState = createInitialState
		mainRegion.stateNodes += actualState
		for (step : executionTrace.steps) {
			val newState = createState
			val transition = createTransition
			transition.sourceState = actualState
			transition.targetState = newState
			statechart.transitions += transition
			
			step.actions
			
			actualState = newState
		}
		return statechart
	}
	
	protected def transformPorts(StatechartDefinition statechart, Trace trace) {
		for (componentPort : executionTrace.component.ports) {
			val environmentPort = componentPort.clone(true, true)
			val interfaceRealization = environmentPort.interfaceRealization
			interfaceRealization.realizationMode = interfaceRealization.realizationMode.opposite
			trace.put(componentPort, environmentPort)
		}
	}
	
	protected def dispatch transformTrigger(TimeElapse act) {
		
	}
	
	protected def dispatch transformTrigger(RaiseEventAct act) {
		val port = act.port
		val environmentPort = trace.get(port)
		val event = act.event
		val arguments = act.arguments
		
		return createRaiseEventAction => [
			it.port = environmentPort
			it.event = event
			for (argument : arguments) {
				it.arguments += argument.clone(true, true)
			}
		]
	}
	
	protected def dispatch transformTrigger(Schedule act) {
		
	}
	
}