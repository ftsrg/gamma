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

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.Transition
import java.util.Collection
import org.eclipse.xtend.lib.annotations.Data

@Data
class AnnotatableElements {
	
	Collection<SynchronousComponentInstance> deadlockCoverableComponents
	
	Collection<SynchronousComponentInstance> nondeterministicTransitionCoverableComponents
	
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