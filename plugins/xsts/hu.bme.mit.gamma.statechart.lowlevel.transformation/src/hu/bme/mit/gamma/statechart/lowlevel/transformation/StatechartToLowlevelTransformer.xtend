/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.statechart.lowlevel.transformation

import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventDirection
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.interface_.RealizationMode
import hu.bme.mit.gamma.statechart.interface_.TimeUnit
import hu.bme.mit.gamma.statechart.lowlevel.model.Component
import hu.bme.mit.gamma.statechart.lowlevel.model.EventDeclaration
import hu.bme.mit.gamma.statechart.lowlevel.model.StateNode
import hu.bme.mit.gamma.statechart.lowlevel.model.StatechartModelFactory
import hu.bme.mit.gamma.statechart.lowlevel.util.LowlevelStatechartUtil
import hu.bme.mit.gamma.statechart.statechart.DeepHistoryState
import hu.bme.mit.gamma.statechart.statechart.GuardEvaluation
import hu.bme.mit.gamma.statechart.statechart.InitialState
import hu.bme.mit.gamma.statechart.statechart.OrthogonalRegionSchedulingOrder
import hu.bme.mit.gamma.statechart.statechart.PseudoState
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.RunUponExternalEventAnnotation
import hu.bme.mit.gamma.statechart.statechart.RunUponExternalEventOrInternalTimeoutAnnotation
import hu.bme.mit.gamma.statechart.statechart.SchedulingOrder
import hu.bme.mit.gamma.statechart.statechart.ShallowHistoryState
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.TimeoutAction
import hu.bme.mit.gamma.statechart.statechart.TimeoutDeclaration
import hu.bme.mit.gamma.statechart.statechart.TimeoutEventReference
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.xsts.transformation.util.LowlevelNamings.*

class StatechartToLowlevelTransformer {
	// Auxiliary objects
	protected final extension TypeTransformer typeTransformer
	protected final extension ExpressionTransformer expressionTransformer
	protected final extension ValueDeclarationTransformer valueDeclarationTransformer
	protected final extension ActionTransformer actionTransformer
	protected final extension TriggerTransformer triggerTransformer
	protected final extension PseudoStateTransformer pseudoStateTransformer
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension LowlevelStatechartUtil lowlevelUtil = LowlevelStatechartUtil.INSTANCE
	protected final extension EventAttributeTransformer eventAttributeTransformer = EventAttributeTransformer.INSTANCE
	// Low-level statechart model factory
	protected final extension StatechartModelFactory factory = StatechartModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory constraintFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionFactory = ActionModelFactory.eINSTANCE
	// Trace object for storing the mappings
	protected final Trace trace
	
	new() {
		this(null)
	}
	
	new(TimeUnit baseTimeUnit) {
		this(true, 10, baseTimeUnit)
	}
	
	new(boolean functionInlining, int maxRecursionDepth, TimeUnit baseTimeUnit) {
		this.trace = new Trace
		this.typeTransformer = new TypeTransformer(this.trace)
		this.expressionTransformer = new ExpressionTransformer(this.trace, functionInlining, maxRecursionDepth, baseTimeUnit)
		this.valueDeclarationTransformer = new ValueDeclarationTransformer(this.trace)
		this.actionTransformer = new ActionTransformer(this.trace, functionInlining, maxRecursionDepth, baseTimeUnit)
		this.triggerTransformer = new TriggerTransformer(this.trace, functionInlining, maxRecursionDepth, baseTimeUnit)
		this.pseudoStateTransformer = new PseudoStateTransformer(this.trace)
	}
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.Package execute(Package _package) {
		return _package.transform
	}
	
	def hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition execute(StatechartDefinition statechart) {
		// Eliminating merge states
		val mergeStateEliminator = new MergeStateEliminator(statechart)
		mergeStateEliminator.execute
		//
		return statechart.transformComponent as hu.bme.mit.gamma.statechart.lowlevel.model.StatechartDefinition
	}

	protected def hu.bme.mit.gamma.statechart.lowlevel.model.Package transform(Package _package) {
		if (trace.isMapped(_package)) {
			// It is already transformed
			return trace.get(_package)
		}
		val lowlevelPackage = _package.createAndTracePackage
		// Transforming other type declarations in ExpressionTransformer during variable transformation
		// Not transforming imports as it is unnecessary (Traces.getLowlevelPackage would not work either)
		return lowlevelPackage
	}
	
	protected def createAndTracePackage(Package _package) {
		val lowlevelPackage = createPackage => [
			it.name = _package.name
		]
		trace.put(_package, lowlevelPackage) // Saving in trace
		
		return lowlevelPackage
	}
	
	/**
	 * Returns a list, as an INOUT declaration is mapped to an IN and an OUT declaration.
	 */
	protected def List<EventDeclaration> transform(
			hu.bme.mit.gamma.statechart.interface_.EventDeclaration declaration, Port gammaPort) {
		val gammaDirection = declaration.direction
		val realizationMode = gammaPort.interfaceRealization.realizationMode
		if (gammaDirection == EventDirection.IN &&
				realizationMode == RealizationMode.PROVIDED ||
				gammaDirection == EventDirection.OUT &&
				realizationMode == RealizationMode.REQUIRED) {
			// Event coming in
			val lowlevelEventIn = declaration.event.transform(gammaPort, EventDirection.IN)
			trace.put(gammaPort, declaration, lowlevelEventIn) // Tracing the EventDeclaration
			trace.put(gammaPort, declaration.event, lowlevelEventIn) // Tracing the Event
			return #[lowlevelEventIn]
		}
		else if	(gammaDirection == EventDirection.IN &&
				realizationMode == RealizationMode.REQUIRED ||
				gammaDirection == EventDirection.OUT &&
				realizationMode == RealizationMode.PROVIDED) {
			// Events going out
			val lowlevelEventOut = declaration.event.transform(gammaPort, EventDirection.OUT)
			trace.put(gammaPort, declaration, lowlevelEventOut) // Tracing the EventDeclaration
			trace.put(gammaPort, declaration.event, lowlevelEventOut) // Tracing the Event
			return #[lowlevelEventOut]
		}
		else {
			// In-out and internal events
			// At low-level, INTERNAL events are transformed as INOUT events
			checkState(gammaDirection == EventDirection.INOUT ||
				gammaDirection == EventDirection.INTERNAL)
			val lowlevelEventIn = declaration.event.transform(gammaPort, EventDirection.IN)
			trace.put(gammaPort, declaration, lowlevelEventIn) // Tracing the EventDeclaration
			val lowlevelEventOut = declaration.event.transform(gammaPort, EventDirection.OUT)
			trace.put(gammaPort, declaration, lowlevelEventOut) // Tracing the EventDeclaration
			return #[lowlevelEventIn, lowlevelEventOut]
		}
	}

	protected def EventDeclaration transform(Event gammaEvent, Port gammaPort, EventDirection direction) {
		checkState(direction == EventDirection.IN || direction == EventDirection.OUT)
		val lowlevelEvent = createEventDeclaration => [
			it.name = (direction == EventDirection.IN) ?
				gammaEvent.getInputName(gammaPort) : gammaEvent.getOutputName(gammaPort)
			it.persistency = gammaEvent.persistency.transform
			it.direction = direction.transform
			it.isRaised = createVariableDeclaration => [
				it.name = "isRaised"
				it.type = createBooleanTypeDefinition
			]
			if (direction == EventDirection.IN && gammaPort.internal) { // Internal event
				it.isRaised.addInternalAnnotation
			}
		]
		trace.put(gammaPort, gammaEvent, lowlevelEvent)
		// Transforming the parameters
		for (gammaParameter : gammaEvent.parameterDeclarations) {
			val lowlevelParameters = (direction == EventDirection.IN) ?
				gammaParameter.transformInParameter(gammaPort) : 
				gammaParameter.transformOutParameter(gammaPort)
			lowlevelEvent.parameters += lowlevelParameters
		}
		return lowlevelEvent
	}

	protected def VariableDeclaration transform(TimeoutDeclaration timeout) {
		val statechart = timeout.containingStatechart
		val transitions = statechart.transitions.filter[it.getAllContentsOfType(
				TimeoutEventReference).exists[it.timeout === timeout]]
		// We can optimize, if this timeout is used for triggering the transitions of only one state
		if (transitions.size == 1) {
			val transition = transitions.head
			val source = transition.sourceState
			if (source instanceof State) {
				// We can optimize, if this is an after N sec trigger (each timeout is set only once, hence the "== 1" if it is one)
				if (source.getAllContentsOfType(
						TimeoutAction).exists[it.timeoutDeclaration === timeout]) {
					// We can optimize, if all outgoing transitions use (potentially) only this timeout
					if (source.outgoingTransitions.map[it.getAllContentsOfType(
							TimeoutEventReference).toList].flatten.forall[it.timeout === timeout]) {
						val gammaParentRegion = source.parentRegion
						if (!trace.doesRegionHaveOptimizedTimeout(gammaParentRegion)) {
							val lowlevelTimeout = timeout.createTimeoutVariable
							trace.put(gammaParentRegion, lowlevelTimeout)
						}
						val lowlevelTimeout = trace.getTimeout(gammaParentRegion)
						trace.put(timeout, lowlevelTimeout) // If the above if is true, this is not necessary
						return lowlevelTimeout
					}
				}
			}
		}
		return timeout.createTimeoutVariable
	}
	
	protected def createTimeoutVariable(TimeoutDeclaration timeout) {
		val lowlevelTimeout = createVariableDeclaration => [
			it.name = getName(timeout)
			it.type = createIntegerTypeDefinition // Could be rational
			// Initial expression in EventReferenceTransformer
		]
		trace.put(timeout, lowlevelTimeout)
		return lowlevelTimeout
	}
	
	protected def dispatch Component transformComponent(hu.bme.mit.gamma.statechart.interface_.Component component) {
		throw new IllegalArgumentException("Not known component: " + component)
	}
	
	protected def dispatch Component transformComponent(StatechartDefinition statechart) {
		if (trace.isMapped(statechart)) {
			// It is already transformed
			return trace.get(statechart)
		}
		val lowlevelStatechart = createStatechartDefinition => [
			it.name = getName(statechart)
			it.schedulingOrder = statechart.schedulingOrder.transform
			it.guardEvaluation = statechart.guardEvaluation.transform
			it.orthogonalRegionSchedulingOrder = statechart.orthogonalRegionSchedulingOrder.transform
		]
		if (!statechart.hasOrthogonalRegions) {
			// If there are no orthogonal regions, then the guard evaluation policy is irrelevant;
			// on the fly is the faster option, though
			lowlevelStatechart.guardEvaluation =
				hu.bme.mit.gamma.statechart.lowlevel.model.GuardEvaluation.ON_THE_FLY
		}
		if (statechart.hasAnnotation(RunUponExternalEventAnnotation)) {
			lowlevelStatechart.addRunUponExternalEventAnnotation
		}
		if (statechart.hasAnnotation(RunUponExternalEventOrInternalTimeoutAnnotation)) {
			lowlevelStatechart.addRunUponExternalEventOrInternalTimeoutAnnotation
		}
		trace.put(statechart, lowlevelStatechart) // Saving in trace
		
		// Constants
		val gammaPackage = statechart.containingPackage
		for (constantDeclaration : gammaPackage.selfAndImports // During code generation, imported constants can be referenced
				.map[it.constantDeclarations].flatten) {
			lowlevelStatechart.variableDeclarations += constantDeclaration.transform
		}
		// No parameter declarations mapping
		for (parameterDeclaration : statechart.parameterDeclarations) {
			val lowlevelParameterDeclaration = parameterDeclaration.transformComponentParameter
			lowlevelStatechart.variableDeclarations += lowlevelParameterDeclaration
			lowlevelStatechart.parameterDeclarations += lowlevelParameterDeclaration
		}
		for (variableDeclaration : statechart.variableDeclarations) {
			lowlevelStatechart.variableDeclarations += variableDeclaration.transform
		}
		for (timeoutDeclaration : statechart.timeoutDeclarations) {
			// Timeout declarations are transformed to integer variable declarations
			val lowlevelTimeoutDeclaration = timeoutDeclaration.transform
			lowlevelStatechart.variableDeclarations += lowlevelTimeoutDeclaration
			lowlevelStatechart.timeoutDeclarations += lowlevelTimeoutDeclaration
		}
		for (port : statechart.ports) {
			// Both in and out events are transformed to a boolean VarDecl with additional parameters
			for (eventDeclaration : port.allEventDeclarations) {
				val lowlevelEventDeclarations = eventDeclaration.transform(port)
				lowlevelStatechart.eventDeclarations += lowlevelEventDeclarations
				if (eventDeclaration.direction == EventDirection.INTERNAL) {
					// Tracing
					lowlevelStatechart.internalEventDeclarations += lowlevelEventDeclarations
				}
			}
		}
		for (region : statechart.regions) {
			lowlevelStatechart.regions += region.transform
		}
		for (transition : statechart.transitions) {
			// Prioritizing transitions is done here
			val lowlevelTransition = transition.transform
			lowlevelStatechart.transitions += lowlevelTransition
		}
		
		// Mapping port and interface invariants (now, not before, because we want to refer to e.g., state nodes and variables)
		// First the interface invariants must be mapped to the ports realizing the interface
		for (port : statechart.ports) {
			val mappedInvariants = port.mapInterfaceInvariantsToPort
			if (!mappedInvariants.empty) {
				lowlevelStatechart.environmentalInvariants += mappedInvariants.map[it.transformSimpleExpression]
			}
			val invariants = port.invariants
			if (!invariants.empty) {
				lowlevelStatechart.environmentalInvariants += invariants.map[it.transformSimpleExpression]
			}
		}
		
		// Mapping statechart invariants
		val statechartInvariants = statechart.invariants
		if (!statechartInvariants.empty) {
			lowlevelStatechart.invariants += statechartInvariants.map[it.transformSimpleExpression]
		}
		
		return lowlevelStatechart
	}

	protected def transform(SchedulingOrder order) {
		switch (order) {
			case SchedulingOrder.BOTTOM_UP: {
				return hu.bme.mit.gamma.statechart.lowlevel.model.SchedulingOrder.BOTTOM_UP
			}
			case SchedulingOrder.TOP_DOWN: {
				return hu.bme.mit.gamma.statechart.lowlevel.model.SchedulingOrder.TOP_DOWN
			}
			default: {
				throw new IllegalArgumentException("Not known scheduling order: " + order)
			}
		}
	}
	
	protected def transform(GuardEvaluation guardEvaluation) {
		switch (guardEvaluation) {
			case GuardEvaluation.ON_THE_FLY: {
				return hu.bme.mit.gamma.statechart.lowlevel.model.GuardEvaluation.ON_THE_FLY
			}
			case GuardEvaluation.BEGINNING_OF_STEP: {
				return hu.bme.mit.gamma.statechart.lowlevel.model.GuardEvaluation.BEGINNING_OF_STEP
			}
			default: {
				throw new IllegalArgumentException("Not known guard evaluation: " + guardEvaluation)
			}
		}
	}
	
	protected def transform(OrthogonalRegionSchedulingOrder schedulingOrder) {
		switch (schedulingOrder) {
			case OrthogonalRegionSchedulingOrder.SEQUENTIAL: {
				return hu.bme.mit.gamma.statechart.lowlevel.model.OrthogonalRegionSchedulingOrder.SEQUENTIAL
			}
			case OrthogonalRegionSchedulingOrder.UNORDERED: {
				return hu.bme.mit.gamma.statechart.lowlevel.model.OrthogonalRegionSchedulingOrder.UNORDERED
			}
			case OrthogonalRegionSchedulingOrder.PARALLEL: {
				return hu.bme.mit.gamma.statechart.lowlevel.model.OrthogonalRegionSchedulingOrder.PARALLEL
			}
			default: {
				throw new IllegalArgumentException("Not known scheduling order: " + schedulingOrder)
			}
		}
	}

	protected def hu.bme.mit.gamma.statechart.lowlevel.model.Region transform(Region region) {
		val gammaStateNodes = region.stateNodes
		checkState(gammaStateNodes.filter(InitialState).size <= 1,
				"More than one initial state in " + region.name)
		checkState(gammaStateNodes.filter(ShallowHistoryState).size <= 1,
				"More than one shallow history state in " + region.name)
		checkState(gammaStateNodes.filter(DeepHistoryState).size <= 1,
				"More than one deep history state in " + region.name)
		
		val lowlevelRegion = createRegion => [
			it.name = region.regionName
		]
		trace.put(region, lowlevelRegion)
		// Transforming normal nodes
		for (stateNode : gammaStateNodes.filter(State)) {
			lowlevelRegion.stateNodes += stateNode.transformNode
		}
		// Transforming abstract transition nodes
		for (pseudoState : gammaStateNodes.filter(PseudoState)) {
			lowlevelRegion.stateNodes += pseudoState.transformPseudoState
		}
		return lowlevelRegion
	}
	
	protected def StateNode transformNode(State state) {
		val lowlevelState = createState => [
			it.name = state.stateName
		]
		trace.put(state, lowlevelState)
		// Transforming regions
		for (region : state.regions) {
			lowlevelState.regions += region.transform
		}
		// Entry and exit actions
		lowlevelState.entryAction = state.entryActions.transformActions
		lowlevelState.exitAction = state.exitActions.transformActions
		
		val invariants = state.invariants
		if (!invariants.empty) {
			lowlevelState.invariants += invariants.map[it.transformSimpleExpression]
		}
		
		return lowlevelState
	}

	protected def hu.bme.mit.gamma.statechart.lowlevel.model.Transition transform(Transition gammaTransition) {
		// Trivial simple transitions
		val gammaSource = gammaTransition.sourceState
		val gammaTarget = gammaTransition.targetState
		val lowlevelSource = if (gammaSource instanceof State) {
			trace.get(gammaSource)
		} else if (gammaSource instanceof PseudoState) {
			trace.get(gammaSource)
		}
		val lowlevelTarget = if (gammaTarget instanceof State) {
			trace.get(gammaTarget)
		} else if (gammaTarget instanceof PseudoState) {
			trace.get(gammaTarget)
		}
		val lowlevelTransition = createTransition => [
			it.source = lowlevelSource
			it.target = lowlevelTarget
			it.priority = gammaTransition.calculatePriority.intValue // Priority is handled later
		]
		trace.put(gammaTransition, lowlevelTransition) // Saving in trace
		// Important to trace the Gamma transition as the trigger transformer depends on it
		lowlevelTransition.guard = gammaTransition.transformTriggerAndGuard
		lowlevelTransition.action = gammaTransition.effects.transformActions
		
		return lowlevelTransition
	}
	
	/**
	 * Can return null.
	 */
	protected def Expression transformTriggerAndGuard(Transition transition) {
		val lowlevelGuardList = newArrayList
		val gammaTrigger = transition.trigger
		if (gammaTrigger !== null) {
			lowlevelGuardList += gammaTrigger.transformTrigger // Trigger guard
		}
		var guard = transition.guard
		if (guard !== null) {
			if (!guard.elseOrDefault) {
				lowlevelGuardList += guard.transformExpression
			}
			// We do not transform the else guard: priority is already set during the creation of the transition
		}
		// The expressions are in an AND relation
		lowlevelGuardList.removeIf[it instanceof TrueExpression]
		return lowlevelGuardList.wrapIntoMultiaryExpression(createAndExpression)
	}
	
	//
	
	def getTrace() {
		return trace
	}
	
}