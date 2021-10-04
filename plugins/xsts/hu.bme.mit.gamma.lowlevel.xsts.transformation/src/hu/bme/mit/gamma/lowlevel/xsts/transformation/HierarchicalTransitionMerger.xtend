package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Statecharts
import hu.bme.mit.gamma.statechart.lowlevel.model.ChoiceState
import hu.bme.mit.gamma.statechart.lowlevel.model.ForkState
import hu.bme.mit.gamma.statechart.lowlevel.model.GuardEvaluation
import hu.bme.mit.gamma.statechart.lowlevel.model.JoinState
import hu.bme.mit.gamma.statechart.lowlevel.model.MergeState
import hu.bme.mit.gamma.statechart.lowlevel.model.Region
import hu.bme.mit.gamma.statechart.lowlevel.model.SchedulingOrder
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.XTransition
import java.util.Comparator
import java.util.List
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension java.lang.Math.abs

class HierarchicalTransitionMerger extends AbstractTransitionMerger {
	
	// Guard extraction is not yet supported
	
	new(ViatraQueryEngine engine, Trace trace, boolean extractGuards) {
		// Conflict and priority encoding are unnecessary
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
		
		val regionGroups = (statechart.schedulingOrder == SchedulingOrder.TOP_DOWN) ?
			statechart.topDownRegionGroups : statechart.bottomUpRegionGroups
		
		var ifAction = createIfAction
		
		for (regionGroup : regionGroups) {
			if (regionGroup.size > 1) {
				// Orthogonal regions
				val parallelAction = createParallelAction => [
					
				]
			}
			else {
				// Simple region
				val lowlevelRegion = regionGroup.head
				val xStsRegionBehavior = lowlevelRegion.mergeTransitionsOfRegion
			}
		}
		
		val xStsMergedAction = ifAction
		// The many transitions are now replaced by a single merged transition
		xSts.changeTransitions(xStsMergedAction.wrap)
	}
	
	private def mergeTransitionsOfRegion(Region lowlevelRegion) {
		val xStsTransitions =  <Integer, List<XTransition>>newTreeMap(
			new Comparator<Integer>() {
				override compare(Integer l, Integer r) {
					return r.compareTo(l) // Higher value means higher priority
				}
			}
		)
		
		val lowlevelStates = lowlevelRegion.states
		val hasDifferentPriorities = lowlevelStates.exists[
				it.outgoingTransitions.hasDifferentPriorities]
				
		// Simple outgoing transitions
		for (lowlevelState : lowlevelStates) {
			val lowlevelOutgoingTransitions = lowlevelState.outgoingTransitions
			for (lowlevelOutgoingTransition : lowlevelOutgoingTransitions
						.filter[trace.isTraced(it)] /* Simple transitions */ ) {
				val priority = lowlevelOutgoingTransition.priority
				val xTransitionList = xStsTransitions.getOrCreateList(priority)
				xTransitionList += trace.getXStsTransition(lowlevelOutgoingTransition)
			}
		}
		// Complex transitions
		for (lastJoinState : lowlevelRegion.stateNodes.filter(JoinState).filter[it.isLastJoinState]) {
			val priority = lastJoinState.incomingTransitions.map[it.priority].max // Not correct
			val xTransitionList = xStsTransitions.getOrCreateList(priority)
			xTransitionList += trace.getXStsTransition(lastJoinState)
		}
		for (lastMergeState : lowlevelRegion.stateNodes.filter(MergeState).filter[it.isLastMergeState]) {
			throw new IllegalArgumentException("Merge states are not handled")
		}
		for (firstForkState : lowlevelRegion.stateNodes.filter(ForkState).filter[it.isFirstForkState]) {
			val priority = firstForkState.incomingTransitions.map[it.priority].max
			val xTransitionList = xStsTransitions.getOrCreateList(priority)
			xTransitionList += trace.getXStsTransition(firstForkState)
		}
		for (firstChoiceState : lowlevelRegion.stateNodes.filter(ChoiceState).filter[it.isFirstChoiceState]) {
			val priority = firstChoiceState.incomingTransitions.map[it.priority].max
			val xTransitionList = xStsTransitions.getOrCreateList(priority)
			xTransitionList += trace.getXStsTransition(firstChoiceState)
		}
		
		val xStsActions = xStsTransitions.values.flatten.map[it.action]
				.filter(SequentialAction).toList
		if (hasDifferentPriorities) {
			return xStsActions.createChoiceActionWithEmptyDefaultBranch1
			// The default branch must be extended by the caller
		}
		else {
			return xStsActions.createIfAction
			// The last else branch must be extended by the caller
		}
	}
	
	private def handleGuardEvaluations() {
		val statecharts = Statecharts.Matcher.on(engine).allValuesOfstatechart
		checkState(statecharts.size == 1)
		val statechart = statecharts.head
		val guardEvaluation = statechart.guardEvaluation
		if (guardEvaluation == GuardEvaluation.BEGINNING_OF_STEP) {
			val xStsNewMergedAction = createSequentialAction
			val extractableExpressions = newArrayList
			extractableExpressions += trace.getGuards.values.flatten.toList
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