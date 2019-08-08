package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.codegenerator.java.queries.EventToEvent
import hu.bme.mit.gamma.codegenerator.java.queries.Traces
import hu.bme.mit.gamma.statechart.model.Port
import org.eclipse.emf.ecore.EObject
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.yakindu.base.types.Event

class Trace {
	
	protected final ViatraQueryEngine engine
	
	new(ViatraQueryEngine engine) {
		this.engine = engine
	}
	
	/**
	 * Returns a Set of EObjects that are created of the given "from" object.
	 */
	protected def getAllValuesOfTo(EObject from) {
		return engine.getMatcher(Traces.instance).getAllValuesOfto(null, from)		
	}
	
	/**
	 * Returns a Set of EObjects that the given "to" object is created of.
	 */
	protected def getAllValuesOfFrom(EObject to) {
		return engine.getMatcher(Traces.instance).getAllValuesOffrom(null, to)
	}
	
	/**
	 * Returns the Yakindu event the given Gamma event is generated from.
	 */
	protected def Event toYakinduEvent(hu.bme.mit.gamma.statechart.model.interface_.Event event, Port port) {
		val yEvents = EventToEvent.Matcher.on(engine).getAllValuesOfyEvent(port, event)
		if (yEvents.size != 1) {
			throw new IllegalArgumentException("Not one Yakindu event mapped to Gamma event. Gamma port: " + port.name + ". " + "Gamma event: " + event.name + ". Yakindu event size: " + yEvents.size + ". Yakindu events:" + yEvents)
		}
		return yEvents.head
	}
	
}