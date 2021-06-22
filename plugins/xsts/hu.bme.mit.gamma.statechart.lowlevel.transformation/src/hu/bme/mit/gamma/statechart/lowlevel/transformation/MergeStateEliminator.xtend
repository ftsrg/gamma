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
				val incomingTransitions = terminalState.incomingTransitions
				val size = incomingTransitions.size
				val outgoingTransitions = terminalState.outgoingTransitions
				
				for (var i = 1; i < size; i++) { // A transition remains targeted to the original choice or fork
					val incomingTransition = incomingTransitions.get(i)
					val newChoice = terminalState.clone
					newChoice.name = newChoice.name + i // To avoid name duplication
					incomingTransition.targetState = newChoice
					
					for (newOutGoingTransition : outgoingTransitions.clone) {
						newOutGoingTransition.sourceState = newChoice
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