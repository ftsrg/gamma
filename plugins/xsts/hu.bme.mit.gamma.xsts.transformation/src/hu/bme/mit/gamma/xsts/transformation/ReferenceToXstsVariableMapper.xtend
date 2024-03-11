/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventReference
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.List
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class ReferenceToXstsVariableMapper {
	
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
	
	def hasInputEventVariable(Event event, Port port) {
		return !event.getInputEventVariables(port).isEmpty
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
				logger.info("Not found XSTS variable for " + port.name + "." + event.name)
			}
		}
		return xStsVariables
	}
	
	def getInputEventVariables(Port port) {
		val xStsVariables = newArrayList
		for (inputEvent : port.inputEvents) {
			xStsVariables += inputEvent.getInputEventVariables(port)
		}
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
		return parameter.getInputParameterVariablesByPorts(port)
			.flatten.toList
	}
	
	def getInputParameterVariablesByPorts(ParameterDeclaration parameter, Port port) {
		checkState(port.inputEvents.map[it.parameterDeclarations].flatten.contains(parameter))
		val xStsVariableLists = <List<VariableDeclaration>>newArrayList
		for (simplePort : port.allBoundSimplePorts) {
			// One system port can be connected to multiple in-ports (if it is broadcast)
			val statechart = simplePort.containingComponent
			val instance = statechart.referencingComponentInstance
			val xStsVariableNames = parameter.customizeInNames(simplePort, instance)
			val xStsVariables = xSts.getVariables(xStsVariableNames).filterNull.toList
			if (!xStsVariables.empty) {
				xStsVariableLists += xStsVariables
			}
			else {
				logger.info("Not found XSTS variable for " + port.name + "::" + parameter.name)
			}
		}
		return xStsVariableLists
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
		val allBoundSimplePorts = port.allBoundSimplePorts
		checkState(allBoundSimplePorts.size <= 1)
		val simplePort = allBoundSimplePorts.head
		if (simplePort !== null) {
			val statechart = simplePort.containingComponent
			val instance = statechart.referencingComponentInstance
			val xStsVariableName = event.customizeOutputName(simplePort, instance)
			val xStsVariable = xSts.getVariable(xStsVariableName)
			if (xStsVariable !== null) {
				xStsVariables += xStsVariable
			}
			else {
				logger.info("Not found XSTS variable for " + port.name + "." + event.name)
			}
		}
		return xStsVariables
	}
	
	def getOutputEventVariables(Port port) {
		val xStsVariables = newArrayList
		for (outputEvent : port.outputEvents) {
			xStsVariables += outputEvent.getOutputEventVariables(port)
		}
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
		val allBoundSimplePorts = port.allBoundSimplePorts
		checkState(allBoundSimplePorts.size <= 1)
		val simplePort = allBoundSimplePorts.head
		if (simplePort !== null) {
			// Theoretically, only one port
			val statechart = simplePort.containingComponent
			val instance = statechart.referencingComponentInstance
			val xStsVariableNames = parameter.customizeOutNames(simplePort, instance)
			val xStsVariable = xSts.getVariables(xStsVariableNames)
			if (!xStsVariable.nullOrEmpty) {
				xStsVariables += xStsVariable
			}
			else {
				logger.info("Not found XSTS variable for " + port.name + "::" + parameter.name)
			}
		}
		return xStsVariables
	}
	
	def checkVariableVariable(VariableDeclaration variable) {
		val potentialVariable = variable.variableVariable
		checkState(potentialVariable !== null)
		return potentialVariable
	}
	
	def getVariableVariable(VariableDeclaration variable) {
		val variables = variable.variableVariables
		checkState(variables.size <= 1)
		return variables.head
	}
	
	def getVariableVariables(VariableDeclaration variable) {
		val instance = variable.containingComponentInstance
		val xStsVariableNames = variable.customizeNames(instance)
		val xStsVariables = xSts.getVariables(xStsVariableNames)
		return xStsVariables
	}
	
	def getRegionVariable(Region region) {
		val instance = region.containingComponentInstance
		val xStsVariableName = region.customizeName(instance)
		val xStsVariable = xSts.getVariable(xStsVariableName)
		return xStsVariable
	}
	
	def getStateLiteral(State state) {
		val parentRegion = state.parentRegion
		val xStsRegionVariable = parentRegion.regionVariable
		val type = xStsRegionVariable.type
		
		if (type instanceof TypeReference) {
			val typeDeclaration = type.reference
			val typeDefinition = typeDeclaration.type
			if (typeDefinition instanceof EnumerationTypeDefinition) {
				val literalName = state.customizeName
				val literal = typeDefinition.literals.findFirst[it.name == literalName]
				return literal
			}
		}
		throw new IllegalArgumentException("Not known state literal: " + state)
	}
	
	def getEnumLiteral(EnumerationLiteralDefinition literal) {
		val enumType = literal.typeDeclaration
		val enumTypeName = enumType.customizeTypeName
		
		val typeDeclaration = xSts.typeDeclarations.findFirst[it.name == enumTypeName]
		if (typeDeclaration !== null) {
			val enumName = literal.customizeEnumLiteralName
			val enumDefinition = typeDeclaration.typeDefinition as EnumerationTypeDefinition
			val enumLiteral = enumDefinition.literals.findFirst[it.name == enumName]
			
			if (enumLiteral !== null) {
				return enumLiteral
			}
		}
		
		throw new IllegalArgumentException("Not known enum literal: " + literal)
	}
	
}