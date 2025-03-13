/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util.annotations

import org.eclipse.xtend.lib.annotations.Data

@Data
class AnnotatablePreprocessableElements {
	
	ComponentInstanceReferences testedComponentsForStates
	
	ComponentInstanceReferences testedComponentsForUnstableStates
	
	ComponentInstanceReferences testedComponentsForTrapStates
	
	ComponentInstanceReferences testedComponentsForDeadlock
	
	ComponentInstanceReferences testedComponentsForNondeterministicTransitions
	
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
	
	///
	
	new() {
		// If only a placeholder is needed, this constructor can be used
		this(null, null, null, null, null, null, null, null, null, null, null, null, null, null, null)
	}

	new(ComponentInstanceReferences testedComponentsForStates,
			ComponentInstanceReferences testedComponentsForUnstableStates,
			ComponentInstanceReferences testedComponentsForTrapStates,
			ComponentInstanceReferences testedComponentsForDeadlock,
			ComponentInstanceReferences testedComponentsForNondeterministicTransitions,
			ComponentInstanceReferences testedComponentsForTransitions,
			ComponentInstanceReferences testedComponentsForTransitionPairs,
			ComponentInstancePortReferences testedComponentsForOutEvents,
			ComponentInstancePortStateTransitionReferences testedInteractions, InteractionCoverageCriterion senderCoverageCriterion, InteractionCoverageCriterion receiverCoverageCriterion,
			ComponentInstanceVariableReferences dataflowTestedVariables, DataflowCoverageCriterion dataflowCoverageCriterion,
			ComponentInstancePortReferences testedComponentsForInteractionDataflow, DataflowCoverageCriterion interactionDataflowCoverageCriterion) {
		this.testedComponentsForStates = testedComponentsForStates
		this.testedComponentsForUnstableStates = testedComponentsForUnstableStates
		this.testedComponentsForTrapStates = testedComponentsForTrapStates
		this.testedComponentsForDeadlock = testedComponentsForDeadlock
		this.testedComponentsForNondeterministicTransitions = testedComponentsForNondeterministicTransitions
		this.testedComponentsForTransitions = testedComponentsForTransitions
		this.testedComponentsForTransitionPairs = testedComponentsForTransitionPairs
		this.testedComponentsForOutEvents = testedComponentsForOutEvents
		this.testedInteractions = testedInteractions
		this.senderCoverageCriterion = senderCoverageCriterion
		this.receiverCoverageCriterion = receiverCoverageCriterion
		this.dataflowTestedVariables = dataflowTestedVariables
		this.dataflowCoverageCriterion = dataflowCoverageCriterion
		this.testedComponentsForInteractionDataflow = testedComponentsForInteractionDataflow
		this.interactionDataflowCoverageCriterion = interactionDataflowCoverageCriterion
	}
	
}