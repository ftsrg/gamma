package hu.bme.mit.gamma.uppaal.composition.transformation.api

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.transformation.util.ModelSlicerModelAnnotatorPropertyGenerator
import hu.bme.mit.gamma.transformation.util.annotations.DataflowCoverageCriterion
import hu.bme.mit.gamma.transformation.util.annotations.InteractionCoverageCriterion
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator.ComponentInstancePortReferences
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator.ComponentInstancePortStateTransitionReferences
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator.ComponentInstanceReferences
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator.ComponentInstanceVariableReferences
import hu.bme.mit.gamma.uppaal.composition.transformation.AsynchronousSchedulerTemplateCreator.Scheduler
import hu.bme.mit.gamma.uppaal.composition.transformation.CompositeToUppaalTransformer
import hu.bme.mit.gamma.uppaal.composition.transformation.Constraint
import hu.bme.mit.gamma.uppaal.composition.transformation.api.util.UppaalModelPreprocessor
import hu.bme.mit.gamma.uppaal.serializer.UppaalModelSerializer
import hu.bme.mit.gamma.uppaal.transformation.ModelValidator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List

class Gamma2UppaalTransformerSerializer {
	
	protected final Component component
	protected final List<Expression> arguments
	protected final String targetFolderUri
	protected final String fileName
	protected final Constraint constraint
	protected final Scheduler scheduler
	protected final boolean isMinimalElementSet
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
	protected final ComponentInstanceVariableReferences dataflowTestedVariables
	protected final DataflowCoverageCriterion dataflowCoverageCriterion
		
	protected final UppaalModelPreprocessor preprocessor = UppaalModelPreprocessor.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	new(Component component, String targetFolderUri, String fileName) {
		this(component, #[], targetFolderUri, fileName)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName) {
		this(component, arguments, targetFolderUri, fileName, null, null, false)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName,
			Constraint constraint, Scheduler scheduler,
			boolean isMinimalElementSet) {
		this(component, arguments, targetFolderUri, fileName, constraint,
			scheduler, isMinimalElementSet, null, null, null, null, null, null,
			InteractionCoverageCriterion.EVERY_INTERACTION, InteractionCoverageCriterion.EVERY_INTERACTION,
			null, DataflowCoverageCriterion.ALL_USE)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName,
			Constraint constraint, Scheduler scheduler,
			boolean isMinimalElementSet,
			PropertyPackage propertyPackage,
			ComponentInstanceReferences testedComponentsForStates,
			ComponentInstanceReferences testedComponentsForTransitions,
			ComponentInstanceReferences testedComponentsForTransitionPairs,
			ComponentInstancePortReferences testedComponentsForOutEvents,
			ComponentInstancePortStateTransitionReferences testedInteractions,
			InteractionCoverageCriterion senderCoverageCriterion,
			InteractionCoverageCriterion receiverCoverageCriterion,
			ComponentInstanceVariableReferences dataflowTestedVariables,
			DataflowCoverageCriterion dataflowCoverageCriterion) {
		this.component = component
		this.arguments = arguments
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
		this.constraint = constraint
		this.scheduler = scheduler
		this.isMinimalElementSet = isMinimalElementSet
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
		this.dataflowTestedVariables = dataflowTestedVariables
		this.dataflowCoverageCriterion = dataflowCoverageCriterion
	}
	
	def void execute() {
		val gammaPackage = StatechartModelDerivedFeatures.getContainingPackage(component)
		
		val newTopComponent = preprocessor.preprocess(gammaPackage, arguments,
			targetFolderUri, fileName)
		// Top component arguments are now be contained by the Package (preprocess)
		// Checking the model whether it contains forbidden elements
		val validator = new ModelValidator(newTopComponent, false)
		validator.checkModel
		// Slicing
		val slicerAnnotatorAndPropertyGenerator = new ModelSlicerModelAnnotatorPropertyGenerator(
				newTopComponent,
				propertyPackage,
				testedComponentsForStates, testedComponentsForTransitions,
				testedComponentsForTransitionPairs, testedComponentsForOutEvents,
				testedInteractions, senderCoverageCriterion, receiverCoverageCriterion,
				dataflowTestedVariables, dataflowCoverageCriterion,
				targetFolderUri, fileName);
		slicerAnnotatorAndPropertyGenerator.execute
		// Normal transformation
		val transformer = new CompositeToUppaalTransformer(
			newTopComponent,
			scheduler,
			constraint,
			isMinimalElementSet) 
		val resultModels = transformer.execute
		val nta = resultModels.getKey
		val trace = resultModels.value
		// Saving the generated models
		nta.normalSave(targetFolderUri, fileName.emfUppaalFileName)
		trace.normalSave(targetFolderUri, fileName.gammaUppaalTraceabilityFileName)
		// Serializing the NTA model to XML
		UppaalModelSerializer.saveToXML(nta, targetFolderUri, fileName.getXmlUppaalFileName)
	}
	
}