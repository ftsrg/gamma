package hu.bme.mit.gamma.uppaal.composition.transformation.api.util

import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.uppaal.composition.transformation.CompositeToUppaalTransformer
import hu.bme.mit.gamma.uppaal.composition.transformation.SimpleInstanceHandler
import hu.bme.mit.gamma.uppaal.composition.transformation.TestQueryGenerationHandler
import hu.bme.mit.gamma.uppaal.serializer.UppaalModelSerializer
import hu.bme.mit.gamma.uppaal.transformation.ModelValidator
import java.io.File
import java.util.AbstractMap.SimpleEntry
import java.util.Collections
import java.util.logging.Level

class DefaultCompositionToUppaalTransformer {
	
	def transformComponent(Package gammaPackage, File containingFile) {
		val parentFolder = containingFile.parent
		val fileName = containingFile.name
		val fileNameExtensionless = fileName.substring(0, fileName.lastIndexOf("."))
		val modelPreprocessor = new ModelPreprocessor
		val topComponent = modelPreprocessor.preprocess(gammaPackage, containingFile)
		// Checking the model whether it contains forbidden elements
		val validator = new ModelValidator(topComponent);
		validator.checkModel
		val simpleInstanceHandler = new SimpleInstanceHandler
		val testGenerationHandler = new TestQueryGenerationHandler(simpleInstanceHandler.getNewSimpleInstances(topComponent),
			Collections.emptySet(), Collections.emptySet(), Collections.emptySet())
		val transformer = new CompositeToUppaalTransformer(topComponent, testGenerationHandler)
		val resultModels = transformer.execute
		val nta = resultModels.key
		val trace = resultModels.value
		// Saving the generated models
		modelPreprocessor.normalSave(nta, parentFolder, "." + fileNameExtensionless + ".uppaal")
		modelPreprocessor.normalSave(trace, parentFolder, "." + fileNameExtensionless + ".g2u")
		// Serializing the NTA model to XML
		val xmlFileName = fileNameExtensionless + ".xml"
		UppaalModelSerializer.saveToXML(nta, parentFolder, xmlFileName)
		// Deleting old q file
		val queryFileName = fileNameExtensionless + ".q"
		new File(parentFolder + File.separator + queryFileName).delete
		UppaalModelSerializer.saveString(parentFolder, queryFileName,
				testGenerationHandler.generateStateCoverageExpressions)
		transformer.dispose
		modelPreprocessor.logger.log(Level.INFO, "The composite system transformation has been finished.")
		
		// Maybe the trace should be reloaded again before returning it?
		return new SimpleEntry(trace,
			new SimpleEntry(
				new File(parentFolder + File.separator + xmlFileName),
				new File(parentFolder + File.separator + queryFileName)
			)
		)
	}
	
}