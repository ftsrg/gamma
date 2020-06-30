package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.statechart.interface_.Port
import java.util.Map
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration

class Trace {
	
	Map<Port, Port> ports = newHashMap
	TimeoutDeclaration timeoutDeclaration
	
	// Port
	
	def isTraced(Port componentPort) {
		return ports.containsKey(componentPort)
	}
	
	def put(Port componentPort, Port environmentPort) {
		return ports.put(componentPort, environmentPort)
	}
	
	def get(Port componentPort) {
		return ports.get(componentPort)
	}
	
	// Timeout declaration
	
	def hasTimeoutDeclaration() {
		return timeoutDeclaration === null
	}
	
	def setTimeoutDeclaration(TimeoutDeclaration timeoutDeclaration) {
		this.timeoutDeclaration = timeoutDeclaration
	}
	
	def getTimeoutDeclaration() {
		return timeoutDeclaration
	}
	
}