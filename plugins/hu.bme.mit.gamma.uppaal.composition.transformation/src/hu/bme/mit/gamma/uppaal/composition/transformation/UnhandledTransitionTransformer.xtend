package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.StatechartModelFactory
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*
import java.util.logging.Level

class UnhandledTransitionTransformer {
	
	extension StatechartModelFactory statechartModelFactory = StatechartModelFactory.eINSTANCE
	// Logger
	extension Logger logger = Logger.getLogger("GammaLogger")
	
	def execute(StatechartDefinition statechart) {
		val unhandledTransitions = statechart.transitions.filter[it.isToHigherAndLower].toList
		
		for (var i = 0; i < unhandledTransitions.size; i++) {
			val unhandledTransition = unhandledTransitions.get(i)
			val source = unhandledTransition.sourceState
			val target = unhandledTransition.targetState
			log(Level.INFO, "Transforming unhandleable transition " + source.name + " -> " + target.name)
			
			val commonRegions = getCommonRegionAncestors(source, target)
			
			checkState(!commonRegions.empty)
			// In theory, the last element is the "closest" region
			val closestCommonRegion = commonRegions.last
			
			val splitterChoice = createChoiceState => [
				it.name = source.name + "_" + target.name + "Splitter"
			]
			
			closestCommonRegion.stateNodes += splitterChoice
			
			statechart.transitions += createTransition => [
				it.sourceState = splitterChoice
				it.targetState = unhandledTransition.targetState
			]
			unhandledTransition.targetState = splitterChoice
		}
	}
	
}