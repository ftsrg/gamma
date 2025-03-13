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
package hu.bme.mit.gamma.uppaal.composition.transformation.api.util

import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import java.util.logging.Level

class UnhandledTransitionTransformer {
	// Singleton
	public static final UnhandledTransitionTransformer INSTANCE =  new UnhandledTransitionTransformer
	protected new() {}
	//

	extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	// Logger
	extension Logger logger = Logger.getLogger("GammaLogger")
	
	def execute(StatechartDefinition statechart) {
		val unhandledTransitions = statechart.transitions.filter[it.isToHigherAndLower].toList
		
		for (var i = 0; i < unhandledTransitions.size; i++) {
			val unhandledTransition = unhandledTransitions.get(i)
			val source = unhandledTransition.sourceState
			val target = unhandledTransition.targetState
			log(Level.INFO, "Transforming unhandleable transition " + source.name + " -> " + target.name)
			
			val commonRegions = getCommonRegionAncestors(source, target)
			
			checkState(!commonRegions.empty)
			// In theory, the last element is the "closest" region
			val closestCommonRegion = commonRegions.lastOrNull
			
			val splitterChoice = createChoiceState => [
				it.name = source.name + "_" + target.name + "Splitter"
			]
			
			closestCommonRegion.stateNodes += splitterChoice
			
			statechart.transitions += createTransition => [
				it.sourceState = splitterChoice
				it.targetState = unhandledTransition.targetState
			]
			unhandledTransition.targetState = splitterChoice
		}
	}
	
}
