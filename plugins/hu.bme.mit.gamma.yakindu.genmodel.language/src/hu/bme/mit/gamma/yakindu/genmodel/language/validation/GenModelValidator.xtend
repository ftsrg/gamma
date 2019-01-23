/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.yakindu.genmodel.language.validation

import hu.bme.mit.gamma.constraint.model.BooleanTypeDefinition
import hu.bme.mit.gamma.constraint.model.IntegerTypeDefinition
import hu.bme.mit.gamma.constraint.model.RealTypeDefinition
import hu.bme.mit.gamma.statechart.model.RealizationMode
import hu.bme.mit.gamma.statechart.model.interface_.EventDeclaration
import hu.bme.mit.gamma.statechart.model.interface_.EventDirection
import hu.bme.mit.gamma.statechart.model.interface_.Interface
import hu.bme.mit.gamma.yakindu.genmodel.EventMapping
import hu.bme.mit.gamma.yakindu.genmodel.GenmodelPackage
import hu.bme.mit.gamma.yakindu.genmodel.InterfaceMapping
import hu.bme.mit.gamma.yakindu.genmodel.StatechartCompilation
import java.util.Collections
import java.util.HashMap
import java.util.HashSet
import java.util.Set
import org.eclipse.xtext.validation.Check
import org.yakindu.base.types.Direction
import org.yakindu.base.types.Event
import org.yakindu.sct.model.stext.stext.InterfaceScope

/**
 * This class contains custom validation rules. 
 *
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#validation
 */
class GenModelValidator extends AbstractGenModelValidator { 
	
	@Check
	def checkIfAllInterfacesMapped(StatechartCompilation statechartCompilation) {
		val interfaces = statechartCompilation.statechart.scopes.filter(InterfaceScope).toSet
		val mappedInterfaces = statechartCompilation.interfaceMappings.map[it.yakinduInterface].toSet
		interfaces.removeAll(mappedInterfaces)
		if (!interfaces.empty) {
			val interfacesWithEvents = interfaces.filter[!it.events.empty].toSet
			val interfacesWithoutEvents = interfaces.filter[it.events.empty].toSet
			if (!interfacesWithEvents.empty) {
				error("The following interfaces with events are not mapped: " + interfacesWithEvents.map[it.name] + ".", GenmodelPackage.Literals.YAKINDU_COMPILATION__STATECHART)
			}
			if (!interfacesWithoutEvents.empty) {
				info("The following interfaces without events are not mapped: " + interfacesWithoutEvents.map[it.name] + ".", GenmodelPackage.Literals.YAKINDU_COMPILATION__STATECHART)
			}
		}
	}
	
	@Check
	def checkInterfaceConformance(InterfaceMapping mapping) {
		if (!(mapping.checkConformance)) {
			switch mapping.realizationMode {
				case RealizationMode.PROVIDED:
					error("In case of provided realization mode number of in/out events must equal to the number of in/out events in the Gamma interface and vice versa.", GenmodelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)
				case RealizationMode.REQUIRED:
					error("In case of required realization mode number of in/out events must equal to the number of out/in events in the Gamma interface and vice versa", GenmodelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)
				default:
					throw new IllegalArgumentException("Such interface realization mode is not supported: " + mapping.realizationMode)
			}
		}
	}
	
	/** It checks the events of the parent interfaces as well. */
	private def boolean checkConformance(InterfaceMapping mapping) {
		val yOut = mapping.yakinduInterface.events.filter[it.direction == Direction.OUT].size
		val yIn = mapping.yakinduInterface.events.filter[it.direction == Direction.IN].size
		val gOut = mapping.gammaInterface.allEvents.filter[it.direction != EventDirection.IN].size // Regarding in-out events
		val gIn = mapping.gammaInterface.allEvents.filter[it.direction != EventDirection.OUT].size // Regarding in-out events
		val realMode = mapping.realizationMode
		return (realMode == RealizationMode.PROVIDED && yOut == gOut && yIn == gIn) ||
			(realMode == RealizationMode.REQUIRED && yOut == gIn && yIn == gOut)
	}
	
	@Check
	def checkInterfaceMappingWithoutEventMapping(InterfaceMapping mapping) {
		// 0 event mapping is acceptable if the two interfaces are equal
		val realizationMode = mapping.realizationMode
		if (mapping.eventMappings.size == 0) {
			// If the interface has in-out events, 0 event mapping is surely not acceptable
			if (!mapping.gammaInterface.events.filter[it.direction == EventDirection.INOUT].empty) {
				error("The Gamma interface has in-out events, thus an automatic mapping is not possible", GenmodelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)
				return
			}
			for (yakinduEvent : mapping.yakinduInterface.events) {
				val gammaEvents = mapping.gammaInterface.events.map[it.event].filter[it.name.equals(yakinduEvent.name)]
				val gammaEvent = gammaEvents.head
				if (!(gammaEvents.size == 1 && checkParameters(yakinduEvent, gammaEvent)
					&& realizationMode.areWellDirected(yakinduEvent, gammaEvent.eContainer as EventDeclaration))) {
					val typeName = if (yakinduEvent.type !== null) {" : " + yakinduEvent.type.name} else {""}
					error("Interface mapping without event mapping is only possible if the names and types of the events of the interfaces are equal. " 
						+ yakinduEvent.name + typeName + " has no equivalent event in the Gamma interface.", GenmodelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE
					)
				}			
			}
		}
	}
	
	/**
	 * Checks whether the event directions conform to the realization mode.
	 */
	private def areWellDirected(RealizationMode interfaceType, Event yEvent, EventDeclaration gEvent) {
		if (interfaceType == RealizationMode.PROVIDED) {
			return (yEvent.direction == Direction.OUT && gEvent.direction != EventDirection.IN) ||
			(yEvent.direction == Direction.IN && gEvent.direction != EventDirection.OUT)
		}
		else if (interfaceType == RealizationMode.REQUIRED) {
			return (yEvent.direction == Direction.OUT && gEvent.direction != EventDirection.OUT) ||
			(yEvent.direction == Direction.IN && gEvent.direction != EventDirection.IN)
		}
		else {
			throw new IllegalArgumentException("No such direction: " + interfaceType)
		}
	}
	
	@Check
	def checkMappingCount(InterfaceMapping mapping) {
		// Check only if the interface mapping is not trivial (size != 0)
		if (mapping.eventMappings.size != 0 && mapping.yakinduInterface.events.size != mapping.eventMappings.size) {
			error("Each Yakindu event has to be mapped exactly once.", GenmodelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)
		}
	}
	
	@Check
	def checkYakinduInterfaceUniqueness(InterfaceMapping mapping) {
		val interfaces = new HashSet<InterfaceScope>
		val statechartCompilation = mapping.eContainer as StatechartCompilation
		for (interface : statechartCompilation.interfaceMappings.map[it.yakinduInterface]) {
			if (interfaces.contains(interface)){
				error("Each Yakindu event has to be mapped exactly once.", GenmodelPackage.Literals.INTERFACE_MAPPING__YAKINDU_INTERFACE)
			}
			else {
				interfaces.add(interface)
			}			
		}
	}
	
	@Check
	def checkEventMappingCount(InterfaceMapping mapping) {
		val mappedYakinduEvents = new HashSet<Event>
		val mappedGammaEvents = new HashMap<hu.bme.mit.gamma.statechart.model.interface_.Event, Set<Event>>
		for (eventMapping : mapping.eventMappings) {
			val yakinduEvent = eventMapping.yakinduEvent
			val gammaEvent = eventMapping.gammaEvent
			// Yakindu validation
			if (mappedYakinduEvents.contains(yakinduEvent)) {
				error("This event is mapped multiple times: " + yakinduEvent.name + ".", GenmodelPackage.Literals.INTERFACE_MAPPING__EVENT_MAPPINGS)
			}
			else {
				mappedYakinduEvents += yakinduEvent			
			}
			// Gamma validation
			if (mappedGammaEvents.containsKey(gammaEvent)) {
				val gammaEventDeclaration = gammaEvent.eContainer as EventDeclaration
				if (gammaEventDeclaration.direction == EventDirection.INOUT) {
					val yakinduEventSet = mappedGammaEvents.get(gammaEvent)
					yakinduEventSet += yakinduEvent
					// A single in and a single out event has to be now in yakinduEventSet
					if (!(yakinduEventSet.filter[it.direction == Direction.IN].size == 1 &&
							yakinduEventSet.filter[it.direction == Direction.OUT].size == 1)) {
						error("A single in and a single out event has to be mapped onto this Gamma event: " + gammaEvent.name + ".",
							GenmodelPackage.Literals.INTERFACE_MAPPING__EVENT_MAPPINGS)
					}
				}
				else {
					// Not an in-out event
					error("Multiple Yakindu events are mapped to this Gamma event: " + gammaEvent.name + ".", GenmodelPackage.Literals.INTERFACE_MAPPING__EVENT_MAPPINGS)
				}
			}
			else {
				// First entry
				mappedGammaEvents.put(gammaEvent, newHashSet(yakinduEvent))			
			}
		}		
	}
	
	@Check
	def checkEventConformance(EventMapping mapping) {		
		val ifReal = mapping.eContainer as InterfaceMapping
		if (!(mapping.checkConformance)) {
			switch (ifReal.realizationMode) {
				case RealizationMode.PROVIDED:
					error("In case of provided realization mode Yakindu events must have the same direction and parameter as Gamma events.", GenmodelPackage.Literals.EVENT_MAPPING__YAKINDU_EVENT)
				case RealizationMode.REQUIRED:
					error("In case of required realization mode Yakindu events must have the opposite direction and same parameter of Gamma events.", GenmodelPackage.Literals.EVENT_MAPPING__YAKINDU_EVENT)		
			default:
				throw new IllegalArgumentException("Such interface realization mode is not supported: " + ifReal.realizationMode)				
			}
		}
	}
	
	private def boolean checkConformance(EventMapping mapping) {
		val yEvent = mapping.yakinduEvent
		val gEvent = mapping.gammaEvent.eContainer as EventDeclaration
		val ifReal = mapping.eContainer as InterfaceMapping
		val realMode = ifReal.realizationMode
		return checkEventConformance(yEvent, gEvent, realMode)
	}
	
	private def checkEventConformance(Event yEvent, EventDeclaration gEvent, RealizationMode realMode) {
		switch (realMode) {
			 // Regarding in-out events
			case RealizationMode.PROVIDED:
				return yEvent.direction == Direction.IN && gEvent.direction != EventDirection.OUT && checkParameters(yEvent, gEvent.event) ||
					yEvent.direction == Direction.OUT && gEvent.direction != EventDirection.IN && checkParameters(yEvent, gEvent.event)
			case RealizationMode.REQUIRED:
				return yEvent.direction == Direction.IN && gEvent.direction != EventDirection.IN && checkParameters(yEvent, gEvent.event) ||
					yEvent.direction == Direction.OUT && gEvent.direction != EventDirection.OUT && checkParameters(yEvent, gEvent.event)
			default:
				throw new IllegalArgumentException("Such interface realization mode is not supported: " + realMode)				
		}
	}
	
	private def checkParameters(Event yEvent, hu.bme.mit.gamma.statechart.model.interface_.Event gEvent) {
		// event.type is null not void if no explicit type is declared
		if (yEvent.type === null && gEvent.parameterDeclarations.empty) {
			return true
		}
		if (!gEvent.parameterDeclarations.empty) {
			switch (gEvent.parameterDeclarations.head.type) {
				IntegerTypeDefinition: {
					if (yEvent.type === null) {
						return false
					}
					return yEvent.type.name.equals("integer") ||
						yEvent.type.name.equals("string") // strings are mapped to integers					
				}
				BooleanTypeDefinition: {
					if (yEvent.type === null) {
						return false
					}
					return yEvent.type.name.equals("boolean")					
				}
				RealTypeDefinition: {
					if (yEvent.type === null) {
						return false
					}
					return yEvent.type.name.equals("real")					
				}
				default:
					throw new IllegalArgumentException("Not known type: " + gEvent.parameterDeclarations.head.type)
			}		
		}
		return false
	}
	
	private def Set<EventDeclaration> getAllEvents(Interface anInterface) {
		if (anInterface === null) {
			return Collections.EMPTY_SET
		}
		val eventSet = new HashSet<EventDeclaration>
		for (parentInterface : anInterface.parents) {
			eventSet.addAll(parentInterface.getAllEvents)
		}
		for (event : anInterface.events.map[it.event]) {
			eventSet.add(event.eContainer as EventDeclaration)
		}
		return eventSet
	}
	
}
