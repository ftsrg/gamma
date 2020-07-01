package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceFactory
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.AbstractMap.SimpleEntry

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TraceToEnvironmentModelTransformer {
	
	int timeoutId
	int stateId
	
	protected final ExecutionTrace executionTrace
	protected final Trace trace
	
	protected extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	
	protected extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	protected extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected extension TraceFactory traceFactory = TraceFactory.eINSTANCE
	
	new(ExecutionTrace executionTrace) {
		this.timeoutId = 0
		this.stateId = 0
		this.executionTrace = executionTrace
		this.trace = new Trace
	}
	
	def execute() {
		val statechart = createStatechartDefinition => [
			it.name = executionTrace.name
		]
		statechart.transformPorts(trace)
		val mainRegion = createRegion => [
			it.name = '''MainRegion'''
		]
		statechart.regions += mainRegion
		val initialState = createInitialState => [
			it.name = '''Initial'''
		]
		mainRegion.stateNodes += initialState
		val firstState = createState => [
			it.name = stateName
		]
		mainRegion.stateNodes += firstState
		var actualTransition = createTransition => [
			it.sourceState = initialState
			it.targetState = firstState
		]
		statechart.transitions += actualTransition
		
		val actions = executionTrace.steps.map[it.actions].flatten.toList
		// Resets are not handled; schedules are handled by introducing a new transition 
		actions.set(0, createComponentSchedule)
		for (action : actions) {
			actualTransition = action.transformTrigger(actualTransition)
		}
		// There is an unnecessary empty transition at the end
		val lastState = actualTransition.sourceState as State
		actualTransition.targetState.delete
		actualTransition.delete
		
		return new SimpleEntry(statechart, lastState)
	}
	
	protected def transformPorts(StatechartDefinition statechart, Trace trace) {
		for (componentPort : executionTrace.component.ports) {
			val environmentPort = componentPort.clone(true, true)
			statechart.ports += environmentPort
			val interfaceRealization = environmentPort.interfaceRealization
			interfaceRealization.realizationMode = interfaceRealization.realizationMode.opposite
			trace.put(componentPort, environmentPort)
		}
	}
	
	protected def dispatch transformTrigger(TimeElapse act, Transition transition) {
		val elapsedTime = act.elapsedTime
		
		val timeoutDeclaration = statechartModelFactory.createTimeoutDeclaration => [
			it.name = timeoutDeclarationName
		]
		val statechart = transition.containingStatechart
		statechart.timeoutDeclarations += timeoutDeclaration
	
		val source = transition.sourceState as State
		
		val setTimeoutActions = source.entryActions.filter(SetTimeoutAction)
		if (!setTimeoutActions.empty) {
			val setTimeoutAction = setTimeoutActions.head
			val value = setTimeoutAction.time.value
			setTimeoutAction.time.value = value.add(elapsedTime.intValue)
		}
		else {
			source.entryActions += createSetTimeoutAction => [
				it.timeoutDeclaration = timeoutDeclaration
				it.time = createTimeSpecification => [
					it.value = createIntegerLiteralExpression => [it.value = elapsedTime]
					it.unit = TimeUnit.MILLISECOND
				]
			]
		}
		transition.extendTrigger(
			createEventTrigger => [
				it.eventReference = createTimeoutEventReference => [
					it.timeout = timeoutDeclaration
				]
			], BinaryType.AND
		)
		return transition
	}
	
	protected def dispatch transformTrigger(RaiseEventAct act, Transition transition) {
		val port = act.port
		val environmentPort = trace.get(port)
		val event = act.event
		val arguments = act.arguments
		
		transition.effects += createRaiseEventAction => [
			it.port = environmentPort
			it.event = event
			for (argument : arguments) {
				it.arguments += argument.clone(true, true)
			}
		]
		return transition
	}
	
	protected def dispatch transformTrigger(ComponentSchedule act, Transition transition) {
		if (transition.trigger === null && transition.sourceState instanceof State) {
			// The old transition has to have a trigger
			transition.trigger = createOnCycleTrigger
		}
		val target = transition.targetState
		val region = target.parentRegion
		val newTarget = createState => [
			it.name = stateName
		]
		region.stateNodes += newTarget
		val newTransition = createTransition => [
			it.sourceState = target
			it.targetState = newTarget
		]
		region.containingStatechart.transitions += newTransition
		return newTransition
	}
	
	def getTrace() {
		return trace
	}
	
	protected def String getStateName() '''_«stateId++»'''
	protected def String getTimeoutDeclarationName() '''Timeout«timeoutId++»'''
	
}