package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.eventpriority.transformation.EventPriorityTransformer
import hu.bme.mit.gamma.statechart.phase.transformation.PhaseStatechartTransformer
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition

class GammaStatechartPreprocessor {
	
	protected final StatechartDefinition statechart
	
	protected final EventPriorityTransformer eventPriorityTransformer
	protected final PhaseStatechartTransformer phaseStatechartTransformer
	
	new(StatechartDefinition statechart) {
		this.statechart = statechart
		this.eventPriorityTransformer = new EventPriorityTransformer(statechart)
		this.phaseStatechartTransformer = new PhaseStatechartTransformer(statechart)
	}
	
	def execute() {
		eventPriorityTransformer.execute
		phaseStatechartTransformer.execute
		return statechart
	}
	
}