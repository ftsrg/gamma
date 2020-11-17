package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.transformation.util.annotations.InteractionCoverageCriterion
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator.ComponentInstancePortReferences
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator.ComponentInstancePortStateTransitionReferences
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator.ComponentInstanceReferences
import hu.bme.mit.gamma.util.GammaEcoreUtil

class ModelSlicerModelAnnotatorPropertyGenerator {
	
	protected final Component newTopComponent
	protected final String targetFolderUri
	protected final String fileName
	// Slicing
	protected final PropertyPackage propertyPackage
	// Annotation
	protected final ComponentInstanceReferences testedComponentsForStates
	protected final ComponentInstanceReferences testedComponentsForTransitions
	protected final ComponentInstanceReferences testedComponentsForTransitionPairs
	protected final ComponentInstancePortReferences testedComponentsForOutEvents
	protected final ComponentInstancePortStateTransitionReferences testedInteractions
	protected final InteractionCoverageCriterion senderCoverageCriterion
	protected final InteractionCoverageCriterion receiverCoverageCriterion
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	new(Component newTopComponent, PropertyPackage propertyPackage,
			ComponentInstanceReferences testedComponentsForStates,
			ComponentInstanceReferences testedComponentsForTransitions,
			ComponentInstanceReferences testedComponentsForTransitionPairs,
			ComponentInstancePortReferences testedComponentsForOutEvents,
			ComponentInstancePortStateTransitionReferences testedInteractions,
			InteractionCoverageCriterion senderCoverageCriterion,
			InteractionCoverageCriterion receiverCoverageCriterion,
			String targetFolderUri, String fileName) {
		this.newTopComponent = newTopComponent
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
		//
		this.propertyPackage = propertyPackage
		//
		this.testedComponentsForStates = testedComponentsForStates
		this.testedComponentsForTransitions = testedComponentsForTransitions
		this.testedComponentsForTransitionPairs = testedComponentsForTransitionPairs
		this.testedComponentsForOutEvents = testedComponentsForOutEvents
		this.testedInteractions = testedInteractions
		this.senderCoverageCriterion = senderCoverageCriterion
		this.receiverCoverageCriterion = receiverCoverageCriterion
	}
	
	def execute() {
		// Slicing
		val slicer = new PropertyUnfolderModelSlicer(newTopComponent, propertyPackage, false)
		slicer.execute
		// Annotation
		val annotatorAndPropertyGenerator =
				new ModelAnnotatorPropertyGenerator(newTopComponent,
					testedComponentsForStates, testedComponentsForTransitions,
					testedComponentsForTransitionPairs, testedComponentsForOutEvents,
					testedInteractions, senderCoverageCriterion, receiverCoverageCriterion);
		val result = annotatorAndPropertyGenerator.execute
		val propertyPackage = result.generatedPropertyPackage
		if (propertyPackage !== null) {
			ecoreUtil.normalSave(propertyPackage, targetFolderUri, fileName.hiddenEmfPropertyFileName)
		}
		return result
	}
	
}