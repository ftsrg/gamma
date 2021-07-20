/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
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
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class Namings {
	
	def static String getFQN(List<ComponentInstance> instances) '''«FOR instance : instances SEPARATOR '_'»«instance.name»«ENDFOR»'''
	def static String getFQN(ComponentInstanceReference instance) '''«instance.componentInstanceHierarchy.FQN»'''
	def static String getFQN(ComponentInstance instance) '''«instance.componentInstanceChain.FQN»'''
	
}