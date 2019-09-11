package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance

class Namings {
	
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
	
}