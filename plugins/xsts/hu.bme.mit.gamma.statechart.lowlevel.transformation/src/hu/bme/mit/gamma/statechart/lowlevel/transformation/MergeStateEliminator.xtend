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
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.ForkState
import hu.bme.mit.gamma.statechart.statechart.MergeState
import hu.bme.mit.gamma.statechart.statechart.PseudoState
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static com.google.common.base.Preconditions.checkState

import static extension com.google.common.collect.Iterables.getOnlyElement
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class MergeStateEliminator {
	
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	
	protected final StatechartDefinition statechart
	
	new(StatechartDefinition statechart) {
		this.statechart = statechart
	}
	
	def execute() {
		eliminateMergeStates
		handleTerminalStatesWithMoreIncomingTransitions
	}
	
	protected def eliminateMergeStates() {
		for (merge : statechart.getAllContentsOfType(MergeState)) {
			val outgoingTransitions = merge.outgoingTransitions
			val outgoingTransition = outgoingTransitions.onlyElement
			checkState(outgoingTransition.trigger === null && outgoingTransition.guard === null)
			
			val target = outgoingTransition.targetState
			for (incomingTransition : merge.incomingTransitions) {
				incomingTransition.effects += outgoingTransition.effects.clone
				incomingTransition.targetState = target
			}
			merge.remove
			outgoingTransition.remove
		}
	}
	
	protected def handleTerminalStatesWithMoreIncomingTransitions() {
		var duplicatableTerminalStates = getDuplicatableTerminalStates
		while (!duplicatableTerminalStates.empty) {
			for (terminalState : duplicatableTerminalStates) {
				val region = terminalState.parentRegion
				val incomingTransitions = terminalState.incomingTransitions
				val size = incomingTransitions.size
				val outgoingTransitions = terminalState.outgoingTransitions
				
				for (var i = 1; i < size; i++) { // A transition remains targeted to the original choice or fork
					val incomingTransition = incomingTransitions.get(i)
					
					val newTerminalState = terminalState.clone
					newTerminalState.name = newTerminalState.name + i // To avoid name duplication
					region.stateNodes += newTerminalState
					
					incomingTransition.targetState = newTerminalState
					
					for (newOutGoingTransition : outgoingTransitions.clone) {
						statechart.transitions += newOutGoingTransition
						newOutGoingTransition.sourceState = newTerminalState
					}
				}
			}
			duplicatableTerminalStates = getDuplicatableTerminalStates
		}
	}
	
	protected def getDuplicatableTerminalStates() {
		return statechart.getAllContentsOfType(PseudoState)
				.filter[it instanceof ChoiceState || it instanceof ForkState]
				.filter[it.incomingTransitions.size > 1]
	}
	
}