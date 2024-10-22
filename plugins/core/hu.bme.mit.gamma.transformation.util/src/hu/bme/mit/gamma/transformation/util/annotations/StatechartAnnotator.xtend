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
package hu.bme.mit.gamma.transformation.util.annotations

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.model.Branch
import hu.bme.mit.gamma.action.model.ChoiceStatement
import hu.bme.mit.gamma.action.model.IfStatement
import hu.bme.mit.gamma.action.model.SwitchStatement
import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.ValueDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.EntryState
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.transformation.util.queries.InteractionCUses
import hu.bme.mit.gamma.transformation.util.queries.InteractionPUses
import hu.bme.mit.gamma.transformation.util.queries.InteractionUses
import hu.bme.mit.gamma.transformation.util.queries.RaiseInstanceEvents
import hu.bme.mit.gamma.transformation.util.queries.VariableCUses
import hu.bme.mit.gamma.transformation.util.queries.VariableDefs
import hu.bme.mit.gamma.transformation.util.queries.VariablePUses
import hu.bme.mit.gamma.transformation.util.queries.VariableUses
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import java.util.AbstractMap.SimpleEntry
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.Map.Entry
import java.util.Set
import org.eclipse.emf.ecore.EObject
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static extension hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class StatechartAnnotator {
	//
	protected final Package gammaPackage
	protected final ViatraQueryEngine engine
	
	// Transition coverage
	protected boolean DEADLOCK_COVERAGE
	protected final Set<SynchronousComponentInstance> deadlockCoverableComponents = newHashSet
	protected final Set<Transition> coverableDeadlockTransitions = newHashSet
	protected final Map<Transition, VariableDeclaration> deadlockTransitionVariables = newHashMap // Boolean variables
	
	// Nondeterministic transition coverage
	protected boolean NONDETERMINISTIC_TRANSITION_COVERAGE
	protected final Set<SynchronousComponentInstance> nondeterministicTransitionCoverableComponents = newHashSet
	protected final Set<Transition> coverableNondeterministicTransitions = newHashSet
	protected final Map<Region, State> nondeterministicTrapStates = newHashMap
	
	// Transition coverage
	protected boolean TRANSITION_COVERAGE
	protected final Set<SynchronousComponentInstance> transitionCoverableComponents = newHashSet
	protected final Set<Transition> coverableTransitions = newHashSet
	protected final Map<Transition, VariableDeclaration> transitionVariables = newHashMap // Boolean variables
	
	// Transition pair coverage (same as the normal transition coverage, the difference is that the values are reused in pairs)
	protected boolean TRANSITION_PAIR_COVERAGE
	protected final Set<SynchronousComponentInstance> transitionPairCoverableComponents = newHashSet
	protected final Set<Transition> coverableTransitionPairs = newHashSet
	protected long transitionId = 1 // As 0 is the reset value
	protected final Map<Transition, Long> transitionIds = newHashMap
	protected final Map<State, VariablePair> transitionPairVariables = newHashMap
	protected final List<TransitionPairAnnotation> transitionPairAnnotations = newArrayList
	
	// Interaction coverage
	protected boolean INTERACTION_COVERAGE
	protected InteractionCoverageCriterion SENDER_INTERACTION_TUPLE
	protected InteractionCoverageCriterion RECEIVER_INTERACTION_TUPLE
	protected final boolean RECEIVER_CONSIDERATION // Derived feature: RECEIVER_INTERACTION_TUPLE != RECEIVER_INTERACTION_TUPLE.EVENTS
	
	protected final Set<Port> interactionCoverablePorts = newHashSet
	protected final Set<State> interactionCoverableStates = newHashSet
	protected final Set<Transition> interactionCoverableTransitions = newHashSet
	
	protected long senderId = 1 // As 0 is the reset value
	protected long recevierId = 1 // As 0 is the reset value
	
	protected final Map<RaiseEventAction, Long> sendingIds = newHashMap
	protected final Map<Transition, Long> receivingIds = newHashMap
	protected final Map<Transition, List<Entry<Port, Event>>> receivingInteractions = newHashMap // Check: list must be unique
	protected final Map<Region, List<VariablePair>> regionInteractionVariables = newHashMap // Check: list must be unique
	protected final Map<StatechartDefinition, // Optimization: stores the variable pairs of other regions for reuse
		List<VariablePair>> statechartInteractionVariables = newHashMap // Check: list must be unique
	protected final List<Interaction> interactions = newArrayList
	
	// Data-flow coverage
	protected boolean DATAFLOW_COVERAGE
	protected DataflowCoverageCriterion DATAFLOW_COVERAGE_CRITERION
	protected final Set<VariableDeclaration> dataflowCoverableVariables = newHashSet
	
	protected final Map<ValueDeclaration, /* Original declaration whose def is marked */
		VariableDeclaration /* Variable storing the id of the last def */> defVariables = newHashMap
	protected final Map<EObject, /* Def */ DefVariableId> defIds = newHashMap
	protected final Map<ReferenceExpression, /* Use */
		VariableDeclaration /* Storing the id of the read def */> useVariables = newHashMap
	protected final Map<ReferenceExpression, /* Use */ DefUseVariablePair> defUseVariablePairs = newHashMap
	protected long defId = 1 // As 0 is the reset value
	
	// Interaction data-flow coverage
	protected boolean INTERACTION_DATAFLOW_COVERAGE
	protected DataflowCoverageCriterion INTERACTION_DATAFLOW_COVERAGE_CRITERION
	protected final Set<Port> interactionDataflowCoverablePorts = newHashSet
	
	protected final Map<EObject, /* Def */ DefVariableId> interactionDefIds = newHashMap
	protected final Map<ReferenceExpression, /* Use */
		VariableDeclaration /* Storing the id of the read def */> interactionUseVariables = newHashMap
	protected final Map<ReferenceExpression, /* Use */ DefUseVariablePair> interactionDefUseVariablePairs = newHashMap
	protected final Set<Pair<Port, Port>> connectedPorts = newHashSet
	protected long interactionDefId = 1 // As 0 is the reset value
	
	// Factories
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionModelFactory = ActionModelFactory.eINSTANCE
	protected final extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	// Namings
	protected final AnnotationNamings namings = new AnnotationNamings // Instance due to the id
	
	new(Package gammaPackage, AnnotatableElements annotableElements) {
		this.gammaPackage = gammaPackage
		this.engine = ViatraQueryEngine.on(
			new EMFScope(
				gammaPackage.eResource.resourceSet))
		
		if (!annotableElements.deadlockCoverableComponents.empty) {
			this.DEADLOCK_COVERAGE = true
			this.deadlockCoverableComponents += annotableElements.deadlockCoverableComponents
			this.coverableDeadlockTransitions += deadlockCoverableComponents
				.map[it.type].filter(StatechartDefinition)
				.map[it.transitions].flatten.filter[it.sourceState.state]
		}
		if (!annotableElements.nondeterministicTransitionCoverableComponents.empty) {
			this.NONDETERMINISTIC_TRANSITION_COVERAGE = true
			this.nondeterministicTransitionCoverableComponents += annotableElements.nondeterministicTransitionCoverableComponents
			this.coverableNondeterministicTransitions += nondeterministicTransitionCoverableComponents
				.map[it.type].filter(StatechartDefinition)
				.map[it.transitions].flatten.filter[it.sourceState.outgoingTransitions.size > 1]
		}
		if (!annotableElements.transitionCoverableComponents.empty) {
			this.TRANSITION_COVERAGE = true
			this.transitionCoverableComponents += annotableElements.transitionCoverableComponents
			this.coverableTransitions += transitionCoverableComponents
				.map[it.type].filter(StatechartDefinition)
				.map[it.transitions].flatten
		}
		if (!annotableElements.transitionPairCoverableComponents.empty) {
			this.TRANSITION_PAIR_COVERAGE = true
			this.transitionPairCoverableComponents += annotableElements.transitionPairCoverableComponents
			this.coverableTransitionPairs += transitionPairCoverableComponents
				.map[it.type].filter(StatechartDefinition)
				.map[it.transitions].flatten
		}
		if (!annotableElements.interactionCoverablePorts.isEmpty) {
			this.INTERACTION_COVERAGE = true
			this.SENDER_INTERACTION_TUPLE = annotableElements.senderInteractionTuple
			this.RECEIVER_INTERACTION_TUPLE = annotableElements.receiverInteractionTuple
			this.interactionCoverablePorts += annotableElements.interactionCoverablePorts
			this.interactionCoverableStates += annotableElements.interactionCoverableStates
			this.interactionCoverableTransitions += annotableElements.interactionCoverableTransitions
		}
		this.RECEIVER_CONSIDERATION =
			RECEIVER_INTERACTION_TUPLE != InteractionCoverageCriterion.EVENTS
		if (!annotableElements.dataflowCoverableVariables.isEmpty) {
			this.DATAFLOW_COVERAGE = true
			this.dataflowCoverableVariables += annotableElements.dataflowCoverableVariables
			this.DATAFLOW_COVERAGE_CRITERION = annotableElements.dataflowCoverageCriterion
		}
		if (!annotableElements.interactionDataflowCoverablePorts.isEmpty) {
			this.INTERACTION_DATAFLOW_COVERAGE = true
			this.interactionDataflowCoverablePorts += annotableElements.interactionDataflowCoverablePorts
			this.INTERACTION_DATAFLOW_COVERAGE_CRITERION = annotableElements.interactionDataflowCoverageCriterion
		}
	}
	
	// Entry point
	
	def annotateModel() {
		annotateModelForDeadlockCoverage
		annotateModelForNondeterministicTransitionCoverage
		annotateModelForTransitionCoverage
		annotateModelForTransitionPairCoverage
		annotateModelForInteractionCoverage
		annotateModelForDataFlowCoverage
		annotateModelForInteractionDataFlowCoverage
	}
	
	// Deadlock coverage
	
	def annotateModelForDeadlockCoverage() {
		if (!DEADLOCK_COVERAGE) {
			return
		}
		for (transition : coverableDeadlockTransitions.filter[it.needsAnnotation]) {
			val variable = transition.createTransitionVariable(deadlockTransitionVariables)
			transition.effects += variable.createAssignment(createTrueExpression)
		}
	}
	
	def getDeadlockTransitionVariables() {
		return new TransitionAnnotations(this.deadlockTransitionVariables)
	}
	
	// Nondeterministic transition coverage
	
	protected def getNondeterministicTrapState(Region region) {
		if (!nondeterministicTrapStates.containsKey(region)) {
			val trapState = region.createState(namings.trapStateName)
			nondeterministicTrapStates += region -> trapState
		}
		
		return nondeterministicTrapStates.get(region)
	}
	
	protected def getNondeterministicTrapState(Transition transition) {
		val source = transition.sourceState
		val parentRegion = source.parentRegion
		
		return parentRegion.nondeterministicTrapState
	}
	
	def annotateModelForNondeterministicTransitionCoverage() {
		if (!NONDETERMINISTIC_TRANSITION_COVERAGE) {
			return
		}
		val alreadyCoveredTransitions = newHashSet
		for (transition : coverableNondeterministicTransitions
				.filter[it.needsAnnotation].reject[it.^else]) { // No 'else' transitions
			val statechart = transition.containingStatechart
			val source = transition.sourceState
			val potentiallyNondeterministicTransitions = coverableNondeterministicTransitions
					.filter[it !== transition && it.sourceState === source && !it.^else &&
						!alreadyCoveredTransitions.contains(transition -> it)]
			for (potentiallyNondeterministicTransition : potentiallyNondeterministicTransitions) {
				//
				alreadyCoveredTransitions += transition -> potentiallyNondeterministicTransition
				alreadyCoveredTransitions += potentiallyNondeterministicTransition -> transition
				//
				val trapState = transition.nondeterministicTrapState // Only if there is a potential transition
				
				val mergedTransition = transition.clone
				statechart.transitions += mergedTransition
				
				val otherTrigger = potentiallyNondeterministicTransition.trigger?.clone
				mergedTransition.extendTrigger(otherTrigger, BinaryType.AND)
				
				val otherGuard = potentiallyNondeterministicTransition.guard?.clone
				mergedTransition.extendGuard(otherGuard, createAndExpression)
				
				mergedTransition.effects.clear
				
				mergedTransition.targetState = trapState
			}
		}
	}
	
	def getTrapStates() {
		return nondeterministicTrapStates.values
	}
	
	// Transition coverage
	
	protected def needsAnnotation(Transition transition) {
		return !(transition.sourceState instanceof EntryState)
	}
	
	protected def createTransitionVariable(Transition transition,
			Map<Transition, VariableDeclaration> variables) {
		val statechart = transition.containingStatechart
		val variableDeclarations = statechart.variableDeclarations
		
		val name = namings.getVariableName(transition)
		
		// Same variable as we want to inject, e.g., pre-injected boolean variables for transitions
		val foundVariable = variableDeclarations.findFirst[it.name == name && it.resettable &&
				it.typeDefinition instanceof BooleanTypeDefinition]
		//
		val variable = (foundVariable !== null) ? foundVariable :
				createBooleanTypeDefinition.createVariableDeclaration(name)
		statechart.variableDeclarations += variable // Variable may be added "again" to the list (nothing happens)
		variables.put(transition, variable)
		
		variable.addResettableAnnotation // Annotation will not be duplicated if already present
		
		variable.addInjectedAnnotation
		
		return variable
	}

	//
	
	def annotateModelForTransitionCoverage() {
		if (!TRANSITION_COVERAGE) {
			return
		}
		for (transition : coverableTransitions.filter[it.needsAnnotation]) {
			val variable = transition.createTransitionVariable(transitionVariables)
			transition.effects += variable.createAssignment(createTrueExpression)
		}
	}
	
	def getTransitionVariables() {
		return new TransitionAnnotations(this.transitionVariables)
	}
	
	// Transition pair coverage
	
	protected def isIncomingTransition(Transition transition) {
		return transition.targetState instanceof State
	}
	
	protected def isOutgoingTransition(Transition transition) {
		return transition.sourceState instanceof State
	}
	
	protected def getTransitionId(Transition transition) {
		if (!transitionIds.containsKey(transition)) {
			transitionIds.put(transition, transitionId++)
		}
		return transitionIds.get(transition)
	}
	
	protected def getOrCreateVariablePair(State state) {
		// Now every time a new variable pair is created, this could be optimized later
		// e.g., states, that are not reachable from each other, could use the same variable pair
		if (!transitionPairVariables.containsKey(state)) {
			val statechart = state.containingStatechart
			val variablePair = statechart.createVariablePair(null, null, true /*For transition-pairs */,
				false /*They are not resettable, as two consecutive cycles have to be considered*/)
			transitionPairVariables.put(state, variablePair)
		}
		return transitionPairVariables.get(state)
	}
	
	def annotateModelForTransitionPairCoverage() {
		if (!TRANSITION_PAIR_COVERAGE) {
			return
		}
		val incomingTransitions = coverableTransitionPairs.filter[it.incomingTransition]
		val outgoingTransitions = coverableTransitionPairs.filter[it.outgoingTransition]
		val incomingTransitionAnnotations = newArrayList
		val outgoingTransitionAnnotations = newArrayList
		// States with incoming and outgoing transitions
		val states = incomingTransitions.map[it.targetState].filter(State).toSet
		states.retainAll(outgoingTransitions.map[it.sourceState].toList)
		for (state : states) {
			val variablePair = state.getOrCreateVariablePair
			val firstVariable = variablePair.first
			val secondVariable = variablePair.second
			state.exitActions += secondVariable.createAssignment(firstVariable.createReferenceExpression)
		}
		for (incomingTransition : incomingTransitions) {
			val incomingId =  incomingTransition.transitionId
			val state = incomingTransition.targetState as State
			val variablePair = state.getOrCreateVariablePair
			val firstVariable = variablePair.first
			val secondVariable = variablePair.second
			incomingTransition.effects += firstVariable.createAssignment(incomingId.toIntegerLiteral) /*FirstVariable*/
			incomingTransitionAnnotations += new TransitionAnnotation(incomingTransition,
				secondVariable /*SecondVariable, as the exit action in the state will shift it here*/, incomingId)
		}
		for (outgoingTransition : outgoingTransitions) {
			val outgoingId =  outgoingTransition.transitionId
			val state = outgoingTransition.sourceState as State
			val variablePair = state.getOrCreateVariablePair
			val firstVariable = variablePair.first
			outgoingTransition.effects += firstVariable.createAssignment(outgoingId.toIntegerLiteral)
			outgoingTransitionAnnotations += new TransitionAnnotation(outgoingTransition,
				firstVariable, outgoingId)
		}
		for (incomingTransitionAnnotation : incomingTransitionAnnotations) {
			val incomingTransition = incomingTransitionAnnotation.getTransition
			val state = incomingTransition.targetState as State
			for (outgoingTransitionAnnotation : outgoingTransitionAnnotations
					.filter[it.transition.sourceState === state]) {
				// Annotation objects are NOT cloned
				transitionPairAnnotations += new TransitionPairAnnotation(
					incomingTransitionAnnotation, outgoingTransitionAnnotation)
			}
		}
	}
	
	def getTransitionPairAnnotations() {
		return transitionPairAnnotations
	}
	
	// Interaction coverage
	
	protected def hasSendingId(RaiseEventAction action) {
		return sendingIds.containsKey(action)
	}
	
	protected def getSendingId(RaiseEventAction action) {
		if (!sendingIds.containsKey(action)) {
			if (SENDER_INTERACTION_TUPLE == InteractionCoverageCriterion.EVERY_INTERACTION) {
				sendingIds.put(action, senderId++)
			}
			else {
				val actions = sendingIds.keySet
				var found = false
				for (var i = 0; i < actions.size && !found; i++) {
					val actionWithId = actions.get(i)
					if (action.needSameId(actionWithId)) {
						val originalId = sendingIds.get(actionWithId)
						sendingIds.put(action, originalId)
						found = true
					}
				}
				if (!found) {
					sendingIds.put(action, senderId++)
				}
			}
		}
		return sendingIds.get(action)
	}
	
	protected def needSameId(RaiseEventAction lhs, RaiseEventAction rhs) {
		if (SENDER_INTERACTION_TUPLE == InteractionCoverageCriterion.EVERY_INTERACTION ||
				lhs.containingStatechart !== rhs.containingStatechart) {
				// This way, raise event actions in different statecharts get different ids: crucial during property generation
			return false 
		}
		val lhsState = lhs.correspondingStateNode
		val rhsState = rhs.correspondingStateNode
		val isSamePortEvent = lhs.hasSamePortEvent(rhs) // Arguments are not checked
		return SENDER_INTERACTION_TUPLE == InteractionCoverageCriterion.STATES_AND_EVENTS &&
				lhsState === rhsState && isSamePortEvent ||
			SENDER_INTERACTION_TUPLE == InteractionCoverageCriterion.EVENTS && isSamePortEvent
	}
	
	protected def getCorrespondingStateNode(RaiseEventAction action) {
		return action.containingOrSourceStateNode
	}
	
	protected def getReceivingId(Transition transition) {
		if (!receivingIds.containsKey(transition)) {
			if (RECEIVER_INTERACTION_TUPLE == InteractionCoverageCriterion.EVERY_INTERACTION) {
				receivingIds.put(transition, recevierId++)
			}
			else {
				val transitions = receivingIds.keySet
				var found = false
				for (var i = 0; i < transitions.size && !found; i++) {
					val transitionWithId = transitions.get(i)
					if (transition.needSameId(transitionWithId)) {
						val originalId = receivingIds.get(transitionWithId)
						receivingIds.put(transition, originalId)
						found = true
					}
				}
				if (!found) {
					receivingIds.put(transition, recevierId++)
				}
			}
		}
		return receivingIds.get(transition)
	}
	
	protected def needSameId(Transition lhs, Transition rhs) {
		if (RECEIVER_INTERACTION_TUPLE == InteractionCoverageCriterion.EVERY_INTERACTION ||
				lhs.containingStatechart !== rhs.containingStatechart) {
			// This way, the transitions in different statecharts get different ids: crucial during property generation
			return false 
		}
		val lhsSource = lhs.sourceState
		val lhsTrigger = lhs.trigger
		val rhsSource = rhs.sourceState
		val rhsTrigger = rhs.trigger
		val equals = lhsTrigger.helperEquals(rhsTrigger)
		// Composite triggers and their possible relations are NOT considered now
		return RECEIVER_INTERACTION_TUPLE == InteractionCoverageCriterion.STATES_AND_EVENTS &&
				lhsSource === rhsSource && equals ||
			RECEIVER_INTERACTION_TUPLE == InteractionCoverageCriterion.EVENTS && equals
	}
	
	protected def getInteractionVariables(Region region) {
		return regionInteractionVariables.getOrCreateList(region)
	}
	
	protected def getInteractionVariables(StatechartDefinition statechart) {
		return statechartInteractionVariables.getOrCreateList(statechart)
	}
	
	protected def getReceivingInteractions(Transition transition) {
		return receivingInteractions.getOrCreateList(transition)
	}
	
	protected def putReceivingInteraction(Transition transition, Port port, Event event) {
		val interactions = transition.receivingInteractions
		interactions += new SimpleEntry(port, event)
	}
	
	protected def hasReceivingInteraction(Transition transition, Port port, Event event) {
		val receivingInteractionsOfTransition = transition.receivingInteractions
		return receivingInteractionsOfTransition.contains(new SimpleEntry(port, event))
	}
	
	protected def isThereEnoughInteractionVariable(Transition transition) {
		val region = transition.correspondingRegion
		val interactionVariablesList = region.interactionVariables
		val receivingInteractionsList = transition.receivingInteractions
		return receivingInteractionsList.size <= interactionVariablesList.size
	}
	
	protected def getCorrespondingRegion(Transition transition) {
		return transition.sourceState.parentRegion
	}
	
	protected def getOrCreateInteractionVariablePair(Transition transition) {
		val region = transition.correspondingRegion
		val statechart = region.containingStatechart
		val regionInteractionVariables = region.interactionVariables
		val statechartInteractionVariables = statechart.interactionVariables
		return region.getOrCreateVariablePair(regionInteractionVariables,
			statechartInteractionVariables, RECEIVER_CONSIDERATION, true)
	}
	
	protected def getInteractionVariables(Transition transition, Port port, Event event) {
		if (!transition.isThereEnoughInteractionVariable) {
			transition.getOrCreateInteractionVariablePair
		}
		val interactions = transition.receivingInteractions
		// The i. interaction is saved using the i. variable
		val index = interactions.indexOf(new SimpleEntry(port, event))
		val region = transition.correspondingRegion
		val regionVariables = region.interactionVariables
		return regionVariables.get(index)
	}
	
	def annotateModelForInteractionCoverage() {
		if (!INTERACTION_COVERAGE) {
			return
		}
		val interactionMatcher = RaiseInstanceEvents.Matcher.on(engine)
		val matches = interactionMatcher.allMatches
		val relevantMatches = matches
			.filter[ // If BOTH sender and receiver elements are included, the interaction is covered
				interactionCoverablePorts.contains(it.outPort) &&
					interactionCoverablePorts.contains(it.inPort) &&
				interactionCoverableStates.contains(it.raiseEventAction.correspondingStateNode) &&
				interactionCoverableStates.contains(it.receivingTransition.sourceState) &&
				(it.raiseEventAction.containingTransitionOrState instanceof State ||
					interactionCoverableTransitions.contains(
						it.raiseEventAction.containingTransitionOrState)) && 
				interactionCoverableTransitions.contains(it.receivingTransition)]
			// Filtering definitely impossible interaction points (event parameter arguments)
			.reject[it.receivingTransition.guard.areDefinitelyFalseArguments(
				it.inPort, it.raisedEvent, it.raiseEventAction.arguments)]
		
		val raisedEvents = relevantMatches.map[it.raisedEvent].toSet // Set, so one event is set only once
		// Creating event parameters
		for (event : raisedEvents) {
			val idParameter = event.extendEventWithParameter(
					createIntegerTypeDefinition, namings.getParameterName(event))
			idParameter.addInternalAnnotation
			// Parameter is always the last
		}
		
		// Sorting according to in events helps to create id assignments to a minimal number
		// of variables when RECEIVER_CONSIDERATION is false and there are complex triggers
		val sortedRelevantMatches = relevantMatches.sortBy[
			'''«raiseEventAction.containingStatechart.name»_«inPort.name»_«raisedEvent.name»''']
		for (match : sortedRelevantMatches) {
			// Sending
			val raiseEventAction = match.raiseEventAction
			if (!raiseEventAction.hasSendingId) {
				// One raise event action can synchronize to multiple transitions (broadcast channel)
				val sendingId = raiseEventAction.sendingId // Must not be retrieved before the enclosing If
				raiseEventAction.arguments += sendingId.toIntegerLiteral
			}
			// Receiving
			val inPort = match.inPort
			val event = match.raisedEvent
			val inParameter = event.parameterDeclarations.last // It is always the last
			val receivingTransition = match.receivingTransition
			
			// We do not want to duplicate the same assignments to the same variable
			if (!receivingTransition.hasReceivingInteraction(inPort, event)) {
				receivingTransition.putReceivingInteraction(inPort, event)

				val interactionVariables = receivingTransition.getInteractionVariables(
						inPort, event)
				val senderVariable = interactionVariables.first
				// Sender assignment, necessary even when receiver is not
				receivingTransition.effects += senderVariable.createAssignment(
					createEventParameterReferenceExpression => [
						it.port = inPort
						it.event = event
						it.parameter = inParameter
					]
				)
				if (RECEIVER_CONSIDERATION) {
					val receivingId = receivingTransition.receivingId
					val receiverVariable = interactionVariables.second
					// Receiver assignment
					receivingTransition.effects += receiverVariable.createAssignment(
						receivingId.toIntegerLiteral)
				}
			}
			val variablePair = receivingTransition.getInteractionVariables(inPort, event)
			interactions += new Interaction(raiseEventAction, receivingTransition,
				variablePair, raiseEventAction.sendingId, receivingTransition.receivingId)
		}
		
		// Due to well-formedness constraints, unattended raise event actions
		// have to have the correct number of arguments - they get the 0 (reset) id
		val attendedRaiseEventActions = relevantMatches.map[it.raiseEventAction].toSet
		attendedRaiseEventActions.extendUnattendedRaiseEventActions
	}
	
	protected def extendUnattendedRaiseEventActions(
			Collection<? extends RaiseEventAction> attendedRaiseEventActions) {
		val rootContainers = attendedRaiseEventActions.map[it.root].toSet
		val raisedEvents = attendedRaiseEventActions.map[it.event].toSet
		val raiseEventActions = rootContainers
				.map[it.getSelfAndAllContentsOfType(RaiseEventAction)].flatten
				.filter[raisedEvents.contains(it.event)].toSet
		raiseEventActions -= attendedRaiseEventActions
		for (raiseEventAction : raiseEventActions) {
			raiseEventAction.arguments += 0.toIntegerLiteral // Default value
		}
	}
	
	// Data-flow coverage - utility methods for both dataflows
	
	protected def void saveDefId(EObject definition, ValueDeclaration defVariable,
			Map<EObject, DefVariableId> defIds, long defId) {
		if (!defIds.containsKey(definition)) {
			defIds += definition -> new DefVariableId(defVariable, defId)
		}
	}
	
	protected def createUseVariable(ReferenceExpression reference,
			Map<ReferenceExpression, VariableDeclaration> useMap, String name) {
		if (!useMap.containsKey(reference)) {
			val statechart = reference.containingStatechart
			val useVariable = createIntegerTypeDefinition.createVariableDeclaration(name)
			
			useVariable.addResettableAnnotation
			useVariable.addInjectedAnnotation
			
			statechart.variableDeclarations += useVariable
			useMap += reference -> useVariable
		}
		return useMap.get(reference)
	}
	
	protected def void saveDefUseVariablePair(ReferenceExpression reference,
			ValueDeclaration defVariable, VariableDeclaration useVariable,
			Map<ReferenceExpression, DefUseVariablePair> defUseVariablePairs) {
		if (!defUseVariablePairs.containsKey(reference)) {
			defUseVariablePairs += reference -> new DefUseVariablePair(defVariable, useVariable)
		}
	}
	
	// Utility methods for plain dataflow
	
	protected def createDefVariable(ValueDeclaration originalDeclaration,
			Map<ValueDeclaration, VariableDeclaration> defMap, String name) {
		if (!defMap.containsKey(originalDeclaration)) {
			val statechart = originalDeclaration.containingStatechart
			
			val defVariable = createIntegerTypeDefinition.createVariableDeclaration(name)
			defVariable.addInjectedAnnotation
			
			statechart.variableDeclarations += defVariable
			defMap += originalDeclaration -> defVariable
		}
		return defMap.get(originalDeclaration)
	}
	
	protected def void saveDefId(DirectReferenceExpression definition, VariableDeclaration defVariable) {
		definition.saveDefId(defVariable, defIds, defId)
		defId++
	}
	
	protected def saveDefUseVariablePair(DirectReferenceExpression reference,
			VariableDeclaration defVariable, VariableDeclaration useVariable) {
		reference.saveDefUseVariablePair(defVariable, useVariable, defUseVariablePairs)
	}
	
	//
	
	def annotateModelForDataFlowCoverage() {
		if (!DATAFLOW_COVERAGE) {
			return
		}
		val defReferences = newHashSet
		val defMatcher = VariableDefs.Matcher.on(engine)
		defReferences += defMatcher.allValuesOfreference
		
		val useReferences = newHashSet
		switch (DATAFLOW_COVERAGE_CRITERION) {
			case ALL_P_USE: {
				val useMatcher = VariablePUses.Matcher.on(engine)
				useReferences += useMatcher.allValuesOfreference
			}
			case ALL_C_USE: {
				val useMatcher = VariableCUses.Matcher.on(engine)
				useReferences += useMatcher.allValuesOfreference
			}
			case ALL_DEF,
			case ALL_USE: {
				val useMatcher = VariableUses.Matcher.on(engine)
				useReferences += useMatcher.allValuesOfreference
			}
		}
		// Optimization
		val consideredVariables = newHashSet
		consideredVariables += defMatcher.allValuesOfvariable
		consideredVariables.retainAll(useReferences.map[it.declaration].toSet)
		consideredVariables.retainAll(dataflowCoverableVariables) // Only considered vars
		
		defReferences.removeIf[!consideredVariables.contains(it.declaration)]
		useReferences.removeIf[!consideredVariables.contains(it.declaration)]
		
		// Creating and caching the variables
		// Def
		for (defReference : defReferences) {
			val referredVariable = defReference.declaration as VariableDeclaration
			val defVariable = referredVariable.createDefVariable(defVariables,
				namings.getDefVariableName(referredVariable))
			defReference.saveDefId(defVariable)
		}
		// Use
		for (useReference : useReferences) {
			val referredVariable = useReference.declaration as VariableDeclaration
			val useVariable = useReference.createUseVariable(useVariables,
				namings.getUseVariableName(referredVariable))
			val defVariable = defVariables.get(referredVariable)
			useReference.saveDefUseVariablePair(defVariable, useVariable)
		}
		
		defIds.annotateModelForDataflowCoverage(defUseVariablePairs)
		// "Connections" are made when calling the getter method
	}
	
	protected def annotateModelForDataflowCoverage(Map<? extends EObject, DefVariableId> defIds,
			Map<? extends ReferenceExpression, DefUseVariablePair> defUseVariablePairs) {
		// Defs first, e.g., for a := a + 3 (see append) 
		for (defReference : defIds.keySet) {
			val defVariableId = defIds.get(defReference)
			val defVariable = defVariableId.defVariable as VariableDeclaration
			val id = defVariableId.defId
			
			val assignment = defVariable.createAssignment(id.toIntegerLiteral)
			
			defReference.extendDefReference(assignment)
		}
		// Uses second
		for (useReference : defUseVariablePairs.keySet) {
			val defUseVariablePair = defUseVariablePairs.get(useReference)
			val defVariable = defUseVariablePair.defVariable
			val useVariable = defUseVariablePair.useVariable
			val assignment = useVariable.createAssignment(defVariable)
			
			useReference.extendUseReference(assignment)
		}
	}
	
	protected def extendDefReference(EObject defReference, Action annotationAction) {
		val originalAssignment = defReference.getSelfOrContainerOfType(Action)
		originalAssignment.append(annotationAction)
	}
	
	protected def extendUseReference(ReferenceExpression useReference, Action annotationAction) {
		val containingAction = useReference.getContainerOfType(Action)
		if (containingAction === null) {
			// p-use in transition guards
			val actionList = useReference.containingActionList
			actionList.add(0, annotationAction)
			// Maybe this action should rather be put in the entry action of the source state
			// Or the previous transition in the case of a choice node to simulate non-determinism
		}
		else {
			val containingBranch = useReference.getContainerOfType(Branch)
			if (containingBranch !== null) {
				// p-use in a branch guard
				val guard = containingBranch.guard
				if (guard.containsTransitively(useReference)) {
					if (containingBranch.containedByChoiceStatement) {
						val choiceStatement = containingBranch.getContainerOfType(ChoiceStatement)
						// Nondeterministic: the declaration is used if the execution gets to the choice
						annotationAction.prepend(choiceStatement)
					}
					else {
						if (containingBranch.containedByIfStatement) {
							val ifStatement = containingBranch.getContainerOfType(IfStatement)
							// Deterministic: the declaration is used if the current or a subsequent branch is executed
							ifStatement.getOrCreateElseBranch // An (implicit) else branch is needed
						}
						else if (containingBranch.containedBySwitchStatement) {
							val switchStatement = containingBranch.getContainerOfType(SwitchStatement)
							// Deterministic: the declaration is used if the current or a subsequent branch is executed
							switchStatement.getOrCreateDefaultBranch // An (implicit) default branch is needed
						}
						containingBranch.extendThisAndNextBranches(annotationAction)
					}
				}
			}
			// c-use
			containingAction.append(annotationAction)
		}
	}
	
	// Utility methods for interaction dataflow
	
	protected def void saveDefId(RaiseEventAction definition, ParameterDeclaration defVariable) {
		definition.saveDefId(defVariable, interactionDefIds, interactionDefId)
		interactionDefId++
	}
	
	protected def saveDefUseVariablePair(EventParameterReferenceExpression reference,
			ParameterDeclaration defVariable, VariableDeclaration useVariable) {
		reference.saveDefUseVariablePair(defVariable, useVariable, interactionDefUseVariablePairs)
	}
	
	// Interaction dataflow
	
	def annotateModelForInteractionDataFlowCoverage() {
		if (!INTERACTION_DATAFLOW_COVERAGE) {
			return
		}
		val pUseMatcher = InteractionPUses.Matcher.on(engine)
		val cUseMatcher = InteractionCUses.Matcher.on(engine)
		val allUseMatcher = InteractionUses.Matcher.on(engine)
		
		val defReferences = <RaiseEventAction>newHashSet
		val useReferences = <EventParameterReferenceExpression>newHashSet
		connectedPorts.clear // Used in the getter method
		
		switch (INTERACTION_DATAFLOW_COVERAGE_CRITERION) {
			case ALL_P_USE: {
				defReferences += pUseMatcher.allMatches
					.filter[it.inPort.areBothPortsConsidered(it.outPort)]
					.map[it.raiseEventAction]
				useReferences += pUseMatcher.allMatches
					.filter[it.inPort.areBothPortsConsidered(it.outPort)]
					.map[it.reference]
				connectedPorts += pUseMatcher.allMatches
					.filter[it.inPort.areBothPortsConsidered(it.outPort)]
					.map[it.outPort -> it.inPort]
			}
			case ALL_C_USE: {
				defReferences += cUseMatcher.allMatches
					.filter[it.inPort.areBothPortsConsidered(it.outPort)]
					.map[it.raiseEventAction]
				useReferences += cUseMatcher.allMatches
					.filter[it.inPort.areBothPortsConsidered(it.outPort)]
					.map[it.reference]
				connectedPorts += cUseMatcher.allMatches
					.filter[it.inPort.areBothPortsConsidered(it.outPort)]
					.map[it.outPort -> it.inPort]
			}
			case ALL_USE: {
				defReferences += allUseMatcher.allMatches
					.filter[it.inPort.areBothPortsConsidered(it.outPort)]
					.map[it.raiseEventAction]
				useReferences += allUseMatcher.allMatches
					.filter[it.inPort.areBothPortsConsidered(it.outPort)]
					.map[it.reference]
				connectedPorts += allUseMatcher.allMatches
					.filter[it.inPort.areBothPortsConsidered(it.outPort)]
					.map[it.outPort -> it.inPort]
			}
			default: {
				throw new IllegalArgumentException("No supported mode: " + INTERACTION_DATAFLOW_COVERAGE_CRITERION)
			}
		}
		
		val raisedEvents = defReferences.map[it.event].toSet // Set, so one event is set only once
		// Creating event parameters
		for (event : raisedEvents) {
			event.extendEventWithParameter(createIntegerTypeDefinition,
				namings.getInteractionDefVariableName(event))
			// Parameter is always the last
		}
		
		// Def
		for (defReference : defReferences) {
			val event = defReference.event
			val defVariable = event.parameterDeclarations.last // Parameter is always the last
			defReference.saveDefId(defVariable)
			// Argument addition is in annotateModelForInteractionDataflowCoverage
		}
		// Use
		for (useReference : useReferences) {
			val event = useReference.event
			val defVariable = event.parameterDeclarations.last // Parameter is always the last
			val useVariable = useReference.createUseVariable(interactionUseVariables,
				namings.getInteractionUseVariableName(useReference))
			useReference.saveDefUseVariablePair(defVariable, useVariable)
		}
		
		interactionDefIds.annotateModelForInteractionDataflowCoverage(interactionDefUseVariablePairs)
		
		// Due to well-formedness constraints, unattended raise event actions
		// have to have the correct number of arguments - they get the 0 (reset) id
		defReferences.extendUnattendedRaiseEventActions
		
		// Collecting parameter transfer between ports among which there is a channel
		// is in the getter method
	}
	
	protected def areBothPortsConsidered(Port inPort, Port outPort) {
		return interactionDataflowCoverablePorts.contains(inPort) &&
			interactionDataflowCoverablePorts.contains(outPort)
	}
	
	protected def annotateModelForInteractionDataflowCoverage(
			Map<? extends EObject, DefVariableId> defIds,
			Map<? extends ReferenceExpression, DefUseVariablePair> defUseVariablePairs) {
		// Defs first
		for (defReference : defIds.keySet.filter(RaiseEventAction)) {
			val defVariableId = defIds.get(defReference)
			val defVariable = defVariableId.defVariable
			val parameterId = defVariable.index
			val id = defVariableId.defId
			
			defReference.arguments.add(parameterId, id.toIntegerLiteral)
		}
		// Uses second
		for (useReference : defUseVariablePairs.keySet.filter(EventParameterReferenceExpression)) {
			val defUseVariablePair = defUseVariablePairs.get(useReference)
			val defVariable = defUseVariablePair.defVariable as ParameterDeclaration
			val defReference = createEventParameterReferenceExpression => [
				it.port = useReference.port
				it.event = useReference.event
				it.parameter = defVariable
			]
			val useVariable = defUseVariablePair.useVariable
			val assignment = useVariable.createAssignment(defReference)
			
			useReference.extendUseReference(assignment)
		}
	}
	
	// Variable pair creators, used both by transition pair and interaction annotation
	
	protected def getOrCreateVariablePair(Region region,
			List<VariablePair> localPool, List<VariablePair> globalPool, boolean createSecond, boolean resettable) {
		val statechart = region.containingStatechart
		if (region.orthogonal) {
			// A new variable is needed for orthogonal regions and it cannot be shared
			return statechart.createVariablePair(localPool,
				null /*Variables cannot be shared with other regions*/,
				createSecond, resettable)
		}
		// Optimization, maybe a new one does not need to be created
		return statechart.getOrCreateVariablePair(localPool, globalPool, createSecond, resettable)
	}
	
	protected def getOrCreateVariablePair(StatechartDefinition statechart,
			List<VariablePair> localPool, List<VariablePair> globalPool, boolean createSecond, boolean resettable) {
		val localPoolSize = localPool.size
		val globalPoolSize = globalPool.size
		if (localPoolSize < globalPoolSize) {
			// Putting a variable to the local pool from the global pool
			val retrievedVariablePair = globalPool.get(localPoolSize)
			localPool += retrievedVariablePair
			return retrievedVariablePair
		}
		else {
			return statechart.createVariablePair(localPool,
				globalPool /*Variables can be shared with other regions*/,
				createSecond, resettable)
		}
	}
	
	protected def createVariablePair(StatechartDefinition statechart,
			List<VariablePair> localPool, List<VariablePair> globalPool, boolean createSecond, boolean resettable) {
		val senderVariable = createIntegerTypeDefinition.createVariableDeclaration(
			namings.getFirstVariableName(statechart))
		statechart.variableDeclarations += senderVariable
		var VariableDeclaration receiverVariable = null
		if (createSecond) {
			receiverVariable = createIntegerTypeDefinition.createVariableDeclaration(
				namings.getSecondVariableName(statechart))
			statechart.variableDeclarations += receiverVariable
		}
		val variablePair = new VariablePair(senderVariable, receiverVariable)
		
		if (localPool !== null) {
			localPool += variablePair
		}
		if (globalPool !== null) {
			globalPool += variablePair
		}
		
		if (resettable) {
			senderVariable.addResettableAnnotation
			receiverVariable.addResettableAnnotation
		}
		
		senderVariable.addInjectedAnnotation
		receiverVariable.addInjectedAnnotation
		
		return variablePair
	}
	
	// Def-use connector
	
	protected def connectDefUses(Map<EObject, DefVariableId> defIds,
			Map<ReferenceExpression, DefUseVariablePair> defUseVariablePairs) {
		val variableIds = newHashMap
		
		for (defReference : defIds.keySet) {
			val id = defIds.get(defReference)
			
			val defId = id.defId
			val defVariable = id.defVariable
			val defReferenceId = new DefReferenceId(defReference, defId)
			val useVariables = defUseVariablePairs.entrySet
				.filter[it.value.defVariable === defVariable]
				.map[new UseVariable(it.key, it.value.useVariable)]
				.toSet
			variableIds += defReferenceId -> useVariables
		}
		
		return variableIds
	}
	
	// Getters
	
	def getInteractions() {
		return new InteractionAnnotations(this.interactions)
	}
	
	def getVariableDefUses() {
		return defIds.connectDefUses(defUseVariablePairs)
	}
	
	def getDataflowCoverageCriterion() {
		return this.DATAFLOW_COVERAGE_CRITERION
	}
	
	def getInteractionDefUses() {
		val defUses = interactionDefIds.connectDefUses(interactionDefUseVariablePairs)
		val keySet = defUses.keySet
		for (def : keySet.toList) {
			val raiseEventAction = def.defReference as RaiseEventAction
			val outPort = raiseEventAction.port
			val arguments = raiseEventAction.arguments
			val uses = defUses.get(def)
			for (use : uses.toList) {
				val useReference = use.useReference as EventParameterReferenceExpression
				val inPort = useReference.port
				 // For optimization
				val event = useReference.event
				val guard = useReference.getSelfOrLastContainerOfType(Expression)
				val isContainedByTransition = guard.eContainer instanceof Transition
				if (!connectedPorts.contains(outPort -> inPort) ||
						isContainedByTransition && // If the guard is false, the transition cannot fire
						guard.areDefinitelyFalseArguments(inPort, event, arguments)) {
					uses -= use
				}
			}
			if (uses.empty) {
				keySet -= def
			}
		}
		return defUses
	}
	
	def getInteractionDataflowCoverageCriterion() {
		return this.INTERACTION_DATAFLOW_COVERAGE_CRITERION
	}
	
}