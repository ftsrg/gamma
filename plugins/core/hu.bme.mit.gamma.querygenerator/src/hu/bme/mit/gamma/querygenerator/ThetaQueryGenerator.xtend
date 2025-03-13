/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.RecordTypeDefinition
import hu.bme.mit.gamma.expression.model.TypeDefinition
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.composite.MessageQueue
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.xsts.transformation.util.Namings
import java.util.List

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.Namings.*

class ThetaQueryGenerator extends AbstractQueryGenerator {
	//
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	//
	new(Component component) {
		super(component)
	}
	
	override parseRegularQuery(String text, TemporalOperator operator) {
		switch (operator) {
			case MUST_ALWAYS: {
				return operator.operator + " " + text.parseIdentifiers
			}
			case MIGHT_EVENTUALLY: {
				return operator.operator + " " + text.parseIdentifiers.wrap
			}
			default: {
				throw new IllegalArgumentException("Not supported temporal operator: " + operator.toString)
			}
		}
	}
	
	override parseLeadsToQuery(String first, String second) {
		throw new UnsupportedOperationException("TODO: auto-generated method stub")
	}
	
	//
	
	override protected getTargetStateName(State state, Region parentRegion, SynchronousComponentInstance instance) {
		return '''«state.getSingleTargetStateName(parentRegion, instance)»«FOR parent : state.ancestors BEFORE " && " SEPARATOR " && "»«parent.getSingleTargetStateName(parent.parentRegion, instance)»«ENDFOR»'''
	}
	
	def protected getSingleTargetStateName(State state, Region parentRegion, SynchronousComponentInstance instance) {
		return '''«parentRegion.customizeName(instance)» == «parentRegion.customizeRegionTypeName».«state.customizeName»'''
	}
	
	override protected getTargetVariableNames(VariableDeclaration variable, SynchronousComponentInstance instance) {
		return variable.customizeNames(instance)
	}
	
	override protected getTargetOutEventName(Event event, Port port, SynchronousComponentInstance instance) {
		return event.customizeOutputName(port, instance)
	}
	
	override protected getTargetOutEventParameterNames(Event event, Port port, ParameterDeclaration parameter, SynchronousComponentInstance instance) {
		return parameter.customizeOutNames(port, instance)
	}
	
	def protected getTargetInEventName(Event event, Port port, SynchronousComponentInstance instance) {
		return event.customizeInputName(port, instance)
	}
	
	def protected getTargetInEventParameterName(Event event, Port port, ParameterDeclaration parameter, SynchronousComponentInstance instance) {
		return parameter.customizeInNames(port, instance)
	}
	
	def protected getTargetMasterQueueName(MessageQueue queue, AsynchronousComponentInstance instance) {
		return queue.customizeMasterQueueName(instance)
	}
	
	def protected getTargetSlaveQueueName(Event event, Port port, ParameterDeclaration parameter, AsynchronousComponentInstance instance) {
		return parameter.customizeSlaveQueueName(port, instance)
	}
	
	// Auxiliary methods for back-annotation
	
	// Checkers
	
	def isSourceState(String targetStateName) {
		try {
			targetStateName.getSourceState
			return true
		} catch (IllegalArgumentException e) {
			return false
		}
	}
	
	def isSourceVariable(String targetVariableName) {
		try {
			targetVariableName.getSourceVariable
			return true
		} catch (IllegalArgumentException e) {
			return false
		}
	}
	
	def isDelay(String targetVariableName) {
		return targetVariableName == Namings.delayVariableName
	}
	
	// Record
	def isSourceRecordVariable(String targetVariableName) {
		try {
			val variable = targetVariableName.getSourceVariable
			val type = variable.key.typeDefinition
			return type instanceof RecordTypeDefinition
		} catch (IllegalArgumentException e) {
			return false
		}
	}
	
	def isSourceOutEvent(String targetOutEventName) {
		try {
			targetOutEventName.getSourceOutEvent
			return true
		} catch (IllegalArgumentException e) {
			return false
		}
	}
	
	def isSourceOutEventParameter(String targetOutEventParameterName) {
		try {
			targetOutEventParameterName.getSourceOutEventParameter
			return true
		} catch (IllegalArgumentException e) {
			return false
		}
	}
	
	def isSourceRecordOutEventParameter(String targetOutEventParameterName) {
		try {
			val array = targetOutEventParameterName.getSourceOutEventParameter
			val parameter = array.get(2) as ValueDeclaration
			val type = parameter.typeDefinition
			return type instanceof RecordTypeDefinition
		} catch (IllegalArgumentException e) {
			return false
		}
	}
	
	def isSynchronousSourceInEvent(String targetInEventName) {
		try {
			if (!component.synchronous) {
				return false
			}
			targetInEventName.getSynchronousSourceInEvent
			return true
		} catch (IllegalArgumentException e) {
			return false
		}
	}
	
	def isSynchronousSourceInEventParameter(String targetInEventParameterName) {
		try {
			if (!component.synchronous) {
				return false
			}
			targetInEventParameterName.getSynchronousSourceInEventParameter
			return true
		} catch (IllegalArgumentException e) {
			return false
		}
	}
	
	def isAsynchronousSourceMessageQueue(String targetMasterQueueName) {
		try {
			if (!component.asynchronous) {
				return false
			}
			targetMasterQueueName.getAsynchronousSourceMessageQueue
			return true
		} catch (IllegalArgumentException e) {
			return false
		}
	}
	
	def isAsynchronousSourceInEventParameter(String targetSlaveQueueName) {
		try {
			if (!component.asynchronous) {
				return false
			}
			targetSlaveQueueName.getAsynchronousSourceInEventParameter
			return true
		} catch (IllegalArgumentException e) {
			return false
		}
	}
	
	// Getters
	
	def getSourceState(String targetStateName) {
		for (match : instanceStates) {
			val name = getSingleTargetStateName(match.state, match.parentRegion, match.instance)
			if (name == targetStateName) {
				return match.state -> match.instance
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	def getSourceVariable(String targetVariableName) {
		for (match : instanceVariables) {
			val names = getTargetVariableNames(match.variable, match.instance)
			if (names.contains(targetVariableName)) {
				return new Pair(match.variable, match.instance)
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	// Record
	def getSourceVariableFieldHierarchy(String targetVariableName) {
		for (match : instanceVariables) {
			val variable = match.variable
			val type = variable.typeDefinition
			val names = getTargetVariableNames(match.variable, match.instance)
			if (names.contains(targetVariableName)) {
				return type.getSourceFieldHierarchy(names, targetVariableName)
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	def getSourceOutEvent(String targetOutEventName) {
		if (component.asynchronous) {
			return targetOutEventName.asynchronousSourceOutEvent
		}
		else if (component.synchronous) {
			return targetOutEventName.synchronousSourceOutEvent
		}
		throw new IllegalArgumentException("Not known type: " + component)
	}
	
	def getAsynchronousSourceOutEvent(String targetOutEventName) {
		for (match : asynchronousSystemOutEvents) {
			val name = getTargetOutEventName(match.first, match.second, match.third)
			if (name == targetOutEventName) {
				return #[match.first, match.second, match.third]
			}
		}
		throw new IllegalArgumentException("Not known id: " + targetOutEventName)
	}
	
	def getSynchronousSourceOutEvent(String targetOutEventName) {
		for (match : synchronousSystemOutEvents) {
			val name = getTargetOutEventName(match.event, match.port, match.instance)
			if (name == targetOutEventName) {
				return #[match.event, match.port, match.instance]
			}
		}
		
		throw new IllegalArgumentException("Not known id: " + targetOutEventName)
	}
	
	def getSourceOutEventParameter(String targetOutEventParameterName) {
		if (component.asynchronous) {
			return targetOutEventParameterName.asynchronousSourceOutEventParameter
		}
		else if (component.synchronous) {
			return targetOutEventParameterName.synchronousSourceOutEventParameter
		}
		throw new IllegalArgumentException("Not known type: " + component)
	}
	
	def getSynchronousSourceOutEventParameter(String targetOutEventParameterName) {
		for (match : synchronousSystemOutEvents) {
			val event = match.event
			val port = match.port
			val instance = match.instance
			for (parameter : event.parameterDeclarations) {
				val names = getTargetOutEventParameterNames(event, port, parameter, instance)
				if (names.contains(targetOutEventParameterName)) {
					return #[event, port, parameter, instance]
				}
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	def getAsynchronousSourceOutEventParameter(String targetOutEventParameterName) {
		for (match : asynchronousSystemOutEvents) {
			val event = match.first
			val port = match.second
			val instance = match.third
			for (parameter : event.parameterDeclarations) {
				val names = getTargetOutEventParameterNames(event, port, parameter, instance)
				if (names.contains(targetOutEventParameterName)) {
					return #[event, port, parameter, instance]
				}
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	// Record
	def getSourceOutEventParameterFieldHierarchy(String targetOutEventParameterName) {
		for (match : synchronousSystemOutEvents) {
			val event = match.event
			for (parameter : event.parameterDeclarations) {
				val type = parameter.typeDefinition
				val names = getTargetOutEventParameterNames(event, match.port, parameter, match.instance)
				if (names.contains(targetOutEventParameterName)) {
					return type.getSourceFieldHierarchy(names, targetOutEventParameterName)
				}
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	def getSynchronousSourceInEvent(String targetInEventName) {
		for (match : synchronousSystemInEvents) {
			val name = getTargetInEventName(match.event, match.port, match.instance)
			if (name.equals(targetInEventName)) {
				return #[match.event, match.port, match.instance]
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	def getSynchronousSourceInEventParameter(String targetInEventParameterName) {
		for (match : synchronousSystemInEvents) {
			val event = match.event
			for (parameter : event.parameterDeclarations) {
				val names = getTargetInEventParameterName(event, match.port, parameter, match.instance)
				if (names.contains(targetInEventParameterName)) {
					return #[event, match.port, parameter, match.instance]
				}
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	// Record
	def getSynchronousSourceInEventParameterFieldHierarchy(String targetInEventParameterName) {
		for (match : synchronousSystemInEvents) {
			val event = match.event
			for (parameter : event.parameterDeclarations) {
				val type = parameter.typeDefinition
				val names = getTargetInEventParameterName(event, match.port, parameter, match.instance)
				if (names.contains(targetInEventParameterName)) {
					return type.getSourceFieldHierarchy(names, targetInEventParameterName)
				}
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	def getAsynchronousSourceMessageQueue(String targetMasterQueueName) {
		for (pair : getAynchronousMessageQueues) {
			val instance = pair.key
			val queue = pair.value
			val name = getTargetMasterQueueName(queue, instance)
			if (name.equals(targetMasterQueueName)) {
				return queue
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	def getAsynchronousSourceInEventParameter(String targetSlaveQueueName) {
		for (portEvent : asynchronousSystemInEvents) {
			val port = portEvent.first
			val event = portEvent.second
			val instance = portEvent.third
			for (parameter : event.parameterDeclarations) {
				val names = getTargetSlaveQueueName(event, port, parameter, instance)
				if (names.contains(targetSlaveQueueName)) {
					return #[event, port, parameter, instance]
				}
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	// Record
	def getAsynchronousSourceInEventParameterFieldHierarchy(String targetSlaveQueueName) {
		for (portEvent : asynchronousSystemInEvents) {
			val port = portEvent.first
			val event = portEvent.second
			val instance = portEvent.third
			for (parameter : event.parameterDeclarations) {
				val type = parameter.typeDefinition
				val names = getTargetSlaveQueueName(event, port, parameter, instance)
				if (names.contains(targetSlaveQueueName)) {
					return type.getSourceFieldHierarchy(names, targetSlaveQueueName)
				}
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	// Record specific auxiliary method
	
	protected def getSourceFieldHierarchy(TypeDefinition type, List<String> names, String targetName) {
		val fields = type.fieldHierarchies
		for (var i = 0; i < names.size; i++) {
			val name = names.get(i)
			if (name == targetName) {
				return fields.get(i) // If ith name is equal, it is the ith field
				// See LowlevelNamings.getNames
			}
		}
		throw new IllegalArgumentException("Not known id")
	}
	
	// Temporary utility methods as long as single AAs are supported
	
    private def isSynchronous(Component component) {
    	return component.adapter || // Single adapters are handled synchronous components during back-annotation
    		StatechartModelDerivedFeatures.isSynchronous(component)
    }
    
    private def isAsynchronous(Component component) {
    	return !component.synchronous
    }
    
    //
    
	protected def getBracketLessId(String id) {
		return (id.contains("[")) ? id.substring(0, id.indexOf("[")) : id
	}
	
}