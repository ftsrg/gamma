package hu.bme.mit.gamma.transformation.util.annotations

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection
import java.util.List
import org.eclipse.xtend.lib.annotations.Data

class ModelAnnotatorPropertyGenerator {
	
	protected final Component newTopComponent
	protected final List<SynchronousComponentInstance> testedComponentsForStates
	protected final List<SynchronousComponentInstance> testedComponentsForTransitions
	protected final List<SynchronousComponentInstance> testedComponentsForTransitionPairs
	protected final List<SynchronousComponentInstance> testedComponentsForOutEvents
	protected final List<Port> testedPortsForInteractions
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	new(Component newTopComponent,
			List<SynchronousComponentInstance> testedComponentsForStates,
			List<SynchronousComponentInstance> testedComponentsForTransitions,
			List<SynchronousComponentInstance> testedComponentsForTransitionPairs,
			List<SynchronousComponentInstance> testedComponentsForOutEvents,
			List<Port> testedPortsForInteractions) {
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
		val Collection<VariableDeclaration> resetableVariables = newArrayList
		if (!testedComponentsForStates.nullOrEmpty || !testedComponentsForTransitions.nullOrEmpty ||
				!testedComponentsForTransitionPairs.nullOrEmpty || !testedComponentsForOutEvents.nullOrEmpty ||
				!testedPortsForInteractions.nullOrEmpty) {
			val statechartAnnotator = new GammaStatechartAnnotator(newPackage,
					testedComponentsForTransitions, testedComponentsForTransitionPairs,
					testedPortsForInteractions)
			statechartAnnotator.annotateModel
			resetableVariables += statechartAnnotator.resetableVariables
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
		return new Result(generatedPropertyPackage, resetableVariables)
	}
	
	@Data
	static class Result {
		PropertyPackage generatedPropertyPackage
		Collection<VariableDeclaration> resetableVariables
	}
	
}