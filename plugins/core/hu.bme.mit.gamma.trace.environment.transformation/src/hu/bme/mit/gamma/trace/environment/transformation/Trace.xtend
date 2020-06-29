package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.statechart.interface_.Port
import java.util.Map

class Trace {
	
	Map<Port, Port> ports = newHashMap
	
	def isTraced(Port componentPort) {
		return ports.containsKey(componentPort)
	}
	
	def put(Port componentPort, Port environmentPort) {
		return ports.put(componentPort, environmentPort)
	}
	
	def get(Port componentPort) {
		return ports.get(componentPort)
	}
	
}