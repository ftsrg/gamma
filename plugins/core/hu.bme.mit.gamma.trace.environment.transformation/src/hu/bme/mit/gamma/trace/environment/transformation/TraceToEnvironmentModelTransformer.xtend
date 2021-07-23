package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import java.util.Collection
import java.util.Map.Entry
import java.util.function.Function
import org.eclipse.xtend.lib.annotations.Data

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TraceToEnvironmentModelTransformer {
	
	protected final extension Namings namings
	
	protected final String environmentModelName
	protected final ExecutionTrace executionTrace
	protected final EnvironmentModel environmentModel
	protected final Trace trace
	
	protected extension ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE
	protected extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected extension JavaUtil javaUtil = JavaUtil.INSTANCE
	
	protected extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	protected extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	
	new(String environmentModelName, ExecutionTrace executionTrace, EnvironmentModel environmentModel) {
		this.environmentModelName = environmentModelName
		this.executionTrace = executionTrace
		this.environmentModel = environmentModel
		this.namings = new Namings
		this.trace = new Trace
	}
	
	def execute() {
		val statechart = createStatechartDefinition => [
			it.name = environmentModelName
		]
		
		statechart.transformPorts(trace)
		
		val mainRegion = createRegion => [
			it.name = mainRegionName
		]
		statechart.regions += mainRegion
		val initialState = createInitialState => [
			it.name = initialStateName
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
		
		lastState.createEnvironmentBehavior
		
		return new Result(statechart, lastState)
	}
	
	protected def transformPorts(StatechartDefinition environmentModel, Trace trace) {
		val component = executionTrace.component
		for (componentPort : component.ports) {
			// Environment ports: connected to the original ports
			val environmentPort = componentPort.clone
			val interfaceRealization = environmentPort.interfaceRealization
			
			environmentPort.name = componentPort.environmentPortName
			interfaceRealization.realizationMode = interfaceRealization.realizationMode.opposite
			
			environmentModel.ports += environmentPort
			trace.putComponentEnvironmentPort(componentPort, environmentPort)
			
			// Proxy ports: led out to the system
			if (this.environmentModel !== EnvironmentModel.OFF) { 
				val proxyPort = componentPort.clone
				
				proxyPort.name = componentPort.proxyPortName
				
				environmentModel.ports += proxyPort
				trace.putComponentProxyPort(componentPort, proxyPort)
				trace.putProxyEnvironmentPort(proxyPort, environmentPort)
			}
		}
	}
	
	// Transform ports
	
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
		val componentPort = act.port
		val environmentPort = trace.getComponentEnvironmentPort(componentPort)
		val event = act.event
		val arguments = act.arguments
		
		transition.effects += createRaiseEventAction => [
			it.port = environmentPort
			it.event = event
			for (argument : arguments) {
				it.arguments += argument.clone
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
	
	///
	
	protected def createEnvironmentBehavior(State lastState) {
		if (environmentModel === EnvironmentModel.SYNCHRONOUS) {
			lastState.createSynchronousEnvironmentBehavior
		}
		else if (environmentModel === EnvironmentModel.ASYNCHRONOUS) {
			lastState.createAsynchronousEnvironmentBehavior
		}
		// No behavior in the case of OFF
	}
	
	protected def createSynchronousEnvironmentBehavior(State lastState) {
		val envrionmentModel = lastState.containingStatechart
		val region = lastState.parentRegion
		
		var StateNode lastTargetState = lastState
		
		val proxyPortPairs = trace.proxyEnvironmentPortPairs
		val transitions = proxyPortPairs.createEventPassingTransitions[it.inputEvents]
		for (transition : transitions) {
			val elseTransition = createTransition => [
				it.guard = createElseExpression
			]
			envrionmentModel.transitions += transition
			envrionmentModel.transitions += elseTransition
			
			transition.sourceState = lastTargetState
			elseTransition.sourceState = lastTargetState
			
			val mergeState = createMergeState => [
				it.name = mergeName
			]
			region.stateNodes += mergeState
			
			transition.targetState = mergeState
			elseTransition.targetState = mergeState
			
			lastTargetState = createChoiceState => [
				it.name = choiceName
			]
			region.stateNodes += lastTargetState
			val mergeChoiceTransition = createTransition => [
				it.sourceState = mergeState
				it.targetState = targetState
			]
			envrionmentModel.transitions += mergeChoiceTransition
		}
		val lastMergeChoiceTransition = lastTargetState.incomingTransitions.onlyElement
		val lastMerge = lastMergeChoiceTransition.sourceState
		val lastTransitions = lastMerge.incomingTransitions
		for (lastTransition : lastTransitions) {
			lastTransition.targetState = lastState
		}
		
		lastTargetState.remove
		lastMergeChoiceTransition.remove
		lastMerge.remove
		
		// TODO Should be done the same for output events and a pair of orthogonal regions should be created 
	}
	
	protected def createAsynchronousEnvironmentBehavior(State lastState) {
		val envrionmentModel = lastState.containingStatechart
		
		val proxyPortPairs = trace.proxyEnvironmentPortPairs
		val transitions = proxyPortPairs.createEventPassingTransitions[it.inputEvents]
		for (transition : transitions) {
			envrionmentModel.transitions += transition
			
			transition.sourceState = lastState
			transition.targetState = lastState
		}
		// TODO Should be done the same for output events and a pair of orthogonal regions should be created 
	}
	
	protected def createEventPassingTransitions(Collection<? extends Entry<Port, Port>> portPairs,
			Function<Port, Collection<Event>> eventRetriever) {
		val transitions = newArrayList
		for (portPair : portPairs) {
			val sourcePort = portPair.key
			val targetPort = portPair.value
			
			val inEvents = eventRetriever.apply(sourcePort) // Input or output events are expected
			for (inEvent : inEvents) {
				transitions += inEvent.createEventPassingTransition(sourcePort, targetPort)
			}
		}
		return transitions
	}
	
	protected def createEventPassingTransition(Event event, Port sourcePort, Port targetPort) {
		val transition = createTransition // transition handling by the caller
		// Mapping the input event into...
		transition.trigger = createEventTrigger => [
			it.eventReference = createPortEventReference => [
				it.port = sourcePort
				it.event = event
			]
		]
		// ... a raise event action				
		transition.effects += createRaiseEventAction => [
			it.port = targetPort
			it.event = event
			for (parameter : event.parameterDeclarations) {
				// Just passing through the parameter values...
				it.arguments += createEventParameterReferenceExpression => [
					it.port = sourcePort
					it.event = event
					it.parameter = parameter
				]
			}
		]
		return transition
	}
	
	///
	
	def getTrace() {
		return trace
	}
	
	///
	
	static class Namings {
	
		int timeoutId
		int stateId
		int mergeId
		int choiceId
		
		def String getEnvironmentPortName(Port port) '''_«port.name»_'''
		def String getProxyPortName(Port port) '''«port.name»'''
		
		def String getStateName() '''_«stateId++»'''
		def String getMergeName() '''Merge«mergeId++»'''
		def String getChoiceName() '''Choice«choiceId++»'''
		def String getTimeoutDeclarationName() '''Timeout«timeoutId++»'''
		def String getMainRegionName() '''MainRegion'''
		def String getInitialStateName() '''Initial'''
		
	}
	
	// Result class
	
	@Data
	static class Result {
		StatechartDefinition statechart
		State lastState
	}
	
}