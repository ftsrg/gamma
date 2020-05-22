package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.util.ExpressionUtil
import hu.bme.mit.gamma.statechart.model.composite.BroadcastChannel
import hu.bme.mit.gamma.statechart.model.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.model.composite.SimpleChannel
import hu.bme.mit.gamma.xsts.model.model.XSTS

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class EventConnector {
	// Auxiliary objects
	protected extension ExpressionUtil expressionUtil = new ExpressionUtil
	
	def void connectEventsThroughChannels(XSTS xSts, CompositeComponent component) {
		for (channel : component.channels) {
			val providedPort = channel.providedPort.port
			val requiredPorts = newArrayList
			if (channel instanceof SimpleChannel) {
				requiredPorts += channel.requiredPort.port
			}
			else if (channel instanceof BroadcastChannel) {
				requiredPorts += channel.requiredPorts.map[it.port]
			}
			// Connection
			val providedSimplePorts = providedPort.allConnectedSimplePorts
			checkState(providedSimplePorts.size == 1)
			val providedSimplePort = providedSimplePorts.head
			val providedStatechart = providedSimplePort.containingStatechart
			val providedInstance = providedStatechart.referencingComponentInstance
			for (requiredPort : requiredPorts) {
				for (requiredSimplePort : requiredPort.allConnectedSimplePorts) {
					val requiredStatechart = providedSimplePort.containingStatechart
					val requiredInstance = requiredStatechart.referencingComponentInstance
					// In events on required port
					for (event : requiredSimplePort.inputEvents) {
						val requiredInEventName = event.customizeInputName(requiredSimplePort, requiredInstance)
						val xStsInEventVariable = xSts.variableDeclarations.findFirst[it.name == requiredInEventName]
						val providedOutEventName = event.customizeOutputName(providedSimplePort, providedInstance)
						val xStsOutEventVariable = xSts.variableDeclarations.findFirst[it.name == providedOutEventName]
						xStsInEventVariable.change(xStsOutEventVariable, xSts)
						// In-parameters
						for (parameter : event.parameterDeclarations) {
							val requiredInParamaterName = parameter.customizeInName(requiredSimplePort, requiredInstance)
							val xStsInParameterVariable = xSts.variableDeclarations.findFirst[it.name == requiredInParamaterName]
							val providedOutParamaterName = parameter.customizeOutName(providedSimplePort, providedInstance)
							val xStsOutParameterVariable = xSts.variableDeclarations.findFirst[it.name == providedOutParamaterName]
							xStsInParameterVariable.change(xStsOutParameterVariable, xSts)
						}
					}
					// Out events on required port
					for (event : requiredSimplePort.outputEvents) {
						val requiredOutEventName = event.customizeOutputName(requiredSimplePort, requiredInstance)
						val xStsOutEventVariable = xSts.variableDeclarations.findFirst[it.name == requiredOutEventName]
						val providedInEventName = event.customizeInputName(providedSimplePort, providedInstance)
						val xStsInEventVariable = xSts.variableDeclarations.findFirst[it.name == providedInEventName]
						xStsOutEventVariable.change(xStsInEventVariable, xSts)
						// Out-parameters
						for (parameter : event.parameterDeclarations) {
							val requiredOutParamaterName = parameter.customizeOutName(requiredSimplePort, requiredInstance)
							val xStsOutParameterVariable = xSts.variableDeclarations.findFirst[it.name == requiredOutParamaterName]
							val providedInParamaterName = parameter.customizeInName(providedSimplePort, providedInstance)
							val xStsInParameterVariable = xSts.variableDeclarations.findFirst[it.name == providedInParamaterName]
							xStsOutParameterVariable.change(xStsInParameterVariable, xSts)
						}
					}
				}
			}
		}
	}
	
}