package hu.bme.mit.gamma.transformation.util.annotations

import hu.bme.mit.gamma.action.model.Action
import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.action.model.Branch
import hu.bme.mit.gamma.action.model.ChoiceStatement
import hu.bme.mit.gamma.action.model.IfStatement
import hu.bme.mit.gamma.action.model.SwitchStatement
import hu.bme.mit.gamma.expression.model.Declaration
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
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
import java.util.AbstractMap.SimpleEntry
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.Map.Entry
import java.util.Set
import org.eclipse.emf.ecore.EObject
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope
import org.eclipse.xtend.lib.annotations.Data

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.action.derivedfeatures.ActionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class GammaStatechartAnnotator {
	protected final Package gammaPackage
	protected final ViatraQueryEngine engine
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
	protected final Set<ParameterDeclaration> newEventParameters = newHashSet
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
	protected final Map<VariableDeclaration, /* Original variable whose def is marked */
		List<DataflowReferenceVariable> /* Reference-variable pairs denoting if the original variable is set */> variableDefs = newHashMap
	protected final Map<VariableDeclaration, /* Original variable whose use is marked */
		List<DataflowReferenceVariable> /* Reference-variable pairs denoting if the original variable is used */> variableUses = newHashMap
	// Interaction data-flow coverage
	protected boolean INTERACTION_DATAFLOW_COVERAGE
	protected DataflowCoverageCriterion INTERACTION_DATAFLOW_COVERAGE_CRITERION
	protected final Set<ParameterDeclaration> interactionDataflowCoverableParameters = newHashSet
	protected final Map<Pair<Port, ParameterDeclaration>, /* Original parameter whose def is marked */
		List<DataflowReferenceVariable> /* Reference-variable pairs denoting if the original parameter is set */> parameterDefs = newHashMap
	protected final Map<Pair<Port, ParameterDeclaration>, /* Original parameter whose use is marked */
		List<DataflowReferenceVariable> /* Reference-variable pairs denoting if the original parameter is used */> parameterUses = newHashMap
	protected final List<Pair<DefUseReferences /* Defs */, DefUseReferences /* Uses */>> interactionDefUses = newArrayList
	// Factories
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionModelFactory = ActionModelFactory.eINSTANCE
	protected final extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	// Namings
	protected final AnnotationNamings namings = new AnnotationNamings // Instance due to the id
	
	new(Package gammaPackage,
			Collection<SynchronousComponentInstance> transitionCoverableComponents,
			Collection<SynchronousComponentInstance> transitionPairCoverableComponents,
			Collection<Port> interactionCoverablePorts, Collection<State> interactionCoverableStates,
			Collection<Transition> interactionCoverableTransitions,
			Collection<VariableDeclaration> dataflowCoverableVariables, DataflowCoverageCriterion dataflowCoverageCriterion) {
		this(gammaPackage, transitionCoverableComponents, transitionPairCoverableComponents,
			interactionCoverablePorts, interactionCoverableStates,
			interactionCoverableTransitions, InteractionCoverageCriterion.EVERY_INTERACTION,
				InteractionCoverageCriterion.EVERY_INTERACTION,
			dataflowCoverableVariables, dataflowCoverageCriterion)
	}
	
	new(Package gammaPackage,
			Collection<SynchronousComponentInstance> transitionCoverableComponents,
			Collection<SynchronousComponentInstance> transitionPairCoverableComponents,
			Collection<Port> interactionCoverablePorts, Collection<State> interactionCoverableStates,
			Collection<Transition> interactionCoverableTransitions,
			InteractionCoverageCriterion senderInteractionTuple, InteractionCoverageCriterion receiverInteractionTuple,
			Collection<VariableDeclaration> dataflowCoverableVariables, DataflowCoverageCriterion dataflowCoverageCriterion) {
		this.gammaPackage = gammaPackage
		this.engine = ViatraQueryEngine.on(new EMFScope(gammaPackage.eResource.resourceSet))
		if (!transitionCoverableComponents.empty) {
			this.TRANSITION_COVERAGE = true
			this.transitionCoverableComponents += transitionCoverableComponents
			this.coverableTransitions += transitionCoverableComponents
				.map[it.type].filter(StatechartDefinition)
				.map[it.transitions].flatten
		}
		if (!transitionPairCoverableComponents.empty) {
			this.TRANSITION_PAIR_COVERAGE = true
			this.transitionPairCoverableComponents += transitionPairCoverableComponents
			this.coverableTransitionPairs += transitionPairCoverableComponents
				.map[it.type].filter(StatechartDefinition)
				.map[it.transitions].flatten
		}
		if (!interactionCoverablePorts.isEmpty) {
			this.INTERACTION_COVERAGE = true
			this.SENDER_INTERACTION_TUPLE = senderInteractionTuple
			this.RECEIVER_INTERACTION_TUPLE = receiverInteractionTuple
			this.interactionCoverablePorts += interactionCoverablePorts
			this.interactionCoverableStates += interactionCoverableStates
			this.interactionCoverableTransitions += interactionCoverableTransitions
		}
		this.RECEIVER_CONSIDERATION =
			RECEIVER_INTERACTION_TUPLE != InteractionCoverageCriterion.EVENTS
		if (!dataflowCoverableVariables.isEmpty) {
			this.DATAFLOW_COVERAGE = true
			this.dataflowCoverableVariables += dataflowCoverableVariables
			this.DATAFLOW_COVERAGE_CRITERION = dataflowCoverageCriterion
		}
		if (false) { // TODO introduce parameters
			this.INTERACTION_DATAFLOW_COVERAGE = true
			this.INTERACTION_DATAFLOW_COVERAGE_CRITERION = DataflowCoverageCriterion.ALL_USE
		}
	}
	
	// Transition coverage
	
	protected def needsAnnotation(Transition transition) {
		return !(transition.sourceState instanceof EntryState)
	}
	
	protected def createTransitionVariable(Transition transition,
			Map<Transition, VariableDeclaration> variables, boolean isResetable) {
		val statechart = transition.containingStatechart
		val variable = createVariableDeclaration => [
			it.type = createBooleanTypeDefinition
			it.name = namings.getVariableName(transition)
		]
		statechart.variableDeclarations += variable
		variables.put(transition, variable)
		if (isResetable) {
			variable.designateVariableResetable
		}
		return variable
	}

	//
	
	def annotateModelForTransitionCoverage() {
		if (!TRANSITION_COVERAGE) {
			return
		}
		for (transition : coverableTransitions.filter[it.needsAnnotation]) {
			val variable = transition.createTransitionVariable(transitionVariables, true)
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
		val lhsContainer = lhs.containingTransitionOrState
		val rhsContainer = rhs.containingTransitionOrState
		if (SENDER_INTERACTION_TUPLE == InteractionCoverageCriterion.EVERY_INTERACTION ||
				lhs.containingStatechart !== rhs.containingStatechart ||
				/*The algorithm would be correct without this too
				  This way, the raise event actions in different statecharts get different ids*/ 
				lhsContainer instanceof State || rhsContainer instanceof State) {
			return false 
		}
		val lhsState = lhs.correspondingStateNode
		val rhsState = rhs.correspondingStateNode
		// This way, arguments have to be equal
		return SENDER_INTERACTION_TUPLE == InteractionCoverageCriterion.STATES_AND_EVENTS &&
				lhsState === rhsState && lhs.helperEquals(rhs) ||
			SENDER_INTERACTION_TUPLE == InteractionCoverageCriterion.EVENTS && lhs.helperEquals(rhs)
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
			// The algorithm would be correct without this too
			// This way, the transitions in different statecharts get different ids 
			return false 
		}
		val lhsSource = lhs.sourceState
		val lhsTrigger = lhs.trigger
		val rhsSource = rhs.sourceState
		val rhsTrigger = rhs.trigger
		// Composite triggers and their possible relations are NOT considered now
		return RECEIVER_INTERACTION_TUPLE == InteractionCoverageCriterion.STATES_AND_EVENTS &&
				lhsSource === rhsSource && lhsTrigger.helperEquals(rhsTrigger) ||
			RECEIVER_INTERACTION_TUPLE == InteractionCoverageCriterion.EVENTS && lhsTrigger.helperEquals(rhsTrigger)
	}
	
	protected def getInteractionVariables(Region region) {
		if (!regionInteractionVariables.containsKey(region)) {
			regionInteractionVariables.put(region, newArrayList)
		}
		return regionInteractionVariables.get(region)
	}
	
	protected def getInteractionVariables(StatechartDefinition statechart) {
		if (!statechartInteractionVariables.containsKey(statechart)) {
			statechartInteractionVariables.put(statechart, newArrayList)
		}
		return statechartInteractionVariables.get(statechart)
	}
	
	protected def getReceivingInteractions(Transition transition) {
		if (!receivingInteractions.containsKey(transition)) {
			receivingInteractions.put(transition, newArrayList)
		}
		return receivingInteractions.get(transition)
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
				// Filtering definitely bad arguments
				.reject[it.receivingTransition.guard.areDefinitelyFalseArguments(
					it.inPort, it.raisedEvent, it.raiseEventAction.arguments)]
		
		val raisedEvents = relevantMatches.map[it.raisedEvent].toSet // Set, so one event is set only once
		// Creating event parameters
		for (event : raisedEvents) {
			val newParameter = createParameterDeclaration => [
				it.type = createIntegerTypeDefinition
				it.name = namings.getParameterName(event)
			]
			event.parameterDeclarations += newParameter // It is always the last
			newEventParameters += newParameter
		}
		
		// Annotating raise event actions and transitions
		for (match : relevantMatches) {
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
	}
	
	// Data-flow coverage
	
	protected def createDefUseVariable(DirectReferenceExpression reference,
			Map<VariableDeclaration, List<DataflowReferenceVariable>> defUseMap,
			String name, boolean isResetable) {
		val statechart = reference.containingStatechart
		val referredVariable = reference.declaration as VariableDeclaration
		val defUseVariable = createVariableDeclaration => [
			it.type = createBooleanTypeDefinition
			it.name = name
		]
		statechart.variableDeclarations += defUseVariable
		if (!defUseMap.containsKey(referredVariable)) {
			defUseMap.put(referredVariable, newArrayList)
		}
		val variableDefList = defUseMap.get(referredVariable)
		variableDefList += new DataflowReferenceVariable(reference, defUseVariable)
		if (isResetable) {
			defUseVariable.designateVariableResetable
		}
		return defUseVariable
	}
	
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
		// Creating the variables
		// Def
		for (defReference : defReferences) {
			val referredVariable = defReference.declaration as VariableDeclaration
			defReference.createDefUseVariable(variableDefs,
				namings.getDefVariableName(referredVariable), false)
		}
		// Use
		for (useReference : useReferences) {
			val referredVariable = useReference.declaration as VariableDeclaration
			useReference.createDefUseVariable(variableUses,
				namings.getUseVariableName(referredVariable), true)
		}
		
		defReferences.annotateModelForDataflowCoverage(useReferences, 
			new DataflowDeclarationHandler {
				override getDefDataflowReferences(EObject defReference) {
					val directReference = defReference as DirectReferenceExpression
					val originalVariable = directReference.declaration as VariableDeclaration
					return variableDefs.get(originalVariable)
				}
				override getUseVariable(ReferenceExpression useReference) {
					val useDataflowReference = variableUses.values.flatten
							.filter[it.getOriginalVariableReference === useReference]
					checkState(useDataflowReference.size == 1)
					return useDataflowReference.head.getDefUseVariable
				}
			}
		)
	}
	
	protected def annotateModelForDataflowCoverage(Set<? extends EObject> defReferences,
			Set<? extends ReferenceExpression> useReferences, DataflowDeclarationHandler handler) {
		// Every def variable must be created before this next loop
		for (defReference : defReferences) {
			val defVariablePairList = handler.getDefDataflowReferences(defReference)
			val originalAssignment = defReference.getSelfOrContainerOfType(Action)
			for (defVariablePair : defVariablePairList) {
				val reference = defVariablePair.getOriginalVariableReference
				val defVariable = defVariablePair.getDefUseVariable
				val expression = defReference === reference ? createTrueExpression : createFalseExpression
				originalAssignment.append(defVariable.createAssignment(expression))
			}
		}
		// Every use variable must be created before this next loop
		for (useReference : useReferences) {
			val useVariable = handler.getUseVariable(useReference)
			val assignment = useVariable.createAssignment(createTrueExpression)
			val containingAction = useReference.getContainerOfType(Action)
			if (containingAction === null) {
				// p-use in transition guards
				val actionList = useReference.containingActionList
				actionList.add(0, assignment)
				// Maybe this action should rather be put in the entry action of the source state
				// Or the previous transition in the case of a choice node to simulate non-determinism
			}
			else {
				val containingBranch = useReference.getContainerOfType(Branch)
				if (containingBranch !== null) {
					// p-use in a branch guard
					val guard = containingBranch.guard
					if (guard.contains(useReference)) {
						if (containingBranch.containedByChoiceStatement) {
							val choiceStatement = containingBranch.getContainerOfType(ChoiceStatement)
							// Nondeterministic: the declaration is used if the execution gets to the choice
							assignment.prepend(choiceStatement)
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
							containingBranch.extendThisAndNextBranches(assignment)
						}
					}
				}
				// c-use
				containingAction.append(assignment)
			}
		}
	}
	
	static interface DataflowDeclarationHandler {
		def Collection<DataflowReferenceVariable> getDefDataflowReferences(EObject defReference)
		def VariableDeclaration getUseVariable(ReferenceExpression useReference)
	}
	
	// Interaction dataflow coverage
	
	protected def createInteractionDefUseVariable(EObject reference,
			Map<Pair<Port, ParameterDeclaration>, List<DataflowReferenceVariable>> defUseMap,
			String name, boolean isResetable) {
		var Port referredPort
		val referredParameters = newArrayList
		if (reference instanceof RaiseEventAction) {
			referredPort = reference.port
			referredParameters += reference.event.parameterDeclarations
		}
		else if (reference instanceof EventParameterReferenceExpression) {
			referredPort = reference.port
			referredParameters += reference.parameter
		}
		else {
			throw new IllegalArgumentException("Not known reference: " + reference)
		}
		val statechart = reference.containingStatechart
		val defUseVariable = createVariableDeclaration => [
			it.type = createBooleanTypeDefinition
			it.name = name
		]
		statechart.variableDeclarations += defUseVariable
		// A raise event action raises many parameters, however, one defUseVariable is enough 
		for (referredParameter : referredParameters) {
			val portParameterKey = referredPort -> referredParameter
			if (!defUseMap.containsKey(portParameterKey)) {
				defUseMap.put(portParameterKey, newArrayList)
			}
			val variableDefList = defUseMap.get(portParameterKey)
			variableDefList += new DataflowReferenceVariable(reference, defUseVariable)
		}
		if (isResetable) {
			defUseVariable.designateVariableResetable
		}
		return defUseVariable
	}
	
	def annotateModelForInteractionDataFlowCoverage() {
		if (!INTERACTION_DATAFLOW_COVERAGE) {
			return
		}
		val pUseMatcher = InteractionPUses.Matcher.on(engine)
		val cUseMatcher = InteractionCUses.Matcher.on(engine)
		val allUseMatcher = InteractionUses.Matcher.on(engine)
		
		val defReferences = <RaiseEventAction>newHashSet
		val useReferences = <EventParameterReferenceExpression>newHashSet
		val connectedPorts = newHashSet
		
		switch (INTERACTION_DATAFLOW_COVERAGE_CRITERION) {
			case ALL_P_USE: {
				defReferences += pUseMatcher.allValuesOfraiseEventAction
				useReferences += pUseMatcher.allValuesOfreference
				connectedPorts += pUseMatcher.allMatches.map[it.outPort -> it.inPort]
			}
			case ALL_C_USE: {
				defReferences += cUseMatcher.allValuesOfraiseEventAction
				useReferences += cUseMatcher.allValuesOfreference
				connectedPorts += cUseMatcher.allMatches.map[it.outPort -> it.inPort]
			}
			case ALL_USE: {
				defReferences += allUseMatcher.allValuesOfraiseEventAction
				useReferences += allUseMatcher.allValuesOfreference
				connectedPorts += allUseMatcher.allMatches.map[it.outPort -> it.inPort]
			}
			default: {
				throw new IllegalArgumentException("No supported mode: " + INTERACTION_DATAFLOW_COVERAGE_CRITERION)
			}
		}
		// Optimization
		
		// Creating the variables
		// Def
		for (defReference : defReferences) {
			defReference.createInteractionDefUseVariable(parameterDefs,
				namings.getInteractionDefVariableName(defReference), false)
		}
		// Use
		for (useReference : useReferences) {
			useReference.createInteractionDefUseVariable(parameterUses,
				namings.getInteractionUseVariableName(useReference), true)
		}
		defReferences.annotateModelForDataflowCoverage(useReferences, 
			new DataflowDeclarationHandler {
				override getDefDataflowReferences(EObject defReference) {
					val raise = defReference as RaiseEventAction
					val port = raise.port
					val parameters = raise.event.parameterDeclarations
					val dataflowReferenceVariables = newHashSet
					for (parameter : parameters) {
						dataflowReferenceVariables += parameterDefs.get(port -> parameter)
					}
					return dataflowReferenceVariables
				}
				override getUseVariable(ReferenceExpression useReference) {
					val useDataflowReference = parameterUses.values.flatten
							.filter[it.getOriginalVariableReference === useReference]
					checkState(useDataflowReference.size == 1)
					return useDataflowReference.head.getDefUseVariable
				}
			}
		)
		
		// Collecting parameter transfer between ports among which there is a channel
		for (connectedPort : connectedPorts) {
			val outPort = connectedPort.key
			val inPort = connectedPort.value
			interactionDefUses += outPort.createDataflowReferenceMap(parameterDefs) ->
				inPort.createDataflowReferenceMap(parameterUses)
		}
	}
	
	protected def createDataflowReferenceMap(Port pivotPort,
			Map<Pair<Port, ParameterDeclaration>, List<DataflowReferenceVariable>> parameterDefUses) {
		val dataflowReferenceMap = newHashMap
		for (parameterDefEntry : parameterDefUses.entrySet) {
			val port = parameterDefEntry.key.key
			if (port === pivotPort) {
				val parameter = parameterDefEntry.key.value
				val dataflowReferences = parameterDefEntry.value
				dataflowReferenceMap += parameter -> dataflowReferences
			}
		}
		return new DefUseReferences(dataflowReferenceMap)
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
		val senderVariable = createVariableDeclaration => [
			it.type = createIntegerTypeDefinition
			it.name = namings.getFirstVariableName(statechart)
		]
		statechart.variableDeclarations += senderVariable
		var VariableDeclaration receiverVariable = null
		if (createSecond) {
			receiverVariable = createVariableDeclaration => [
				it.type = createIntegerTypeDefinition
				it.name = namings.getSecondVariableName(statechart)
			]
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
			senderVariable.designateVariableResetable
			receiverVariable.designateVariableResetable
		}
		return variablePair
	}
	
	// Adder
	
	def designateVariableResetable(VariableDeclaration variable) {
		if (variable !== null) {
			variable.annotations += createResetableVariableDeclarationAnnotation
		}
	}
	
	// Getters
	
	def getNewEventParameters() {
		return this.newEventParameters
	}
	
	def getInteractions() {
		return new InteractionAnnotations(this.interactions)
	}
	
	def getVariableDefs() {
		return new DefUseReferences(this.variableDefs)
	}
	
	def getVariableUses() {
		return new DefUseReferences(this.variableUses)
	}
	
	def getDataflowCoverageCriterion() {
		return this.DATAFLOW_COVERAGE_CRITERION
	}
	
	def getInteractionDefUses() {
		return this.interactionDefUses
	}
	
	def getInteractionDataflowCoverageCriterion() {
		return this.INTERACTION_DATAFLOW_COVERAGE_CRITERION
	}
	
	// Entry point
	
	def annotateModel() {
		annotateModelForTransitionCoverage
		annotateModelForTransitionPairCoverage
		annotateModelForInteractionCoverage
		annotateModelForDataFlowCoverage
		annotateModelForInteractionDataFlowCoverage
	}
	
	// Auxiliary classes for the transition and interaction
	
	static class TransitionAnnotations {
		
		final Map<Transition, VariableDeclaration> transitionPairVariables
		
		new(Map<Transition, VariableDeclaration> transitionPairVariables) {
			this.transitionPairVariables = transitionPairVariables
		}
		
		def getTransitions() {
			return transitionPairVariables.keySet
		}
		
		def isAnnotated(Transition transition) {
			return transitionPairVariables.containsKey(transition)
		}
		
		def getVariable(Transition transition) {
			return transitionPairVariables.get(transition)
		}
		
		def isEmpty() {
			return transitionPairVariables.empty
		}
		
	}
	
	@Data
	static class VariablePair {
		VariableDeclaration first
		VariableDeclaration second
		
		def hasFirst() {
			return first !== null
		}
		
		def hasSecond() {
			return second !== null
		}
		
	}
	
	@Data
	static class TransitionAnnotation {
		Transition transition
		VariableDeclaration transitionVariable
		Long transitionId
	}
	
	@Data
	static class TransitionPairAnnotation {
		TransitionAnnotation incomingAnnotation
		TransitionAnnotation outgoingAnnotation
	}
	
	@Data
	static class Interaction {
		RaiseEventAction sender
		Transition receiver
		VariablePair variablePair
		Long senderId
		Long receiverId
	}
	
	static class InteractionAnnotations {
		
		final Collection<Interaction> interactions
		Set<Interaction> interactionSet
		
		new(Collection<Interaction> interactions) {
			this.interactions = interactions
		}
		
		def getInteractions() {
			return this.interactions
		}
		
		def getUniqueInteractions() {
			if (interactionSet === null) {
				interactionSet = newHashSet
				// If the interaction has no second variable, duplication can occur
				for (i : interactions) {
					val sender = i.sender
					var Transition receiver = null
					val variablePair = i.variablePair
					val senderId = i.senderId
					var Long receiverId = null
					if (variablePair.hasSecond) {
						receiver = i.receiver
						receiverId = i.receiverId
					}
					interactionSet += new Interaction(sender, receiver, variablePair, senderId, receiverId)
				}
			}
			return interactionSet
		}
		
		def isEmpty() {
			return this.interactions.empty
		}
		
	}
	
	@Data
	static class DataflowReferenceVariable {
		EObject originalVariableReference // EventParameterReferenceExpression, DirectReferenceExpression or RaiseEventAction
		VariableDeclaration defUseVariable // Boolean variable denoting def or use
	}
	
	static class DefUseReferences {
		final Map<? extends Declaration, /* Original declaration (parameter or variable) whose def or use is marked */
			List<DataflowReferenceVariable> /* Reference-variable pairs denoting if the original declaration is set or read */>
				declarationDefs
		
		new(Map<? extends Declaration, List<DataflowReferenceVariable>> declarationDefs) {
			this.declarationDefs = declarationDefs
		}
		
		def getVariables() {
			return declarationDefs.keySet
		}
		
		def getAuxiliaryReferences(Declaration declaration) {
			if (declarationDefs.containsKey(declaration)) {
				return declarationDefs.get(declaration)
			}
			else {
				return #[]
			}
		}
		
		def getAuxiliaryVariables(Declaration declaration) {
			return declaration.getAuxiliaryReferences.map[it.getDefUseVariable].toList
		}
		
	}
	
}

class AnnotationNamings {
	
	public static val PREFIX = "__id_"
	public static val POSTFIX = "_"
	
	int id = 0
	int defId = 0
	int useId = 0
	int interactionDefId = 0
	int interactionUseId = 0
	
	def String getVariableName(Transition transition) '''«IF transition.id !== null»«transition.id»«ELSE»«PREFIX»«transition.sourceState.name»_«id++»_«transition.targetState.name»«POSTFIX»«ENDIF»'''
	def String getFirstVariableName(StatechartDefinition statechart) '''«PREFIX»first_«statechart.name»«id++»«POSTFIX»'''
	def String getSecondVariableName(StatechartDefinition statechart) '''«PREFIX»second_«statechart.name»«id++»«POSTFIX»'''
	def String getParameterName(Event event) '''«PREFIX»«event.name»«POSTFIX»'''
	def String getDefVariableName(VariableDeclaration variable) '''«PREFIX»def_«variable.name»_«defId++»«POSTFIX»'''
	def String getUseVariableName(VariableDeclaration variable) '''«PREFIX»use_«variable.name»_«useId++»«POSTFIX»'''
	def String getInteractionDefVariableName(RaiseEventAction raise) '''«PREFIX»def_«raise.port.name»_«raise.event.name»_«interactionDefId++»«POSTFIX»'''
	def String getInteractionUseVariableName(EventParameterReferenceExpression reference) '''«PREFIX»use_«reference.port.name»_«reference.event.name»_«reference.parameter.name»_«interactionUseId++»«POSTFIX»'''
}

enum InteractionCoverageCriterion {
	EVERY_INTERACTION, STATES_AND_EVENTS, EVENTS
}

enum DataflowCoverageCriterion {
	ALL_DEF, ALL_P_USE, ALL_C_USE, ALL_USE
}
