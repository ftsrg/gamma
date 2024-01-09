/********************************************************************************
 * Copyright (c) 2023-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.mutation

import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.statechart.ChoiceState
import hu.bme.mit.gamma.statechart.statechart.EntryState
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.Region
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.GammaRandom
import java.util.Collection
import java.util.List
import java.util.Map
import java.util.Random
import java.util.Set
import java.util.logging.Logger
import org.eclipse.emf.ecore.EObject

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ModelMutator {
	// Caching
	protected final Set<AnyPortEventReference> anyPortEventReferences = newHashSet
	protected final Set<PortEventReference> portEventReferences = newHashSet
	protected final Set<RaiseEventAction> raiseEventActions = newHashSet
	protected final Set<EventParameterReferenceExpression> eventParameterReferenceExpressions = newHashSet
	protected final Set<DirectReferenceExpression> directReferenceExpressions = newHashSet
	protected final Set<State> states = newHashSet
	protected final Set<Region> regions = newHashSet
	
	protected final Set<Expression> expressions = newHashSet
	
	// Mutations
	protected final Set<Transition> transitionSourceMutations = newHashSet
	protected final Set<Transition> transitionTargetMutations = newHashSet
	protected final Set<Transition> transitionRemoveMutations = newHashSet
	protected final Set<Transition> transitionGuardRemoveMutations = newHashSet
	protected final Set<Transition> transitionTriggerRemoveMutations = newHashSet
	
	protected final Set<AnyPortEventReference> anyPortEventReferenceMutations = newHashSet
	protected final Set<PortEventReference> portEventReferenceChangeMutations = newHashSet
	protected final Set<RaiseEventAction> raiseEventActionChangeMutations = newHashSet
	protected final Set<EventParameterReferenceExpression> eventParameterReferenceExpressionChangeMutations = newHashSet
	protected final Set<DirectReferenceExpression> directReferenceExpressionChangeMutations = newHashSet
	protected final Set<Transition> transitionEffectRemoveMutations = newHashSet
	protected final Set<State> stateEntryActionRemoveMutations = newHashSet
	protected final Set<State> stateExitActionRemoveMutations = newHashSet
	protected final Set<EntryState> entryStateChangeMutations = newHashSet // Hard to trace due to replacement
	
	protected final Set<Expression> expressionChangeMutations = newHashSet // Hard to trace due to replacement
	protected final Set<Expression> expressionInversionMutations = newHashSet
	
	//
	
	protected final extension ModelElementMutator modelElementMutator
	protected final MutationHeuristics mutationHeuristics
	
	protected final Random random = new Random
	
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	//
	
	new() {
		this(new MutationHeuristics)
	}
	
	new(MutationHeuristics mutationHeuristics) {
		this.modelElementMutator = new ModelElementMutator // May be parameterized later
		this.mutationHeuristics = mutationHeuristics
	}
	
	//
	
	def execute(Component component) {
		if (component instanceof StatechartDefinition) {
			component.executeOnStatechart
		}
		else if (component instanceof CompositeComponent) {
			
		}
	}
	
	def executeOnStatechart(Component component) {
		if (component instanceof StatechartDefinition) {
			component.execute
			component.addMutantAnnotation
		}
		else if (component instanceof CompositeComponent) {
			val statecharts = component.selfOrAllContainedStatecharts
			val statechart = statecharts.selectElementForMutation(newArrayList)
			
			statechart.execute
			statechart.addMutantAnnotation
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
								val transition = statechart.selectTransitionForSourceChange
								transition.changeTransitionSource
							}
							case 1: {
								val transition = statechart.selectTransitionForTargetChange
								transition.changeTransitionTarget
							}
							case 2: {
								val transition = statechart.selectTransitionForRemoval
								transition.removeTransition
							}
							case 3: {
								val transition = statechart.selectTransitionForGuardRemoval
								transition.removeTransitionGuard
							}
							case 4: {
								val transition = statechart.selectTransitionForTriggerRemoval
								transition.removeTransitionTrigger
							}
							default:
								throw new IllegalArgumentException("Not known operator index: " + i)
						}
					}
					case TRANSITION_DYNAMICS: {
						val OPERATOR_COUNT = 10
						val i = mutationOperatorIndex % OPERATOR_COUNT
						switch (i) {
							case 0: {
								val reference = statechart.selectAnyPortEventReferenceForPortChange
								reference.changePortReference
							}
							case 1: {
								val reference = statechart.selectPortEventReferenceForChange
								reference.changePortReference
							}
							case 2: {
								val reference = statechart.selectPortEventReferenceForChange
								reference.changeEventReference
							}
							case 3: {
								val action = statechart.selectRaiseEventActionForChange
								action.changePortReference
							}
							case 4: {
								val action = statechart.selectRaiseEventActionForChange
								action.changeEventReference
							}
							case 5: {
								val reference = statechart.selectEventParameterReferenceExpressionForChange
								reference.changePortReference
							}
							case 6: {
								val reference = statechart.selectEventParameterReferenceExpressionForChange
								reference.changeEventReference
							}
							case 7: {
								val reference = statechart.selectEventParameterReferenceExpressionForChange
								reference.changeParameterReference
							}
							case 8: {
								val reference = statechart.selectDirectReferenceExpressionForDeclarationChange
								reference.changeDeclarationReference
							}
							case 9: {
								val transition = statechart.selectTransitionForEffectRemoval
								transition.removeEffect
							}
							default:
								throw new IllegalArgumentException("Not known operator index: " + i)
						}
					}
					case STATE_DYNAMICS: {
						val OPERATOR_COUNT = 4
						val i = mutationOperatorIndex % OPERATOR_COUNT
						switch (i) {
							case 0: {
								val state = statechart.selectStateForEntryActionRemoval
								state.removeEntryAction
							}
							case 1: {
								val state = statechart.selectStateForExitActionRemoval
								state.removeExitAction
							}
							case 2: {
								val entryState = statechart.selectEntryStateForChange
								entryState.changeEntryStateTarget
							}
							case 3: {
								val entryState = statechart.selectEntryStateForChange
								entryState.changeEntryState
							}
							default:
								throw new IllegalArgumentException("Not known operator index: " + i)
						}
					}
					case EXPRESSION_DYNAMICS: {
						val OPERATOR_COUNT = 2
						val i = mutationOperatorIndex % OPERATOR_COUNT
						switch (i) {
							case 0: {
								val expression = statechart.selectExpressionForChange
								expression.changeExpression
							}
							case 1: {
								val expression = statechart.selectExpressionForInversion
								expression.invertExpression
							}
							default:
								throw new IllegalArgumentException("Not known operator index: " + i)
						}
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
	
	protected def selectTransitionForSourceChange(StatechartDefinition statechart) {
		val transitions = statechart.transitions.filter[
				it.leavingState].toList
		val transition = transitions.selectElementForMutation(transitionSourceMutations)
		return transition
	}
	
	protected def selectTransitionForTargetChange(StatechartDefinition statechart) {
		val transitions = statechart.transitions.filter[
				it.targetState instanceof State].toList
		val transition = transitions.selectElementForMutation(transitionTargetMutations)
		return transition
	}
	
	protected def selectTransitionForRemoval(StatechartDefinition statechart) {
		val transitions = statechart.transitions.filter[
				it.leavingState ||
				it.sourceState instanceof ChoiceState &&
						it.sourceState.outgoingTransitions.size > 1].toList
		val transition = transitions.selectElementForMutation(transitionRemoveMutations)
		return transition
	}
	
	protected def selectTransitionForGuardRemoval(StatechartDefinition statechart) {
		val transitions = statechart.transitions.filter[
				it.hasGuard].toList
		val transition = transitions.selectElementForMutation(transitionGuardRemoveMutations)
		return transition
	}
	
	protected def selectTransitionForTriggerRemoval(StatechartDefinition statechart) {
		val transitions = statechart.transitions.filter[
				it.hasTrigger].toList
		val transition = transitions.selectElementForMutation(transitionTriggerRemoveMutations)
		return transition
	}
	
	//
	
	protected def selectAnyPortEventReferenceForPortChange(StatechartDefinition statechart) {
		if (anyPortEventReferences.empty) {
			anyPortEventReferences += statechart.getAllContentsOfType(AnyPortEventReference)
		}
		val anyPortEventReference = anyPortEventReferences.selectElementForMutation(anyPortEventReferenceMutations)
		return anyPortEventReference
	}
	
	protected def selectPortEventReferenceForChange(StatechartDefinition statechart) {
		if (portEventReferences.empty) {
			portEventReferences += statechart.getAllContentsOfType(PortEventReference)
		}
		val portEventReference = portEventReferences.selectElementForMutation(portEventReferenceChangeMutations)
		return portEventReference
	}
	
	protected def selectRaiseEventActionForChange(StatechartDefinition statechart) {
		if (raiseEventActions.empty) {
			raiseEventActions += statechart.getAllContentsOfType(RaiseEventAction)
		}
		val raiseEventAction = raiseEventActions.selectElementForMutation(raiseEventActionChangeMutations)
		return raiseEventAction
	}
	
	protected def selectEventParameterReferenceExpressionForChange(StatechartDefinition statechart) {
		if (eventParameterReferenceExpressions.empty) {
			eventParameterReferenceExpressions += statechart.getAllContentsOfType(EventParameterReferenceExpression)
		}
		val reference = eventParameterReferenceExpressions.selectElementForMutation(eventParameterReferenceExpressionChangeMutations)
		return reference
	}
	
	protected def selectDirectReferenceExpressionForDeclarationChange(StatechartDefinition statechart) {
		if (directReferenceExpressions.empty) {
			directReferenceExpressions += statechart.getAllContentsOfType(DirectReferenceExpression)
		}
		val reference = directReferenceExpressions.selectElementForMutation(directReferenceExpressionChangeMutations)
		return reference
	}
	
	protected def selectTransitionForEffectRemoval(StatechartDefinition statechart) {
		val transitions = statechart.transitions
				.filter[!it.effects.empty].toList
		val transition = transitions.selectElementForMutation(transitionEffectRemoveMutations)
		return transition
	}
	
	protected def selectStateForEntryActionRemoval(StatechartDefinition statechart) {
		if (states.empty) {
			states += statechart.getAllStates
		}
		val states = states.filter[!it.entryActions.empty].toList
		val state = states.selectElementForMutation(stateEntryActionRemoveMutations)
		return state
	}
	
	protected def selectStateForExitActionRemoval(StatechartDefinition statechart) {
		if (states.empty) {
			states += statechart.getAllStates
		}
		val states = states.filter[!it.exitActions.empty].toList
		val state = states.selectElementForMutation(stateExitActionRemoveMutations)
		return state
	}
	
	protected def selectEntryStateForChange(StatechartDefinition statechart) {
		if (regions.empty) {
			regions += statechart.allRegions
		}
		val entryStates = regions.map[it.stateNodes].flatten.filter(EntryState).toList
		val entryState = entryStates.selectElementForMutation(entryStates)
		return entryState
	}
	
	//
	
	protected def selectExpressionForChange(StatechartDefinition statechart) {
		if (expressions.empty) {
			expressions += statechart.getAllContentsOfType(Expression)
		}
		val expression = expressions.selectElementForMutation(expressionChangeMutations)
		return expression
	}
	
	protected def selectExpressionForInversion(StatechartDefinition statechart) {
		if (expressions.empty) {
			expressions += statechart.getAllContentsOfType(Expression)
		}
		val expression = expressions.selectElementForMutation(expressionInversionMutations)
		return expression
	}
	
	//
	
	protected def <T extends EObject> selectElementForMutation(Collection<? extends T> objects,
			Collection<T> unselectableObjects) {
		val selectableObjects = newArrayList
		selectableObjects += objects
		selectableObjects -= unselectableObjects
		
		checkState(!selectableObjects.empty)
		
		// Can be changed according to heuristics
		val object = mutationHeuristics.select(selectableObjects)
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
		val MAX = 100
		return random.nextInt(MAX)
	}
	
	//
	
	enum StatechartMutationType {
			TRANSITION_STRUCTURE, TRANSITION_DYNAMICS, STATE_DYNAMICS, EXPRESSION_DYNAMICS }
			
	//
	
	static class MutationHeuristics {
		//
		protected final Map<State, Integer> stateFrequency = newHashMap
	
		protected final Random random = new Random
		protected final GammaRandom gammaRandom = GammaRandom.INSTANCE
	
		protected final extension Logger logger = Logger.getLogger("GammaLogger")
		//
		
		new() {
			this(null)
		}
		
		new(Map<? extends State, Integer> stateFrequency) {
			if (stateFrequency !== null) {
				this.stateFrequency += stateFrequency
			}
		}
		
		//
		
		def <T extends EObject> select(List<? extends T> objects) {
			if (objects.forall[it.selfOrContainingOrSourceStateNode !== null]) {
				return objects.selectLessFrequentRandomly
			}
			return objects.selectRandom
		}
		
		//
		
		def <T extends EObject> selectRandom(List<? extends T> objects) {
			val i = random.nextInt(objects.size)
			val object = objects.get(i)
			
			return object
		}
		
		def <T extends EObject> selectLessFrequentRandomly(List<? extends T> objects) {
			if (stateFrequency.empty) {
				return objects.selectRandom
			}
			
			val stateNodes = objects.map[it.selfOrContainingOrSourceStateNode].toList
			val states = stateNodes.filter(State) // Considering only states: elements can be discarded
			
			val frequencies = newHashMap
			for (state : states) {
				val fqn = state.fullContainmentHierarchy
				// Summing: no differentiating between different instances of the same component
				val frequency = stateFrequency.entrySet
						.filter[it.key.fullContainmentHierarchy == fqn]
						.fold(0, [sum, a | sum + a.value])
				
				frequencies += state -> frequency
			}
			
			val selectedStateObject = gammaRandom.selectBasedOnInvertedFrequency(frequencies)
			val i = stateNodes.indexOf(selectedStateObject)
			
			val object = objects.get(i)
			logger.info("Selected " + object + " based on frequency calculation")
			
			return object
		}
		
		//
		
		def getStateFrequency() {
			return this.stateFrequency
		}
		
	}
	
}