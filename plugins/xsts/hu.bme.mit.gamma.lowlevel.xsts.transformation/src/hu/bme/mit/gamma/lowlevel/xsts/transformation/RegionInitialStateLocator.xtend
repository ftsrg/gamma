package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.statechart.lowlevel.model.ChoiceState
import hu.bme.mit.gamma.statechart.lowlevel.model.EntryState
import hu.bme.mit.gamma.statechart.lowlevel.model.ForkState
import hu.bme.mit.gamma.statechart.lowlevel.model.InitialState
import hu.bme.mit.gamma.statechart.lowlevel.model.PseudoState
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.statechart.lowlevel.model.Transition
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

class RegionInitialStateLocator {
	// Auxiliary objects: derived classes of TerminalTransitionToXTransitionTransformer
	protected final extension SingleInitialStateLocator singleInitialStateLocator
	protected final extension RecursiveInitialStateLocator recursiveInitialStateLocator
	
	new(ViatraQueryEngine engine, Trace trace, RegionActivator regionActivator) {
		this.singleInitialStateLocator = new SingleInitialStateLocator(engine, trace, regionActivator)
		this.recursiveInitialStateLocator = new RecursiveInitialStateLocator(engine, trace, regionActivator)
	}
		
	protected def createSingleXStsInitialStateSettingAction(EntryState lowlevelEntry) {
		return singleInitialStateLocator.transformForward(lowlevelEntry)
	}
	
	protected def createRecursiveXStsStateAndSubstateActivatingAction(InitialState lowlevelInitialState) {
		return recursiveInitialStateLocator.transformForward(lowlevelInitialState)
	}
	
	static class SingleInitialStateLocator extends TerminalTransitionToXTransitionTransformer {
	
		new(ViatraQueryEngine engine, Trace trace, RegionActivator regionActivator) {
			super(engine, trace, regionActivator)
		}
		
		// Only single region activation, no entry actions, no orthogonality
		
		protected def createSingleXStsForwardNodeConnection(PseudoState lowlevelPseudoState,
				Transition lowlevelTransition, State lowlevelTarget) {
			return createSequentialAction => [
				it.actions += lowlevelTransition.action.transformAction
				it.actions += lowlevelTarget.createSingleXStsStateSettingAction
			]
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
	
		new(ViatraQueryEngine engine, Trace trace, RegionActivator regionActivator) {
			super(engine, trace, regionActivator)  
		}
		
		// Only recursive region activation, no entry actions, no orthogonality
		
		protected def createSimpleRecursiveXStsForwardNodeConnection(PseudoState lowlevelPseudoState,
				Transition lowlevelTransition, State lowlevelTarget) {
			return createSequentialAction => [
				it.actions += lowlevelTransition.action.transformAction
				it.actions += lowlevelTarget.createRecursiveXStsStateAndSubstateActivatingAction
			]
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