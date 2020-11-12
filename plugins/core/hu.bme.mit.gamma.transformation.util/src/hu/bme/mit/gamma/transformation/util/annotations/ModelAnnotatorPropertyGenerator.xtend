package hu.bme.mit.gamma.transformation.util.annotations

import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.composite.ComponentInstancePortReference
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReference
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.transformation.util.SimpleInstanceHandler
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection
import java.util.List
import org.eclipse.xtend.lib.annotations.Data

class ModelAnnotatorPropertyGenerator {
	
	protected final Component newTopComponent
	protected final ComponentInstanceReferences testedComponentsForStates
	protected final ComponentInstanceReferences testedComponentsForTransitions
	protected final ComponentInstanceReferences testedComponentsForTransitionPairs
	protected final ComponentInstanceReferences testedComponentsForOutEvents
	protected final ComponentInstanceAndPortReferences testedPortsForInteractions
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension SimpleInstanceHandler simpleInstanceHandler = SimpleInstanceHandler.INSTANCE
	
	new(Component newTopComponent,
			ComponentInstanceReferences testedComponentsForStates,
			ComponentInstanceReferences testedComponentsForTransitions,
			ComponentInstanceReferences testedComponentsForTransitionPairs,
			ComponentInstanceReferences testedComponentsForOutEvents,
			ComponentInstanceAndPortReferences testedPortsForInteractions) {
		this.newTopComponent = newTopComponent
		this.testedComponentsForStates = testedComponentsForStates
		this.testedComponentsForTransitions = testedComponentsForTransitions
		this.testedComponentsForTransitionPairs = testedComponentsForTransitionPairs
		this.testedComponentsForOutEvents = testedComponentsForOutEvents
		this.testedPortsForInteractions = testedPortsForInteractions
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
		// Transition pair coverage
		val testedComponentsForTransitionPairs = getIncludedSynchronousInstances(
				testedComponentsForTransitionPairs, newTopComponent)
		// Out event coverage
		val testedComponentsForOutEvents = getIncludedSynchronousInstances(
				testedComponentsForOutEvents, newTopComponent)
		// Interaction coverage
		val testedPortsForInteractions = getIncludedSynchronousInstancePorts(
				testedPortsForInteractions, newTopComponent)
		
		if (!testedComponentsForStates.nullOrEmpty || !testedComponentsForTransitions.nullOrEmpty ||
				!testedComponentsForTransitionPairs.nullOrEmpty || !testedComponentsForOutEvents.nullOrEmpty ||
				!testedPortsForInteractions.nullOrEmpty) {
			val statechartAnnotator = new GammaStatechartAnnotator(newPackage,
					testedComponentsForTransitions, testedComponentsForTransitionPairs,
					testedPortsForInteractions)
			statechartAnnotator.annotateModel
			newPackage.save // It must be saved so the property package can be serialized
			
			// We are after model unfolding, so the argument is true
			val propertyGenerator = new PropertyGenerator(true)
			generatedPropertyPackage = propertyGenerator.initializePackage(newTopComponent)
			val formulas = generatedPropertyPackage.formulas
			formulas += propertyGenerator.createTransitionReachability(
							statechartAnnotator.getTransitionVariables)
			formulas += propertyGenerator.createTransitionPairReachability(
							statechartAnnotator.transitionPairAnnotations)
			formulas += propertyGenerator.createInteractionReachability(statechartAnnotator.getInteractions)
			formulas += propertyGenerator.createStateReachability(testedComponentsForStates)
			formulas += propertyGenerator.createOutEventReachability(newTopComponent,
							testedComponentsForOutEvents)
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
			ComponentInstanceAndPortReferences references, Component component) {
		if (references === null) {
			return #[]
		}
		val includedInstances =
			simpleInstanceHandler.getNewSimpleInstances(references.getInstance.include, component)
		val excludedInstances =
			simpleInstanceHandler.getNewSimpleInstances(references.getInstance.exclude, component)
		val includedPorts =
			simpleInstanceHandler.getNewSimpleInstancePorts(references.getPort.include, component)
		val excludedPorts =
			simpleInstanceHandler.getNewSimpleInstancePorts(references.getPort.exclude, component)
		
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
		return ports;
	}
	
	protected def List<Port> getPorts(List<SynchronousComponentInstance> instances) {
		val ports = newArrayList
		for (instance : instances) {
			val type = instance.getType
			ports += type.ports
		}
		return ports
	}
	
	@Data
	static class ComponentInstanceReferences {
		Collection<ComponentInstanceReference> include
		Collection<ComponentInstanceReference> exclude
	}
	
	@Data
	static class ComponentInstancePortReferences {
		Collection<ComponentInstancePortReference> include
		Collection<ComponentInstancePortReference> exclude
	}
	
	@Data
	static class ComponentInstanceAndPortReferences {
		ComponentInstanceReferences instance
		ComponentInstancePortReferences port
	}
	
	@Data
	static class Result {
		PropertyPackage generatedPropertyPackage
	}
	
}