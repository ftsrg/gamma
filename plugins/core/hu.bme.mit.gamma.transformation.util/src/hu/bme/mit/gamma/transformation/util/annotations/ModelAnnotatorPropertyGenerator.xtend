package hu.bme.mit.gamma.transformation.util.annotations

import hu.bme.mit.gamma.property.model.ComponentInstancePortReference
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference
import hu.bme.mit.gamma.property.model.ComponentInstanceTransitionReference
import hu.bme.mit.gamma.property.model.ComponentInstanceVariableReference
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.transformation.util.SimpleInstanceHandler
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection
import java.util.List
import org.eclipse.xtend.lib.annotations.Data

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ModelAnnotatorPropertyGenerator {
	
	protected final Component newTopComponent
	protected final ComponentInstanceReferences testedComponentsForStates
	protected final ComponentInstanceReferences testedComponentsForTransitions
	protected final ComponentInstanceReferences testedComponentsForTransitionPairs
	protected final ComponentInstancePortReferences testedComponentsForOutEvents
	protected final ComponentInstancePortStateTransitionReferences testedInteractions
	protected final InteractionCoverageCriterion senderCoverageCriterion
	protected final InteractionCoverageCriterion receiverCoverageCriterion
	protected final ComponentInstanceVariableReferences dataflowTestedVariables
	protected final DataflowCoverageCriterion dataflowCoverageCriterion
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension SimpleInstanceHandler simpleInstanceHandler = SimpleInstanceHandler.INSTANCE
	
	new(Component newTopComponent,
			ComponentInstanceReferences testedComponentsForStates,
			ComponentInstanceReferences testedComponentsForTransitions,
			ComponentInstanceReferences testedComponentsForTransitionPairs,
			ComponentInstancePortReferences testedComponentsForOutEvents,
			ComponentInstancePortStateTransitionReferences testedInteractions,
			InteractionCoverageCriterion senderCoverageCriterion,
			InteractionCoverageCriterion receiverCoverageCriterion,
			ComponentInstanceVariableReferences dataflowTestedVariables,
			DataflowCoverageCriterion dataflowCoverageCriterion) {
		this.newTopComponent = newTopComponent
		this.testedComponentsForStates = testedComponentsForStates
		this.testedComponentsForTransitions = testedComponentsForTransitions
		this.testedComponentsForTransitionPairs = testedComponentsForTransitionPairs
		this.testedComponentsForOutEvents = testedComponentsForOutEvents
		this.testedInteractions = testedInteractions
		this.senderCoverageCriterion = senderCoverageCriterion
		this.receiverCoverageCriterion = receiverCoverageCriterion
		this.dataflowTestedVariables = dataflowTestedVariables
		this.dataflowCoverageCriterion = dataflowCoverageCriterion
	}
	
	def execute() {
		val newPackage = StatechartModelDerivedFeatures.getContainingPackage(newTopComponent)
		// Checking if we need annotation and property generation
		var PropertyPackage generatedPropertyPackage
		
		// State coverage
		val testedComponentsForStates = getIncludedSynchronousInstances(
				testedComponentsForStates, newTopComponent)
		// Transition coverage
		val testedComponentsForTransitions = getIncludedSynchronousInstances(
				testedComponentsForTransitions, newTopComponent)
		// Transition-pair coverage
		val testedComponentsForTransitionPairs = getIncludedSynchronousInstances(
				testedComponentsForTransitionPairs, newTopComponent)
		// Out event coverage
		val testedPortsForOutEvents = getIncludedSynchronousInstancePorts(
				testedComponentsForOutEvents, newTopComponent)
		if (!testedPortsForOutEvents.nullOrEmpty) {
			// Only system out events are covered as other internal events might be removed
			testedPortsForOutEvents.retainAll(newTopComponent.allConnectedSimplePorts)
		}
		// Interaction coverage
		val testedPortsForInteractions = getIncludedSynchronousInstancePorts(
				testedInteractions, newTopComponent)
		val testedStatesForInteractions = getIncludedSynchronousInstanceStates(
				testedInteractions, newTopComponent)
		val testedTransitionsForInteractions = getIncludedSynchronousInstanceTransitions(
				testedInteractions, newTopComponent)
		// Dataflow coverage
		val dataflowTestedVariables = getIncludedSynchronousInstanceVariables(
				dataflowTestedVariables, newTopComponent)
		
		if (!testedComponentsForStates.nullOrEmpty || !testedComponentsForTransitions.nullOrEmpty ||
				!testedComponentsForTransitionPairs.nullOrEmpty || !testedPortsForOutEvents.nullOrEmpty ||
				!testedPortsForInteractions.nullOrEmpty || !testedStatesForInteractions.nullOrEmpty ||
				!testedTransitionsForInteractions.nullOrEmpty ||
				!dataflowTestedVariables.nullOrEmpty) {
			val annotator = new GammaStatechartAnnotator(newPackage,
					testedComponentsForTransitions, testedComponentsForTransitionPairs,
					testedPortsForInteractions, testedStatesForInteractions,
					testedTransitionsForInteractions,
					senderCoverageCriterion, receiverCoverageCriterion,
					dataflowTestedVariables, dataflowCoverageCriterion)
			annotator.annotateModel
			newPackage.save // It must be saved so the property package can be serialized
			
			// We are after model unfolding, so the argument is true
			val propertyGenerator = new PropertyGenerator(true)
			generatedPropertyPackage = propertyGenerator.initializePackage(newTopComponent)
			val formulas = generatedPropertyPackage.formulas
			formulas += propertyGenerator.createTransitionReachability(
							annotator.getTransitionVariables)
			formulas += propertyGenerator.createTransitionPairReachability(
							annotator.transitionPairAnnotations)
			formulas += propertyGenerator.createInteractionReachability(
							annotator.getInteractions)
			formulas += propertyGenerator.createStateReachability(testedComponentsForStates)
			formulas += propertyGenerator.createOutEventReachability(
							testedPortsForOutEvents)
			
			formulas += propertyGenerator.createDataflowReachability(annotator.getVariableDefs,
							annotator.getVariableUses, annotator.dataflowCoverageCriterion)
			// Saving the property package and serializing the properties has to be done by the caller!
		}
		return new Result(generatedPropertyPackage)
	}
	
	protected def List<SynchronousComponentInstance> getIncludedSynchronousInstances(
			ComponentInstanceReferences references, Component component) {
		if (references === null) {
			return #[]
		}
		return simpleInstanceHandler.getNewSimpleInstances(references.include,
			references.exclude, component)
	}
	
	protected def List<Port> getIncludedSynchronousInstancePorts(
			ComponentInstancePortReferences references, Component component) {
		if (references === null) {
			return #[]
		}
		val includedInstances =
			simpleInstanceHandler.getNewSimpleInstances(references.instances.include, component)
		val excludedInstances =
			simpleInstanceHandler.getNewSimpleInstances(references.instances.exclude, component)
		val includedPorts =
			simpleInstanceHandler.getNewSimpleInstancePorts(references.ports.include, component)
		val excludedPorts =
			simpleInstanceHandler.getNewSimpleInstancePorts(references.ports.exclude, component)
		
		val ports = newArrayList
		if (includedInstances.empty && includedPorts.empty) {
			// If both includes are empty, then we include all the new instances
			val List<SynchronousComponentInstance> newSimpleInstances =
					simpleInstanceHandler.getNewSimpleInstances(component)
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
		var includedStates = simpleInstanceHandler.getNewSimpleInstanceStates(
			stateReferences.include, component).toList
		if (includedStates.empty) {
			includedStates = component.allSimpleInstances.map[it.type]
				.filter(StatechartDefinition).map[it.allStates].flatten.toList
		}
		val excludedStates = simpleInstanceHandler.getNewSimpleInstanceStates(
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
		var includedTransitions = simpleInstanceHandler.getNewSimpleInstanceTransitions(
			transitionReferences.include, component).toList
		if (includedTransitions.empty) {
			includedTransitions = component.allSimpleInstances.map[it.type]
				.filter(StatechartDefinition).map[it.transitions].flatten.toList
		}
		val excludedTransitions = simpleInstanceHandler.getNewSimpleInstanceTransitions(
			transitionReferences.exclude, component)
		includedTransitions -= excludedTransitions
		return includedTransitions
	}
	
	protected def getIncludedSynchronousInstanceVariables(
			ComponentInstanceVariableReferences references, Component component) {
		if (references === null) {
			return #[]
		}
		val includedInstances =	simpleInstanceHandler
				.getNewSimpleInstances(references.instances.include, component)
		val excludedInstances =	simpleInstanceHandler
				.getNewSimpleInstances(references.instances.exclude, component)
		val includedVariables =	simpleInstanceHandler
				.getNewSimpleInstanceVariables(references.variables.include, component)
		val excludedVariables =	simpleInstanceHandler
				.getNewSimpleInstanceVariables(references.variables.exclude, component)
		
		val variables = newArrayList
		if (includedInstances.empty && includedVariables.empty) {
			// If both includes are empty, then we include all the new instances
			val List<SynchronousComponentInstance> newSimpleInstances =
					simpleInstanceHandler.getNewSimpleInstances(component)
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
	
	// Auxiliary data objects
	
	@Data
	static class ComponentInstanceReferences {
		Collection<ComponentInstanceReference> include
		Collection<ComponentInstanceReference> exclude
	}
	
	@Data
	static class ComponentPortReferences {
		Collection<ComponentInstancePortReference> include
		Collection<ComponentInstancePortReference> exclude
	}
	
	@Data
	static class ComponentStateReferences {
		Collection<ComponentInstanceStateConfigurationReference> include
		Collection<ComponentInstanceStateConfigurationReference> exclude
	}
	
	@Data
	static class ComponentVariableReferences {
		Collection<ComponentInstanceVariableReference> include
		Collection<ComponentInstanceVariableReference> exclude
	}
	
	@Data
	static class ComponentTransitionReferences {
		Collection<ComponentInstanceTransitionReference> include
		Collection<ComponentInstanceTransitionReference> exclude
	}
	
	@Data
	static class ComponentInstancePortReferences {
		ComponentInstanceReferences instances
		ComponentPortReferences ports
	}
	
	@Data
	static class ComponentInstancePortStateTransitionReferences extends ComponentInstancePortReferences {
		ComponentStateReferences states
		ComponentTransitionReferences transitions
	}
	
	@Data
	static class ComponentInstanceVariableReferences {
		ComponentInstanceReferences instances
		ComponentVariableReferences variables
	}
	
	// Data
	
	@Data
	static class Result {
		PropertyPackage generatedPropertyPackage
	}
	
}