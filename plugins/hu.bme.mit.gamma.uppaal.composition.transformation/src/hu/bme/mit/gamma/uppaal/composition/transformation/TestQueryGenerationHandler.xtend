package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.EntryState
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.Transition
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import java.util.Collection
import java.util.Map
import java.util.Set
import uppaal.NTA
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.uppaal.composition.transformation.Namings.*

class TestQueryGenerationHandler {
	// Has to be set externally
	extension NtaBuilder ntaBuilder
	NTA nta
	// State coverage
	protected boolean STATE_COVERAGE
	protected final Set<SynchronousComponentInstance> stateCoverableComponents = newHashSet
	// Transition coverage
	protected boolean TRANSITION_COVERAGE
	protected final Set<SynchronousComponentInstance> transitionCoverableComponents = newHashSet
	protected final Map<Transition, Integer> transitionAnnotations = newHashMap
	protected DataVariableDeclaration transitionIdVariable
	protected final int INITIAL_TRANSITION_ID = 1
	protected int transitionId = INITIAL_TRANSITION_ID
	
	new(Collection<SynchronousComponentInstance> stateCoverableComponents,
			Collection<SynchronousComponentInstance> transitionCoverableComponents) {
		if (!stateCoverableComponents.empty) {
			this.STATE_COVERAGE = true
			this.stateCoverableComponents += stateCoverableComponents
		}
		if (!transitionCoverableComponents.empty) {
			this.TRANSITION_COVERAGE = true
			this.transitionCoverableComponents += transitionCoverableComponents
		}
	}
	
	/**
	 * Has to be called explicitly from within the transformer!
	 */
	def setNtaBuilder(NtaBuilder ntaBuilder) {
		this.ntaBuilder = ntaBuilder
		this.nta = ntaBuilder.nta
		if (TRANSITION_COVERAGE) {
			this.createTransitionIdVariable
		}
	}
	
	private def createTransitionIdVariable() {		
		this.transitionIdVariable = this.nta.globalDeclarations.createVariable(DataVariablePrefix.NONE,
			nta.int, transitionIdVariableName)
	}
	
	// State coverage
	
	def String generateStateCoverageExpressions() {
		val expressions = new StringBuilder('''A[] not deadlock«System.lineSeparator»''')
		// VIATRA matches cannot be used here, as testedComponentsForStates has different pointers for some reason
		for (instance : stateCoverableComponents) {
			val statechart = instance.type as StatechartDefinition
			val regions = newHashSet
			regions += statechart.allRegions
			for (region : regions) {
				val templateName = region.getTemplateName(instance)
					for (state : region.stateNodes.filter(State)) {
						val locationName = state.locationName
						if (templateName.hasLocation(locationName)) {
							expressions.append('''E<> «templateName».«locationName» && «Namings.isStableVariableName»«System.lineSeparator»''')
						}
					}
			}
		}
		return expressions.toString
	}
	
	private def hasLocation(String templateName, String locationName) {
		val templates = nta.template.filter[it.name == templateName]
		checkState(templates.size == 1, templates + " " + templateName + " " + locationName)
		val template = templates.head
		if (template !== null) {
			return template.location.exists[it.name == locationName]
		}
		return false
	}
	
	// Transition coverage
	
	def getTransitionIdVariable() {
		return this.transitionIdVariable
	}
	
	def needsAnnotation(Transition transition) {
		return !(transition.sourceState instanceof EntryState) &&
			(transition.targetState instanceof State) &&
			transitionCoverableComponents.map[it.type].filter(StatechartDefinition).contains(transition)
	}
	
	def getNextAnnotationValue(Transition transition) {
		checkState(!transitionAnnotations.containsKey(transition))
		transitionAnnotations.put(transition, transitionId)
		return transitionId++
	}
	
	def String generateTransitionCoverageExpressions() {
		val expressions = new StringBuilder
		// VIATRA matches cannot be used here, as testedComponentsForStates has different pointers for some reason
		for (entry : transitionAnnotations.entrySet) {
			val transition = entry.key
			val id = entry.value
			expressions.append('''/* «transition.sourceState.name» --> «transition.targetState.name» */«System.lineSeparator»''')
			// Suffix present? If not, all transitions can be reached; if yes, some transitions
			// are covered by transition fired in the same step, but the end is a stable state
			expressions.append('''E<> «transitionIdVariable.variable.head.name» == «id» && «Namings.isStableVariableName»«System.lineSeparator»''')
		}
		return expressions.toString
	}
	
	def generateExpressions() {
		val expressions = new StringBuilder
		if (STATE_COVERAGE) {
			expressions.append(generateStateCoverageExpressions)
		}
		if (TRANSITION_COVERAGE) {
			expressions.append(generateTransitionCoverageExpressions)
		}
		return expressions.toString
	}
	
}