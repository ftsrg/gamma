package hu.bme.mit.gamma.uppaal.composition.transformation.api

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator
import hu.bme.mit.gamma.uppaal.composition.transformation.AsynchronousSchedulerTemplateCreator.Scheduler
import hu.bme.mit.gamma.uppaal.composition.transformation.CompositeToUppaalTransformer
import hu.bme.mit.gamma.uppaal.composition.transformation.Constraint
import hu.bme.mit.gamma.uppaal.composition.transformation.api.util.UppaalModelPreprocessor
import hu.bme.mit.gamma.uppaal.serializer.UppaalModelSerializer
import hu.bme.mit.gamma.uppaal.transformation.ModelValidator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.io.File
import java.util.List
import java.util.logging.Level
import java.util.logging.Logger
import hu.bme.mit.gamma.transformation.util.GammaFileNamer

class Gamma2UppaalTransformer {
		
	protected final UppaalModelPreprocessor preprocessor = UppaalModelPreprocessor.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	protected final extension Logger logger = Logger.getLogger("GammaLogger")
	
	def void execute(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName,
			Constraint constraint, Scheduler scheduler,
			PropertyPackage propertyPackage,
			List<SynchronousComponentInstance> testedComponentsForStates,
			List<SynchronousComponentInstance> testedComponentsForTransitions,
			List<SynchronousComponentInstance> testedComponentsForTransitionPairs,
			List<SynchronousComponentInstance> testedComponentsForOutEvents,
			List<Port> testedPortsForInteractions,
			boolean isMinimalElementSet) {
		val gammaPackage = StatechartModelDerivedFeatures.getContainingPackage(component)
		val newTopComponent = preprocessor.preprocess(gammaPackage, arguments,
			new File(targetFolderUri + File.separator + fileName))
		// Top component arguments are now be contained by the Package (preprocess)
		// Checking the model whether it contains forbidden elements
		val validator = new ModelValidator(newTopComponent, false)
		validator.checkModel
		// Annotate model for test generation
		val annotator = new ModelAnnotatorPropertyGenerator(newTopComponent,
			testedComponentsForStates, testedComponentsForTransitions, testedComponentsForTransitionPairs,
			testedComponentsForOutEvents, testedPortsForInteractions)
		val annotationResult = annotator.execute
		val resetableVariables = annotationResult.resetableVariables
		val generatedPropertyPackage = annotationResult.generatedPropertyPackage
		
		// Normal transformation
		logger.log(Level.INFO, "Resource set content for flattened Gamma to UPPAAL transformation: " +
				newTopComponent.eResource.resourceSet)
		val transformer = new CompositeToUppaalTransformer(
			newTopComponent,
			resetableVariables,
			scheduler,
			constraint,
			isMinimalElementSet) 
		val resultModels = transformer.execute
		val nta = resultModels.getKey
		val trace = resultModels.value
		// Saving the generated models
		ecoreUtil.normalSave(nta, targetFolderUri, fileName.emfUppaalFileName)
		ecoreUtil.normalSave(trace, targetFolderUri, fileName.gammaUppaalTraceabilityFileName)
		// Serializing the NTA model to XML
		UppaalModelSerializer.saveToXML(nta, targetFolderUri, fileName.uppaalQueryFileName)
		logger.log(Level.INFO, "The UPPAAL transformation has been finished.")
	}
	
}