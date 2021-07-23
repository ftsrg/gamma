package hu.bme.mit.gamma.trace.environment.transformation

import hu.bme.mit.gamma.statechart.interface_.Port
import java.util.Map

class Trace {
	
	// Proxy port (environment model port towards the environment)
	// Environment port (environment model port towards the component)
	// Component port (original component port towards the environment model)
	
	final Map<Port, Port> componentEnvironmentPorts = newHashMap
	final Map<Port, Port> componentProxyPorts = newHashMap
	final Map<Port, Port> proxyEnvironmentPorts = newHashMap // Proxy port -> environment port -> component port
	
	// Component-environment ports
	
	def putComponentEnvironmentPort(Port componentPort, Port environmentPort) {
		return componentEnvironmentPorts.put(componentPort, environmentPort)
	}
	
	def getComponentEnvironmentPort(Port componentPort) {
		return componentEnvironmentPorts.get(componentPort)
	}
	
	def getComponentEnvironmentPortPairs() { // Need to be connected via a channel
		return componentEnvironmentPorts.entrySet
	}
	
	// Component-proxy ports
	
	def putComponentProxyPort(Port componentPort, Port proxyPort) {
		return componentProxyPorts.put(componentPort, proxyPort)
	}
	
	def getComponentProxyPort(Port componentPort) {
		return componentProxyPorts.get(componentPort)
	}
	
	// Proxy-environment ports
	
	def putProxyEnvironmentPort(Port proxyPort, Port environmentPort) {
		return proxyEnvironmentPorts.put(proxyPort, environmentPort)
	}
	
	def getProxyEnvironmentPort(Port proxyPort) {
		return proxyEnvironmentPorts.get(proxyPort)
	}
	
	def getProxyEnvironmentPortPairs() {
		return proxyEnvironmentPorts.entrySet
	}
	
}