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

import hu.bme.mit.gamma.statechart.lowlevel.model.ChoiceState
import hu.bme.mit.gamma.statechart.lowlevel.model.EntryState
import hu.bme.mit.gamma.statechart.lowlevel.model.ForkState
import hu.bme.mit.gamma.statechart.lowlevel.model.InitialState
import hu.bme.mit.gamma.statechart.lowlevel.model.PseudoState
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.statechart.lowlevel.model.Transition
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import hu.bme.mit.gamma.xsts.model.XSTS

class RegionInitialStateLocator {
	// Auxiliary objects: derived classes of TerminalTransitionToXTransitionTransformer
	protected final extension SingleInitialStateLocator singleInitialStateLocator
	protected final extension RecursiveInitialStateLocator recursiveInitialStateLocator
	
	new(ViatraQueryEngine engine, Trace trace, XSTS xSts, RegionActivator regionActivator) {
		this.singleInitialStateLocator = new SingleInitialStateLocator(engine, trace, xSts, regionActivator)
		this.recursiveInitialStateLocator = new RecursiveInitialStateLocator(engine, trace, xSts, regionActivator)
	}
		
	protected def createSingleXStsInitialStateSettingAction(EntryState lowlevelEntry) {
		return singleInitialStateLocator.transformForward(lowlevelEntry)
	}
	
	protected def createRecursiveXStsStateAndSubstateActivatingAction(InitialState lowlevelInitialState) {
		return recursiveInitialStateLocator.transformForward(lowlevelInitialState)
	}
	
	static class SingleInitialStateLocator extends TerminalTransitionToXTransitionTransformer {
	
		new(ViatraQueryEngine engine, Trace trace, XSTS xSts, RegionActivator regionActivator) {
			super(engine, trace, xSts, regionActivator)
		}
		
		// Only single region activation, no entry actions, no orthogonality
		
		protected def createSingleXStsForwardNodeConnection(PseudoState lowlevelPseudoState,
				Transition lowlevelTransition, State lowlevelTarget) {
			return createSequentialAction => [
				it.actions += lowlevelTransition.action.transformAction
				it.actions += lowlevelTarget.createSingleXStsStateSettingAction
			]
		}
		
		protected def dispatch createRecursiveXStsForwardNodeConnection(EntryState lowlevelEntryState,
				Transition lowlevelTransition, State lowlevelTarget) {
			return lowlevelEntryState.createSingleXStsForwardNodeConnection(lowlevelTransition, lowlevelTarget)
		}
		
		protected override dispatch createRecursiveXStsForwardNodeConnection(ChoiceState lowlevelChoice,
				Transition lowlevelTransition, State lowlevelTarget) {
			return lowlevelChoice.createSingleXStsForwardNodeConnection(lowlevelTransition, lowlevelTarget)
		}
		
		protected override dispatch createRecursiveXStsForwardNodeConnection(ForkState lowlevelFork,
				Transition lowlevelTransition, State lowlevelTarget) {
			return lowlevelFork.createSingleXStsForwardNodeConnection(lowlevelTransition, lowlevelTarget)
		}
		
	}
	
	static class RecursiveInitialStateLocator extends TerminalTransitionToXTransitionTransformer {
	
		new(ViatraQueryEngine engine, Trace trace, XSTS xSts, RegionActivator regionActivator) {
			super(engine, trace, xSts, regionActivator)  
		}
		
		// Only recursive region activation, no entry actions, no orthogonality
		
		protected def createSimpleRecursiveXStsForwardNodeConnection(PseudoState lowlevelPseudoState,
				Transition lowlevelTransition, State lowlevelTarget) {
			return createSequentialAction => [
				it.actions += lowlevelTransition.action.transformAction
				it.actions += lowlevelTarget.createRecursiveXStsStateAndSubstateActivatingAction
			]
		}
		
		protected def dispatch createRecursiveXStsForwardNodeConnection(EntryState lowlevelEntryState,
				Transition lowlevelTransition, State lowlevelTarget) {
			return lowlevelEntryState.createSimpleRecursiveXStsForwardNodeConnection(lowlevelTransition, lowlevelTarget)
		}
		
		protected override dispatch createRecursiveXStsForwardNodeConnection(ChoiceState lowlevelChoiceState,
				Transition lowlevelTransition, State lowlevelTarget) {
			return lowlevelChoiceState.createSimpleRecursiveXStsForwardNodeConnection(lowlevelTransition, lowlevelTarget)
		}
		
		protected override dispatch createRecursiveXStsForwardNodeConnection(ForkState lowlevelForkState,
				Transition lowlevelTransition, State lowlevelTarget) {
			return lowlevelForkState.createSimpleRecursiveXStsForwardNodeConnection(lowlevelTransition, lowlevelTarget)
		}
		
	}
	
}