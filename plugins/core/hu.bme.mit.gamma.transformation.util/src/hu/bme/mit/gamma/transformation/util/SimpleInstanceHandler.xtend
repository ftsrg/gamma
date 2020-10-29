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

import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstancePortReference
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port
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
	
	// Component instance port references
	
	def getNewIncludedSimpleInstancePorts(Collection<ComponentInstancePortReference> includedOriginalReferences,
			Collection<ComponentInstancePortReference> excludedOriginalReferences, Component newType) {
		val newPorts = newArrayList
		newPorts += includedOriginalReferences.getNewSimpleInstancePorts(newType)
		newPorts -= excludedOriginalReferences.getNewSimpleInstancePorts(newType)
		return newPorts
	}
	
	def getNewSimpleInstancePorts(
			Collection<ComponentInstancePortReference> originalReferences, Component newType) {
		val newPorts = newArrayList
		for (originalReference : originalReferences) {
			val originalInstance = originalReference.componentInstance
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
		// Include - exclude
		val newInstances = newArrayList
		if (includedOriginalInstances.empty) {
			// If it is empty, it means all simple instances must be covered
			newInstances += newType.getNewSimpleInstances
		}
		else {
			newInstances += includedOriginalInstances.getNewSimpleInstances(newType)
		}
		newInstances -= excludedOriginalInstances.getNewSimpleInstances(newType)
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
	
	private def contains(ComponentInstanceReference original, ComponentInstance copy) {
		val originalInstances = original.componentInstanceHierarchy
		val copyInstances = copy.parentComponentInstances
		copyInstances += copy
		// The naming conventions are clear
		// Without originalInstances.head.name == copyInstances.head.name ambiguous naming situations could occur
		return originalInstances.head.name == copyInstances.head.name &&
			copy.name.startsWith(originalInstances.FQN)
	}
	
}