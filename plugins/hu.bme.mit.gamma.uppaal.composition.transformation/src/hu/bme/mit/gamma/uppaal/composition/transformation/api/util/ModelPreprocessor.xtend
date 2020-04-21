package hu.bme.mit.gamma.uppaal.composition.transformation.api.util

import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.contract.AdaptiveContractAnnotation
import hu.bme.mit.gamma.statechart.model.contract.StateContractAnnotation
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.uppaal.composition.transformation.ModelUnfolder
import hu.bme.mit.gamma.uppaal.composition.transformation.SystemReducer
import hu.bme.mit.gamma.uppaal.composition.transformation.UnhandledTransitionTransformer
import java.io.File
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl
import org.eclipse.emf.ecore.util.EcoreUtil

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class ModelPreprocessor {
	
	protected val logger = Logger.getLogger("GammaLogger")
	protected extension StatechartUtil statechartUtil = new StatechartUtil
	
	def preprocess(Package gammaPackage, File containingFile) {
		val parentFolder = containingFile.parent
		val fileName = containingFile.name
		val fileNameExtensionless = fileName.substring(0, fileName.lastIndexOf("."))
		// Unfolding the given system
		val trace = new ModelUnfolder().unfold(gammaPackage)
		var _package = trace.package
		// If it is a single statechart, we wrap it
		val component = trace.topComponent
		if (component instanceof StatechartDefinition) {
			_package.components.add(0, component.wrapSynchronousComponent)
		}
		// Saving the package, because VIATRA will NOT return matches if the models are not in the same ResourceSet
		val flattenedModelFileName = "." + fileNameExtensionless + ".gsm"
		val flattenedModelUri = URI.createFileURI(parentFolder + File.separator + flattenedModelFileName)
		normalSave(_package, flattenedModelUri)
		// Reading the model from disk as this is the only way it works
		val optimizationResourceSet = new ResourceSetImpl
		val resourceTransitionOptimization = optimizationResourceSet.getResource(flattenedModelUri, true)
		logger.log(Level.INFO, "Resource set for transition optimization in Gamma to UPPAAL transformation created: " + 
				optimizationResourceSet)
		// Optimizing - removing unfireable transitions
		val transitionOptimizer = new SystemReducer(optimizationResourceSet)
		transitionOptimizer.execute
		_package = resourceTransitionOptimization.contents.head as Package
		// Transforming unhandled transitions to two transitions connected by a choice
		val unhandledTransitionTransformer = new UnhandledTransitionTransformer
		_package.components
			.filter(StatechartDefinition)
			.forEach[unhandledTransitionTransformer.execute(it as StatechartDefinition)]
		// Saving the Package of the unfolded model
		normalSave(_package, flattenedModelUri)
		// Reading the model from disk as this is the only way it works
		val finalResourceSet = new ResourceSetImpl
		val resource = finalResourceSet.getResource(flattenedModelUri, true)
		logger.log(Level.INFO, "Resource set for flattened Gamma to UPPAAL transformation created: " + finalResourceSet);
		return resource.contents.filter(Package).head
			.components.head
	}
	
	def removeAnnotations(Component component) {
		// Removing annotations only from the models; they are saved on disk
		val newPackage = component.containingPackage
		EcoreUtil.getAllContents(newPackage, true)
			.filter(AdaptiveContractAnnotation).forEach[EcoreUtil.remove(it)]
		EcoreUtil.getAllContents(newPackage, true)
			.filter(StateContractAnnotation).forEach[EcoreUtil.remove(it)]
	}
	
	def getLogger() {
		return logger
	}
}