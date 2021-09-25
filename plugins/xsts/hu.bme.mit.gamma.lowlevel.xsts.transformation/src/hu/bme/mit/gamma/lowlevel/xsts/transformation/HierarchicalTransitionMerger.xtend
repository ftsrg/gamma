package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Statecharts
import hu.bme.mit.gamma.statechart.lowlevel.model.ChoiceState
import hu.bme.mit.gamma.statechart.lowlevel.model.CompositeElement
import hu.bme.mit.gamma.statechart.lowlevel.model.ForkState
import hu.bme.mit.gamma.statechart.lowlevel.model.GuardEvaluation
import hu.bme.mit.gamma.statechart.lowlevel.model.JoinState
import hu.bme.mit.gamma.statechart.lowlevel.model.MergeState
import hu.bme.mit.gamma.statechart.lowlevel.model.Region
import hu.bme.mit.gamma.statechart.lowlevel.model.State
import hu.bme.mit.gamma.xsts.model.AssumeAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension java.lang.Math.abs

class HierarchicalTransitionMerger extends AbstractTransitionMerger {
	
	// Guard extraction is not yet supported
	
	new(ViatraQueryEngine engine, Trace trace, boolean extractGuards) {
		super(engine, trace, extractGuards)
	}
	
	override mergeTransitions() {
		internalMergeTransitions
		handleGuardEvaluations
	}
	
	private def internalMergeTransitions() {
		val statecharts = Statecharts.Matcher.on(engine).allValuesOfstatechart
		checkState(statecharts.size == 1)
		val statechart = statecharts.head
		val xStsMergedAction = createNonDeterministicAction
		statechart.mergeTransitions(xStsMergedAction)
		// The many transitions are now replaced by a single merged transition
		xSts.changeTransitions(xStsMergedAction.wrap)
		// Adding default else branch: if "region" cannot fire
		xStsMergedAction.extendChoiceWithDefaultBranch(createEmptyAction)
		// For this to work, each assume action has to be at index 0 of the containing composite action
	}
	
	protected def void mergeTransitions(CompositeElement lowlevelComposite, NonDeterministicAction xStsAction) {
		val lowlevelRegions = lowlevelComposite.regions
		if (lowlevelRegions.size > 1) {
			val xStsSequentialAction = createSequentialAction
			xStsAction.actions += xStsSequentialAction
			val orExpression = createOrExpression // This parallel action can fire only if one of its regions can fire
			val xStsAssumeAction = createAssumeAction // Cannot be deleted, see: if (a || b) { if (a) if (!a) if (b) if (!b) } if (!(a || b))
			xStsAssumeAction.assumption = orExpression
			xStsSequentialAction.actions += xStsAssumeAction
			val xStsParallelAction = createParallelAction
			xStsSequentialAction.actions += xStsParallelAction
			for (lowlevelRegion : lowlevelRegions) {
				val xStsSubchoiceAction = createNonDeterministicAction
				xStsParallelAction.actions += xStsSubchoiceAction
				lowlevelRegion.mergeTransitionsOfRegion(xStsSubchoiceAction)
				// Adding default else branch: if "region" cannot fire
				val xStsPrecondition = xStsSubchoiceAction.precondition
				if (xStsPrecondition !== null) { // Can be null if the region has no transitions
					orExpression.operands += xStsPrecondition
					xStsSubchoiceAction.extendChoiceWithDefaultBranch(createEmptyAction)
				}
				// For this to work, each assume action has to be at index 0 of the containing composite action
			}
		} else if (lowlevelRegions.size == 1) {
			lowlevelRegions.head.mergeTransitionsOfRegion(xStsAction)
		}
	}
	
	private def void mergeTransitionsOfRegion(Region lowlevelRegion, NonDeterministicAction xStsAction) {
		val xStsTransitions = newHashSet
		val lowlevelStates = lowlevelRegion.stateNodes.filter(State)
		// Simple outgoing transitions
		for (lowlevelState : lowlevelStates) {
			for (lowlevelOutgoingTransition : lowlevelState.outgoingTransitions
					.filter[trace.isTraced(it)] /* Simple transitions */ ) {
				xStsTransitions += trace.getXStsTransition(lowlevelOutgoingTransition)
			}
			if (lowlevelState.isComposite) {
				// Recursion
				lowlevelState.mergeTransitions(xStsAction)
			}
		}
		// Complex transitions
		for (lastJoinState : lowlevelRegion.stateNodes.filter(JoinState).filter[it.isLastJoinState]) {
			xStsTransitions += trace.getXStsTransition(lastJoinState)
		}
		for (lastMergeState : lowlevelRegion.stateNodes.filter(MergeState).filter[it.isLastMergeState]) {
			xStsTransitions += trace.getXStsTransition(lastMergeState)
		}
		for (lastForkState : lowlevelRegion.stateNodes.filter(ForkState).filter[it.isFirstForkState]) {
			xStsTransitions += trace.getXStsTransition(lastForkState)
		}
		for (lastChoiceState : lowlevelRegion.stateNodes.filter(ChoiceState).filter[it.isFirstChoiceState]) {
			xStsTransitions += trace.getXStsTransition(lastChoiceState)
		}
		for (xStsTransition : xStsTransitions) {
			xStsAction.actions += xStsTransition.action
		}
	}
	
	private def handleGuardEvaluations() {
		val statecharts = Statecharts.Matcher.on(engine).allValuesOfstatechart
		checkState(statecharts.size == 1)
		val statechart = statecharts.head
		val guardEvaluation = statechart.guardEvaluation
		if (guardEvaluation == GuardEvaluation.BEGINNING_OF_STEP) {
			val xStsNewMergedAction = createSequentialAction
			// The trace.getGuards method is not correct as guard expressions for parallel actions and else guard expressions are not traced
			val extractableExpressions = newArrayList
			extractableExpressions += xSts.mergedAction.getAllContentsOfType(AssumeAction).map[it.assumption]
			extractableExpressions -= trace.getChoiceGuards.values.flatten.toList
			
			for (extractableExpression : extractableExpressions) {
				val name = "_" + extractableExpression.hashCode.abs
				xStsNewMergedAction.actions += createBooleanTypeDefinition.extractExpression(name, extractableExpression)
			}
			
			xStsNewMergedAction.actions += xSts.mergedAction
			
			xSts.changeTransitions(xStsNewMergedAction.wrap)
		}
	}
	
}