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
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.interface_.Component
import java.util.Collection

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.transformation.util.Namings.*

class SimpleInstanceHandler {
	// Singleton
	public static final SimpleInstanceHandler INSTANCE =  new SimpleInstanceHandler
	protected new() {}
	//
	
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