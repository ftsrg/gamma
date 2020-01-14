package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.Clock
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.Region
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.interface_.Event
import uppaal.declarations.Variable

class Namings {
	
	static var entrySyncId = 0
	static var exitSyncId = 0
	static var exitLocationId = 0
	
	public static var entrySyncNamePrefix = "entryChanOf"
	public static var exitSyncNamePrefix = "exitChanOf"
	
	def static getAsyncSchedulerChannelName(AsynchronousAdapter wrapper) {
		return "async" + wrapper.name
	}
	
	def static getSyncSchedulerChannelName(AsynchronousAdapter wrapper) {
		return "sync" + wrapper.name
	}
	
	def static getInitializedVariableName(AsynchronousAdapter wrapper) {
		return "is"  + wrapper.name.toFirstUpper  + "Initialized"
	}
	
	def static getAsyncSchedulerChannelName(AsynchronousComponentInstance instance) {
		return "async" + instance.name
	}
	
	def static getSyncSchedulerChannelName(AsynchronousComponentInstance instance) {
		return "sync" + instance.name
	}
	
	def static getInitializedVariableName(AsynchronousComponentInstance instance) {
		return "is" + instance.name.toFirstUpper + "Initialized"
	}
	
	def static getPostfix(ComponentInstance instance) {
		if (instance === null) {
			return ""
		}
		return "Of" + instance.name
	}
	
		def static getOutEventName(Event event, Port port, ComponentInstance owner) {
		return port.name + "_" + event.name + "Of" + owner.name
	}
	
	/**
	 * Returns the name of the toRaise boolean flag of the given event of the given port.
	 */
	def static toRaiseName(Event event, Port port, ComponentInstance instance) {
		return "toRaise_" + port.name + "_" + event.name + "Of" + instance.name
	}
	
	/**
	 * Returns the name of the isRaised boolean flag of the given event of the given port.
	 */
	def static isRaisedName(Event event, Port port, ComponentInstance instance) {
		return "isRaised_" + port.name + "_" + event.name + "Of" + instance.name
	}
	
	def static getValueOfName(Variable variable) {
		if (variable.name.startsWith("toRaise_")) {
			return variable.name.substring("toRaise_".length) + "Value"
		}
		else if (variable.name.startsWith("isRaised_")) {
			return variable.name.substring("isRaised_".length) + "Value"
		}
		else {
			return variable.name + "Value"
		}
	}
	
	/**
	 * Returns the template name of a region.
	 */
	def static String getRegionName(Region region) {
	var String templateName
	if (region.eContainer instanceof State) {
			templateName = (region.name + "Of" + (region.eContainer as State).name)
		}
		else {			
			templateName = (region.name + "OfStatechart")
		}
		return templateName.replaceAll(" ","")
	}
	
	/**
	 * Returns the location name of a state.
	 */
	def static String getLocationName(State state) {
 	return state.name.replaceAll(" ","")
	}
	
	/**
	 * Returns the name of the committed entry location of the given composite state.
	 */
	def static getEntryLocationNameOfState(State state) {
		return "entryOf" + state.name.replaceAll(" ", "")
	}
	
	/**
	 * Returns the name of the committed exit location of the given composite state.
	 */
	def static getExitLocationNameOfCompositeState(State state) {
		if (state.regions.empty) {
			throw new IllegalAccessException("State is not composite: " + state)
		}
		return ("exitOf" + state.name + exitLocationId++).replaceAll(" ", "")
	}
	
		
	/**
	 * Returns the name of the committed entry location of the given composite state.
	 */
	def static String getEntrySyncNameOfCompositeState(State state) {
		if (state.regions.empty) {
			throw new IllegalAccessException("State is not composite: " + state)
		}
		return (entrySyncNamePrefix + state.name + entrySyncId++).replaceAll(" ", "")
	}
	
	/**
	 * Returns the name of the committed entry location of the given composite state.
	 */
	def static String getExitSyncNameOfCompositeState(State state) {
		if (state.regions.empty) {
			throw new IllegalAccessException("State is not composite: " + state)
		}
		return (exitSyncNamePrefix + state.name + exitSyncId++).replaceAll(" ", "")
	}
	
	def static getConstRepresentationName(Event event, Port port) {
		return port.name + "_" + event.name
	}
	
	def static getConstRepresentationName(Clock clock) {
		return clock.name + "Of" + (clock.eContainer as AsynchronousAdapter).name
	}
	
	def static finalizeSyncVarName() {
		return "finalize"
	}
	
	def static getIsStableVariableName() {
		return "isStable"
	}
	
	def static getTransitionIdVariableName() {
		return "transitionId"
	}
	
}