/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.FieldHierarchy
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.statechart.PseudoState
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.util.Triple
import java.util.List
import java.util.Map
import java.util.Set

import static com.google.common.base.Preconditions.checkNotNull
import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class Trace {

	final Map<Package, hu.bme.mit.gamma.statechart.lowlevel.model.Package> packageMappings = newHashMap
	final Map<TypeDeclaration, TypeDeclaration> typeDeclarationMappings = newHashMap
	// An event has to be connected to a port
	// Map is needed as a value because an INOUT is transformed to an IN and an OUT event
	final Map<Pair<Port, EventDeclaration>, Map<EventDirection, hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration>> eventDeclMappings = newHashMap
	final Map<Pair<Port, Event>, Map<EventDirection, hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration>> eventMappings = newHashMap
	//
	final Map<Component, hu.bme.mit.gamma.statechart.lowlevel.model.Component> componentMappings = newHashMap
	// Event parameters
	final Map<Triple<Port, Event, Pair<ParameterDeclaration, FieldHierarchy>>, VariableDeclaration> inParDeclMappings = newHashMap
	final Map<Triple<Port, Event, Pair<ParameterDeclaration, FieldHierarchy>>, VariableDeclaration> outParDeclMappings = newHashMap
	// For parameters
	final Map<ParameterDeclaration, ParameterDeclaration> forParDeclMappings = newHashMap
	// Simple and complex variable mappings
	final Map<Pair<ValueDeclaration, FieldHierarchy>, VariableDeclaration> valDeclMappings = newHashMap
	final Map<TimeoutDeclaration, VariableDeclaration> timeoutDeclMappings = newHashMap
	
	final Map<Region, hu.bme.mit.gamma.statechart.lowlevel.model.Region> regionMappings = newHashMap
	final Map<State, hu.bme.mit.gamma.statechart.lowlevel.model.State> stateMappings = newHashMap
	final Map<PseudoState, hu.bme.mit.gamma.statechart.lowlevel.model.PseudoState> pseudoStateMappings = newHashMap
	final Map<Transition, hu.bme.mit.gamma.statechart.lowlevel.model.Transition> transitionMappings = newHashMap
	// For timeout declaration optimization
	final Map<Region, VariableDeclaration> regionTimeoutMappings = newHashMap
	// Else guarded transitions
	final Set<Transition> elseGuardedTransitions = newHashSet
	// Function return variables
	final Map<FunctionAccessExpression, List<VariableDeclaration>> returnVariableMappings = newHashMap
	
	// Package
	def put(Package gammaPackage, hu.bme.mit.gamma.statechart.lowlevel.model.Package lowlevelPackage) {
		checkNotNull(gammaPackage)
		checkNotNull(lowlevelPackage)
		packageMappings.put(gammaPackage, lowlevelPackage)
	}

	def isMapped(Package gammaPackage) {
		checkNotNull(gammaPackage)
		packageMappings.containsKey(gammaPackage)
	}

	def get(Package gammaPackage) {
		checkNotNull(gammaPackage)
		packageMappings.get(gammaPackage)
	}
	
	def getLowlevelPackage() {
		val packages = packageMappings.values
		checkState(packages.size == 1)
		return packages.head
	}
	
	// Type declarations
	def put(TypeDeclaration gammaType, TypeDeclaration lowlevelType) {
		checkNotNull(gammaType)
		checkNotNull(lowlevelType)
		typeDeclarationMappings.put(gammaType, lowlevelType)
	}

	def isMapped(TypeDeclaration gammaType) {
		checkNotNull(gammaType)
		typeDeclarationMappings.containsKey(gammaType)
	}

	def get(TypeDeclaration gammaType) {
		checkNotNull(gammaType)
		typeDeclarationMappings.get(gammaType)
	}
	
	// EventDeclaration
	def put(Port gammaPort, EventDeclaration gammaEventDecl,
			hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration lowlevelEventDecl) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEventDecl)
		checkNotNull(lowlevelEventDecl)
		if (isMapped(gammaPort, gammaEventDecl)) {
			val map = get(gammaPort, gammaEventDecl)
			checkState(map.size == 1)
			map.put(lowlevelEventDecl.direction, lowlevelEventDecl)
		}
		else {
			eventDeclMappings.put(gammaPort -> gammaEventDecl,
				newHashMap(lowlevelEventDecl.direction -> lowlevelEventDecl))
		}
	}

	def isMapped(Port gammaPort, EventDeclaration gammaEventDecl) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEventDecl)
		for (entry : eventDeclMappings.keySet) {
			if (entry.key == gammaPort && entry.value == gammaEventDecl) {
				return true
			}
		}
		return false
	}

	def get(Port gammaPort, EventDeclaration gammaEventDecl) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEventDecl)
		for (entry : eventDeclMappings.keySet) {
			if (entry.key == gammaPort && entry.value == gammaEventDecl) {
				return eventDeclMappings.get(entry)
			}
		}
		throw new IllegalArgumentException("No entry for such parameters: " + gammaPort + " " + gammaEventDecl)
	}
	
	def get(Port gammaPort, EventDeclaration gammaEventDecl, EventDirection direction) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEventDecl)
		val possibleEvent = get(gammaPort, gammaEventDecl).get(direction)
		if (possibleEvent === null) {
			throw new IllegalArgumentException(
				"No entry for such parameters: " + gammaPort + " " + gammaEventDecl + " " + direction)
		}
		return possibleEvent
	}
	
	// Event
	def put(Port gammaPort, Event gammaEvent,
			hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration lowlevelEvent) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEvent)
		checkNotNull(lowlevelEvent)
		if (isMapped(gammaPort, gammaEvent)) {
			val map = get(gammaPort, gammaEvent)
			checkState(map.size == 1, "The size of the map is not 1: " + map)
			map.put(lowlevelEvent.direction, lowlevelEvent)
		}
		else {
			eventMappings.put(gammaPort -> gammaEvent,
				newHashMap(lowlevelEvent.direction -> lowlevelEvent))
		}
	}

	def isMapped(Port gammaPort, Event gammaEvent) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEvent)
		for (entry : eventMappings.keySet) {
			if (entry.key == gammaPort && entry.value == gammaEvent) {
				return true
			}
		}
		return false
	}

	def get(Port gammaPort, Event gammaEvent) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEvent)
		for (entry : eventMappings.keySet) {
			if (entry.key == gammaPort && entry.value == gammaEvent) {
				return eventMappings.get(entry) // Not unmodifiable view due to get method
			}
		}
		throw new IllegalArgumentException("No entry for such parameters: " + gammaPort + " " + gammaEvent)
	}
	
	def get(Port gammaPort, Event gammaEvent, EventDirection direction) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEvent)
		val possibleEvent = get(gammaPort, gammaEvent).get(direction)
		if (possibleEvent === null) {
			throw new IllegalArgumentException(
				"No entry for such parameters: " + gammaPort + " " + gammaEvent + " " + direction)
		}
		return possibleEvent
	}
	
	def getAllLowlevelEvents() {
		eventMappings.values
	}
	
	def getAllLowlevelEvents(EventDirection direction) {
		val lowlevelList = newLinkedList
		for (lowlevelEventMap : allLowlevelEvents) {
			val lowlevelEvent =  lowlevelEventMap.get(direction) // Map: can be null
			if (lowlevelEvent !== null) {
				lowlevelList += lowlevelEvent
			}
		}
		return lowlevelList
	}
	
	def getAllLowlevelEvents(Port port) {
		val events = newLinkedList
		for (event : port.allEventDeclarations) {
			events += get(port, event)
		}
		return events
	}
	
	def getAllLowlevelEvents(Port port, EventDirection direction) {
		return port.allLowlevelEvents.map[it.get(direction)].filterNull.toList
	}
	
	// Component
	def put(Component gammaComponent, hu.bme.mit.gamma.statechart.lowlevel.model.Component lowlevelComponent) {
		checkNotNull(gammaComponent)
		checkNotNull(lowlevelComponent)
		componentMappings.put(gammaComponent, lowlevelComponent)
	}

	def isMapped(Component gammaComponent) {
		checkNotNull(gammaComponent)
		componentMappings.containsKey(gammaComponent)
	}

	def get(Component gammaComponent) {
		checkNotNull(gammaComponent)
		componentMappings.get(gammaComponent)
	}
	
	// Value declarations with fields
	
	// Auxiliary
	private def putParameter(
			Map<Triple<Port, Event, Pair<ParameterDeclaration, FieldHierarchy>>, VariableDeclaration> mappings,
			Port port, Event event, Pair<ParameterDeclaration, FieldHierarchy> recordField,
			VariableDeclaration lowLevelVariable) {
		checkNotNull(port)
		checkNotNull(event)
		checkNotNull(recordField.key)
		checkNotNull(recordField.value)
		checkNotNull(lowLevelVariable)
		mappings.put(new Triple(port, event, recordField), lowLevelVariable)
	}
	
	private def getParameter(
			Map<Triple<Port, Event, Pair<ParameterDeclaration, FieldHierarchy>>, VariableDeclaration> mappings,
			Port port, Event event, Pair<ParameterDeclaration, FieldHierarchy> recordField) {
		val key = recordField.key
		val value = recordField.value
		checkNotNull(port)
		checkNotNull(event)
		checkNotNull(key)
		checkNotNull(value)
		for (entry : mappings.entrySet) {
			val triple = entry.key
			if (triple.first.equals(port) && triple.second.equals(event) &&
					triple.third.key.equals(key) && triple.third.value.equals(value)) {
				return entry.value
			}
		}
		throw new IllegalArgumentException("Not found: " + recordField)
	}
	
	private def getAllParameters(
			Map<Triple<Port, Event, Pair<ParameterDeclaration, FieldHierarchy>>, VariableDeclaration> mappings,
			Port port, Event event, Pair<ParameterDeclaration, FieldHierarchy> recordField) {
		val lowlevelVariables = newArrayList
		val parameter = recordField.key
		val fieldHierarchy = recordField.value
		val extensions = fieldHierarchy.getExtensions(parameter)
		for (^extension : extensions) {
			lowlevelVariables += mappings.getParameter(port, event, parameter -> ^extension)
		}
		return lowlevelVariables
	}
	
	// In-event parameters	
	def putInParameter(Port port, Event event, Pair<ParameterDeclaration, FieldHierarchy> recordField,
			VariableDeclaration lowLevelVariable) {
		inParDeclMappings.putParameter(port, event, recordField, lowLevelVariable)
	} 

	def getInParameter(Port port, Event event, Pair<ParameterDeclaration, FieldHierarchy> recordField) {
		return inParDeclMappings.getParameter(port, event, recordField)
	}
	
	def getAllInParameters(Port port, Event event, Pair<ParameterDeclaration, FieldHierarchy> recordField) {
		return inParDeclMappings.getAllParameters(port, event, recordField)
	}
	
	// Out-event parameters
	def putOutParameter(Port port, Event event, Pair<ParameterDeclaration, FieldHierarchy> recordField,
			VariableDeclaration lowLevelVariable) {
		outParDeclMappings.putParameter(port, event, recordField, lowLevelVariable)
	}

	def getOutParameter(Port port, Event event, Pair<ParameterDeclaration, FieldHierarchy> recordField) {
		return outParDeclMappings.getParameter(port, event, recordField)
	}
	
	def getAllOutParameters(Port port, Event event, Pair<ParameterDeclaration, FieldHierarchy> recordField) {
		return outParDeclMappings.getAllParameters(port, event, recordField)
	}
	
	// For parameters
	def put(ParameterDeclaration gammaParameter, ParameterDeclaration lowLevelParameter) {
		checkNotNull(gammaParameter)
		checkNotNull(lowLevelParameter)
		forParDeclMappings.put(gammaParameter, lowLevelParameter)
	}
	
	def isForStatementParameterMapped(ValueDeclaration gammaParameter) {
		checkNotNull(gammaParameter)
		return forParDeclMappings.containsKey(gammaParameter)
	} 
	
	def get(ParameterDeclaration gammaParameter) {
		checkNotNull(gammaParameter)
		val lowlevelParameter = forParDeclMappings.get(gammaParameter)
		checkNotNull(lowlevelParameter)
		return lowlevelParameter
	} 
	
	// Values
	def put(Pair<ValueDeclaration, FieldHierarchy> recordField, VariableDeclaration lowLevelVariable) {
		checkNotNull(recordField)
		checkNotNull(recordField.key)
		checkNotNull(recordField.value)
		checkNotNull(lowLevelVariable)
		valDeclMappings.put(recordField, lowLevelVariable)
	} 

	def isMapped(Pair<ValueDeclaration, FieldHierarchy> recordField) {
		val key = recordField.key
		val value = recordField.value
		checkNotNull(key)
		checkNotNull(value)
		for (record : valDeclMappings.keySet) {
			if (record.key.equals(key) && record.value.equals(value)) {
				return true
			}
		}
		return false
	}
	
	def get(Pair<ValueDeclaration, FieldHierarchy> recordField) {
		// Returns only a single value, the field hierarchy must match concretely
		val key = recordField.key
		val value = recordField.value
		checkNotNull(key)
		checkNotNull(value)
		for (record : valDeclMappings.keySet) {
			if (record.key.equals(key) && record.value.equals(value)) {
				return valDeclMappings.get(record)
			}
		}
		throw new IllegalArgumentException("Not found: " + recordField)
	}
	
	def getAll(Pair<ValueDeclaration, FieldHierarchy> recordField) {
		// Returns potentially multiple values, that can be retrieved by extending the given field hierarchy
		val lowlevelVariables = newArrayList
		val value = recordField.key
		val fieldHierarchy = recordField.value
		val extensions = fieldHierarchy.getExtensions(value)
		for (^extension : extensions) {
			lowlevelVariables += get(value -> ^extension)
		}
		return lowlevelVariables
	}
	
	def getAll(ValueDeclaration valueDeclaration) {
		// Returns potentially multiple values, that can be retrieved by extending the given field hierarchy
		return getAll(valueDeclaration -> new FieldHierarchy)
	}
	
	// Timeout declaration
	def put(TimeoutDeclaration gammaTimeout, VariableDeclaration lowlevelTimeout) {
		checkNotNull(gammaTimeout)
		checkNotNull(lowlevelTimeout)
		timeoutDeclMappings.put(gammaTimeout, lowlevelTimeout)
	}

	def isMapped(TimeoutDeclaration gammaTimeout) {
		checkNotNull(gammaTimeout)
		timeoutDeclMappings.containsKey(gammaTimeout)
	}

	def get(TimeoutDeclaration gammaTimeout) {
		checkNotNull(gammaTimeout)
		timeoutDeclMappings.get(gammaTimeout)
	}
	
	// Region
	def put(Region gammaRegion, hu.bme.mit.gamma.statechart.lowlevel.model.Region lowlevelRegion) {
		checkNotNull(gammaRegion)
		checkNotNull(lowlevelRegion)
		regionMappings.put(gammaRegion, lowlevelRegion)
	}

	def isMapped(Region gammaRegion) {
		checkNotNull(gammaRegion)
		regionMappings.containsKey(gammaRegion)
	}

	def get(Region gammaRegion) {
		checkNotNull(gammaRegion)
		regionMappings.get(gammaRegion)
	}
	
	// State
	def put(State gammaState, hu.bme.mit.gamma.statechart.lowlevel.model.State lowlevelState) {
		checkNotNull(gammaState)
		checkNotNull(lowlevelState)
		stateMappings.put(gammaState, lowlevelState)
	}

	def isMapped(State gammaState) {
		checkNotNull(gammaState)
		stateMappings.containsKey(gammaState)
	}

	def get(State gammaState) {
		checkNotNull(gammaState)
		stateMappings.get(gammaState)
	}
	
	// Pseudo states
	def put(PseudoState gammaPseudoState,
			hu.bme.mit.gamma.statechart.lowlevel.model.PseudoState lowlevelPseudoState) {
		checkNotNull(gammaPseudoState)
		checkNotNull(lowlevelPseudoState)
		pseudoStateMappings.put(gammaPseudoState, lowlevelPseudoState)
	}

	def isMapped(PseudoState gammaPseudoState) {
		checkNotNull(gammaPseudoState)
		pseudoStateMappings.containsKey(gammaPseudoState)
	}

	def get(PseudoState gammaPseudoState) {
		checkNotNull(gammaPseudoState)
		pseudoStateMappings.get(gammaPseudoState)
	}
	
	// Regular transition
	def put(Transition gammaTransition,
			hu.bme.mit.gamma.statechart.lowlevel.model.Transition lowlevelTransition) {
		checkNotNull(gammaTransition)
		checkNotNull(lowlevelTransition)
		transitionMappings.put(gammaTransition, lowlevelTransition)
	}

	def isMapped(Transition gammaTransition) {
		checkNotNull(gammaTransition)
		transitionMappings.containsKey(gammaTransition)
	}

	def get(Transition gammaTransition) {
		checkNotNull(gammaTransition)
		transitionMappings.get(gammaTransition)
	}
	
	// TimeoutDeclaration optimization
	def put(Region gammaRegion, VariableDeclaration lowlevelTimeout) {
		checkNotNull(gammaRegion)
		checkNotNull(lowlevelTimeout)
		regionTimeoutMappings.put(gammaRegion, lowlevelTimeout)
	}

	def doesRegionHaveOptimizedTimeout(Region gammaRegion) {
		checkNotNull(gammaRegion)
		regionTimeoutMappings.containsKey(gammaRegion)
	}

	def getTimeout(Region gammaRegion) {
		checkNotNull(gammaRegion)
		regionTimeoutMappings.get(gammaRegion)
	}
	
	// Else guarded transitions
	def designateElseGuardedTransition(Transition gammaTransition) {
		checkNotNull(gammaTransition)
		elseGuardedTransitions += gammaTransition
	}
	
	def getElseGuardedTransition() {
		return elseGuardedTransitions
	}

	// Function return variable
	def put(FunctionAccessExpression functionAccessExpression, List<VariableDeclaration> returnVariable) {
		checkNotNull(functionAccessExpression)
		checkNotNull(returnVariable)
		returnVariableMappings.put(functionAccessExpression, returnVariable)
	}

	def isMapped(FunctionAccessExpression functionAccessExpression) {
		checkNotNull(functionAccessExpression)
		returnVariableMappings.containsKey(functionAccessExpression)
	}

	def get(FunctionAccessExpression functionAccessExpression) {
		checkNotNull(functionAccessExpression)
		returnVariableMappings.get(functionAccessExpression)
	}
	
}
