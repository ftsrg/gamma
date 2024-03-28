/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util.reducer

import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.BroadcastChannel
import hu.bme.mit.gamma.statechart.composite.SimpleChannel
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.composite.SynchronousCompositeComponent
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.GuardEvaluation
import hu.bme.mit.gamma.statechart.statechart.OrthogonalRegionSchedulingOrder
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.SchedulingOrder
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StateReferenceExpression
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority
import hu.bme.mit.gamma.transformation.util.queries.Regions
import hu.bme.mit.gamma.transformation.util.queries.RemovableTransitions
import hu.bme.mit.gamma.transformation.util.queries.SimpleInstances
import hu.bme.mit.gamma.transformation.util.queries.TopRegions
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection
import java.util.logging.Logger
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static extension hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class SystemReducer implements Reducer {
	
	protected final ViatraQueryEngine engine
	// Storing the reduced states, so in-state expressions can be removed
	protected final Collection<StateNode> removedUnreachableStates = newHashSet
	protected final Collection<StateNode> removedInitialStates = newHashSet
	//
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension Logger logger = Logger.getLogger("GammaLogger")
	
	new(ResourceSet resourceSet) {
		this.engine = ViatraQueryEngine.on(
				new EMFScope(resourceSet))
	}
	
	override execute() {
		val transitionMatcher = RemovableTransitions.Matcher.on(engine)
		val topRegionsMatcher = TopRegions.Matcher.on(engine)
		val simpleInstancesMatcher = SimpleInstances.Matcher.on(engine)
		val statecharts = newHashSet
		statecharts += topRegionsMatcher.allValuesOfstatechart
		// Transition optimizing
		while (transitionMatcher.hasMatch) {
			for (transition : transitionMatcher.allValuesOftransition.reject[it.eContainer === null]) {
				transition.removeTransition
			}
		}
		//
		statecharts.optimizeSemanticVariationPoints
		//
		statecharts.removeFalseGuardedTransitions
		// Timeout optimizing
		statecharts.removeUnnecessaryTimeouts
		// Region optimizing
		val regionMatcher = Regions.Matcher.on(engine)
		for (region : regionMatcher.allValuesOfregion) {
			region.removeUnnecessaryRegion
		}
		// In-state reduction
		while (!removedUnreachableStates.empty || !removedInitialStates.empty) {
			statecharts.removeFalseInStateExpressions(
				removedUnreachableStates, removedInitialStates)
			removedUnreachableStates.clear
			removedInitialStates.clear // So the next action can put new state nodes into the set
			statecharts.removeFalseGuardedTransitions
		}
		// Statechart optimizing
		for (statechart : statecharts) {
			if (statechart.regions.empty || !simpleInstancesMatcher.hasMatch(null, statechart)) {
				statechart.regions.clear
				statechart.variableDeclarations.clear
				statechart.timeoutDeclarations.clear
				statechart.transitions.clear
				info("Removing statechart content: " + statechart.name)
			}
			// Removing transitions who went out of a state from a removed region
			for (transition : statechart.transitions.toSet /*To avoid concurrent modification*/ ) {
				val source = transition.sourceState
				val target = transition.targetState
				try {
					source.containingStatechart.name // To invoke a nullptr
					target.containingStatechart.name
				} catch (NullPointerException e) {
					info("Removing transition as source or target is deleted: " + source.name + " -> " + target.name)
					transition.remove
				}
			}
		}
		// Instance optimizing
		for (instance : simpleInstancesMatcher.allValuesOfinstance) {
			instance.removeUnnecessaryStatechartInstance
		}
	}
	
	private def void removeTransition(Transition transition) {
		val target = transition.targetState
		info("Removing transition " + transition.sourceState.name + " -> " + target.name)
		transition.remove
		try {
			if (target.allIncomingTransitions.empty /* 0 due to transition.remove */) {
				for (outgoingTransition : target.outgoingTransitions
						.reject[it === transition] /* Addressing loops */) {
					outgoingTransition.removeTransition
				}
				info("Removing state node " + target.name)
				target.remove
				removedUnreachableStates += target
			}
		} catch (NullPointerException e) {
			// The ancestor of the target has already been removed
		}
	}
	
	private def void removeUnnecessaryTimeouts(Collection<StatechartDefinition> statecharts) {
		val timeouts = statecharts.map[it.timeoutDeclarations].flatten.toSet
		val referencedTimeouts = newHashSet
		val setTimeoutActions = newHashSet
		for (statechart : statecharts) {
			referencedTimeouts += statechart
				.getAllContentsOfType(TimeoutEventReference).map[it.timeout]
			setTimeoutActions += statechart.getAllContentsOfType(SetTimeoutAction)
		}
		val removableTimeouts = newHashSet
		removableTimeouts += timeouts
		removableTimeouts -= referencedTimeouts
		for (setTimeoutAction : setTimeoutActions) {
			val timeout = setTimeoutAction.timeoutDeclaration
			if (removableTimeouts.contains(timeout)) {
				setTimeoutAction.remove
			}
		}
		for (removableTimeout : removableTimeouts) {
			info("Removing timeout declaration " + removableTimeout.name + " of " + 
				removableTimeout.containingStatechart.name)
			removableTimeout.remove
		}
	}
	
	private def void removeUnnecessaryRegion(Region region) {
		val initialTransition = region.initialTransition
		val stateNodes = region.stateNodes
		val states = region.states
		val pseudoStates = region.pseudoStates // E.g., choice might have an incoming transition from another transition
		try {
			if (initialTransition.effects.forall[it.effectlessAction] &&
					pseudoStates.forall[it.precedingStates.empty] &&
					states.forall[(!it.composite && it.outgoingTransitions.empty &&
							it.incomingTransitions.forall[states.contains(it.sourceState)] && // Considering transitions via regions
							it.entryActions.forall[it.effectlessAction] &&
							it.exitActions.forall[it.effectlessAction]) ||
							it.allIncomingTransitions.empty]) { // Never true due to initial transition?
				// First, removing all related transitions (as otherwise nullptr exceptions are generated in incomingTransitions)
				val statechart = region.containingStatechart
				statechart.transitions -= (stateNodes.map[it.allIncomingTransitions].flatten +
						stateNodes.map[it.allOutgoingTransitions].flatten).toList
				// Removing region
				region.remove
				info("Removing region " + region.name + " of " + statechart.name)
				// Selecting unreachable states and always active states
				val unreachableStates = states.filter[it.allIncomingTransitions.empty].toList
				val reachedStates = states.filter[it.allOutgoingTransitions.empty].toList
				reachedStates -= unreachableStates
				removedUnreachableStates += unreachableStates
				removedInitialStates += reachedStates
			}
		} catch (NullPointerException e) {
			// An ancestor of a state has already been removed
			// Transitions are checked again, no need to bother with them here
		}
	}
	
	private def void removeUnnecessaryStatechartInstance(SynchronousComponentInstance instance) {
		val statechart = instance.type as StatechartDefinition
		if (statechart.regions.empty) {
			val container = instance.eContainer
			// It can be either an asynchronous adapter or a synchronous composite
			if (container instanceof SynchronousCompositeComponent) {
				container.components -= instance
				val _package = statechart.eContainer as Package
				_package.components -= statechart
				info("Removing statechart instance " + instance.name)
				// Port binding remover
				val unnecessaryPortBindings = container.portBindings
					.filter[it.instancePortReference.instance === instance].toList
				container.portBindings -= unnecessaryPortBindings
				// Channel remover
				val channels = container.channels
				val unnecessaryChannels = (channels.filter[it.providedPort.instance === instance] + 
					channels.filter(SimpleChannel).filter[it.requiredPort.instance === instance] +
					channels.filter(BroadcastChannel).filter[it.requiredPorts.exists[it.instance === instance]]).toList
				container.channels -= unnecessaryChannels
			}
		}
	}
	
	private def getFalseGuardedTransitions(Collection<StatechartDefinition> statecharts) {
		val transitions = statecharts.map[it.transitions].flatten.reject[it.guard === null]
		val falseGuardedTransitions = newArrayList
		for (transition : transitions) {
			try {
				val guard = transition.guard
				if (guard.definitelyFalseExpression) {
					falseGuardedTransitions += transition
				}
			} catch (IllegalArgumentException e) {
				// The guard contains a variable reference
			}
		}
		return falseGuardedTransitions
	}
	
	private def optimizeSemanticVariationPoints(Collection<StatechartDefinition> statecharts) {
		for (statechart : statecharts) {
			val hasOrthogonalRegions = statechart.hasOrthogonalRegions // Transitively
			if (!hasOrthogonalRegions) {
				statechart.guardEvaluation = GuardEvaluation.ON_THE_FLY
				statechart.orthogonalRegionSchedulingOrder = OrthogonalRegionSchedulingOrder.SEQUENTIAL
				info("Setting guard evaluation to on-the-fly and orthogonal region scheduling order to sequential")
			}
			//
			if (statechart.hasContainerOfType(AsynchronousAdapter)) {
				val adapter = statechart.getContainerOfType(AsynchronousAdapter)
				if (adapter.whenAnyRunOnce) { // A single event/trigger a time
					// Transition priority if outgoing transitions are always disjoint
					var areTriggersDisjoint = true
					val stateNodes = statechart.allStateNodes
					for (stateNode : stateNodes) {
						val outgoingTransitions = stateNode.outgoingTransitions
						if (!outgoingTransitions.areTriggersDisjoint) {
							areTriggersDisjoint = false
						}
					}
					if (areTriggersDisjoint) {
						statechart.transitionPriority = TransitionPriority.ORDER_BASED
						info("Setting transition priority to order-based")
					}
					
					// Top-down region scheduling if there are no occluding transitions
					areTriggersDisjoint = true
					if (stateNodes.exists[it.hasParentState]) {
						val transitions = statechart.transitions.filter[it.leavingState] // Only for states
						for (transition : transitions) {
							val source = transition.sourceState
							val outgoingTransitionsOfAncestors = source.outgoingTransitionsOfAncestors
							for (outgoingTransitionsOfAncestor : outgoingTransitionsOfAncestors) {
								if (!transition.areTriggersDisjoint(outgoingTransitionsOfAncestor)) {
									areTriggersDisjoint = false
								}
							}
						}
					}
					if (areTriggersDisjoint) {
						statechart.schedulingOrder = SchedulingOrder.TOP_DOWN
						info("Setting region scheduling order to top-down")
					}
				}
			}
		}
	}
	
	private def removeFalseGuardedTransitions(Collection<StatechartDefinition> statecharts) {
		val falseGuardedTransitions = statecharts.falseGuardedTransitions
		for (transition : falseGuardedTransitions.reject[it.eContainer === null]) {
			transition.removeTransition
		}
	}
	
	private def removeFalseInStateExpressions(Collection<StatechartDefinition> statecharts,
			Collection<StateNode> removedUnreachableStates, Collection<StateNode> removedInitialStates) {
		for (statechart : statecharts) {
			val inStateExpressions = statechart.getAllContentsOfType(StateReferenceExpression)
			for (inStateExpression : inStateExpressions) {
				val region = inStateExpression.region
				val state = inStateExpression.state
				val newExpression =
				if (removedUnreachableStates.contains(state)) {
					createFalseExpression // Unreachable state
				}
				else if (removedInitialStates.contains(state)) {
					createTrueExpression // First and only active state of the region
				}
				if (newExpression !== null) {
					// There should be no cross reference to the inStateExpression, hence the replace
					newExpression.replace(inStateExpression)
					info("Removing state reference " + region.name + "." + state.name)
				}
			}
		}
	}
	
}
