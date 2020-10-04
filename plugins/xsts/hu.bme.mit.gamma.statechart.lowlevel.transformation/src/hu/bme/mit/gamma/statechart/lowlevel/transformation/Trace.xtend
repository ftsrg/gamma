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

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.TypeDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.PseudoState
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventDeclaration
import java.util.HashMap
import java.util.Map

import static com.google.common.base.Preconditions.checkNotNull
import static com.google.common.base.Preconditions.checkState
import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.FieldDeclaration
import java.util.List

package class Trace {

	final Map<Package, hu.bme.mit.gamma.statechart.lowlevel.model.Package> packageMappings = new HashMap<Package, hu.bme.mit.gamma.statechart.lowlevel.model.Package>
	final Map<TypeDeclaration, TypeDeclaration> typeDeclarationMappings = new HashMap<TypeDeclaration, TypeDeclaration>
	// An event has to be connected to a port
	// Map is needed as a value because an INOUT is transformed to an IN and an OUT event
	final Map<Pair<Port, EventDeclaration>, Map<EventDirection, hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration>> eventDeclMappings = new HashMap<Pair<Port, EventDeclaration>, Map<EventDirection, hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration>>
	final Map<Pair<Port, Event>, Map<EventDirection, hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration>> eventMappings = new HashMap<Pair<Port, Event>, Map<EventDirection, hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration>>
	final Map<Triple<Port, Event, ParameterDeclaration>, Map<EventDirection, VariableDeclaration>> paramMappings = new HashMap<Triple<Port, Event, ParameterDeclaration>, Map<EventDirection, VariableDeclaration>>
	//
	final Map<Component, hu.bme.mit.gamma.statechart.lowlevel.model.Component> componentMappings = new HashMap<Component, hu.bme.mit.gamma.statechart.lowlevel.model.Component>
	final Map<TimeoutDeclaration, VariableDeclaration> timeoutDeclMappings = new HashMap<TimeoutDeclaration, VariableDeclaration>
	final Map<ParameterDeclaration, VariableDeclaration> parDeclMappings = new HashMap<ParameterDeclaration, VariableDeclaration>
	final Map<VariableDeclaration, VariableDeclaration> varDeclMappings = new HashMap<VariableDeclaration, VariableDeclaration>
	final Map<Region, hu.bme.mit.gamma.statechart.lowlevel.model.Region> regionMappings = new HashMap<Region, hu.bme.mit.gamma.statechart.lowlevel.model.Region>
	final Map<State, hu.bme.mit.gamma.statechart.lowlevel.model.State> stateMappings = new HashMap<State, hu.bme.mit.gamma.statechart.lowlevel.model.State>
	final Map<PseudoState, hu.bme.mit.gamma.statechart.lowlevel.model.PseudoState> pseudoStateMappings = new HashMap<PseudoState, hu.bme.mit.gamma.statechart.lowlevel.model.PseudoState>
	final Map<Transition, hu.bme.mit.gamma.statechart.lowlevel.model.Transition> transitionMappings = new HashMap<Transition, hu.bme.mit.gamma.statechart.lowlevel.model.Transition>
	// For timeout declaration optimization
	final Map<Region, VariableDeclaration> regionTimeoutMappings = newHashMap
	// Function return variables
	final Map<FunctionAccessExpression, VariableDeclaration> returnVariableMappings = new HashMap<FunctionAccessExpression, VariableDeclaration>
	// Record mappings
	final Map<Pair<VariableDeclaration, List<FieldDeclaration>>, VariableDeclaration> recordVarDeclMappings = new HashMap()
	
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
	def put(Port gammaPort, EventDeclaration gammaEventDecl, hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration lowlevelEventDecl) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEventDecl)
		checkNotNull(lowlevelEventDecl)
		if (isMapped(gammaPort, gammaEventDecl)) {
			val map = get(gammaPort, gammaEventDecl)
			checkState(map.size == 1)
			map.put(lowlevelEventDecl.direction, lowlevelEventDecl)
		}
		else {
			eventDeclMappings.put(new Pair(gammaPort, gammaEventDecl), newHashMap(lowlevelEventDecl.direction -> lowlevelEventDecl))
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
			throw new IllegalArgumentException("No entry for such parameters: " + gammaPort + " " + gammaEventDecl + " " + direction)
		}
		return possibleEvent
	}
	
	// Event
	def put(Port gammaPort, Event gammaEvent, hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration lowlevelEvent) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEvent)
		checkNotNull(lowlevelEvent)
		if (isMapped(gammaPort, gammaEvent)) {
			val map = get(gammaPort, gammaEvent)
			checkState(map.size == 1, "The size of the map is not 1: " + map)
			map.put(lowlevelEvent.direction, lowlevelEvent)
		}
		else {
			eventMappings.put(new Pair(gammaPort, gammaEvent), newHashMap(lowlevelEvent.direction -> lowlevelEvent))
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
			throw new IllegalArgumentException("No entry for such parameters: " + gammaPort + " " + gammaEvent + " " + direction)
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
		for (event : port.interfaceRealization.interface.events) {
			events += get(port, event)
		}
		return events
	}
	
	def getAllLowlevelEvents(Port port, EventDirection direction) {
		return allLowlevelEvents.map[it.get(direction)].toList
	}
	
	// Parameter
	def put(Port gammaPort, Event gammaEvent, ParameterDeclaration gammaParam, EventDirection direction, VariableDeclaration lowlevelParam) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEvent)
		checkNotNull(gammaParam)
		checkNotNull(lowlevelParam)
		if (isMapped(gammaPort, gammaEvent, gammaParam)) {
			val map = get(gammaPort, gammaEvent, gammaParam)
			checkState(map.size == 1)
			map.put(direction, lowlevelParam)
		}
		else {
			paramMappings.put(Triple.of(gammaPort, gammaEvent, gammaParam), newHashMap(direction -> lowlevelParam))
		}
	}

	def isMapped(Port gammaPort, Event gammaEvent, ParameterDeclaration gammaParam) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEvent)
		checkNotNull(gammaParam)
		for (entry : paramMappings.keySet) {
			if (entry.first == gammaPort && entry.second == gammaEvent && entry.third == gammaParam) {
				return true
			}
		}
		return false
	}

	def get(Port gammaPort, Event gammaEvent, ParameterDeclaration gammaParam) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEvent)
		checkNotNull(gammaParam)
		for (entry : paramMappings.keySet) {
			if (entry.first == gammaPort && entry.second == gammaEvent && entry.third == gammaParam) {
				return paramMappings.get(entry).unmodifiableView
			}
		}
		throw new IllegalArgumentException("No entry for such parameters: " + gammaPort + " " + gammaEvent + " " + gammaParam)
	}
	
	def get(Port gammaPort, Event gammaEvent, ParameterDeclaration gammaParam, EventDirection direction) {
		checkNotNull(gammaPort)
		checkNotNull(gammaEvent)
		checkNotNull(gammaParam)
		val possibleParam = get(gammaPort, gammaEvent, gammaParam).get(direction) // Possible params of IN and OUT event 
		if (possibleParam === null) {
			throw new IllegalArgumentException("No entry for such parameters: " + gammaPort + " " + gammaEvent + " " + gammaParam + " " + direction)
		}
		return possibleParam
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
	
	// Parameter declaration of components
	def put(ParameterDeclaration gammaParameter, VariableDeclaration lowlevelVariable) {
		checkNotNull(gammaParameter)
		checkNotNull(lowlevelVariable)
		parDeclMappings.put(gammaParameter, lowlevelVariable)
	}

	def isMapped(ParameterDeclaration gammaParameter) {
		checkNotNull(gammaParameter)
		parDeclMappings.containsKey(gammaParameter)
	}

	def get(ParameterDeclaration gammaParameter) {
		checkNotNull(gammaParameter)
		parDeclMappings.get(gammaParameter)
	}
	
	// Variable declaration
	def put(VariableDeclaration gammaVariable, VariableDeclaration lowlevelVariable) {
		checkNotNull(gammaVariable)
		checkNotNull(lowlevelVariable)
		varDeclMappings.put(gammaVariable, lowlevelVariable)
	}

	def isMapped(VariableDeclaration gammaVariable) {
		checkNotNull(gammaVariable)
		varDeclMappings.containsKey(gammaVariable)
	}

	def get(VariableDeclaration gammaVariable) {
		checkNotNull(gammaVariable)
		varDeclMappings.get(gammaVariable)
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
	
	// Entry state
//	def put(EntryState gammaEntry, hu.bme.mit.gamma.statechart.lowlevel.model.EntryState lowlevelEntry) {
//		checkNotNull(gammaEntry)
//		checkNotNull(lowlevelEntry)
//		entryStateMappings.put(gammaEntry, lowlevelEntry)
//	}
//
//	def isMapped(EntryState gammaEntry) {
//		checkNotNull(gammaEntry)
//		entryStateMappings.containsKey(gammaEntry)
//	}
//
//	def get(EntryState gammaEntry) {
//		checkNotNull(gammaEntry)
//		entryStateMappings.get(gammaEntry)
//	}
	
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
	def put(PseudoState gammaPseudoState, hu.bme.mit.gamma.statechart.lowlevel.model.PseudoState lowlevelPseudoState) {
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
	def put(Transition gammaTransition, hu.bme.mit.gamma.statechart.lowlevel.model.Transition lowlevelTransition) {
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
	
	// Function return variable
	def put(FunctionAccessExpression functionAccessExpression, VariableDeclaration returnVariable) {
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
	
	// Record variables
	def put(Pair<VariableDeclaration, List<FieldDeclaration>> recordField, VariableDeclaration lowLevelVariable) {
		checkNotNull(recordField)
		checkNotNull(recordField.key)
		checkNotNull(recordField.value)
		checkNotNull(recordField.value.get(0))	//as least one element
		checkNotNull(lowLevelVariable)
		recordVarDeclMappings.put(recordField, lowLevelVariable)
	} 

	def isMapped(Pair<VariableDeclaration, FieldDeclaration> recordField) {
		checkNotNull(recordField)
		checkNotNull(recordField.key)
		checkNotNull(recordField.value)
		for (key : recordVarDeclMappings.keySet) {
			if(key.key.equals(recordField.key) && key.value.equals(recordField.value)) {
				return true
			}
		}
		return false
	}
	
	def get(Pair<VariableDeclaration, FieldDeclaration> recordField) {
		checkNotNull(recordField)
		checkNotNull(recordField.key)
		checkNotNull(recordField.value)
		for (key : recordVarDeclMappings.keySet) {
			if(key.key.equals(recordField.key) && key.value.equals(recordField.value)) {
				recordVarDeclMappings.get(key)
			}
		}
		return null
	}
	
	private static class Triple<K, V, T> {
		K first;
		V second;
		T third;
		
		private new(K first, V second, T third) {
			this.first = first;
			this.second = second;
			this.third = third;
		}
		
		def static <K, V, T> of(K first, V second, T third) {
			return new Triple(first, second, third)
		}
		
		def getFirst() {
			return first;
		}
		
		def getSecond() {
			return second;
		}
		
		def getThird() {
			return third;
		}
		
	} 
	
}
