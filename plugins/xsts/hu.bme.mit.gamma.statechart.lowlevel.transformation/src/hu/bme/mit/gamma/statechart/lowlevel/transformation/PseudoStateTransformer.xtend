package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartModelFactory
import hu.bme.mit.gamma.statechart.model.ChoiceState
import hu.bme.mit.gamma.statechart.model.DeepHistoryState
import hu.bme.mit.gamma.statechart.model.ForkState
import hu.bme.mit.gamma.statechart.model.InitialState
import hu.bme.mit.gamma.statechart.model.JoinState
import hu.bme.mit.gamma.statechart.model.MergeState
import hu.bme.mit.gamma.statechart.model.ShallowHistoryState

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class PseudoStateTransformer {
	// Low-level statechart model factory
	protected final extension StatechartModelFactory factory = StatechartModelFactory.eINSTANCE
	// Trace object for storing the mappings
	protected final Trace trace
	
	new(Trace trace) {
		this.trace = trace
	}
	
	protected def dispatch transformPseudoState(MergeState node) {
		val incomingTransitions = node.incomingTransitions
		val outgoingTransitions = node.outgoingTransitions
		checkArgument(incomingTransitions.size >= 1)
		checkArgument(outgoingTransitions.size == 1)
		val lowlevelMerge = createMergeState => [
			it.name = node.name
		]
		trace.put(node, lowlevelMerge) // Tracing the node
		return lowlevelMerge
	}
	
	protected def dispatch transformPseudoState(JoinState node) {
		val incomingTransitions = node.incomingTransitions
		val outgoingTransitions = node.outgoingTransitions
		checkArgument(incomingTransitions.size >= 1)
		checkArgument(outgoingTransitions.size == 1)
		val lowlevelJoin = createJoinState => [
			it.name = node.name
		]
		trace.put(node, lowlevelJoin) // Tracing the node
		return lowlevelJoin
	}
	
	protected def dispatch transformPseudoState(ChoiceState node) {
		val incomingTransitions = node.incomingTransitions
		val outgoingTransitions = node.outgoingTransitions
		checkArgument(incomingTransitions.size == 1)
		checkArgument(outgoingTransitions.size >= 1)
		val lowlevelChoice = createChoiceState => [
			it.name = node.name
		]
		trace.put(node, lowlevelChoice) // Tracing the node
		return lowlevelChoice
	}
	
	protected def dispatch transformPseudoState(ForkState node) {
		val incomingTransitions = node.incomingTransitions
		val outgoingTransitions = node.outgoingTransitions
		checkArgument(incomingTransitions.size == 1)
		checkArgument(outgoingTransitions.size >= 1)
		val lowlevelFork = createForkState => [
			it.name = node.name
		]
		trace.put(node, lowlevelFork) // Tracing the node
		return lowlevelFork
	}
	
		protected def dispatch transformPseudoState(InitialState node) {
		val outgoingTransitions = node.outgoingTransitions
		checkArgument(outgoingTransitions.size == 1)
		val lowlevelInitialState = createInitialState => [
			it.name = node.name
		]
		trace.put(node, lowlevelInitialState)
		return lowlevelInitialState
	}

	protected def dispatch transformPseudoState(ShallowHistoryState node) {
		val outgoingTransitions = node.outgoingTransitions
		checkArgument(outgoingTransitions.size == 1)
		val lowlevelHistoryState = createShallowHistoryState => [
			it.name = node.name
		]
		trace.put(node, lowlevelHistoryState)
		return lowlevelHistoryState
	}

	protected def dispatch transformPseudoState(DeepHistoryState node) {
		val outgoingTransitions = node.outgoingTransitions
		checkArgument(outgoingTransitions.size == 1)
		val lowlevelHistoryState = createDeepHistoryState => [
			it.name = node.name
		]
		trace.put(node, lowlevelHistoryState)
		return lowlevelHistoryState
	}
	
}