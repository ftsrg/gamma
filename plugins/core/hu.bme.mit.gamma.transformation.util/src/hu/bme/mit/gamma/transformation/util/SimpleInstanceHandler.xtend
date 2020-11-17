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
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.property.model.ComponentInstancePortReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference
import hu.bme.mit.gamma.property.model.ComponentInstanceTransitionReference
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.transformation.util.Namings.*

class SimpleInstanceHandler {
	// Singleton
	public static final SimpleInstanceHandler INSTANCE =  new SimpleInstanceHandler
	protected new() {}
	//
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	// Component instance transition references
	
	def getNewIncludedSimpleInstanceTransitions(
			Collection<ComponentInstanceTransitionReference> includedOriginalReferences,
			Collection<ComponentInstanceTransitionReference> excludedOriginalReferences,
			Component newType) {
		val newTransitions = newArrayList
		// The semantics is defined here: including has priority over excluding
		newTransitions -= excludedOriginalReferences.getNewSimpleInstanceTransitions(newType)
		newTransitions += includedOriginalReferences.getNewSimpleInstanceTransitions(newType)
		return newTransitions
	}
	
	def getNewSimpleInstanceTransitions(
			Collection<ComponentInstanceTransitionReference> originalReferences, Component newType) {
		val newTransitions = newArrayList
		for (originalReference : originalReferences) {
			val originalInstance = originalReference.instance
			val originalTransition = originalReference.transition.getSelfOrContainerOfType(Transition)
			val newInstance = originalInstance.getNewSimpleInstance(newType)
			val newTransition = newInstance.getNewTransition(originalTransition) 
			if (newTransition !== null) {
				newTransitions += newInstance.getNewTransition(originalTransition)
			} 
		}
		return newTransitions
	}
	
	private def getNewTransition(SynchronousComponentInstance newInstance,
			Transition originalTransition) {
		val newType = newInstance.type
		if (newType instanceof StatechartDefinition) {
			for (transition : newType.transitions) {
				if (transition.helperEquals(originalTransition)) {
					return transition
				}
			}
		}
		return null // Can be null due to reduction
	}
	
	// Component instance state references
	
	def getNewIncludedSimpleInstanceStates(
			Collection<ComponentInstanceStateConfigurationReference> includedOriginalReferences,
			Collection<ComponentInstanceStateConfigurationReference> excludedOriginalReferences,
			Component newType) {
		val newStates = newArrayList
		// The semantics is defined here: including has priority over excluding
		newStates -= excludedOriginalReferences.getNewSimpleInstanceStates(newType)
		newStates += includedOriginalReferences.getNewSimpleInstanceStates(newType)
		return newStates
	}
	
	def getNewSimpleInstanceStates(
			Collection<ComponentInstanceStateConfigurationReference> originalReferences, Component newType) {
		val newStates = newArrayList
		for (originalReference : originalReferences) {
			val originalInstance = originalReference.instance
			val originalState= originalReference.state 
			val newInstance = originalInstance.getNewSimpleInstance(newType)
			val newState = newInstance.getNewState(originalState)
			if (newState !== null) {
				newStates += newState
			} 
		}
		return newStates
	}
	
	private def getNewState(SynchronousComponentInstance newInstance, State originalState) {
		val newType = newInstance.type
		if (newType instanceof StatechartDefinition) {
			for (state : newType.allStates) {
				// Not helper equals, as reduction can change the subregions
				if (state.equal(originalState)) {
					return state
				}
			}
		}
		return null // Can be null due to reduction
	}
	
	private def equal(State lhs, State rhs) {
		return lhs.name == rhs.name &&
			lhs.parentRegion.name == rhs.parentRegion.name
	}
	
	// Component instance port references
	
	def getNewIncludedSimpleInstancePorts(Collection<ComponentInstancePortReference> includedOriginalReferences,
			Collection<ComponentInstancePortReference> excludedOriginalReferences, Component newType) {
		val newPorts = newArrayList
		// The semantics is defined here: including has priority over excluding
		newPorts -= excludedOriginalReferences.getNewSimpleInstancePorts(newType)
		newPorts += includedOriginalReferences.getNewSimpleInstancePorts(newType)
		return newPorts
	}
	
	def getNewSimpleInstancePorts(
			Collection<ComponentInstancePortReference> originalReferences, Component newType) {
		val newPorts = newArrayList
		for (originalReference : originalReferences) {
			val originalInstance = originalReference.instance
			val originalPort = originalReference.port 
			val newInstance = originalInstance.getNewSimpleInstance(newType)
			newPorts += newInstance.getNewPort(originalPort) 
		}
		return newPorts
	}
	
	private def getNewPort(SynchronousComponentInstance newInstance, Port originalPort) {
		val newType = newInstance.type
		for (port : newType.ports) {
			if (port.helperEquals(originalPort)) {
				return port
			}
		}
		throw new IllegalStateException("Not found port: " + originalPort)
	}
	
	// Component instance references
	
	def getNewSimpleInstances(Component newType) {
		return newType.allSimpleInstances
	}
	
	def getNewSimpleInstances(Collection<ComponentInstanceReference> includedOriginalInstances,
			Collection<ComponentInstanceReference> excludedOriginalInstances, Component newType) {
		val newInstances = newArrayList
		if (includedOriginalInstances.empty) {
			// If it is empty, it means all simple instances must be covered
			newInstances += newType.getNewSimpleInstances
		}
		// The semantics is defined here: including has priority over excluding
		newInstances -= excludedOriginalInstances.getNewSimpleInstances(newType)
		newInstances += includedOriginalInstances.getNewSimpleInstances(newType)
		return newInstances
	}
	
	def getNewSimpleInstance(ComponentInstanceReference originalInstance, Component newType) {
		return #[originalInstance].getNewSimpleInstances(newType).head
	}
	
	def getNewSimpleInstances(Collection<ComponentInstanceReference> originalInstances, Component newType) {
		val newInstances = newType.allSimpleInstances
		val accpedtedNewInstances = newArrayList
		for (newInstance : newInstances) {
			if (originalInstances.exists[it.contains(newInstance)]) {
				accpedtedNewInstances += newInstance
			}
		}
		return accpedtedNewInstances
	}
	
	def getNewAsynchronousSimpleInstances(ComponentInstanceReference original, Component newType) {
		return newType.allAsynchronousSimpleInstances.filter[original.contains(it)].toList
	}
	
	def contains(ComponentInstanceReference original, ComponentInstance copy) {
		val originalInstances = original.componentInstanceHierarchy
		val copyInstances = copy.parentComponentInstances
		copyInstances += copy
		// The naming conventions are clear
		// Without originalInstances.head.name == copyInstances.head.name ambiguous naming situations could occur
		return originalInstances.head.name == copyInstances.head.name &&
			copy.name.startsWith(originalInstances.FQN)
	}
	
}