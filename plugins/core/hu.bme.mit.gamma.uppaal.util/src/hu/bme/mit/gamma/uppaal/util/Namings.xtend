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
package hu.bme.mit.gamma.uppaal.util

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Clock
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import uppaal.declarations.Variable

import static extension hu.bme.mit.gamma.transformation.util.Namings.*

class Namings {
	
	static var entrySyncId = 0
	static var exitSyncId = 0
	static var exitLocationId = 0
	
	public static var entrySyncNamePrefix = "entryChanOf"
	public static var exitSyncNamePrefix = "exitChanOf"
	public static var acrossRegionSyncNamePrefix = "AcrReg"
	public static var clockNamePrefix = "timer"
	
	def static getAsyncSchedulerChannelName(AsynchronousAdapter wrapper) {
		return "async" + wrapper.name
	}
	
	def static getSyncSchedulerChannelName(AsynchronousAdapter wrapper) {
		return "sync" + wrapper.name
	}
	
	def static getInitializedVariableName(AsynchronousAdapter wrapper) {
		return "is"  + wrapper.name.toFirstUpper  + "Initialized"
	}
	
	def static getAsyncSchedulerChannelName(AsynchronousComponentInstance instance) {
		return "async" + instance.name
	}
	
	def static getSyncSchedulerChannelName(AsynchronousComponentInstance instance) {
		return "sync" + instance.name
	}
	
	def static getInitializedVariableName(AsynchronousComponentInstance instance) {
		return "is" + instance.name.toFirstUpper + "Initialized"
	}
	
	def static getPostfix(ComponentInstance instance) {
		if (instance === null) {
			return ""
		}
		return "Of" + instance.name
	}
	
	def static getOutEventName(Event event, Port port, ComponentInstanceReferenceExpression owner) {
		return getOutEventName(event, port, owner.FQN)
	}
	
	def static getOutEventName(Event event, Port port, ComponentInstance owner) {
		return getOutEventName(event, port, owner.name)
	}
	
	def static getOutEventName(Event event, Port port, String owner) {
		return port.name + "_" + event.name + "Of" + owner
	}
	
	def static getToRaiseName(Event event, Port port, ComponentInstanceReferenceExpression instance) {
		return getToRaiseName(event, port, instance.FQN)
	}
	
	def static getToRaiseName(Event event, Port port, ComponentInstance instance) {
		return getToRaiseName(event, port, instance.name)
	}
	
	def static getToRaiseName(Event event, Port port, String instance) {
		return "toRaise_" + port.name + "_" + event.name + "Of" + instance
	}
	
	def static getIsRaisedName(Event event, Port port, ComponentInstanceReferenceExpression instance) {
		return getIsRaisedName(event, port, instance.FQN)
	}
	
	def static getIsRaisedName(Event event, Port port, ComponentInstance instance) {
		return getIsRaisedName(event, port, instance.name)
	}
	
	def static getIsRaisedName(Event event, Port port, String instance) {
		return "isRaised_" + port.name + "_" + event.name + "Of" + instance
	}
	
	def static getOutValueOfName(Event event, Port port, ParameterDeclaration parameter, ComponentInstanceReferenceExpression instance) {
		return getOutEventName(event, port, instance) + parameter.name
	}
	
	def static getOutValueOfName(Event event, Port port, ParameterDeclaration parameter, ComponentInstance instance) {
		return getOutEventName(event, port, instance) + parameter.name
	}
	
	def static getToRaiseValueOfName(Event event, Port port, ParameterDeclaration parameter, ComponentInstanceReferenceExpression instance) {
		return getToRaiseName(event, port, instance) + parameter.name
	}
	
	def static getToRaiseValueOfName(Event event, Port port, ParameterDeclaration parameter, ComponentInstance instance) {
		return getToRaiseName(event, port, instance) + parameter.name
	}
	
	def static getIsRaisedValueOfName(Event event, Port port, ParameterDeclaration parameter, ComponentInstance instance) {
		return getIsRaisedName(event, port, instance) +  parameter.name
	}
	
	def static getIsRaisedValueOfName(Event event, Port port, ParameterDeclaration parameter, ComponentInstanceReferenceExpression instance) {
		return getIsRaisedName(event, port, instance) +  parameter.name
	}
	
	def static getValueOfName(Variable variable, ParameterDeclaration parameter) {
		return variable.name + parameter.name
	}
	
	def static getVariableName(VariableDeclaration variable, ComponentInstanceReferenceExpression instance) {
		return getVariableName(variable.name, instance.FQN)
	}
	
	def static getVariableName(VariableDeclaration variable, ComponentInstance instance) {
		return getVariableName(variable.name, instance.name)
	}
	
	def static getVariableName(String variableName, String instanceName) {
		return variableName + "Of" + instanceName
	}
	
	/**
	 * Returns the template name of a region.
	 */
	def static String getTemplateName(Region region, ComponentInstanceReferenceExpression instance) {
		return getTemplateName(region, instance.FQN)
	}
	
	def static String getTemplateName(Region region, SynchronousComponentInstance instance) {
		return getTemplateName(region, instance.name)
	}
	 
	def static String getTemplateName(Region region, String instance) {
		var String templateName
		if (region.eContainer instanceof State) {
			templateName = (region.name + "Of" + (region.eContainer as State).name)
		}
		else {			
			templateName = (region.name + "OfStatechart")
		}
		return templateName.replaceAll(" ","")  + "Of" +  instance
	}
	
	/**
	 * Returns the process name of the template.
	 */
	def static String getProcessName(String templateName) {
		return "P_" +  templateName
	}
	
	/**
	 * Returns the location name of a state.
	 */
	def static String getLocationName(StateNode state) {
		val name = state.name
		if (name.nullOrEmpty) {
			return state.class.name + exitLocationId++
		}
 		return state.name.replaceAll(" ","").toFirstUpper
	}
	
	/**
	 * Returns the name of the committed entry location of the given composite state.
	 */
	def static getEntryLocationNameOfState(State state) {
		return "entryOf" + state.name.replaceAll(" ", "")
	}
	
	/**
	 * Returns the name of the committed exit location of the given composite state.
	 */
	def static getExitLocationNameOfCompositeState(State state) {
		if (state.regions.empty) {
			throw new IllegalAccessException("State is not composite: " + state)
		}
		return ("exitOf" + state.name + exitLocationId++).replaceAll(" ", "")
	}
	
	/**
	 * Returns the name of the committed entry location of the given composite state.
	 */
	def static String getEntrySyncNameOfCompositeState(State state) {
		if (state.regions.empty) {
			throw new IllegalAccessException("State is not composite: " + state)
		}
		return (entrySyncNamePrefix + state.name + entrySyncId++).replaceAll(" ", "")
	}
	
	/**
	 * Returns the name of the committed entry location of the given composite state.
	 */
	def static String getExitSyncNameOfCompositeState(State state) {
		if (state.regions.empty) {
			throw new IllegalAccessException("State is not composite: " + state)
		}
		return (exitSyncNamePrefix + state.name + exitSyncId++).replaceAll(" ", "")
	}
	
	def static getConstRepresentationName(Event event, Port port) {
		return port.name + "_" + event.name
	}
	
	def static getConstRepresentationName(Clock clock) {
		return clock.name + "Of" + (clock.eContainer as AsynchronousAdapter).name
	}
	
	def static finalizeSyncVarName() {
		return "finalize"
	}
	
	def static getIsStableVariableName() {
		return "isStable"
	}
	
	def static getTransitionIdVariableName() {
		return "transitionId"
	}
	
	def static getSendingInteractionIdVariableName(ComponentInstance instance) {
		return "sendingInteractionOf" + instance.name
	}
	
	def static getReceivingInteractionIdVariableName(ComponentInstance instance) {
		return "receivingInteractionOf" + instance.name
	}
	
}
