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
package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.xsts.model.ComponentParameterGroup
import hu.bme.mit.gamma.xsts.model.InEventGroup
import hu.bme.mit.gamma.xsts.model.InEventParameterGroup
import hu.bme.mit.gamma.xsts.model.OutEventGroup
import hu.bme.mit.gamma.xsts.model.OutEventParameterGroup
import hu.bme.mit.gamma.xsts.model.PlainVariableGroup
import hu.bme.mit.gamma.xsts.model.RegionGroup
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