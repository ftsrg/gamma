package hu.bme.mit.gamma.scenario.statechart.traversal

import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.Trigger
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class PathPreProcessor {

	List<Port> correctPorts = newArrayList

	def Path preProcess(Path path) {
		correctPorts.clear
		var statechart = path.getTransitions.get(0).containingStatechart
		correctPorts += statechart.ports.filter[!it.inputEvents.empty]

		for (t : path.transitions) {
			t.trigger = traverseTrigger(t.trigger)
		}
		return path
	}

	def protected Trigger traverseTrigger(Trigger trigger) {

		if (trigger instanceof EventTrigger) {
			var evt = trigger.eventReference
			if (evt instanceof PortEventReference) {
				if (!correctPorts.contains(evt.port))
					return null
				else {
					return trigger
				}
			} else if (evt instanceof AnyPortEventReference) {
				if (!correctPorts.contains(evt.port))
					return null
				else
					return trigger
			} else if (evt instanceof TimeoutEventReference) {
				return trigger
			}
			return trigger
		} else if (trigger instanceof UnaryTrigger && (trigger as UnaryTrigger).type.equals(UnaryType.NOT)) {
			(trigger as UnaryTrigger).operand = traverseTrigger((trigger as UnaryTrigger).operand)
			return trigger
		} else if (trigger instanceof BinaryTrigger) {
			trigger.rightOperand = traverseTrigger((trigger as BinaryTrigger).rightOperand)
			trigger.leftOperand = traverseTrigger((trigger as BinaryTrigger).leftOperand)
			return trigger
		}
	}
}
