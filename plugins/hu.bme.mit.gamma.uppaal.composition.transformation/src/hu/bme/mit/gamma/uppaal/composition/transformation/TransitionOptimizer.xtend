package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.Transition
import hu.bme.mit.gamma.uppaal.composition.transformation.queries.RemovableTransitions
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.query.runtime.emf.EMFScope

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class TransitionOptimizer {
	
	final ViatraQueryEngine engine
	
	final extension Logger logger = Logger.getLogger("GammaLogger")

	new(ResourceSet resourceSet) {
		this.engine = ViatraQueryEngine.on(new EMFScope(resourceSet))
	}
	
	def execute() {
		val matcher = RemovableTransitions.Matcher.on(engine)
		while (matcher.hasMatch) {
			for (transition : matcher.allValuesOftransition.reject[it.eContainer === null]) {
				transition.removeTransition
			}
		}
	}
	
	private def void removeTransition(Transition transition) {
		val statechart = transition.eContainer as StatechartDefinition
		val target = transition.targetState
		if (target.incomingTransitions.size == 1) {
			for (outgoingTransition : target.outgoingTransitions) {
				outgoingTransition.removeTransition
			}
			val region = target.parentRegion
			log(Level.INFO, "Removing " + target.name)
			region.stateNodes -= target
		}
		log(Level.INFO, "Removing " + transition.sourceState.name + " -> " + transition.targetState.name)
		statechart.transitions -= transition
	}
	
}