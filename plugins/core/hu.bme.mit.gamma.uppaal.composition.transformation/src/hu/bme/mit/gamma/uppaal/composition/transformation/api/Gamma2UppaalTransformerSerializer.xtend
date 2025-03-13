package hu.bme.mit.gamma.uppaal.composition.transformation.api

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.transformation.util.ModelSlicerModelAnnotatorPropertyGenerator
import hu.bme.mit.gamma.transformation.util.annotations.AnnotatablePreprocessableElements
import hu.bme.mit.gamma.transformation.util.annotations.DataflowCoverageCriterion
import hu.bme.mit.gamma.transformation.util.annotations.InteractionCoverageCriterion
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
	// Slicing
	protected final boolean optimize
	protected final PropertyPackage propertyPackage
	// Annotation
	protected final AnnotatablePreprocessableElements annotatableElements
		
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
			boolean optimize) {
		this(component, arguments, targetFolderUri, fileName, constraint,
			scheduler, optimize, null,
			new AnnotatablePreprocessableElements(
				null, null, null, null, null, null, null, null, null,
				InteractionCoverageCriterion.EVERY_INTERACTION, InteractionCoverageCriterion.EVERY_INTERACTION,
				null, DataflowCoverageCriterion.ALL_USE,
				null, DataflowCoverageCriterion.ALL_USE)
			)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName,
			Constraint constraint, Scheduler scheduler,
			boolean optimize, PropertyPackage propertyPackage,
			AnnotatablePreprocessableElements annotatableElements) {
		this.component = component
		this.arguments = arguments
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
		this.constraint = constraint
		this.scheduler = scheduler
		//
		this.optimize = optimize
		this.propertyPackage = propertyPackage
		//
		this.annotatableElements = annotatableElements
	}
	
	def void execute() {
		val gammaPackage = StatechartModelDerivedFeatures.getContainingPackage(component)
		
		val newTopComponent = preprocessor.preprocess(gammaPackage, arguments,
			targetFolderUri, fileName, optimize)
		// Top component arguments are now be contained by the Package (preprocess)
		// Checking the model whether it contains forbidden elements
		val validator = new ModelValidator(newTopComponent, false)
		validator.checkModel
		// Slicing
		val slicerAnnotatorAndPropertyGenerator = new ModelSlicerModelAnnotatorPropertyGenerator(
				newTopComponent,
				propertyPackage,
				annotatableElements,
				targetFolderUri, fileName);
		slicerAnnotatorAndPropertyGenerator.execute
		// Normal transformation
		val transformer = new CompositeToUppaalTransformer(
			newTopComponent, scheduler, constraint) 
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