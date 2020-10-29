package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.EntryState
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.transformation.util.queries.RaiseInstanceEvents
import java.math.BigInteger
import java.util.AbstractMap.SimpleEntry
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.Map.Entry
import java.util.Set
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

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
	protected final Map<Transition, VariableDeclaration> transitionPairVariables = newHashMap // Boolean variables
	// Interaction coverage
	protected boolean INTERACTION_COVERAGE
	protected final Set<Port> interactionCoverablePorts= newHashSet
	protected final Set<ParameterDeclaration> newParameters = newHashSet
	protected long senderId = 1 // As 0 is the reset value
	protected long recevierId = 1 // As 0 is the reset value
	protected final Map<RaiseEventAction, Long> sendingIds = newHashMap
	protected final Map<Transition, Long> receivingIds = newHashMap
	protected final Map<Transition, List<Entry<Port, Event>>> receivingInteractions = newHashMap // Check: list must be unique
	protected final Map<Region,
		List<Pair<VariableDeclaration /*sender*/, VariableDeclaration /*receiver*/>>> interactionVariables = newHashMap // Check: list must be unique
	protected final Map<Entry<RaiseEventAction, Transition> /*interaction*/,
		Entry<Entry<VariableDeclaration, Long> /*sender*/,
		Entry<VariableDeclaration, Long> /*receiver*/>> interactions = newHashMap
	// Resetable variables
	protected final Set<VariableDeclaration> resetableVariables = newHashSet
	// Factories
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionModelFactory = ActionModelFactory.eINSTANCE
	protected final extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	// Namings
	protected final AnnotationNamings annotationNamings = new AnnotationNamings // Instance due to the id
	
	new(Package gammaPackage,
			Collection<SynchronousComponentInstance> transitionCoverableComponents,
			Collection<SynchronousComponentInstance> transitionPairCoverableComponents,
			Collection<Port> interactionCoverablePorts) {
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
			this.interactionCoverablePorts += interactionCoverablePorts
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
			it.name = annotationNamings.getVariableName(transition)
		]
		// TODO optimization if a variable has been created for a transition
		// Regarding both transition and transitionPair map
		statechart.variableDeclarations += variable
		variables.put(transition, variable)
		if (isResetable) {
			resetableVariables += variable
		}
		return variable
	}
	
	protected def createAssignment(VariableDeclaration variable) {
		return createAssignmentStatement => [
			it.lhs = createReferenceExpression => [
				it.declaration = variable
			]
			it.rhs = createTrueExpression
		]
	}
	
	//
	
	def annotateModelForTransitionCoverage() {
		if (!TRANSITION_COVERAGE) {
			return
		}
		for (transition : coverableTransitions.filter[it.needsAnnotation]) {
			val variable = transition.createTransitionVariable(transitionVariables, true)
			transition.effects += variable.createAssignment
		}
	}
	
	def getTransitionVariables() {
		return this.transitionVariables
	}
	
	// Transition pair coverage
	
	def annotateModelForTransitionPairCoverage() {
		if (!TRANSITION_PAIR_COVERAGE) {
			return
		}
		for (transition : coverableTransitionPairs.filter[it.needsAnnotation]) {
			val variable = transition.createTransitionVariable(transitionPairVariables, false)
			transition.effects += variable.createAssignment
		}
	}
	
	def getTransitionPairVariables() {
		return this.transitionPairVariables
	}
	
	// Interaction coverage
	
	protected def getSendingId(RaiseEventAction action) {
		if (!sendingIds.containsKey(action)) {
			sendingIds.put(action, senderId++)
		}
		return sendingIds.get(action)
	}
	
	protected def getReceivingId(Transition transition) {
		if (!receivingIds.containsKey(transition)) {
			receivingIds.put(transition, recevierId++)
		}
		return receivingIds.get(transition)
	}
	
	protected def getInteractionVariables(Region region) {
		if (!interactionVariables.containsKey(region)) {
			interactionVariables.put(region, newArrayList)
		}
		return interactionVariables.get(region)
	}
	
	protected def getReceivingInteractions(Transition transition) {
		if (!receivingInteractions.containsKey(transition)) {
			receivingInteractions.put(transition, newArrayList)
		}
		return receivingInteractions.get(transition)
	}
	
	protected def putReceivingInteraction(Transition transition, Port port, Event event) {
		if (!receivingInteractions.containsKey(transition)) {
			receivingInteractions.put(transition, newArrayList)
		}
		val interactions = receivingInteractions.get(transition)
		interactions += new SimpleEntry(port, event)
	}
	
	protected def createInteractionVariables(Region region) {
		val statechart = region.containingStatechart
		val senderVariable = createVariableDeclaration => [
			it.type = createIntegerTypeDefinition
			it.name = annotationNamings.getSendingVariableName(region)
		]
		val receiverVariable = createVariableDeclaration => [
			it.type = createIntegerTypeDefinition
			it.name = annotationNamings.getReceivingVariableName(region)
		]
		val variablePair = new Pair(senderVariable, receiverVariable)
		statechart.variableDeclarations += senderVariable
		statechart.variableDeclarations += receiverVariable
		
		val interactionVariablesSet = region.interactionVariables
		interactionVariablesSet += variablePair
		resetableVariables += senderVariable
		resetableVariables += receiverVariable
		return variablePair
	}
	
	protected def getInteractionVariables(Transition transition, Port port, Event event) {
		val interactions = transition.receivingInteractions
		val index = interactions.indexOf(new SimpleEntry(port, event)) // The i. interaction is saved using the i. variable
		val inRegion = transition.correspondingRegion
		val variables = inRegion.interactionVariables
		return variables.get(index)
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
	
	def annotateModelForInteractionCoverage() {
		if (!INTERACTION_COVERAGE) {
			return
		}
		val interactionMatcher = RaiseInstanceEvents.Matcher.on(engine)
		val matches = interactionMatcher.allMatches
		val relevantMatches = matches
				.filter[ // If BOTH ports are included, the interaction is covered
					interactionCoverablePorts.contains(it.outPort) &&
						interactionCoverablePorts.contains(it.inPort)]
		
		val raisedEvents = relevantMatches.map[it.raisedEvent].toSet // Set, so one event is set only once
		// Creating event parameters
		for (event : raisedEvents) {
			val newParameter = createParameterDeclaration => [
				it.type = createIntegerTypeDefinition
				it.name = annotationNamings.getParameterName(event)
			]
			event.parameterDeclarations += newParameter
			newParameters += newParameter
		}
		
		// Annotating transitions
		for (match : relevantMatches) {
			// Sending
			val raiseEventAction = match.raiseEventAction
			if (!sendingIds.containsKey(raiseEventAction)) {
				// One raise event action can synchronize to multiple transitions (broadcast channel)
				raiseEventAction.arguments += createIntegerLiteralExpression => 
					[it.value = BigInteger.valueOf(raiseEventAction.sendingId)]
			}
			// Receiving
			val inPort = match.inPort
			val event = match.raisedEvent
			val inParameter = event.parameterDeclarations.last // It is always the last
			val receivingTransition = match.receivingTransition
			val inRegion = receivingTransition.correspondingRegion
			
			// We do not want to duplicate the same assignments to the same variable
			if (!receivingTransition.hasReceivingInteraction(inPort, event)) {
				receivingTransition.putReceivingInteraction(inPort, event)
				if (!receivingTransition.isThereEnoughInteractionVariable) {
					// Note: a new variable is needed since if there is only one variable,
					// the subsequent assignments to the same variable overwrite each other
					inRegion.createInteractionVariables
					// The difference can be at most one due to the nature of the algorithm
				}
				val interactionVariables = receivingTransition.getInteractionVariables(inPort, event)
				val senderVariable = interactionVariables.key
				val receiverVariable = interactionVariables.value
				// Sender assignment
				receivingTransition.effects += createAssignmentStatement => [
					it.lhs = createReferenceExpression => [
						it.declaration = senderVariable
					]
					it.rhs = createEventParameterReferenceExpression => [
						it.port = inPort
						it.event = event
						it.parameter = inParameter
					]
				]
				// Receiver assignment
				receivingTransition.effects += createAssignmentStatement => [
					it.lhs = createReferenceExpression => [
						it.declaration = receiverVariable
					]
					it.rhs = createIntegerLiteralExpression => [
						it.value = BigInteger.valueOf(receivingTransition.receivingId)
					]
				]
			}
			val variables = receivingTransition.getInteractionVariables(inPort, event)
			val senderVariable = variables.key
			val receiverVariable = variables.value
			interactions.put(new SimpleEntry(raiseEventAction, receivingTransition),
				new SimpleEntry(new SimpleEntry(senderVariable, raiseEventAction.sendingId),
					new SimpleEntry(receiverVariable, receivingTransition.receivingId)
				)
			)
		}
	}
	
	// 
	
	def getNewParameters() {
		return this.newParameters
	}
	
	def getInteractions() {
		return this.interactions
	}
	
	def getResetableVariables() {
		return this.resetableVariables
	}
	
	def annotateModel() {
		annotateModelForTransitionCoverage
		annotateModelForTransitionPairCoverage
		annotateModelForInteractionCoverage
	}
	
}

class AnnotationNamings {
	
	public static val PREFIX = "__id_"
	public static val POSTFIX = "__"
	
	int id = 0
	
	def String getVariableName(Transition transition) '''«IF transition.id !== null»«transition.id»«ELSE»«PREFIX»«transition.sourceState.name»_«id++»_«transition.targetState.name»«POSTFIX»«ENDIF»'''
	def String getReceivingVariableName(Region region) '''«PREFIX»rec_«region.name»«id++»«POSTFIX»'''
	def String getSendingVariableName(Region region) '''«PREFIX»send_«region.name»«id++»«POSTFIX»'''
	def String getParameterName(Event event) '''«PREFIX»«event.name»«POSTFIX»'''
	
}