package hu.bme.mit.gamma.eventpriority.transformation

import hu.bme.mit.gamma.statechart.model.EventTrigger
import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.PortEventReference
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.util.EcoreUtil.Copier

import static com.google.common.base.Preconditions.checkState
import org.eclipse.emf.ecore.util.EcoreUtil.EqualityHelper

class EventPriorityTransformer {
	
	protected final Package gammaPackage
	protected final StatechartDefinition statechart
	
	protected final extension EventPriorityDeterminer eventPriorityDeterminer = new EventPriorityDeterminer
	
	new(StatechartDefinition statechart) {
		this.gammaPackage = statechart.eContainer.clone as Package
		this.statechart = gammaPackage.components.findFirst[it.helperEquals(statechart)] as StatechartDefinition
	}
	
	def execute() {
		for (transition : statechart.transitions) {
			if (transition.isTransitionTriggerPrioritized) {
				val trigger = transition.trigger
				checkState(trigger instanceof EventTrigger,
					"The trigger of the transition is not an event trigger: " + trigger)
				if (trigger instanceof EventTrigger) {
					val eventReference = trigger.eventReference
					checkState(eventReference instanceof PortEventReference,
						"The event reference is not a port event reference: " + eventReference)
					if (eventReference instanceof PortEventReference) {
						val event = eventReference.event
						checkState(transition.priority === null || transition.priority.intValue == 0,
							"The transition priority is not null or 0: " + transition.priority)
						transition.priority = event.priority
					}
				}
			}
		}
		return gammaPackage
	}
	
	private def helperEquals(EObject lhs, EObject rhs) {
		val helper = new EqualityHelper
		return helper.equals(lhs, rhs) 
	}
	
	private def <T extends EObject> T clone(T element) {
		// A new copier should be used every time, otherwise anomalies happen (references are changed without asking)
		val copier = new Copier(true, true)
		val clone = copier.copy(element) as T
		copier.copyReferences()
		return clone
	}
	
}