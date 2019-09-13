package hu.bme.mit.gamma.eventpriority.transformation

import hu.bme.mit.gamma.statechart.model.BinaryTrigger
import hu.bme.mit.gamma.statechart.model.EventReference
import hu.bme.mit.gamma.statechart.model.EventTrigger
import hu.bme.mit.gamma.statechart.model.PortEventReference
import hu.bme.mit.gamma.statechart.model.Transition
import hu.bme.mit.gamma.statechart.model.Trigger
import hu.bme.mit.gamma.statechart.model.UnaryTrigger

class EventPriorityDeterminer {
	
	def isTransitionTriggerPrioritized(Transition transition) {
		if (transition.trigger === null) {
			return false
		}
		return transition.trigger.isTriggerPrioritized
	}
	
	def dispatch boolean isTriggerPrioritized(Trigger trigger) {
		throw new IllegalArgumentException("Not known trigger: " + trigger)
	}
	
	def dispatch boolean isTriggerPrioritized(UnaryTrigger trigger) {
		return trigger.operand.isTriggerPrioritized
	}
	
	def dispatch boolean isTriggerPrioritized(BinaryTrigger trigger) {
		return trigger.leftOperand.isTriggerPrioritized || trigger.rightOperand.isTriggerPrioritized
	}
	
	def dispatch boolean isTriggerPrioritized(EventTrigger trigger) {
		return trigger.eventReference.isEventPrioritized
	}
	
	def dispatch boolean isEventPrioritized(EventReference eventReference) {
		return false
	}
	
	def dispatch boolean isEventPrioritized(PortEventReference eventReference) {
		return eventReference.event.priority !== null
	}
	
}