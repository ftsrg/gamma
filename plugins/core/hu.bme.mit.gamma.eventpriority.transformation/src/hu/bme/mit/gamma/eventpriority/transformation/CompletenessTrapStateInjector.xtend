/********************************************************************************
 * Copyright (c) 2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.eventpriority.transformation

import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.statechart.IncompleteStatechartAnnotation
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.statechart.util.TriggerTransformer
import java.math.BigInteger
import java.util.Map

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class CompletenessTrapStateInjector {
	
	protected final StatechartDefinition statechart
	
	protected final Map<Region, State> trapStates = newHashMap
	
	protected final extension TriggerTransformer triggerTransformer = TriggerTransformer.INSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE;
	protected final extension StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE;
	
	
	new(StatechartDefinition statechart) {
		this.statechart = statechart
	}
	
	def execute() {
		if (!statechart.hasAnnotation(IncompleteStatechartAnnotation)) {
			return
		}
		
		val states = statechart.allStates
		for (state : states) {
			val parentRegion = state.parentRegion
			
			val outgoingTransitions = state.outgoingTransitions
			val lowestPriority = (outgoingTransitions.empty) ?
					BigInteger.ZERO :
					outgoingTransitions.map[it.priority].min
			val priority = lowestPriority.subtract(BigInteger.ONE)
			
			val trapState = parentRegion.getOrCreateTrapState
			trapState.annotations += createCoverageAvoidanceAnnotation
			
			val trapTransition = state.createTransition(trapState)
			trapTransition.annotations += createCoverageAvoidanceAnnotation
			trapTransition.priority = priority
			
			if (statechart.transitionPriority != TransitionPriority.OFF) {
				trapTransition.trigger = createAnyTrigger
			}
			else {
				val defaultGuard = outgoingTransitions.createDefaultGuard
				trapTransition.trigger = createOnCycleTrigger
				trapTransition.guard = defaultGuard
			}
		}
	}
	
	//
	
	protected def getOrCreateTrapState(Region region) {
		if (!trapStates.containsKey(region)) {
			val name = "_TrapState_" + region.name + "_" // TODO extract
			val trapState = region.createState(name)
			trapStates += region -> trapState
		}
		val trapState = trapStates.get(region)
		return trapState
	}
	
}