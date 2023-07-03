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
package hu.bme.mit.gamma.plugintemplate.transformation

import hu.bme.mit.gamma.plugintemplate.transformation.patterns.ChoiceStateTraces
import hu.bme.mit.gamma.plugintemplate.transformation.patterns.DeepHistoryStateTraces
import hu.bme.mit.gamma.plugintemplate.transformation.patterns.ForkStateTraces
import hu.bme.mit.gamma.plugintemplate.transformation.patterns.InitialStateTraces
import hu.bme.mit.gamma.plugintemplate.transformation.patterns.JoinStateTraces
import hu.bme.mit.gamma.plugintemplate.transformation.patterns.MergeStateTraces
import hu.bme.mit.gamma.plugintemplate.transformation.patterns.PackageTraces
import hu.bme.mit.gamma.plugintemplate.transformation.patterns.RegionTraces
import hu.bme.mit.gamma.plugintemplate.transformation.patterns.ShallowHistoryStateTraces
import hu.bme.mit.gamma.plugintemplate.transformation.patterns.StateTraces
import hu.bme.mit.gamma.plugintemplate.transformation.patterns.StatechartTraces
import hu.bme.mit.gamma.plugintemplate.transformation.patterns.TransitionTraces
import hu.bme.mit.gamma.plugintemplate.transformation.traceability.S2STrace
import hu.bme.mit.gamma.plugintemplate.transformation.traceability.TraceabilityFactory
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.CompositeElement
import hu.bme.mit.gamma.statechart.statechart.DeepHistoryState
import hu.bme.mit.gamma.statechart.statechart.ForkState
import hu.bme.mit.gamma.statechart.statechart.InitialState
import hu.bme.mit.gamma.statechart.statechart.JoinState
import hu.bme.mit.gamma.statechart.statechart.MergeState
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.ShallowHistoryState
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StateNode
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static com.google.common.base.Preconditions.checkArgument
import static com.google.common.base.Preconditions.checkState

class Trace {
	// Trace model factory
	protected final extension TraceabilityFactory traceabilityFactory = TraceabilityFactory.eINSTANCE
	// Trace model
	protected final S2STrace trace
	// Tracing engine
	protected final ViatraQueryEngine tracingEngine
	
	new(Package sourcePackage, Package targetPackage) {
		this.trace = createS2STrace => [
			it.sourcePackage = sourcePackage
			it.targetPackage = targetPackage
		]
		this.tracingEngine = ViatraQueryEngine.on(new EMFScope(trace))
	}
	
	// Source and target Packages
	def getSourcePackage() {
		return trace.sourcePackage
	}
	
	def getTargetPackage() {
		return trace.targetPackage
	}
	
	// Source and target package
	def put(Package sourcePackage, Package targetPackage) {
		checkArgument(sourcePackage !== null)
		checkArgument(targetPackage !== null)
		trace.traces += createPackageTrace => [
			it.sourcePackage = sourcePackage
			it.targetPackage = targetPackage
		]
	}
	
	def getSourcePackage(Package targetPackage) {
		checkArgument(targetPackage !== null)
		val matches = PackageTraces.Matcher.on(tracingEngine).getAllValuesOfsourcePackage(targetPackage)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getTargetPackage(Package sourcePackage) {
		checkArgument(sourcePackage !== null)
		val matches = PackageTraces.Matcher.on(tracingEngine).getAllValuesOftargetPackage(sourcePackage)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Source and target statechart
	def put(StatechartDefinition sourceStatechart, StatechartDefinition targetStatechart) {
		checkArgument(sourceStatechart !== null)
		checkArgument(targetStatechart !== null)
		trace.traces += createStatechartTrace => [
			it.sourceStatechart = sourceStatechart
			it.targetStatechart = targetStatechart
		]
	}
	
	def getSourceStatechart(StatechartDefinition targetStatechart) {
		checkArgument(targetStatechart !== null)
		val matches = StatechartTraces.Matcher.on(tracingEngine).getAllValuesOfsourceStatechart(targetStatechart)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getTargetStatechart(StatechartDefinition sourceStatechart) {
		checkArgument(sourcePackage !== null)
		val matches = StatechartTraces.Matcher.on(tracingEngine).getAllValuesOftargetStatechart(sourceStatechart)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def isCompositeElementMapped(CompositeElement sourceCompositeElement)	{
		checkArgument(sourceCompositeElement !== null)
		if (sourceCompositeElement instanceof StatechartDefinition) {
			return StatechartTraces.Matcher.on(tracingEngine).hasMatch(sourceCompositeElement, null)
		}
		if (sourceCompositeElement instanceof State) {
			return StateTraces.Matcher.on(tracingEngine).hasMatch(sourceCompositeElement, null)
		}
		throw new IllegalArgumentException("Not known composite element: " + sourceCompositeElement)
	}
	
	// Source and target regions
	def put(Region sourceRegion, Region targetRegion) {
		checkArgument(sourceRegion !== null)
		checkArgument(targetRegion !== null)
		trace.traces += createRegionTrace => [
			it.sourceRegion = sourceRegion
			it.targetRegion = targetRegion
		]
	}
	
	def isRegionMapped(Region sourceRegion)	{
		checkArgument(sourceRegion !== null)
		return RegionTraces.Matcher.on(tracingEngine).hasMatch(sourceRegion, null)
	}

	def getSourceRegion(Region targetRegion) {
		checkArgument(targetRegion !== null)
		val matches = RegionTraces.Matcher.on(tracingEngine).getAllValuesOfsourceRegion(targetRegion)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getTargetRegion(Region sourceRegion) {
		checkArgument(sourceRegion !== null)
		val matches = RegionTraces.Matcher.on(tracingEngine).getAllValuesOftargetRegion(sourceRegion)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getSourceStateNode(StateNode stateNode) {
		checkArgument(stateNode !== null)
		if (stateNode instanceof InitialState) {
			return stateNode.sourceState
		} else if (stateNode instanceof ShallowHistoryState) {
			return stateNode.sourceState
		} else if (stateNode instanceof DeepHistoryState) {
			return stateNode.sourceState
		} else if (stateNode instanceof ChoiceState) {
			return stateNode.sourceState
		} else if (stateNode instanceof State) {
			return stateNode.sourceState
		} else {
			throw new IllegalArgumentException("TODO: not known state node: " + stateNode)
		}
	}
	
	def getTargetStateNode(StateNode stateNode) {
		checkArgument(stateNode !== null)
		if (stateNode instanceof InitialState) {
			return stateNode.targetState
		} else if (stateNode instanceof ShallowHistoryState) {
			return stateNode.targetState
		} else if (stateNode instanceof DeepHistoryState) {
			return stateNode.targetState
		} else if (stateNode instanceof ChoiceState) {
			return stateNode.targetState
		} else if (stateNode instanceof State) {
			return stateNode.targetState
		} else {
			throw new IllegalArgumentException("TODO: not known state node: " + stateNode)
		}
	}
	
	// Source and target initial states
	def put(InitialState sourceInitialState, InitialState targetInitialState) {
		checkArgument(sourceInitialState !== null)
		checkArgument(targetInitialState !== null)
		trace.traces += createInitialStateTrace => [
			it.sourceInitialState = sourceInitialState
			it.targetInitialState = targetInitialState
		]
	}
	
	def getSourceState(InitialState targetInitialState) {
		checkArgument(targetInitialState !== null)
		val matches = InitialStateTraces.Matcher.on(tracingEngine).getAllValuesOfsourceInitialState(targetInitialState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getTargetState(InitialState sourceInitialState) {
		checkArgument(sourceInitialState !== null)
		val matches = InitialStateTraces.Matcher.on(tracingEngine).getAllValuesOftargetInitialState(sourceInitialState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Source and target shallow history states
	def put(ShallowHistoryState sourceShallowHistoryState, ShallowHistoryState targetShallowHistoryState) {
		checkArgument(sourceShallowHistoryState !== null)
		checkArgument(targetShallowHistoryState !== null)
		trace.traces += createShallowHistoryStateTrace => [
			it.sourceShallowHistoryState = sourceShallowHistoryState
			it.targetShallowHistoryState = targetShallowHistoryState
		]
	}
	
	def getSourceState(ShallowHistoryState targetShallowHistoryState) {
		checkArgument(targetShallowHistoryState !== null)
		val matches = ShallowHistoryStateTraces.Matcher.on(tracingEngine).getAllValuesOfsourceShallowHistoryState(targetShallowHistoryState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getTargetState(ShallowHistoryState sourceShallowHistoryState) {
		checkArgument(sourceShallowHistoryState !== null)
		val matches = ShallowHistoryStateTraces.Matcher.on(tracingEngine).getAllValuesOftargetShallowHistoryState(sourceShallowHistoryState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Source and target deep history states
	def put(DeepHistoryState sourceDeepHistoryState, DeepHistoryState targetDeepHistoryState) {
		checkArgument(sourceDeepHistoryState !== null)
		checkArgument(targetDeepHistoryState !== null)
		trace.traces += createDeepHistoryStateTrace => [
			it.sourceDeepHistoryState = sourceDeepHistoryState
			it.targetDeepHistoryState = targetDeepHistoryState
		]
	}
	
	def getSourceState(DeepHistoryState targetDeepHistoryState) {
		checkArgument(targetDeepHistoryState !== null)
		val matches = DeepHistoryStateTraces.Matcher.on(tracingEngine).getAllValuesOfsourceDeepHistoryState(targetDeepHistoryState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getTargetState(DeepHistoryState sourceDeepHistoryState) {
		checkArgument(sourceDeepHistoryState !== null)
		val matches = DeepHistoryStateTraces.Matcher.on(tracingEngine).getAllValuesOftargetDeepHistoryState(sourceDeepHistoryState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Source and target choice states
	def put(ChoiceState sourceChoiceState, ChoiceState targetChoiceState) {
		checkArgument(sourceChoiceState !== null)
		checkArgument(targetChoiceState !== null)
		trace.traces += createChoiceStateTrace => [
			it.sourceChoiceState = sourceChoiceState
			it.targetChoiceState = targetChoiceState
		]
	}
	
	def getSourceState(ChoiceState targetChoiceState) {
		checkArgument(targetChoiceState !== null)
		val matches = ChoiceStateTraces.Matcher.on(tracingEngine).getAllValuesOfsourceChoiceState(targetChoiceState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getTargetState(ChoiceState sourceChoiceState) {
		checkArgument(sourceChoiceState !== null)
		val matches = ChoiceStateTraces.Matcher.on(tracingEngine).getAllValuesOftargetChoiceState(sourceChoiceState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Source and target fork states
	def put(ForkState sourceForkState, ForkState targetForkState) {
		checkArgument(sourceForkState !== null)
		checkArgument(targetForkState !== null)
		trace.traces += createForkStateTrace => [
			it.sourceForkState = sourceForkState
			it.targetForkState = targetForkState
		]
	}
	
	def getSourceState(ForkState targetForkState) {
		checkArgument(targetForkState !== null)
		val matches = ForkStateTraces.Matcher.on(tracingEngine).getAllValuesOfsourceForkState(targetForkState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getTargetState(ForkState sourceForkState) {
		checkArgument(sourceForkState !== null)
		val matches = ForkStateTraces.Matcher.on(tracingEngine).getAllValuesOftargetForkState(sourceForkState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Source and target merge states
	def put(MergeState sourceMergeState, MergeState targetMergeState) {
		checkArgument(sourceMergeState !== null)
		checkArgument(targetMergeState !== null)
		trace.traces += createMergeStateTrace => [
			it.sourceMergeState = sourceMergeState
			it.targetMergeState = targetMergeState
		]
	}
	
	def getSourceState(MergeState targetMergeState) {
		checkArgument(targetMergeState !== null)
		val matches = MergeStateTraces.Matcher.on(tracingEngine).getAllValuesOfsourceMergeState(targetMergeState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getTargetState(MergeState sourceMergeState) {
		checkArgument(sourceMergeState !== null)
		val matches = MergeStateTraces.Matcher.on(tracingEngine).getAllValuesOftargetMergeState(sourceMergeState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	
	// Source and target join states
	def put(JoinState sourceJoinState, JoinState targetJoinState) {
		checkArgument(sourceJoinState !== null)
		checkArgument(targetJoinState !== null)
		trace.traces += createJoinStateTrace => [
			it.sourceJoinState = sourceJoinState
			it.targetJoinState = targetJoinState
		]
	}
	
	def getSourceState(JoinState targetJoinState) {
		checkArgument(targetJoinState !== null)
		val matches = JoinStateTraces.Matcher.on(tracingEngine).getAllValuesOfsourceJoinState(targetJoinState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getTargetState(JoinState sourceJoinState) {
		checkArgument(sourceJoinState !== null)
		val matches = JoinStateTraces.Matcher.on(tracingEngine).getAllValuesOftargetJoinState(sourceJoinState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Source and target states
	def put(State sourceState, State targetState) {
		checkArgument(sourceState !== null)
		checkArgument(targetState !== null)
		trace.traces += createStateTrace => [
			it.sourceState = sourceState
			it.targetState = targetState
		]
	}
	
	def getSourceState(State targetState) {
		checkArgument(targetState !== null)
		val matches = StateTraces.Matcher.on(tracingEngine).getAllValuesOfsourceState(targetState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getTargetState(State sourceState) {
		checkArgument(sourceState !== null)
		val matches = StateTraces.Matcher.on(tracingEngine).getAllValuesOftargetState(sourceState)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	// Source and target transitions
	def put(Transition sourceTransition, Transition targetTransition) {
		checkArgument(sourceTransition !== null)
		checkArgument(targetTransition !== null)
		trace.traces += createTransitionTrace => [
			it.sourceTransition = sourceTransition
			it.targetTransition = targetTransition
		]
	}
	
	def getSourceTransition(Transition targetTransition) {
		checkArgument(targetTransition !== null)
		val matches = TransitionTraces.Matcher.on(tracingEngine).getAllValuesOfsourceTransition(targetTransition)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
	def getTargetTransition(Transition sourceTransition) {
		checkArgument(sourceTransition !== null)
		val matches = TransitionTraces.Matcher.on(tracingEngine).getAllValuesOftargetTransition(sourceTransition)
		checkState(matches.size == 1, matches.size)
		return matches.head
	}
	
}