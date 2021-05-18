package hu.bme.mit.gamma.uppaal.composition.transformation.api.util

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.transformation.util.SimpleInstanceHandler
import hu.bme.mit.gamma.uppaal.composition.transformation.CompositeToUppaalTransformer
import hu.bme.mit.gamma.uppaal.composition.transformation.TestQueryGenerationHandler
import hu.bme.mit.gamma.uppaal.serializer.UppaalModelSerializer
import hu.bme.mit.gamma.uppaal.transformation.ModelValidator
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.io.File
import java.util.Collection
import java.util.Collections
import java.util.List
import java.util.logging.Level
import org.eclipse.xtend.lib.annotations.Data

class DefaultCompositionToUppaalTransformer {
	
	TestQueryGenerationHandler testQueryGenerationHandler
	
    protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	def transformComponent(Package gammaPackage, String targetFolderUri, String fileName) {
		return transformComponent(gammaPackage, #[], targetFolderUri, fileName,
			Collections.singleton(ElementCoverage.STATE_COVERAGE))
	}
	
	def transformComponent(Package gammaPackage, String targetFolderUri, String fileName,
			Collection<ElementCoverage> coverage) {
		return transformComponent(gammaPackage, #[], targetFolderUri, fileName, coverage)
	}
	
	def transformComponent(Package gammaPackage, List<Expression> topComponentArguments,
			String targetFolderUri, String fileName, Collection<ElementCoverage> coverage) {
		val fileNameExtensionless = fileName.extensionlessName
		val modelPreprocessor = new UppaalModelPreprocessor
		val topComponent = modelPreprocessor.preprocess(gammaPackage, topComponentArguments,
			targetFolderUri, fileName, true)

		// Checking the model whether it contains forbidden elements
		val validator = new ModelValidator(topComponent)
		validator.checkModel
		testQueryGenerationHandler = new TestQueryGenerationHandler(
			topComponent.getCoverableInstances(ElementCoverage.STATE_COVERAGE, coverage),
			topComponent.getCoverableInstances(ElementCoverage.TRANSITION_COVERAGE, coverage),
			topComponent.getCoverableInstances(ElementCoverage.OUT_EVENT_COVERAGE, coverage),
			topComponent.getCoverableInstances(ElementCoverage.INTERACTION_COVERAGE, coverage))
		val transformer = new CompositeToUppaalTransformer(topComponent)
		val resultModels = transformer.execute
		val nta = resultModels.key
		var trace = resultModels.value
		// Saving the generated models
		val resourceSet = topComponent.eResource.resourceSet
		resourceSet.normalSave(nta, targetFolderUri, fileNameExtensionless.emfUppaalFileName)
		resourceSet.normalSave(trace, targetFolderUri, fileNameExtensionless.gammaUppaalTraceabilityFileName)
		// Serializing the NTA model to XML
		val xmlFileName = fileNameExtensionless.xmlUppaalFileName
		UppaalModelSerializer.saveToXML(nta, targetFolderUri, xmlFileName)
		// Deleting old q file
		val queryFileName = fileNameExtensionless.uppaalQueryFileName
		new File(targetFolderUri + File.separator + queryFileName).delete
		UppaalModelSerializer.saveString(targetFolderUri, queryFileName, testQueryGenerationHandler.getQueries(coverage))
		transformer.dispose
		modelPreprocessor.logger.log(Level.INFO, "The composite system transformation has been finished.")
		return new Result(
			topComponent,
			trace,
			new File(targetFolderUri + File.separator + xmlFileName),
			new File(targetFolderUri + File.separator + queryFileName)
		)
	}
	
	def getTestQueryGenerationHandler() {
		return testQueryGenerationHandler
	}
	
	private def getCoverableInstances(Component component, ElementCoverage expected, Collection<ElementCoverage> received) {
		val instanceHandler = SimpleInstanceHandler.INSTANCE
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
	
	@Data
	static class Result {
		Component topComponent
		G2UTrace trace
		File modelFile
		File queryFile
	}
	
}