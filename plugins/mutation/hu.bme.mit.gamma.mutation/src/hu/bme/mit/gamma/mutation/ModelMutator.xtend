/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.mutation

import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import java.util.Collection
import java.util.Random
import java.util.Set

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ModelMutator {
	//
	protected final Set<Transition> transitionSourceMutations = newLinkedHashSet
	protected final Set<Transition> transitionTargetMutations = newLinkedHashSet
	protected final Set<Transition> transitionRemoveMutations = newLinkedHashSet
	protected final Set<Transition> transitionGuardRemoveMutations = newLinkedHashSet
	protected final Set<Transition> transitionTriggerRemoveMutations = newLinkedHashSet
	
	protected final extension ModelElementMutator modelElementMutator
	
	protected final Random random = new Random();
	//
	
	new() {
		this.modelElementMutator = new ModelElementMutator // May be parameterized later
	}
	
	//
	
	def execute(Component component) {
		if (component instanceof StatechartDefinition) {
			component.execute
		}
		else if (component instanceof CompositeComponent) {
			
		}
	}
	
	def executeOnStatechart(Component component) {
		if (component instanceof StatechartDefinition) {
			component.execute
		}
		else if (component instanceof CompositeComponent) {
			val statecharts = component.selfOrAllContainedStatecharts
			val statechart = statecharts.selectElementForMutation(newArrayList)
			
			statechart.execute
		}
	}
	
	//
	
	def execute(StatechartDefinition statechart) {
		var success = true
		do {
 			try {
 				success = true
				val mutationType = mutationType
				val mutationOperatorIndex = mutation
				
				switch (mutationType) {
					case TRANSITION_STRUCTURE: {
						val OPERATOR_COUNT = 5
						val i = mutationOperatorIndex % OPERATOR_COUNT
						switch (i) {
							case 0: {
								val transition = statechart.selectTransitionForSourceMutation
								transition.changeTransitionSource
							}
							case 1: {
								val transition = statechart.selectTransitionForTargetMutation
								transition.changeTransitionTarget
							}
							case 2: {
								val transition = statechart.selectTransitionForRemovalMutation
								transition.removeTransition
							}
							case 3: {
								val transition = statechart.selectTransitionForGuardRemovalMutation
								transition.removeTransitionGuard
							}
							case 4: {
								val transition = statechart.selectTransitionForTriggerRemovalMutation
								transition.removeTransitionTrigger
							}
							default:
								throw new IllegalArgumentException("Not known operator index: " + i)
						}
					}
					case TRANSITION_DYNAMICS: {
						
					}
					case STATE_DYNAMICS: {
						
					}
					case EXPRESSION_DYNAMICS: {
						
					}
					default:
						throw new IllegalArgumentException("Not known mutation type: " + mutationType)
				}
			} catch (IllegalArgumentException | IllegalStateException e) {
				// Not mutatable model element
				success = false
			}
		} while (!success)
	}
	
	//
	
	protected def selectTransitionForSourceMutation(StatechartDefinition statechart) {
		val transitions = statechart.transitions.filter[
				it.leavingState].toList
		
		val transition = transitions.selectTransitionForMutation(transitionSourceMutations)
		
		return transition
	}
	
	protected def selectTransitionForTargetMutation(StatechartDefinition statechart) {
		val transitions = statechart.transitions.filter[
				it.targetState instanceof State].toList
		
		val transition = transitions.selectTransitionForMutation(transitionTargetMutations)
		
		return transition
	}
	
	protected def selectTransitionForRemovalMutation(StatechartDefinition statechart) {
		val transitions = statechart.transitions.filter[
				it.leavingState ||
				it.sourceState instanceof ChoiceState &&
						it.sourceState.outgoingTransitions.size > 1].toList
		
		val transition = transitions.selectTransitionForMutation(transitionRemoveMutations)
		
		return transition
	}
	
	protected def selectTransitionForGuardRemovalMutation(StatechartDefinition statechart) {
		val transitions = statechart.transitions.filter[
				it.hasGuard].toList
		
		val transition = transitions.selectTransitionForMutation(transitionGuardRemoveMutations)
		
		return transition
	}
	
	protected def selectTransitionForTriggerRemovalMutation(StatechartDefinition statechart) {
		val transitions = statechart.transitions.filter[
				it.hasTrigger].toList
		
		val transition = transitions.selectTransitionForMutation(transitionTriggerRemoveMutations)
		
		return transition
	}
	
	//
	
	protected def selectTransitionForMutation(Collection<? extends Transition> transitions,
			Collection<Transition> unselectableTransitions) {
		return transitions.selectElementForMutation(unselectableTransitions)
	}
	
	protected def <T> selectElementForMutation(Collection<? extends T> objects,
			Collection<T> unselectableObjects) {
		val selectableObjects = newArrayList
		selectableObjects += objects
		selectableObjects -= unselectableObjects
		
		checkState(!selectableObjects.empty)
		
		// TODO Change due to heuristics
		val i = random.nextInt(selectableObjects.size)
		val object = selectableObjects.get(i)
		//
		
		unselectableObjects += object
		
		return object
	}
	
	//
	
	protected def getMutationType() {
		val mutationTypes = StatechartMutationType.values
		val mutationTypesCount = mutationTypes.length
		val i = random.nextInt(mutationTypesCount)
		
		val mutationType = mutationTypes.get(i)
		return mutationType
	}
	
	protected def getMutation() {
		val MAX = 20
		return random.nextInt(MAX)
	}
	
	//
	
	enum StatechartMutationType {
			TRANSITION_STRUCTURE, TRANSITION_DYNAMICS, STATE_DYNAMICS, EXPRESSION_DYNAMICS }
	
}