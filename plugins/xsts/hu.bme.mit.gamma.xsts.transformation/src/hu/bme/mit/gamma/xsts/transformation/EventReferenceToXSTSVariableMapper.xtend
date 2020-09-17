package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventReference
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XSTSActionUtil

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class EventReferenceToXSTSVariableMapper {
	
	protected final XSTS xSts
	protected final extension XSTSActionUtil xStsActionUtil = XSTSActionUtil.INSTANCE
	
	new (XSTS xSts) {
		this.xSts = xSts
	}
	
	dispatch def getVariables(EventReference eventReference) {
		// Currently other event references are not supported
		return #[]
	}
	
	dispatch def getVariables(PortEventReference eventReference) {
		val port = eventReference.port
		val event = eventReference.event
		return event.getInputEventVariables(port)
	}
	
	dispatch def getVariables(AnyPortEventReference eventReference) {
		val xStsVariables = newHashSet
		val port = eventReference.port
		for (inEvent : port.inputEvents) {
			xStsVariables += inEvent.getInputEventVariables(port)
		}
		return xStsVariables
	}
	
	def getInputEventVariables(Event event, Port port) {
		checkState(port.inputEvents.contains(event))
		val xStsVariables = newArrayList
		for (simplePort : port.allConnectedSimplePorts) {
			// One system port can be connected to multiple in-ports (if it is broadcast)
			val statechart = simplePort.containingComponent
			val instance = statechart.referencingComponentInstance
			val xStsVariableName = event.customizeInputName(simplePort, instance)
			xStsVariables += xSts.getVariable(xStsVariableName)
		}
		return xStsVariables
	}
	
	def getInputParameterVariables(ParameterDeclaration parameter, Port port) {
		checkState(port.inputEvents.map[it.parameterDeclarations].flatten.contains(parameter))
		val xStsVariables = newArrayList
		for (simplePort : port.allConnectedSimplePorts) {
			// One system port can be connected to multiple in-ports (if it is broadcast)
			val statechart = simplePort.containingComponent
			val instance = statechart.referencingComponentInstance
			val xStsVariableName = parameter.customizeInName(simplePort, instance)
			xStsVariables += xSts.getVariable(xStsVariableName)
		}
		return xStsVariables
	}
	
}