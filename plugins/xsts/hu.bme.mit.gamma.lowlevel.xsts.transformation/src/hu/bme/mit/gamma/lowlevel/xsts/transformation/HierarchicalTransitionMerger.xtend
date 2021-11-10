package hu.bme.mit.gamma.lowlevel.xsts.transformation

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.lowlevel.xsts.transformation.patterns.Statecharts
import hu.bme.mit.gamma.statechart.lowlevel.model.ChoiceState
import hu.bme.mit.gamma.statechart.lowlevel.model.CompositeElement
import hu.bme.mit.gamma.statechart.lowlevel.model.ForkState
import hu.bme.mit.gamma.statechart.lowlevel.model.GuardEvaluation
import hu.bme.mit.gamma.statechart.lowlevel.model.JoinState
import hu.bme.mit.gamma.statechart.lowlevel.model.MergeState
import hu.bme.mit.gamma.statechart.lowlevel.model.Region
import hu.bme.mit.gamma.statechart.lowlevel.model.SchedulingOrder
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.IfAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.XTransition
import java.util.Comparator
import java.util.List
import java.util.Map
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.lowlevel.derivedfeatures.LowlevelStatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*
import static extension java.lang.Math.abs

class HierarchicalTransitionMerger extends AbstractTransitionMerger {
	
	new(ViatraQueryEngine engine, Trace trace) {
		// Conflict and priority encoding are unnecessary
		super(engine, trace)
	}
	
	override mergeTransitions() {
		internalMergeTransitions
		handleGuardEvaluations
	}
	
	private def internalMergeTransitions() {
		val statecharts = Statecharts.Matcher.on(engine).allValuesOfstatechart
		checkState(statecharts.size == 1)
		val statechart = statecharts.head
		
		val lowlevelRegions = statechart.allRegions
		val regionActions = newHashMap
		for (lowlevelRegion : lowlevelRegions) {
			val xStsAction = lowlevelRegion.mergeTransitionsOfRegion // If or NonDet
			regionActions += lowlevelRegion -> xStsAction
		}
		
		val xStsMergedAction = statechart.mergeAllTransitionsOfRegion(regionActions)
		// The many transitions are now replaced by a single merged transition
		xSts.changeTransitions(xStsMergedAction.wrap)
	}
	
	private def Action mergeAllTransitionsOfRegion(CompositeElement element,
			Map<Region, Action> regionActions) {
		val lowlevelRegions = element.regions
		
		if (lowlevelRegions.empty) {
			return createEmptyAction
		}
		if (lowlevelRegions.size == 1) {
			val lowlevelRegion = lowlevelRegions.head
			return lowlevelRegion.mergeAllTransitionsOfRegion(regionActions)
		}
		else {
			val xStsSequentialAction = createSequentialAction
			
			val xStsExecutedVariableAction = createBooleanTypeDefinition
					.createVariableDeclarationAction('''isExec_«element.hashCode.abs»''',
						createFalseExpression)
			val xStsExecutedVariable = xStsExecutedVariableAction.variableDeclaration
			xStsSequentialAction.actions += xStsExecutedVariableAction
			
			val xStsParallelAction = createParallelAction
			xStsSequentialAction.actions += xStsParallelAction
			
			for (lowlevelRegion : lowlevelRegions) {
				for (Region subregion : lowlevelRegion.selfAndAllRegions) {
					val xStsSubregionAction = regionActions.get(subregion)
					xStsSubregionAction.injectExecutedVariableAnnotation(xStsExecutedVariable)
				}
				xStsParallelAction.actions += lowlevelRegion.mergeAllTransitionsOfRegion(regionActions)
			}
			xStsSequentialAction.actions += xStsExecutedVariable.createReferenceExpression
					.createNotExpression.createIfAction(createEmptyAction)
					
			return xStsSequentialAction
		}
		
	}
	
	private def Action mergeAllTransitionsOfRegion(Region region,
			Map<Region, Action> regionActions) {
		val lowlevelStatechart = region.statechart
		val lowlevelSchedulingOrder = lowlevelStatechart.schedulingOrder
		
		var Action firstXStsAction = null
		var Action lastXStsAction = null
		
		val lowlevelCompositeStates = region.states.filter[it.composite]
		for (lowlevelCompositeState : lowlevelCompositeStates) {
			val xStsStateAction = lowlevelCompositeState.mergeAllTransitionsOfRegion(regionActions)
			if (lastXStsAction === null) {
				firstXStsAction = xStsStateAction
				lastXStsAction = xStsStateAction
			}
			else {
				lastXStsAction.extendElse(xStsStateAction)
				lastXStsAction = xStsStateAction
			}
		}
		
		val xStsRegionAction = regionActions.get(region)
		if (firstXStsAction === null) {
			return xStsRegionAction
		}
		if (lowlevelSchedulingOrder == SchedulingOrder.TOP_DOWN) {
			xStsRegionAction.extendElse(firstXStsAction)
			return xStsRegionAction
		}
		else {
			lastXStsAction.extendElse(xStsRegionAction)
			return firstXStsAction
		}
	}
	
	private def mergeTransitionsOfRegion(Region lowlevelRegion) {
		val xStsTransitions = <Integer, List<XTransition>>newTreeMap(
			new Comparator<Integer>() {
				override compare(Integer l, Integer r) {
					return r.compareTo(l) // Higher value means higher priority
				}
			}
		)
		
		val lowlevelStates = lowlevelRegion.states
		val arePrioritiesUnique = lowlevelStates.forall[
				it.outgoingTransitions.arePrioritiesUnique]
				
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
		if (xStsActions.empty) {
			return createEmptyAction
		}
		else if (arePrioritiesUnique) {
			return xStsActions.createIfAction
			// The last else branch must be extended by the caller
		}
		else {
			return xStsActions.createChoiceAction
			// The default branch must be extended by the caller
		}
	}
	
	private def injectExecutedVariableAnnotation(Action action, VariableDeclaration execVariable) {
		val execSetting = execVariable.createAssignmentAction(createTrueExpression)
		if (action instanceof IfAction) {
			val ifActions = action.getSelfAndAllContentsOfType(IfAction)
			for (ifAction : ifActions) {
				val then = ifAction.then
				then.appendToAction(execSetting)
			}
		}
		else if (action instanceof NonDeterministicAction) {
			for (branch : action.actions) {
				branch.appendToAction(execSetting)
			}
		}
		else {
			throw new IllegalArgumentException("Not known action: " + action)
		}
	}
	
	private def void extendElse(Action extendable, Action action) {
		// Extendable is either an If, NonDet or a Sequential with an If at the end
		// See mergeAllTransitionsOfRegion(CompositeElement element...
		if (extendable instanceof IfAction) {
			extendable.append(action) // See the referenced method
		}
		else if (extendable instanceof NonDeterministicAction) {
			extendable.extendChoiceWithDefaultBranch(action)
			// Can the same NonDeterministicAction be extended multiple times?
		}
		else if (extendable instanceof SequentialAction) {
			val lastAction = extendable.actions.last
			val ifAction = lastAction as IfAction
			val thenAction = ifAction.then // See the referenced method
			// thenAction is EmptyAction the first time it is referenced, however,
			// the same SequentialAction can be extended multiple times, hence this logic
			// (see Procedure_Executive_and_Analysis model for an example)
			if (thenAction.nullOrEmptyAction) {
				ifAction.then = action
			}
			else {
				thenAction.extendElse(action)
			}
		}
		else {
			throw new IllegalArgumentException("Not known action: " + extendable)
		}
	}
	
	private def handleGuardEvaluations() {
		val statecharts = Statecharts.Matcher.on(engine).allValuesOfstatechart
		checkState(statecharts.size == 1)
		val statechart = statecharts.head
		val guardEvaluation = statechart.guardEvaluation
		if (guardEvaluation == GuardEvaluation.BEGINNING_OF_STEP) {
			val xStsNewMergedAction = createSequentialAction
			
			val extractableExpressions = trace.getGuards.values.flatten
			// trace.getGuards does not contain choice guards
			
			for (extractableExpression : extractableExpressions) {
				val name = "_" + extractableExpression.hashCode.abs
				xStsNewMergedAction.actions += createBooleanTypeDefinition
						.extractExpression(name, extractableExpression)
			}
			
			xStsNewMergedAction.actions += xSts.mergedAction
			
			xSts.changeTransitions(xStsNewMergedAction.wrap)
		}
	}
	
}