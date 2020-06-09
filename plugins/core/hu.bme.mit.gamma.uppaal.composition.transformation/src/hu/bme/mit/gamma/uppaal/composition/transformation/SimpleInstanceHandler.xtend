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

import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import java.util.Collection

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class SimpleInstanceHandler {
	
	def getNewSimpleInstances(Component newType) {
		return newType.allSimpleInstances
	}
	
	def getNewSimpleInstances(Collection<? extends ComponentInstance> includedOriginalInstances,
			Collection<? extends ComponentInstance> excludedOriginalInstances, Component newType) {
		// Include - exclude
		val oldInstances = newArrayList
		oldInstances += includedOriginalInstances.getNewSimpleInstances(newType)
		oldInstances -= excludedOriginalInstances.getNewSimpleInstances(newType)
		return oldInstances
	}
	
	def getNewSimpleInstances(Collection<? extends ComponentInstance> originalInstances, Component newType) {
		val oldInstances = originalInstances.allSimpleInstances
		val newInstances = newType.allSimpleInstances
		val accpedtedNewInstances = newArrayList
		for (newInstance : newInstances) {
			if (oldInstances.exists[it.instanceEquals(newInstance)]) {
				accpedtedNewInstances += newInstance
			}
		}
		return accpedtedNewInstances
	}
	
	def getNewAsynchronousSimpleInstances(AsynchronousComponentInstance original, Component newType) {
		return newType.allAsynchronousSimpleInstances
			.filter[original.instanceEquals(it)].toList
	}
	
	private def instanceEquals(ComponentInstance original, ComponentInstance copy) {
		// TODO better equality check (helper equals does not work as the original statecharts have been optimized)
		return copy.name == original.name /* Flat composite */ ||
			copy.name.endsWith("_" + original.name) /* Hierarchical composite */
	}
	
}