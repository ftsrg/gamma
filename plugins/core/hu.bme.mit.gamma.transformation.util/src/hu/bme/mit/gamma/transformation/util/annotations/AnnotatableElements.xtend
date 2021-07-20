package hu.bme.mit.gamma.transformation.util.annotations

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.Transition
import java.util.Collection
import org.eclipse.xtend.lib.annotations.Data

@Data
class AnnotatableElements {
	
	Collection<SynchronousComponentInstance> transitionCoverableComponents
	
	Collection<SynchronousComponentInstance> transitionPairCoverableComponents
	
	Collection<Port> interactionCoverablePorts
	Collection<State> interactionCoverableStates
	Collection<Transition> interactionCoverableTransitions
	InteractionCoverageCriterion senderInteractionTuple
	InteractionCoverageCriterion receiverInteractionTuple
	
	Collection<VariableDeclaration> dataflowCoverableVariables
	DataflowCoverageCriterion dataflowCoverageCriterion
	
	Collection<Port> interactionDataflowCoverablePorts
	DataflowCoverageCriterion interactionDataflowCoverageCriterion
	
}