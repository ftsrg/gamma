package hu.bme.mit.gamma.codegenerator.java

import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.RealizationMode
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import java.util.Collection
import java.util.HashSet

class ComponentCodeGenerator {
	
	protected final extension EventDeclarationHandler gammaEventDeclarationHandler
	protected final extension TypeTransformer typeTransformer
	
	new(Trace trace) {
		this.gammaEventDeclarationHandler = new EventDeclarationHandler(trace)
		this.typeTransformer = new TypeTransformer(trace)
	}
	
	/**
	 * Generates fields for parameter declarations
	 */
	def CharSequence generateParameterDeclarationFields(Component component) '''
		«IF !component.parameterDeclarations.empty»// Fields representing parameters«ENDIF»
		«FOR parameter : component.parameterDeclarations»
			private final «parameter.type.transformType» «parameter.name»;
		«ENDFOR»
	'''
	
	/** 
	 * Returns all events of the given ports that go in the given direction through the ports.
	 */
	protected def getSemanticEvents(Collection<? extends Port> ports, EventDirection direction) {
		val events =  new HashSet<Event>
		for (anInterface : ports.filter[it.interfaceRealization.realizationMode == RealizationMode.PROVIDED].map[it.interfaceRealization.interface]) {
			events.addAll(anInterface.getAllEvents(direction.oppositeDirection))
		}
		for (anInterface : ports.filter[it.interfaceRealization.realizationMode == RealizationMode.REQUIRED].map[it.interfaceRealization.interface]) {
			events.addAll(anInterface.getAllEvents(direction))
		}
		return events
	}
	
}