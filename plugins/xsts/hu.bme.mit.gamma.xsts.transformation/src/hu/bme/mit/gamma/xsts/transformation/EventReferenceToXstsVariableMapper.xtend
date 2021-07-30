package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventReference
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.List
import java.util.logging.Level
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class EventReferenceToXstsVariableMapper {
	
	protected final XSTS xSts
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	// Logger
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
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
	
	def checkInputEventVariable(Event event, Port port) {
		val inputEventVariable = event.getInputEventVariable(port)
		checkState(inputEventVariable !== null)
		return inputEventVariable
	}
	
	def getInputEventVariable(Event event, Port port) {
		val inputEventVariables = event.getInputEventVariables(port)
		checkState(inputEventVariables.size <= 1)
		return inputEventVariables.head
	}
	
	def getInputEventVariables(Event event, Port port) {
		checkState(port.inputEvents.contains(event))
		val xStsVariables = newArrayList
		for (simplePort : port.allBoundSimplePorts) {
			// One system port can be connected to multiple in-ports (if it is broadcast)
			val statechart = simplePort.containingComponent
			val instance = statechart.referencingComponentInstance
			val xStsVariableName = event.customizeInputName(simplePort, instance)
			val xStsVariable = xSts.getVariable(xStsVariableName)
			if (xStsVariable !== null) {
				xStsVariables += xStsVariable
			}
			else {
				logger.log(Level.INFO, "Not found XSTS variable for " + port.name + "." + event.name)
			}
		}
		return xStsVariables
	}
	
	def checkInputParameterVariable(ParameterDeclaration parameter, Port port) {
		val inputParameterVariable = parameter.getInputParameterVariable(port)
		checkState(inputParameterVariable !== null)
		return inputParameterVariable
	}
	
	def getInputParameterVariable(ParameterDeclaration parameter, Port port) {
		val inputParameterVariables = parameter.getInputParameterVariables(port)
		checkState(inputParameterVariables.size <= 1)
		return inputParameterVariables.head
	}
	
	def getInputParameterVariables(ParameterDeclaration parameter, Port port) {
		return parameter.getSeparatedInputParameterVariables(port).flatten.toList
	}
	
	def getSeparatedInputParameterVariables(ParameterDeclaration parameter, Port port) {
		checkState(port.inputEvents.map[it.parameterDeclarations].flatten.contains(parameter))
		val xStsVariables = <List<VariableDeclaration>>newArrayList
		for (simplePort : port.allBoundSimplePorts) {
			// One system port can be connected to multiple in-ports (if it is broadcast)
			val statechart = simplePort.containingComponent
			val instance = statechart.referencingComponentInstance
			val xStsVariableName = parameter.customizeInNames(simplePort, instance)
			val xStsVariable = xSts.getVariables(xStsVariableName)
			if (!xStsVariable.empty) {
				xStsVariables += xStsVariable
			}
			else {
				logger.log(Level.INFO, "Not found XSTS variable for " + port.name + "::" + parameter.name)
			}
		}
		return xStsVariables
	}
	
	def checkOutputEventVariable(Event event, Port port) {
		val outputEventVariable = event.getOutputEventVariables(port)
		checkState(outputEventVariable !== null)
		return outputEventVariable
	}
	
	def getOutputEventVariable(Event event, Port port) {
		val outputEventVariables = event.getOutputEventVariables(port)
		checkState(outputEventVariables.size <= 1)
		return outputEventVariables.head
	}
	
	def getOutputEventVariables(Event event, Port port) {
		checkState(port.outputEvents.contains(event))
		val xStsVariables = newArrayList
		for (simplePort : port.allBoundSimplePorts) {
			// Theoretically, only one port
			val statechart = simplePort.containingComponent
			val instance = statechart.referencingComponentInstance
			val xStsVariableName = event.customizeOutputName(simplePort, instance)
			val xStsVariable = xSts.getVariable(xStsVariableName)
			if (xStsVariable !== null) {
				xStsVariables += xStsVariable
			}
			else {
				logger.log(Level.INFO, "Not found XSTS variable for " + port.name + "." + event.name)
			}
		}
		return xStsVariables
	}
	
	def checkOutputParameterVariable(ParameterDeclaration parameter, Port port) {
		val outputParameterVariable = parameter.getOutputParameterVariable(port)
		checkState(outputParameterVariable !== null)
		return outputParameterVariable
	}
	
	def getOutputParameterVariable(ParameterDeclaration parameter, Port port) {
		val outputParameterVariables = parameter.getOutputParameterVariables(port)
		checkState(outputParameterVariables.size <= 1)
		return outputParameterVariables.head
	}
	
	def getOutputParameterVariables(ParameterDeclaration parameter, Port port) {
		checkState(port.outputEvents.map[it.parameterDeclarations].flatten.contains(parameter))
		val xStsVariables = newArrayList
		for (simplePort : port.allBoundSimplePorts) {
			// Theoretically, only one port
			val statechart = simplePort.containingComponent
			val instance = statechart.referencingComponentInstance
			val xStsVariableNames = parameter.customizeOutNames(simplePort, instance)
			val xStsVariable = xSts.getVariables(xStsVariableNames)
			if (!xStsVariable.nullOrEmpty) {
				xStsVariables += xStsVariable
			}
			else {
				logger.log(Level.INFO, "Not found XSTS variable for " + port.name + "::" + parameter.name)
			}
		}
		return xStsVariables
	}
	
}