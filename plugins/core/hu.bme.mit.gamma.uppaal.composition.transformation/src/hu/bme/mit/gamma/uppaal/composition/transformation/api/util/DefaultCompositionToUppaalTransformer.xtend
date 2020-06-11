package hu.bme.mit.gamma.uppaal.composition.transformation.api.util

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.uppaal.composition.transformation.CompositeToUppaalTransformer
import hu.bme.mit.gamma.uppaal.composition.transformation.SimpleInstanceHandler
import hu.bme.mit.gamma.uppaal.composition.transformation.TestQueryGenerationHandler
import hu.bme.mit.gamma.uppaal.serializer.UppaalModelSerializer
import hu.bme.mit.gamma.uppaal.transformation.ModelValidator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.io.File
import java.util.AbstractMap.SimpleEntry
import java.util.Collection
import java.util.Collections
import java.util.List
import java.util.logging.Level

class DefaultCompositionToUppaalTransformer {
	
    protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	TestQueryGenerationHandler testQueryGenerationHandler
	
	def transformComponent(Package gammaPackage, File containingFile) {
		return transformComponent(gammaPackage, #[], containingFile,
			Collections.singleton(ElementCoverage.STATE_COVERAGE))
	}
	
	def transformComponent(Package gammaPackage, File containingFile,
			Collection<ElementCoverage> coverage) {
		return transformComponent(gammaPackage, #[], containingFile, coverage)
	}
	
	def transformComponent(Package gammaPackage, List<Expression> topComponentArguments,
			File containingFile, Collection<ElementCoverage> coverage) {
		val parentFolder = containingFile.parent
		val fileName = containingFile.name
		val fileNameExtensionless = fileName.substring(0, fileName.lastIndexOf("."))
		val modelPreprocessor = new UppaalModelPreprocessor
		val topComponent = modelPreprocessor.preprocess(gammaPackage, containingFile)
		// Checking the model whether it contains forbidden elements
		val validator = new ModelValidator(topComponent)
		validator.checkModel
		testQueryGenerationHandler = new TestQueryGenerationHandler(
			topComponent.getCoverableInstances(ElementCoverage.STATE_COVERAGE, coverage),
			topComponent.getCoverableInstances(ElementCoverage.TRANSITION_COVERAGE, coverage),
			topComponent.getCoverableInstances(ElementCoverage.OUT_EVENT_COVERAGE, coverage),
			topComponent.getCoverableInstances(ElementCoverage.INTERACTION_COVERAGE, coverage))
		val transformer = new CompositeToUppaalTransformer(topComponent, topComponentArguments, testQueryGenerationHandler)
		val resultModels = transformer.execute
		val nta = resultModels.key
		var trace = resultModels.value
		// Saving the generated models
		val resourceSet = topComponent.eResource.resourceSet
		resourceSet.normalSave(nta, parentFolder, "." + fileNameExtensionless + ".uppaal")
		resourceSet.normalSave(trace, parentFolder, "." + fileNameExtensionless + ".g2u")
		// Serializing the NTA model to XML
		val xmlFileName = fileNameExtensionless + ".xml"
		UppaalModelSerializer.saveToXML(nta, parentFolder, xmlFileName)
		// Deleting old q file
		val queryFileName = fileNameExtensionless + ".q"
		new File(parentFolder + File.separator + queryFileName).delete
		UppaalModelSerializer.saveString(parentFolder, queryFileName,
				testQueryGenerationHandler.getQueries(coverage))
		transformer.dispose
		modelPreprocessor.logger.log(Level.INFO, "The composite system transformation has been finished.")
		return new SimpleEntry(trace,
			new SimpleEntry(
				new File(parentFolder + File.separator + xmlFileName),
				new File(parentFolder + File.separator + queryFileName)
			)
		)
	}
	
	def getTestQueryGenerationHandler() {
		return testQueryGenerationHandler
	}
	
	private def getCoverableInstances(Component component, ElementCoverage expected, Collection<ElementCoverage> received) {
		val instanceHandler = new SimpleInstanceHandler
		val components = newHashSet
		if (received.contains(expected)) {
			components += instanceHandler.getNewSimpleInstances(component)
		}
		return components
	}
	
	private def getQueries(TestQueryGenerationHandler testQueryGenerationHandler, Collection<ElementCoverage> received) {
		val builder = new StringBuilder
		if (received.contains(ElementCoverage.STATE_COVERAGE)) {
			builder.append(testQueryGenerationHandler.generateStateCoverageExpressions)
		}
		if (received.contains(ElementCoverage.TRANSITION_COVERAGE)) {
			builder.append(testQueryGenerationHandler.generateTransitionCoverageExpressions)
		}
		if (received.contains(ElementCoverage.OUT_EVENT_COVERAGE)) {
			builder.append(testQueryGenerationHandler.generateOutEventCoverageExpressions)
		}
		if (received.contains(ElementCoverage.INTERACTION_COVERAGE)) {
			builder.append(testQueryGenerationHandler.generateInteractionCoverageExpressions)
		}
		return builder.toString
	}
	
}