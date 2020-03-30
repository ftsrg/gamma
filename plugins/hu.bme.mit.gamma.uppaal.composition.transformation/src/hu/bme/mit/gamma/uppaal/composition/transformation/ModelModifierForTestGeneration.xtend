package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.EntryState
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.Transition
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.uppaal.transformation.queries.Transitions
import java.util.Collection
import java.util.Map
import java.util.Set
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import uppaal.NTA
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix
import uppaal.templates.Edge
import uppaal.templates.TemplatesPackage

import static com.google.common.base.Preconditions.checkState
import static hu.bme.mit.gamma.uppaal.composition.transformation.Namings.*

class ModelModifierForTestGeneration {
	// Has to be set externally
	extension NtaBuilder ntaBuilder
	extension AssignmentExpressionCreator assignmentExpressionCreator
	NTA nta
	ViatraQueryEngine engine
	extension Trace trace
	// Packages
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	// Transition coverage
	protected boolean TRANSITION_COVERAGE
	protected final Set<SynchronousComponentInstance> transitionCoverableComponents = newHashSet
	protected final Set<Transition> coverableTransitions = newHashSet
	protected final Map<Transition, Integer> transitionAnnotations = newHashMap
	protected DataVariableDeclaration transitionIdVariable
	protected final int INITIAL_TRANSITION_ID = 1
	protected int transitionId = INITIAL_TRANSITION_ID
	// Interaction coverage
	protected boolean INTERACTION_COVERAGE
	protected final Set<SynchronousComponentInstance> interactionCoverableComponents = newHashSet
	
	new(NtaBuilder ntaBuilder, AssignmentExpressionCreator assignmentExpressionCreator,
			ViatraQueryEngine engine, Trace trace) {
		this.ntaBuilder = ntaBuilder
		this.assignmentExpressionCreator = assignmentExpressionCreator
		this.nta = ntaBuilder.nta
		this.engine = engine
		this.trace = trace
	}
	
	/**
	 * Has to be called explicitly.
	 */
	def setComponentInstances(Collection<SynchronousComponentInstance> transitionCoverableComponents,
			Collection<SynchronousComponentInstance> interactionCoverableComponents) {
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
	
	def getEngine() {
		return this.engine
	}
	
	def getNta() {
		return this.nta
	}
	
	def getTransitionIdVariable() {
		this.transitionIdVariable
	}
	
	// Transition coverage
	
	private def needsAnnotation(Transition transition) {
		return !(transition.sourceState instanceof EntryState) &&
			(transition.targetState instanceof State) &&
			coverableTransitions.contains(transition)
	}
	
	private def getNextAnnotationValue(Transition transition) {
		checkState(!transitionAnnotations.containsKey(transition))
		transitionAnnotations.put(transition, transitionId)
		return transitionId++
	}
	
	private def modifyModelForTransitionCoverage() {
		// Creating a global variable in UPPAAL for transition ids
		this.transitionIdVariable = this.nta.globalDeclarations.createVariable(DataVariablePrefix.NONE,
			nta.int, transitionIdVariableName)
		// Annotating the transitions
		for (transition : Transitions.Matcher.on(engine).allValuesOftransition
				.filter[it.needsAnnotation]) {
			val edges = transition.allValuesOfTo.filter(Edge)
			checkState(edges.size == 1)
			val edge = edges.head
			edge.createAssignmentExpression(edge_Update, transitionIdVariable,
				transition.getNextAnnotationValue.toString)
		}
	}
	
	def getTransitionAnnotations() {
		return this.transitionAnnotations
	}
	
	// Interaction coverage
	
	private def modifyModelForInteractionCoverage() {
		
	}
	
	def modifyModelForTestGeneration() {
		modifyModelForTransitionCoverage
		modifyModelForInteractionCoverage
	}
	
}