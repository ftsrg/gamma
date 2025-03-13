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

import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.transformation.util.UnfoldingTraceability
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List
import org.eclipse.xtend.lib.annotations.Data

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ModelAnnotatorPropertyGenerator {
	
	protected final Component newTopComponent
	
	protected final AnnotatablePreprocessableElements annotableElements
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension UnfoldingTraceability traceability = UnfoldingTraceability.INSTANCE
	
	new(Component newTopComponent, AnnotatablePreprocessableElements annotableElements) {
		this.newTopComponent = newTopComponent
		this.annotableElements = annotableElements
	}
	
	def execute() {
		val newPackage = newTopComponent.containingPackage
		// Checking if we need annotation and property generation
		var PropertyPackage generatedPropertyPackage
		val importablePackages = newHashSet
		
		// State coverage
		val testedComponentsForStates = getIncludedSynchronousInstances(
				annotableElements.testedComponentsForStates, newTopComponent)
		// Unstable state coverage
		val testedComponentsForUnstableStates = getIncludedSynchronousInstances(
				annotableElements.testedComponentsForUnstableStates, newTopComponent)
				.map[it.type].filter(StatechartDefinition).map[it.allStates].flatten
		// Trap state coverage
		val testedComponentsForTrapStates = getIncludedSynchronousInstances(
				annotableElements.testedComponentsForTrapStates, newTopComponent)
				.map[it.type].filter(StatechartDefinition).map[it.allStates].flatten
		// Deadlock coverage
		val testedComponentsForDeadlock = getIncludedSynchronousInstances(
				annotableElements.testedComponentsForDeadlock, newTopComponent)
		// Nondeterministic transition coverage
		val testedComponentsForNondeterministicTransitions = getIncludedSynchronousInstances(
				annotableElements.testedComponentsForNondeterministicTransitions, newTopComponent)
		// Transition coverage
		val testedComponentsForTransitions = getIncludedSynchronousInstances(
				annotableElements.testedComponentsForTransitions, newTopComponent)
		// Transition-pair coverage
		val testedComponentsForTransitionPairs = getIncludedSynchronousInstances(
				annotableElements.testedComponentsForTransitionPairs, newTopComponent)
		// Out event coverage
		val testedPortsForOutEvents = getIncludedSynchronousInstancePorts(
				annotableElements.testedComponentsForOutEvents, newTopComponent)
		if (!testedPortsForOutEvents.nullOrEmpty) {
			// Only system out events are covered as other internal events might be removed
			testedPortsForOutEvents.retainAll(newTopComponent.allBoundSimplePorts)
			importablePackages += testedPortsForOutEvents.map[it.interface.allEvents].flatten
				.map[it.parameterDeclarations].flatten
				.map[it.type].filter(TypeReference).map[it.reference.containingPackage]
		}
		// Interaction coverage
		val testedPortsForInteractions = getIncludedSynchronousInstancePorts(
				annotableElements.testedInteractions, newTopComponent)
		val testedStatesForInteractions = getIncludedSynchronousInstanceStates(
				annotableElements.testedInteractions, newTopComponent)
		val testedTransitionsForInteractions = getIncludedSynchronousInstanceTransitions(
				annotableElements.testedInteractions, newTopComponent)
		// Dataflow coverage
		val dataflowTestedVariables = getIncludedSynchronousInstanceVariables(
				annotableElements.dataflowTestedVariables, newTopComponent)
		// Interaction dataflow coverage
		val testedPortsForInteractionDataflow = getIncludedSynchronousInstancePorts(
				annotableElements.testedComponentsForInteractionDataflow, newTopComponent)
		
		if (!testedComponentsForStates.nullOrEmpty ||
				!testedComponentsForUnstableStates.nullOrEmpty ||
				!testedComponentsForTrapStates.nullOrEmpty ||
				!testedComponentsForDeadlock.nullOrEmpty ||
				!testedComponentsForNondeterministicTransitions.nullOrEmpty ||
				!testedComponentsForTransitions.nullOrEmpty ||
				!testedComponentsForTransitionPairs.nullOrEmpty ||
				!testedPortsForOutEvents.nullOrEmpty ||
				!testedPortsForInteractions.nullOrEmpty || !testedStatesForInteractions.nullOrEmpty ||
				!testedTransitionsForInteractions.nullOrEmpty ||
				!dataflowTestedVariables.nullOrEmpty ||
				!testedPortsForInteractionDataflow.nullOrEmpty) {
			val annotator = new StatechartAnnotator(newPackage,
				new AnnotatableElements(
					testedComponentsForDeadlock,
					testedComponentsForNondeterministicTransitions,
					testedComponentsForTransitions,
					testedComponentsForTransitionPairs,
					testedPortsForInteractions, testedStatesForInteractions, testedTransitionsForInteractions,
					annotableElements.senderCoverageCriterion, annotableElements.receiverCoverageCriterion,
					dataflowTestedVariables, annotableElements.dataflowCoverageCriterion,
					testedPortsForInteractionDataflow, annotableElements.interactionDataflowCoverageCriterion
				)
			)
			annotator.annotateModel
			newPackage.save // It must be saved so the property package can be serialized
			
			// We are after model unfolding, so the argument is true
			val propertyGenerator = new PropertyGenerator(true)
			generatedPropertyPackage = propertyGenerator.initializePackage(newTopComponent)
			generatedPropertyPackage.imports += importablePackages
			
			val formulas = generatedPropertyPackage.formulas
			
			formulas += propertyGenerator.createStateReachability(testedComponentsForStates)
			
			formulas += propertyGenerator.createUnstableStateInvariance(testedComponentsForUnstableStates)
			formulas += propertyGenerator.createTrapStateInvariance(testedComponentsForTrapStates)
			formulas += propertyGenerator.createDeadlockInvariance(annotator.getDeadlockTransitionVariables)
			formulas += propertyGenerator.createStateReachabilityFormulas(annotator.trapStates) // Nondeterministic transition coverage
			
			formulas += propertyGenerator.createTransitionReachability(
							annotator.getTransitionVariables)
			formulas += propertyGenerator.createTransitionPairReachability(
							annotator.getTransitionPairAnnotations)
			formulas += propertyGenerator.createInteractionReachability(annotator.getInteractions)
			formulas += propertyGenerator.createOutEventReachability(testedPortsForOutEvents)
			
			formulas += propertyGenerator.createDataflowReachability(annotator.variableDefUses,
					annotator.dataflowCoverageCriterion)
			formulas += propertyGenerator.createInteractionDataflowReachability(
					annotator.getInteractionDefUses, annotator.interactionDataflowCoverageCriterion)
			// Saving the property package and serializing the properties has to be done by the caller!
		}
		return new Result(generatedPropertyPackage)
	}
	
	protected def List<SynchronousComponentInstance> getIncludedSynchronousInstances(
			ComponentInstanceReferences references, Component component) {
		if (references === null) {
			return #[]
		}
		return traceability.getNewSimpleInstances(references.include,
			references.exclude, component)
	}
	
	protected def List<Port> getIncludedSynchronousInstancePorts(
			ComponentInstancePortReferences references, Component component) {
		if (references === null) {
			return #[]
		}
		val includedInstances =
			traceability.getNewSimpleInstances(references.instances.include, component)
		val excludedInstances =
			traceability.getNewSimpleInstances(references.instances.exclude, component)
		val includedPorts =
			traceability.getNewSimpleInstancePorts(references.ports.include, component)
		val excludedPorts =
			traceability.getNewSimpleInstancePorts(references.ports.exclude, component)
		
		val ports = newArrayList
		if (includedInstances.empty && includedPorts.empty) {
			// If both includes are empty, then we include all the new instances
			val newSimpleInstances = component.allSimpleInstances
			ports += newSimpleInstances.ports
		}
		// The semantics is defined here: including has priority over excluding
		ports -= excludedInstances.ports // - excluded instance
		ports += includedInstances.ports // + included instance
		ports -= excludedPorts // - included port
		ports += includedPorts // + included port
		return ports
	}
	
	protected def List<Port> getPorts(List<SynchronousComponentInstance> instances) {
		val ports = newArrayList
		for (instance : instances) {
			val type = instance.getType
			ports += type.allPorts
		}
		return ports
	}
	
	protected def List<State> getIncludedSynchronousInstanceStates(
			ComponentInstancePortStateTransitionReferences references, Component component) {
		if (references === null) {
			return #[]
		}
		val stateReferences = references.getStates
		var includedStates = traceability.getNewSimpleInstanceStates(
			stateReferences.include, component).toList
		if (includedStates.empty) {
			includedStates = component.allSimpleInstances.map[it.type]
				.filter(StatechartDefinition).map[it.allStates].flatten.toList
		}
		val excludedStates = traceability.getNewSimpleInstanceStates(
			stateReferences.exclude, component)
		includedStates -= excludedStates
		return includedStates
	}
	
	protected def List<Transition> getIncludedSynchronousInstanceTransitions(
			ComponentInstancePortStateTransitionReferences references, Component component) {
		if (references === null) {
			return #[]
		}
		val transitionReferences = references.transitions
		var includedTransitions = traceability.getNewSimpleInstanceTransitions(
			transitionReferences.include, component).toList
		if (includedTransitions.empty) {
			includedTransitions = component.allSimpleInstances.map[it.type]
				.filter(StatechartDefinition).map[it.transitions].flatten.toList
		}
		val excludedTransitions = traceability.getNewSimpleInstanceTransitions(
			transitionReferences.exclude, component)
		includedTransitions -= excludedTransitions
		return includedTransitions
	}
	
	protected def getIncludedSynchronousInstanceVariables(
			ComponentInstanceVariableReferences references, Component component) {
		if (references === null) {
			return #[]
		}
		val includedInstances =	traceability
				.getNewSimpleInstances(references.instances.include, component)
		val excludedInstances =	traceability
				.getNewSimpleInstances(references.instances.exclude, component)
		val includedVariables =	traceability
				.getNewSimpleInstanceVariables(references.variables.include, component)
		val excludedVariables =	traceability
				.getNewSimpleInstanceVariables(references.variables.exclude, component)
		
		val variables = newArrayList
		if (includedInstances.empty && includedVariables.empty) {
			// If both includes are empty, then we include all the new instances
			val newSimpleInstances = component.allSimpleInstances
			variables += newSimpleInstances.map[it.type].filter(StatechartDefinition)
				.map[it.variableDeclarations].flatten
		}
		// The semantics is defined here: including has priority over excluding
		variables -= excludedInstances.variables // - excluded instance
		variables += includedInstances.variables // + included instance
		variables -= excludedVariables // - included variable
		variables += includedVariables // + included variable
		return variables
	}
	
	protected def getVariables(List<SynchronousComponentInstance> instances) {
		val variables = newArrayList
		for (instance : instances) {
			val type = instance.getType
			if (type instanceof StatechartDefinition) {
				variables += type.variableDeclarations
			}
		}
		return variables
	}
	
	// Data
	
	@Data
	static class Result {
		PropertyPackage generatedPropertyPackage
	}
	
}