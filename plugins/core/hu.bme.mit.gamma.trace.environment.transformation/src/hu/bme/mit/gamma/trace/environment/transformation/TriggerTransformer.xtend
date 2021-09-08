package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.environment.transformation.TraceToEnvironmentModelTransformer.Namings
import hu.bme.mit.gamma.trace.model.ComponentSchedule
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class TriggerTransformer {
	
	protected final Trace trace
	
	protected final extension Namings namings
	
	protected extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	
	protected extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	protected extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	
	new(Trace trace, Namings namings) {
		this.trace = trace
		this.namings = namings
	}
	
	def dispatch transformTrigger(TimeElapse act, Transition transition) {
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
					it.value = elapsedTime.toIntegerLiteral
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
	
	def dispatch transformTrigger(RaiseEventAct act, Transition transition) {
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
	
	def dispatch transformTrigger(ComponentSchedule act, Transition transition) {
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
		val newTransition = target.createTransition(newTarget)
		return newTransition
	}
	
}