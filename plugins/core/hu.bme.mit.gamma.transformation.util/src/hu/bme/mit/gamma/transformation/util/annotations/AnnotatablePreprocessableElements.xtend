package hu.bme.mit.gamma.transformation.util.annotations

import org.eclipse.xtend.lib.annotations.Data

@Data
class AnnotatablePreprocessableElements {
	
		ComponentInstanceReferences testedComponentsForStates
		
		ComponentInstanceReferences testedComponentsForTransitions
		
		ComponentInstanceReferences testedComponentsForTransitionPairs
		
		ComponentInstancePortReferences testedComponentsForOutEvents
		
		ComponentInstancePortStateTransitionReferences testedInteractions
		InteractionCoverageCriterion senderCoverageCriterion
		InteractionCoverageCriterion receiverCoverageCriterion
		
		ComponentInstanceVariableReferences dataflowTestedVariables
		DataflowCoverageCriterion dataflowCoverageCriterion
		
		ComponentInstancePortReferences testedComponentsForInteractionDataflow
		DataflowCoverageCriterion interactionDataflowCoverageCriterion
	
}