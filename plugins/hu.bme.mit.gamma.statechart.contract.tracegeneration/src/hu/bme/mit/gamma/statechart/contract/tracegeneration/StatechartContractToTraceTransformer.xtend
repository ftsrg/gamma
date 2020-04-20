package hu.bme.mit.gamma.statechart.contract.tracegeneration

import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.traverser.LooplessPathRetriever
import hu.bme.mit.gamma.trace.model.TraceFactory

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class StatechartContractToTraceTransformer {
	
	final extension LooplessPathRetriever looplessPathRetriever = new LooplessPathRetriever
	final extension TransitionToStepTransformer transitionToStepTransformer = new TransitionToStepTransformer
	
	final extension TraceFactory traceFactory = TraceFactory.eINSTANCE
	
	def execute(StatechartDefinition statechart) {
		return execute(statechart, false)
	}
	
	def execute(StatechartDefinition statechart, boolean addReset) {
		val paths = newArrayList
		for (topRegion : statechart.regions) {
			paths += topRegion.retrievePaths
		}
		val traces = newArrayList
		for (path : paths) {
			val trace = createExecutionTrace => [
				it.import = statechart.containingPackage
				it.component = statechart
				// Not adding arguments
			]
			traces += trace
			val steps = trace.steps
			for (transition : path.transitions) {
				steps += transition.execute
			}
			// Adding reset in the first step if necessary
			if (addReset) {
				if (!steps.empty) {
					val firstStep = steps.head
					firstStep.actions.add(0, createReset)
				}
			}
		}
		return traces
	}
	
}