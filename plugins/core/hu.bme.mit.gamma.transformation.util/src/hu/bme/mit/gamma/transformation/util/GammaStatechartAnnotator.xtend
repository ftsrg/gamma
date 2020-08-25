package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.action.model.ActionModelFactory
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.transformation.util.queries.RaiseInstanceEvents
import java.math.BigInteger
import java.util.Collection
import java.util.Map
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
	// Interaction coverage
	protected boolean INTERACTION_COVERAGE
	protected final Set<SynchronousComponentInstance> interactionCoverableComponents = newHashSet
	protected final Map<RaiseEventAction, Integer> sendingIds = newHashMap
	protected final Map<Transition, Set<Integer>> receivingIds = newHashMap
	protected int synchronizationId = 0
	protected final Map<SynchronousComponentInstance, VariableDeclaration> receivingVariables = newHashMap // Integer variables
	protected final Map<Pair<RaiseEventAction, Transition>, Pair<VariableDeclaration, Integer>> interactions = newHashMap // Integer variables
	// Resetable variables
	protected final Set<VariableDeclaration> resetableVariables = newHashSet
	// Factories
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension ActionModelFactory actionModelFactory = ActionModelFactory.eINSTANCE
	protected final extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	protected final extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	
	new(Package gammaPackage,
			Collection<SynchronousComponentInstance> transitionCoverableComponents,
			Collection<SynchronousComponentInstance> interactionCoverableComponents) {
		this.gammaPackage = gammaPackage
		this.engine = ViatraQueryEngine.on(new EMFScope(gammaPackage.eResource.resourceSet))
		if (!transitionCoverableComponents.empty) {
			this.TRANSITION_COVERAGE = true
			this.transitionCoverableComponents += transitionCoverableComponents
			this.coverableTransitions += transitionCoverableComponents
				.map[it.type].filter(StatechartDefinition)
				.map[it.transitions].flatten
		}
		if (!interactionCoverableComponents.empty) {
			this.INTERACTION_COVERAGE = true
			this.interactionCoverableComponents += interactionCoverableComponents
		}
	}
	
	// Transition coverage
	
	protected def needsAnnotation(Transition transition) {
		return coverableTransitions.contains(transition)
	}
	
	protected def createTransitionVariable(Transition transition) {
		val statechart = transition.containingStatechart
		val variable = createVariableDeclaration => [
			it.type = createBooleanTypeDefinition
			it.name = AnnotationNamings.getVariableName(transition)
		]
		statechart.variableDeclarations += variable
		transitionVariables.put(transition, variable)
		resetableVariables += variable 
		return variable
	}
	
	def annotateModelForTransitionCoverage() {
		if (!TRANSITION_COVERAGE) {
			return
		}
		// Annotating the transitions
		for (transition : coverableTransitions.filter[it.needsAnnotation]) {
			val variable = transition.createTransitionVariable
			val assignment = createAssignmentStatement => [
				it.lhs = createReferenceExpression => [
					it.declaration = variable
				]
				it.rhs = createTrueExpression
			]
			transition.effects += assignment
		}
	}
	
	def getTransitionVariables() {
		return this.transitionVariables
	}
	
	// Interaction coverage
	
	protected def createReceivingInteractionVariable(SynchronousComponentInstance instance) {
		val statechart = instance.type as StatechartDefinition
		val variable = createVariableDeclaration => [
			it.type = createIntegerTypeDefinition
			it.name = AnnotationNamings.getVariableName(instance)
		]
		statechart.variableDeclarations += variable
		receivingVariables.put(instance, variable)
		resetableVariables += variable 
		return variable
	}
	
	protected def getSendingId(RaiseEventAction action) {
		if (!sendingIds.containsKey(action)) {
			sendingIds.put(action, synchronizationId++)
		}
		return sendingIds.get(action)
	}
	
	protected def putReceivingId(Transition transition, int id) {
		if (!receivingIds.containsKey(transition)) {
			receivingIds.put(transition, newHashSet)
		}
		val synchronizationSet = receivingIds.get(transition)
		synchronizationSet += id
	}
	
	protected def annotateModelForInteractionCoverage() {
		if (!INTERACTION_COVERAGE) {
			return
		}
		val sendingComponents = newHashSet
		val receivingComponents = newHashSet
		sendingComponents += interactionCoverableComponents
		receivingComponents += interactionCoverableComponents
		val interactionMatcher = RaiseInstanceEvents.Matcher.on(engine)
		sendingComponents.retainAll(interactionMatcher.allValuesOfoutInstance)
		receivingComponents.retainAll(interactionMatcher.allValuesOfinInstance)
		// Creating event parameters
		for (event : interactionMatcher.allValuesOfraisedEvent) {
			event.parameterDeclarations += createParameterDeclaration => [
				it.type = createIntegerTypeDefinition
				it.name = AnnotationNamings.getParameterName(event)
			]
		}
		// Creating in variables
		for (receivingComponent : receivingComponents) {
			receivingComponent.createReceivingInteractionVariable
		}
		// Annotating transitions
		for (match : interactionMatcher.allMatches
				.filter[interactionCoverableComponents.contains(it.outInstance) &&
					interactionCoverableComponents.contains(it.inInstance)]) {
			// Sending
			val raiseEventAction = match.raiseEventAction
			val id = raiseEventAction.sendingId
			raiseEventAction.arguments += createIntegerLiteralExpression => [it.value = BigInteger.valueOf(id)]
			// Receiving
			val inPort = match.inPort
			val event = match.raisedEvent
			val inParameter = event.parameterDeclarations.last // It is always the last
			val receivingTransition = match.receivingTransition
			val inInstance = match.inInstance
			val receivingVariable = receivingVariables.get(inInstance)
			receivingTransition.effects += createAssignmentStatement => [
				it.lhs = createReferenceExpression => [
					it.declaration = receivingVariable
				]
				it.rhs = createEventParameterReferenceExpression => [
					it.port = inPort
					it.event = event
					it.parameter = inParameter
				]
			]
			receivingTransition.putReceivingId(id)
			// Conclusion
			interactions.put(new Pair(raiseEventAction, receivingTransition), new Pair(receivingVariable, id))
		}
	}
	
	def getInteractions() {
		return this.interactions
	}
	
	def annotateModel() {
		annotateModelForTransitionCoverage
		annotateModelForInteractionCoverage
	}
	
}

class AnnotationNamings {
	
	def static String getVariableName(Transition transition) '''«transition.sourceState.name»_«transition.targetState.name»'''
	def static String getVariableName(SynchronousComponentInstance instance) '''interactionVariableOf«instance.name»'''
	def static String getParameterName(Event event) '''interactionVariableOf«event.name»'''
	
}