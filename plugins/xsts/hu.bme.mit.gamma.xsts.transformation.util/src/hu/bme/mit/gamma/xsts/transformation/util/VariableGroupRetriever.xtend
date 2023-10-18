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
package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.xsts.model.ComponentParameterGroup
import hu.bme.mit.gamma.xsts.model.InEventGroup
import hu.bme.mit.gamma.xsts.model.InEventParameterGroup
import hu.bme.mit.gamma.xsts.model.MasterMessageQueueGroup
import hu.bme.mit.gamma.xsts.model.MessageQueueSizeGroup
import hu.bme.mit.gamma.xsts.model.OutEventGroup
import hu.bme.mit.gamma.xsts.model.OutEventParameterGroup
import hu.bme.mit.gamma.xsts.model.PlainVariableGroup
import hu.bme.mit.gamma.xsts.model.RegionGroup
import hu.bme.mit.gamma.xsts.model.SlaveMessageQueueGroup
import hu.bme.mit.gamma.xsts.model.SystemInEventGroup
import hu.bme.mit.gamma.xsts.model.SystemInEventParameterGroup
import hu.bme.mit.gamma.xsts.model.SystemMasterMessageQueueGroup
import hu.bme.mit.gamma.xsts.model.SystemOutEventGroup
import hu.bme.mit.gamma.xsts.model.SystemOutEventParameterGroup
import hu.bme.mit.gamma.xsts.model.SystemSlaveMessageQueueGroup
import hu.bme.mit.gamma.xsts.model.TimeoutGroup
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory

import static com.google.common.base.Preconditions.checkState

class VariableGroupRetriever {
	// Singleton
	public static final VariableGroupRetriever INSTANCE =  new VariableGroupRetriever
	protected new() {}
	// Model factories
	protected final extension XSTSModelFactory factory = XSTSModelFactory.eINSTANCE
	
	// During a single low-level statechart transformation, there is a single component parameter group
	def getComponentParameterGroup(XSTS xSts) {
		var componentParameterGroups = xSts.variableGroups
									.filter[it.annotation instanceof ComponentParameterGroup]
		if (componentParameterGroups.empty) {
			val componentParameterGroup = createVariableGroup => [
				it.annotation = createComponentParameterGroup
			]
			xSts.variableGroups += componentParameterGroup
			return componentParameterGroup
		}
		checkState(componentParameterGroups.size == 1)
		return componentParameterGroups.head
	}

	// During a single low-level statechart transformation, there is a single in event variable group
	def getInEventVariableGroup(XSTS xSts) {
		var eventVariableGroups = xSts.variableGroups
									.filter[it.annotation instanceof InEventGroup]
		if (eventVariableGroups.empty) {
			val eventVariableGroup = createVariableGroup => [
				it.annotation = createInEventGroup
			]
			xSts.variableGroups += eventVariableGroup
			return eventVariableGroup
		}
		checkState(eventVariableGroups.size == 1)
		return eventVariableGroups.head
	}
	
	// During a single low-level statechart transformation, there is a single system In event variable group
	def getSystemInEventVariableGroup(XSTS xSts) {
		var eventVariableGroups = xSts.variableGroups
									.filter[it.annotation instanceof SystemInEventGroup]
		if (eventVariableGroups.empty) {
			val eventVariableGroup = createVariableGroup => [
				it.annotation = createSystemInEventGroup
			]
			xSts.variableGroups += eventVariableGroup
			return eventVariableGroup
		}
		checkState(eventVariableGroups.size == 1)
		return eventVariableGroups.head
	}
	
	// During a single low-level statechart transformation, there is a single out event variable group
	def getOutEventVariableGroup(XSTS xSts) {
		var eventVariableGroups = xSts.variableGroups
									.filter[it.annotation instanceof OutEventGroup]
		if (eventVariableGroups.empty) {
			val eventVariableGroup = createVariableGroup => [
				it.annotation = createOutEventGroup
			]
			xSts.variableGroups += eventVariableGroup
			return eventVariableGroup
		}
		checkState(eventVariableGroups.size == 1)
		return eventVariableGroups.head
	}
	
	// During a single low-level statechart transformation, there is a single system out event variable group
	def getSystemOutEventVariableGroup(XSTS xSts) {
		var eventVariableGroups = xSts.variableGroups
									.filter[it.annotation instanceof SystemOutEventGroup]
		if (eventVariableGroups.empty) {
			val eventVariableGroup = createVariableGroup => [
				it.annotation = createSystemOutEventGroup
			]
			xSts.variableGroups += eventVariableGroup
			return eventVariableGroup
		}
		checkState(eventVariableGroups.size == 1)
		return eventVariableGroups.head
	}
	
	// During a single low-level statechart transformation, there is a single in event parameter variable group
	def getInEventParameterVariableGroup(XSTS xSts) {
		var eventParameterVariableGroups = xSts.variableGroups
									.filter[it.annotation instanceof InEventParameterGroup]
		if (eventParameterVariableGroups.empty) {
			val eventParameterVariableGroup = createVariableGroup => [
				it.annotation = createInEventParameterGroup
			]
			xSts.variableGroups += eventParameterVariableGroup
			return eventParameterVariableGroup
		}
		checkState(eventParameterVariableGroups.size == 1)
		return eventParameterVariableGroups.head
	}
	
	// During a single low-level statechart transformation, there is a single system in event parameter variable group
	def getSystemInEventParameterVariableGroup(XSTS xSts) {
		var eventParameterVariableGroups = xSts.variableGroups
									.filter[it.annotation instanceof SystemInEventParameterGroup]
		if (eventParameterVariableGroups.empty) {
			val eventParameterVariableGroup = createVariableGroup => [
				it.annotation = createSystemInEventParameterGroup
			]
			xSts.variableGroups += eventParameterVariableGroup
			return eventParameterVariableGroup
		}
		checkState(eventParameterVariableGroups.size == 1)
		return eventParameterVariableGroups.head
	}
	
	// During a single low-level statechart transformation, there is a single out event parameter variable group
	def getOutEventParameterVariableGroup(XSTS xSts) {
		var eventParameterVariableGroups = xSts.variableGroups
									.filter[it.annotation instanceof OutEventParameterGroup]
		if (eventParameterVariableGroups.empty) {
			val eventParameterVariableGroup = createVariableGroup => [
				it.annotation = createOutEventParameterGroup
			]
			xSts.variableGroups += eventParameterVariableGroup
			return eventParameterVariableGroup
		}
		checkState(eventParameterVariableGroups.size == 1)
		return eventParameterVariableGroups.head
	}
	
	// During a single low-level statechart transformation, there is a single system out event parameter variable group
	def getSystemOutEventParameterVariableGroup(XSTS xSts) {
		var eventParameterVariableGroups = xSts.variableGroups
									.filter[it.annotation instanceof SystemOutEventParameterGroup]
		if (eventParameterVariableGroups.empty) {
			val eventParameterVariableGroup = createVariableGroup => [
				it.annotation = createSystemOutEventParameterGroup
			]
			xSts.variableGroups += eventParameterVariableGroup
			return eventParameterVariableGroup
		}
		checkState(eventParameterVariableGroups.size == 1)
		return eventParameterVariableGroups.head
	}
	
	def getMasterMessageQueueGroup(XSTS xSts) {
		var masterMessageQueueGroups = xSts.variableGroups
									.filter[it.annotation instanceof MasterMessageQueueGroup]
		if (masterMessageQueueGroups.empty) {
			val masterMessageQueueGroup = createVariableGroup => [
				it.annotation = createMasterMessageQueueGroup
			]
			xSts.variableGroups += masterMessageQueueGroup
			return masterMessageQueueGroup
		}
		checkState(masterMessageQueueGroups.size == 1)
		return masterMessageQueueGroups.head
	}
	
	def getSlaveMessageQueueGroup(XSTS xSts) {
		var slaveMessageQueueGroups = xSts.variableGroups
									.filter[it.annotation instanceof SlaveMessageQueueGroup]
		if (slaveMessageQueueGroups.empty) {
			val slaveMessageQueueGroup = createVariableGroup => [
				it.annotation = createSlaveMessageQueueGroup
			]
			xSts.variableGroups += slaveMessageQueueGroup
			return slaveMessageQueueGroup
		}
		checkState(slaveMessageQueueGroups.size == 1)
		return slaveMessageQueueGroups.head
	}
	
	def getSystemMasterMessageQueueGroup(XSTS xSts) {
		var masterMessageQueueGroups = xSts.variableGroups
									.filter[it.annotation instanceof SystemMasterMessageQueueGroup]
		if (masterMessageQueueGroups.empty) {
			val masterMessageQueueGroup = createVariableGroup => [
				it.annotation = createSystemMasterMessageQueueGroup
			]
			xSts.variableGroups += masterMessageQueueGroup
			return masterMessageQueueGroup
		}
		checkState(masterMessageQueueGroups.size == 1)
		return masterMessageQueueGroups.head
	}
	
	def getSystemSlaveMessageQueueGroup(XSTS xSts) {
		var slaveMessageQueueGroups = xSts.variableGroups
									.filter[it.annotation instanceof SystemSlaveMessageQueueGroup]
		if (slaveMessageQueueGroups.empty) {
			val slaveMessageQueueGroup = createVariableGroup => [
				it.annotation = createSystemSlaveMessageQueueGroup
			]
			xSts.variableGroups += slaveMessageQueueGroup
			return slaveMessageQueueGroup
		}
		checkState(slaveMessageQueueGroups.size == 1)
		return slaveMessageQueueGroups.head
	}
	
	def getMessageQueueSizeGroup(XSTS xSts) {
		var messageQueueSizeGroups = xSts.variableGroups
									.filter[it.annotation instanceof MessageQueueSizeGroup]
		if (messageQueueSizeGroups.empty) {
			val messageQueueSizeGroup = createVariableGroup => [
				it.annotation = createMessageQueueSizeGroup
			]
			xSts.variableGroups += messageQueueSizeGroup
			return messageQueueSizeGroup
		}
		checkState(messageQueueSizeGroups.size == 1)
		return messageQueueSizeGroups.head
	}
	
	def getMessageQueueGroup(XSTS xSts) { // Only derived feature
		val messageQueueGroup = createVariableGroup => [
			it.annotation = null
		]
		
		messageQueueGroup.variables += xSts.masterMessageQueueGroup.variables
		messageQueueGroup.variables += xSts.slaveMessageQueueGroup.variables
		messageQueueGroup.variables += xSts.systemMasterMessageQueueGroup.variables
		messageQueueGroup.variables += xSts.systemSlaveMessageQueueGroup.variables
		
		return messageQueueGroup
	} 

	// During a single low-level statechart transformation, there is a single plain variable group
	def getPlainVariableGroup(XSTS xSts) {
		var plainVariableGroups = xSts.variableGroups
									.filter[it.annotation instanceof PlainVariableGroup]
		if (plainVariableGroups.empty) {
			val plainVariableGroup = createVariableGroup => [
				it.annotation = createPlainVariableGroup
			]
			xSts.variableGroups += plainVariableGroup
			return plainVariableGroup
		}
		checkState(plainVariableGroups.size == 1)
		return plainVariableGroups.head
	}
	
	// During a single low-level statechart transformation, there are multiple region variable group
	def getRegionGroups(XSTS xSts) {
		val regionGroups = xSts.variableGroups
									.filter[it.annotation instanceof RegionGroup]
									.toList
		// Multiple variable groups
		return regionGroups
	}
	
	// During a single low-level statechart transformation, there is a single timeout variable group
	def getTimeoutGroup(XSTS xSts) {
		val timeoutGroups = xSts.variableGroups
									.filter[it.annotation instanceof TimeoutGroup]
		if (timeoutGroups.empty) {
			val timeoutGroup = createVariableGroup => [
				it.annotation = createTimeoutGroup
			]
			xSts.variableGroups += timeoutGroup
			return timeoutGroup
		}
		checkState(timeoutGroups.size == 1)
		return timeoutGroups.head
	}
	
}