package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.statechart.model.EntryState
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.Transition
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.TopSyncSystemOutEvents
import java.util.Collection
import java.util.Map
import java.util.Set
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import uppaal.NTA
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.model.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.uppaal.composition.transformation.Namings.*

class TestQueryGenerationHandler {
	// Has to be set externally
	extension NtaBuilder ntaBuilder // Transition
	NTA nta // Transition
	ViatraQueryEngine engine
	// State coverage
	protected boolean STATE_COVERAGE
	protected final Set<SynchronousComponentInstance> stateCoverableComponents = newHashSet
	// Transition coverage
	protected boolean TRANSITION_COVERAGE
	protected final Set<SynchronousComponentInstance> transitionCoverableComponents = newHashSet
	protected final Set<Transition> coverableTransitions = newHashSet
	protected final Map<Transition, Integer> transitionAnnotations = newHashMap
	protected DataVariableDeclaration transitionIdVariable
	protected final int INITIAL_TRANSITION_ID = 1
	protected int transitionId = INITIAL_TRANSITION_ID
	// Out-event coverage
	protected boolean OUT_EVENT_COVERAGE
	protected final Set<SynchronousComponentInstance> outEventCoverableComponents = newHashSet
	
	// Interaction coverage
	
	new(Collection<SynchronousComponentInstance> stateCoverableComponents,
			Collection<SynchronousComponentInstance> transitionCoverableComponents,
			Collection<SynchronousComponentInstance> outEventCoverableComponents,
			Collection<SynchronousComponentInstance> interactionCoverableComponents) {
		if (!stateCoverableComponents.empty) {
			this.STATE_COVERAGE = true
			this.stateCoverableComponents += stateCoverableComponents
		}
		if (!transitionCoverableComponents.empty) {
			this.TRANSITION_COVERAGE = true
			this.transitionCoverableComponents += transitionCoverableComponents
			this.coverableTransitions += transitionCoverableComponents
				.map[it.type].filter(StatechartDefinition)
				.map[it.transitions].flatten
		}
		if (!outEventCoverableComponents.empty) {
			this.OUT_EVENT_COVERAGE = true
			this.outEventCoverableComponents += outEventCoverableComponents
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
	
	/**
	 * Has to be called explicitly from within the transformer!
	 */
	def setEngine(ViatraQueryEngine engine) {
		this.engine = engine
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
				val processName = templateName.porcessName
				for (state : region.stateNodes.filter(State)) {
					val locationName = state.locationName
					if (templateName.hasLocation(locationName)) {
						expressions.append('''/*«System.lineSeparator»«instance.name»: «region.name».«state.name»«System.lineSeparator»*/«System.lineSeparator»''')
						expressions.append('''E<> «processName».«locationName» && «Namings.isStableVariableName»«System.lineSeparator»''')
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
			coverableTransitions.contains(transition)
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
			val statechart = transition.containingStatechart
			val instance = transitionCoverableComponents.findFirst[it.type === statechart]
			expressions.append('''/*«System.lineSeparator»«instance.name»: «transition.sourceState.name» --> «transition.targetState.name»«System.lineSeparator»*/«System.lineSeparator»''')
			// Suffix present? If not, all transitions can be reached; if yes, some transitions
			// are covered by transition fired in the same step, but the end is a stable state
			expressions.append('''E<> «transitionIdVariable.variable.head.name» == «id» && «Namings.isStableVariableName»«System.lineSeparator»''')
		}
		return expressions.toString
	}
	
	// Out event coverage
	
	def String generateOutEventCoverageExpressions() {
		val expressions = new StringBuilder
		// VIATRA matches cannot be used here, as testedComponentsForStates has different pointers for some reason
		val outEventMatches = TopSyncSystemOutEvents.Matcher.on(engine).allMatches
			.filter[outEventCoverableComponents.contains(it.instance)]
		for (outEventMatch : outEventMatches) {
			val systemPort = outEventMatch.systemPort
			val port = outEventMatch.port
			val event = outEventMatch.event
			val parameters = event.parameterDeclarations
			val parameterValues = newHashSet
			if (!parameters.empty) {
				checkState(parameters.size == 1)
				val parameter = parameters.head
				val typeDefinition = parameter.type.typeDefinition
				switch (typeDefinition) {
					// Checking only booleans and enumerations now
					BooleanTypeDefinition: {
						parameterValues += #{"true", "false"}
					}
					EnumerationTypeDefinition : {
						parameterValues += typeDefinition.literals.map[typeDefinition.literals.indexOf(it).toString]
					}
				}
			}
			val instance = outEventMatch.instance
			val outEventVariableName = Namings.getOutEventName(event, port, instance)
			if (parameterValues.empty) {
				expressions.append('''/*«System.lineSeparator»«systemPort.name».«event.name»«System.lineSeparator»*/«System.lineSeparator»''')
				expressions.append('''E<> «outEventVariableName» == true && «Namings.isStableVariableName»«System.lineSeparator»''')
			}
			else {
				val parameterVariableName = Namings.getValueOfName(event, port, instance)
				for (parameterValue : parameterValues) {
					expressions.append('''/*«System.lineSeparator»«systemPort.name».«event.name»«System.lineSeparator»*/«System.lineSeparator»''')
					expressions.append('''E<> «outEventVariableName» == true && «parameterVariableName» == «parameterValue» && «Namings.isStableVariableName»«System.lineSeparator»''')
				}
			}
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
		if (OUT_EVENT_COVERAGE) {
			expressions.append(generateOutEventCoverageExpressions)
		}
		return expressions.toString
	}
	
}