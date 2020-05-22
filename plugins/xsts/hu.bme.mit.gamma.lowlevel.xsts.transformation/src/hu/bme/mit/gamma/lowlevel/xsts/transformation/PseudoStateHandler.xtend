package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.FirstChoiceStates
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.FirstForkStates
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.LastJoinStates
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.LastMergeStates
import hu.bme.mit.gamma.statechart.lowlevel.model.ChoiceState
import hu.bme.mit.gamma.statechart.lowlevel.model.ForkState
import hu.bme.mit.gamma.statechart.lowlevel.model.JoinState
import hu.bme.mit.gamma.statechart.lowlevel.model.MergeState
import hu.bme.mit.gamma.statechart.lowlevel.model.PrecursoryState
import hu.bme.mit.gamma.statechart.lowlevel.model.TerminalState
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

class PseudoStateHandler {
	protected final ViatraQueryEngine engine
	
	
	new(ViatraQueryEngine engine) {
		this.engine = engine
	}
	
	def isLastMergeState(MergeState lowlevelMergeState) {
		return LastMergeStates.Matcher.on(engine).hasMatch(lowlevelMergeState)
	}
	
	def isLastJoinState(JoinState lowlevelJoinState) {
		return LastJoinStates.Matcher.on(engine).hasMatch(lowlevelJoinState)
	}
	
	def isLastPrecursoryState(PrecursoryState lowlevelPrecursoryState) {
		if (lowlevelPrecursoryState instanceof MergeState) {
			return lowlevelPrecursoryState.isLastMergeState
		}
		if (lowlevelPrecursoryState instanceof JoinState) {
			return lowlevelPrecursoryState.isLastJoinState
		}
		throw new IllegalArgumentException("Not known precursory state: " + lowlevelPrecursoryState)
	}
	
	def isFirstChoiceState(ChoiceState lowlevelChoiceState) {
		return FirstChoiceStates.Matcher.on(engine).hasMatch(lowlevelChoiceState)
	}
	
	def isFirstForkState(ForkState lowlevelForkState) {
		return FirstForkStates.Matcher.on(engine).hasMatch(lowlevelForkState)
	}
	
	def isFirstTerminalState(TerminalState lowlevelTerminalState) {
		if (lowlevelTerminalState instanceof ChoiceState) {
			return lowlevelTerminalState.isFirstChoiceState
		}
		if (lowlevelTerminalState instanceof ForkState) {
			return lowlevelTerminalState.isFirstForkState
		}
		throw new IllegalArgumentException("Not known terminal state: " + lowlevelTerminalState)
	}
	
}