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
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.composite.Channel
import hu.bme.mit.gamma.statechart.composite.CompositeComponent
import hu.bme.mit.gamma.statechart.composite.PortBinding
import hu.bme.mit.gamma.statechart.composite.SchedulableCompositeComponent
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.phase.MissionPhaseAnnotation
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateAnnotation
import hu.bme.mit.gamma.statechart.phase.VariableBinding
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
import hu.bme.mit.gamma.util.ReflectiveViatraMatcher
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
	
	protected final Set<Channel> channelRemoveMutations = newHashSet
	protected final Set<Channel> channelChangeMutations = newHashSet
	protected final Set<PortBinding> portBindingRemoveMutations = newHashSet
	protected final Set<PortBinding> portBindingChangeMutations = newHashSet
	
	protected final Set<VariableBinding> variableBindingRemoveMutations = newHashSet
	protected final Set<VariableBinding> variableBindingChangeMutations = newHashSet
	
	
	protected final Set<MissionPhaseStateAnnotation> adaptationChangeHistoryMutations = newHashSet	
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
	
	def void execute(Component component) {
		if (component instanceof StatechartDefinition) {
			component.executeOnStatechart
		}
		else if (component instanceof CompositeComponent) {
			val MUTATE_STATECHART_PROBABILITY = 0.7
			val random = random.nextDouble
			if (random < MUTATE_STATECHART_PROBABILITY) {
				component.executeOnStatechart
			}
			else {
				val components = component.selfAndAllComponents
				val composite = components
						.filter(CompositeComponent).toList
						.selectElement // Random selection
				
				composite.mutate
				composite.addMutantAnnotation
			}
		}
		else if (component instanceof AsynchronousAdapter) {
			val adaptedType = component.wrappedComponent.type
			adaptedType.execute
		}
		else {
			throw new IllegalArgumentException("Not known type: " + component)
		}
	}
	
	def void executeOnStatechart(Component component) {
		if (component instanceof StatechartDefinition) {
			component.mutate
			component.addMutantAnnotation
		}
		else if (component instanceof CompositeComponent) {
			val statecharts = component.selfOrAllContainedStatecharts.toList
			val statechart = statecharts.selectElement // Random selection
			
			statechart.mutate
			statechart.addMutantAnnotation
		}
		else if (component instanceof AsynchronousAdapter) {
			val adaptedType = component.wrappedComponent.type
			adaptedType.executeOnStatechart
		}
	}
	
	//
	
	def mutate(Component component) {
		var success = true
		do {
 			try {
 				success = true
				switch (component) {
					StatechartDefinition: {
						// Adaptive
						val isAdaptiveStatechart = component.missionPhase
						if (isAdaptiveStatechart) {
							val MUTATE_ADAPTATION_PROBABILITY = 0.3
							val random = random.nextDouble
							if (random < MUTATE_ADAPTATION_PROBABILITY) {
								val annotation = component.annotations.filter(MissionPhaseAnnotation).head
								annotation.mutateOnce
								return
							}
						}
						// Normal statechart
						component.mutateOnce
					}
					CompositeComponent: {
						component.mutateOnce
					}
					default:
						throw new IllegalArgumentException("Not known type: " + component)
				}
			} catch (IllegalArgumentException | IllegalStateException e) {
				// Not mutatable model element
				success = false
				// Note that any selected element stays in the corresponding cache
			}
		} while (!success)
	}
	
	//
	
	protected def mutateOnce(StatechartDefinition statechart) {
		val mutationType = StatechartMutationType.mutationType
		switch (mutationType) {
			case TRANSITION_STRUCTURE_SOURCE_CHANGE: {
				val transition = statechart.selectTransitionForSourceChange
				transition.changeTransitionSource
			}
			case TRANSITION_STRUCTURE_TARGET_CHANGE: {
				val transition = statechart.selectTransitionForTargetChange
				transition.changeTransitionTarget
			}
			case TRANSITION_STRUCTURE_REMOVE: {
				val transition = statechart.selectTransitionForRemoval
				transition.removeTransition
			}
			case TRANSITION_STRUCTURE_GUARD_REMOVE: {
				val transition = statechart.selectTransitionForGuardRemoval
				transition.removeTransitionGuard
			}
			case TRANSITION_STRUCTURE_TRIGGER_REMOVE: {
				val transition = statechart.selectTransitionForTriggerRemoval
				transition.removeTransitionTrigger
			}
			case TRANSITION_DYNAMICS_ANY_PORT_EVENT_REFERENCE_PORT_CHANGE: {
				val reference = statechart.selectAnyPortEventReferenceForPortChange
				reference.changePortReference
			}
			case TRANSITION_DYNAMICS_PORT_EVENT_REFERENCE_PORT_CHANGE: {
				val reference = statechart.selectPortEventReferenceForChange
				reference.changePortReference
			}
			case TRANSITION_DYNAMICS_PORT_EVENT_REFERENCE_EVENT_CHANGE: {
				val reference = statechart.selectPortEventReferenceForChange
				reference.changeEventReference
			}
			case TRANSITION_DYNAMICS_RAISE_EVENT_ACTION_PORT_CHANGE: {
				val action = statechart.selectRaiseEventActionForChange
				action.changePortReference
			}
			case TRANSITION_DYNAMICS_RAISE_EVENT_ACTION_EVENT_CHANGE: {
				val action = statechart.selectRaiseEventActionForChange
				action.changeEventReference
			}
			case TRANSITION_DYNAMICS_EVENT_PARAMETER_REFERENCE_PORT_CHANGE: {
				val reference = statechart.selectEventParameterReferenceExpressionForChange
				reference.changePortReference
			}
			case TRANSITION_DYNAMICS_EVENT_PARAMETER_REFERENCE_EVENT_CHANGE: {
				val reference = statechart.selectEventParameterReferenceExpressionForChange
				reference.changeEventReference
			}
			case TRANSITION_DYNAMICS_EVENT_PARAMETER_REFERENCE_PARAMETER_CHANGE: {
				val reference = statechart.selectEventParameterReferenceExpressionForChange
				reference.changeParameterReference
			}
			case TRANSITION_DYNAMICS_DECLARATION_REFERENCE_DECLARATION_CHANGE: {
				val reference = statechart.selectDirectReferenceExpressionForDeclarationChange
				reference.changeDeclarationReference
			}
			case TRANSITION_DYNAMICS_EFFECT_REMOVE: {
				val transition = statechart.selectTransitionForEffectRemoval
				transition.removeEffect
			}
			case STATE_DYNAMICS_STATE_ENTRY_ACTION_REMOVE: {
				val state = statechart.selectStateForEntryActionRemoval
				state.removeEntryAction
			}
			case STATE_DYNAMICS_STATE_EXIT_ACTION_REMOVE: {
				val state = statechart.selectStateForExitActionRemoval
				state.removeExitAction
			}
			case STATE_DYNAMICS_ENTRY_STATE_TARGET_CHANGE: {
				val entryState = statechart.selectEntryStateForChange
				entryState.changeEntryStateTarget
			}
			case STATE_DYNAMICS_ENTRY_STATE_CHANGE: {
				val entryState = statechart.selectEntryStateForChange
				entryState.changeEntryState
			}
			case EXPRESSION_DYNAMICS_EXPRESSION_CHANGE: {
				val expression = statechart.selectExpressionForChange
				expression.changeExpression
			}
			case EXPRESSION_DYNAMICS_EXPRESSION_INVERT: {
				val expression = statechart.selectExpressionForInversion
				expression.invertExpression
			}
			default:
				throw new IllegalArgumentException("Not known mutation operator: " + mutationType)
		}
	}
	
	protected def mutateOnce(MissionPhaseAnnotation annotation) {
		val statechart = annotation.containingStatechart
		val stateAnnotations = statechart.getAllContentsOfType(MissionPhaseStateAnnotation)
		val stateAnnotation = stateAnnotations.selectElementForMutation
		
		val mutationType = AdaptationMutationType.mutationType
		switch (mutationType) {
			case ANNOTATION_STRUCTURE_REMOVE: {
				stateAnnotation.removeAnnotation
			}
			case ANNOTATION_STRUCTURE_PORT_BINDING_REMOVE: {
				val portBinding = stateAnnotation.selectPortBindingForRemoval
				portBinding.removePortBinding
			}
			case ANNOTATION_STRUCTURE_PORT_BINDING_ENDPOINT_CHANGE: {
				val portBinding = stateAnnotation.selectPortBindingForEndpointChange
				portBinding.changePortBindingEndpoint
			}
			case ANNOTATION_STRUCTURE_VARIABLE_BINDING_REMOVE: {
				val variableBinding = stateAnnotation.selectVariableBindingForRemoval
				variableBinding.removeVariableBinding
			}
			case ANNOTATION_STRUCTURE_VARIABLE_BINDING_ENDPOINT_CHANGE: {
				val variableBinding = stateAnnotation.selectVariableBindingForEndpointChange
				variableBinding.changeVariableBindingEndpoint
			}
			case ANNOTATION_DYNAMICS_HISTORY_CHANGE: {
				adaptationChangeHistoryMutations += stateAnnotation
				stateAnnotation.changeHistory
			}
			case EXPRESSION_DYNAMICS_EXPRESSION_CHANGE: {
				val component = (random.nextBoolean) ? stateAnnotation.component.derivedType : statechart
				val expression = component.selectExpressionForChange
				expression.changeExpression
			}
			case EXPRESSION_DYNAMICS_EXPRESSION_INVERT: {
				val component = (random.nextBoolean) ? stateAnnotation.component.derivedType : statechart
				val expression = component.selectExpressionForInversion
				expression.invertExpression
			}
			default:
				throw new IllegalArgumentException("Not known mutation operator: " + mutationType)
		}
	}
	
	protected def mutateOnce(CompositeComponent composite) {
		val mutationType = CompositeComponentMutationType.mutationType
		//
		val componentScheduleList = switch (composite) {
			SchedulableCompositeComponent: composite.executionList.empty ?
				composite.containedComponents : composite.executionList
			default: composite.containedComponents
		}
		//
		switch (mutationType) {
			case COMPOSITION_STRUCTURE_CHANNEL_REMOVE: {
				val channel = composite.selectChannelForRemoval
				channel.removeChannel
			}
			case COMPOSITION_STRUCTURE_CHANNEL_ENDPOINT_CHANGE: {
				val channel = composite.selectChannelForEndpointChange
				channel.changeChannelEndpoint
			}
			case COMPOSITION_STRUCTURE_PORT_BINDING_REMOVE: {
				val portBinding = composite.selectPortBindingForRemoval
				portBinding.removePortBinding
			}
			case COMPOSITION_STRUCTURE_PORT_BINDING_ENDPOINT_CHANGE: {
				val portBinding = composite.selectPortBindingForEndpointChange
				portBinding.changePortBindingEndpoint
			}
			case COMPOSITION_DYNAMICS_SCHEDULE_LIST_ELEMENT_CHANGE: {
				componentScheduleList.moveOneElement
			}
			case COMPOSITION_DYNAMICS_SCHEDULE_LIST_ELEMENT_REMOVE: {
				checkState(composite instanceof SchedulableCompositeComponent)
				val schedulableComposite = composite as SchedulableCompositeComponent
				checkState(componentScheduleList === schedulableComposite.executionList)
				componentScheduleList.removeOneElement
			}
			case EXPRESSION_DYNAMICS_EXPRESSION_CHANGE: {
				val expression = composite.selectDirectlyContainedExpressionForChange
				expression.changeExpression
			}
			case EXPRESSION_DYNAMICS_EXPRESSION_INVERT: {
				val expression = composite.selectDirectlyContainedExpressionForInversion
				expression.invertExpression
			}
			default:
				throw new IllegalArgumentException("Not known mutation operator: " + mutationType)
		}
	}
	
	//
	
	protected def selectTransitionForSourceChange(StatechartDefinition statechart) {
		val transitions = statechart.transitions.filter[it.leavingState].toList
		val transition = transitions.selectElementForMutation(transitionSourceMutations)
		return transition
	}
	
	protected def selectTransitionForTargetChange(StatechartDefinition statechart) {
		val transitions = statechart.transitions.filter[it.targetState instanceof State].toList
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
		val transitions = statechart.transitions.filter[it.hasGuard].toList
		val transition = transitions.selectElementForMutation(transitionGuardRemoveMutations)
		return transition
	}
	
	protected def selectTransitionForTriggerRemoval(StatechartDefinition statechart) {
		val transitions = statechart.transitions.filter[it.hasTrigger].toList
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
		val transitions = statechart.transitions.filter[!it.effects.empty].toList
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
	
	protected def selectExpressionForChange(Component component) {
		if (expressions.empty) {
			expressions += component.getAllContentsOfType(Expression)
		}
		val expression = expressions.selectElementForMutation(expressionChangeMutations)
		return expression
	}
	
	protected def selectExpressionForInversion(Component component) {
		if (expressions.empty) {
			expressions += component.getAllContentsOfType(Expression)
		}
		val expression = expressions.selectElementForMutation(expressionInversionMutations)
		return expression
	}
	
	protected def selectDirectlyContainedExpressionForChange(Component component) {
		val expressions = component.getContentsOfType(Expression)
		val expression = expressions.selectElementForMutation(expressionChangeMutations)
		return expression
	}
	
	protected def selectDirectlyContainedExpressionForInversion(Component component) {
		val expressions = component.getContentsOfType(Expression)
		val expression = expressions.selectElementForMutation(expressionInversionMutations)
		return expression
	}
	
	//
	
	protected def selectChannelForRemoval(CompositeComponent composite) {
		val channels = composite.channels
		val channel = channels.selectElementForMutation(channelRemoveMutations)
		return channel
	}
	
	protected def selectChannelForEndpointChange(CompositeComponent composite) {
		val channels = composite.channels
		val channel = channels.selectElementForMutation(channelChangeMutations)
		return channel
	}
	
	protected def selectPortBindingForRemoval(CompositeComponent composite) {
		val portBindings = composite.portBindings
		val portBinding = portBindings.selectElementForMutation(portBindingRemoveMutations)
		return portBinding
	}
	
	protected def selectPortBindingForEndpointChange(CompositeComponent composite) {
		val portBindings = composite.portBindings
		val portBinding = portBindings.selectElementForMutation(portBindingChangeMutations)
		return portBinding
	}
	
	//
	
	protected def selectPortBindingForRemoval(MissionPhaseStateAnnotation annotation) {
		val portBindings = annotation.portBindings
		val portBinding = portBindings.selectElementForMutation(portBindingRemoveMutations)
		return portBinding
	}
	
	protected def selectPortBindingForEndpointChange(MissionPhaseStateAnnotation annotation) {
		val portBindings = annotation.portBindings
		val portBinding = portBindings.selectElementForMutation(portBindingChangeMutations)
		return portBinding
	}
	
	protected def selectVariableBindingForRemoval(MissionPhaseStateAnnotation annotation) {
		val variableBindings = annotation.variableBindings
		val variableBinding = variableBindings.selectElementForMutation(variableBindingRemoveMutations)
		return variableBinding
	}
	
	protected def selectVariableBindingForEndpointChange(MissionPhaseStateAnnotation annotation) {
		val variableBindings = annotation.variableBindings
		val variableBinding = variableBindings.selectElementForMutation(variableBindingChangeMutations)
		return variableBinding
	}
	
	//
	
	protected def <T extends EObject> selectElementForMutation(Collection<? extends T> objects) {
		return objects.selectElementForMutation(#[])
	}
	
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
	
	protected def <T> getMutationType(Class<T> clazz) {
		return clazz.getMutationType(null)
	}
	
	protected def <T> getMutationType(Class<T> clazz, Collection<? extends T> consideredMutations) {
		val mutationTypes = <T>newArrayList
		
		mutationTypes += clazz.enumConstants
		if (consideredMutations !== null) { // Removing unwanted mutation types
			mutationTypes.retainAll(consideredMutations)
		}
		
		val mutationTypesCount = mutationTypes.length
		val i = random.nextInt(mutationTypesCount)
		
		val mutationType = mutationTypes.get(i)
		return mutationType
	}
	
	protected def getMutationOperator() {
		val MAX = 100
		return random.nextInt(MAX)
	}
	
	// Note that these literals affect the probabilities of applying a certain mutation operator
	
	enum StatechartMutationType {
		TRANSITION_STRUCTURE_SOURCE_CHANGE, TRANSITION_STRUCTURE_TARGET_CHANGE,
		TRANSITION_STRUCTURE_REMOVE, TRANSITION_STRUCTURE_GUARD_REMOVE,
		TRANSITION_STRUCTURE_TRIGGER_REMOVE,
		//
		TRANSITION_DYNAMICS_ANY_PORT_EVENT_REFERENCE_PORT_CHANGE,
		TRANSITION_DYNAMICS_PORT_EVENT_REFERENCE_PORT_CHANGE,
		TRANSITION_DYNAMICS_PORT_EVENT_REFERENCE_EVENT_CHANGE,
		TRANSITION_DYNAMICS_RAISE_EVENT_ACTION_PORT_CHANGE,
		TRANSITION_DYNAMICS_RAISE_EVENT_ACTION_EVENT_CHANGE,
		TRANSITION_DYNAMICS_EVENT_PARAMETER_REFERENCE_PORT_CHANGE,
		TRANSITION_DYNAMICS_EVENT_PARAMETER_REFERENCE_EVENT_CHANGE,
		TRANSITION_DYNAMICS_EVENT_PARAMETER_REFERENCE_PARAMETER_CHANGE,
		TRANSITION_DYNAMICS_DECLARATION_REFERENCE_DECLARATION_CHANGE,
		TRANSITION_DYNAMICS_EFFECT_REMOVE,
		//
		STATE_DYNAMICS_STATE_ENTRY_ACTION_REMOVE, STATE_DYNAMICS_STATE_EXIT_ACTION_REMOVE,
		STATE_DYNAMICS_ENTRY_STATE_TARGET_CHANGE, STATE_DYNAMICS_ENTRY_STATE_CHANGE,
		//
		EXPRESSION_DYNAMICS_EXPRESSION_CHANGE, EXPRESSION_DYNAMICS_EXPRESSION_INVERT
	}
	
	enum AdaptationMutationType {
		ANNOTATION_STRUCTURE_REMOVE,
		ANNOTATION_STRUCTURE_PORT_BINDING_REMOVE, ANNOTATION_STRUCTURE_PORT_BINDING_ENDPOINT_CHANGE,
		ANNOTATION_STRUCTURE_VARIABLE_BINDING_REMOVE, ANNOTATION_STRUCTURE_VARIABLE_BINDING_ENDPOINT_CHANGE,
		//
		ANNOTATION_DYNAMICS_HISTORY_CHANGE,
		//
		EXPRESSION_DYNAMICS_EXPRESSION_CHANGE, EXPRESSION_DYNAMICS_EXPRESSION_INVERT
		}
	
	enum CompositeComponentMutationType {
		COMPOSITION_STRUCTURE_CHANNEL_REMOVE, COMPOSITION_STRUCTURE_CHANNEL_ENDPOINT_CHANGE,
		COMPOSITION_STRUCTURE_PORT_BINDING_REMOVE, COMPOSITION_STRUCTURE_PORT_BINDING_ENDPOINT_CHANGE,
		//
		COMPOSITION_DYNAMICS_SCHEDULE_LIST_ELEMENT_CHANGE,
		COMPOSITION_DYNAMICS_SCHEDULE_LIST_ELEMENT_REMOVE,
		//
		EXPRESSION_DYNAMICS_EXPRESSION_CHANGE, EXPRESSION_DYNAMICS_EXPRESSION_INVERT
	}
			
	//
	
	static class MutationHeuristics {
		//
		protected final Map<State, Integer> stateFrequency = newHashMap
		protected final Collection<String> patternClassNames = newArrayList
		protected final Collection<EObject> matchedObjects = newLinkedHashSet
		protected String binUri
	
		protected final Random random = new Random
		protected final GammaRandom gammaRandom = GammaRandom.INSTANCE
		protected final ReflectiveViatraMatcher matcher = ReflectiveViatraMatcher.INSTANCE
	
		protected final extension Logger logger = Logger.getLogger("GammaLogger")
		//
		
		new() {
			this(null)
		}
		
		new(Map<? extends State, Integer> stateFrequency) {
			this (stateFrequency, #[], "")
		}
		
		new(Collection<String> patternClassNames, String binUri) {
			this(null, patternClassNames, binUri)
		}
		
		new(Map<? extends State, Integer> stateFrequency,
				Collection<String> patternClassNames, String binUri) {
			if (stateFrequency !== null) {
				this.stateFrequency += stateFrequency
			}
			if (!patternClassNames.nullOrEmpty) {
				this.patternClassNames += patternClassNames
			}
			this.binUri = binUri
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
		
		def <T extends EObject> selectMatchedElementRandomly(List<? extends T> objects) {
			val matchedObjects = objects.filterMatchedObjects
			val object = matchedObjects.selectRandom
			
			return object
		}
		
		def <T extends EObject> selectLessFrequentRandomly(List<? extends T> objects) {
			if (stateFrequency.empty) {
				return objects.selectRandom
			}
			
			val stateNodes = objects
					.filterMatchedObjects // Pattern-based filter
					.map[it.selfOrContainingOrSourceStateNode].toList
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
		
		protected def <T extends EObject> filterMatchedObjects(List<? extends T> objects) {
			if (objects.nullOrEmpty || patternClassNames.nullOrEmpty) {
				return objects
			}
			
			if (matchedObjects.empty) {
				// Querying the matches
				val head = objects.head
				head.computeMatches
			}
			
			val filteredObjects = newArrayList
			filteredObjects += objects
			filteredObjects.retainAll(matchedObjects)
			logger.info("Filtered unmatched elements")
			
			return filteredObjects
		}
		
		protected def computeMatches(EObject resourceObject) {
			for (patternClassName : patternClassNames) {
				val objects = matcher.queryAndMapMatches(resourceObject, this.class.classLoader,
						patternClassName, binUri)
				matchedObjects += objects.filter(EObject)
			}
		}
		
		//
		
		def getStateFrequency() {
			return this.stateFrequency
		}
		
		def getPatternClassNames() {
			return this.patternClassNames
		}
		
		def getBinUri() {
			return binUri
		}
		
		def setBinUri(String binUri) {
			this.binUri = binUri
		}
		
	}
	
}