/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util.preprocessor

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.statechart.composite.AsynchronousAdapter
import hu.bme.mit.gamma.statechart.contract.AdaptiveContractAnnotation
import hu.bme.mit.gamma.statechart.contract.StateContractAnnotation
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.SynchronousStatechartDefinition
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.transformation.util.reducer.SystemReducer
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.io.File
import java.util.List
import java.util.logging.Logger
import org.eclipse.emf.common.util.URI

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class AnalysisModelPreprocessor {
	// Singleton
	public static final AnalysisModelPreprocessor INSTANCE =  new AnalysisModelPreprocessor
	protected new() {}
	//
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	protected final extension InterfaceModelFactory interfaceModelFactory = InterfaceModelFactory.eINSTANCE
	//
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	def preprocess(Package gammaPackage, String targetFolderUri, String fileName, boolean optimize) {
		return gammaPackage.preprocess(#[], targetFolderUri, fileName, optimize)
	}
	
	def preprocess(Package gammaPackage, List<? extends Expression> topComponentArguments,
			String targetFolderUri, String fileName, boolean optimize) {
		val fileNameExtensionless = fileName.extensionlessName
		
		// Unfolding the given system
		val modelUnfolder = new ModelUnfolder(gammaPackage)
		val trace = modelUnfolder.unfold
		var _package = trace.package
		val component = trace.topComponent
		checkState(!component.asynchronousStatechart) // ModelUnfolder handles them
		
		val name = component.name
		// If it is an atomic component, we wrap it
		if (component instanceof SynchronousStatechartDefinition) {
			logger.info("Wrapping synchronous statechart " + name)
			val wrapper = component.wrapSynchronousComponent
			wrapper.addWrapperComponentAnnotation // Adding wrapper annotation
			_package.components.add(0, wrapper)
		}
		else if (component instanceof AsynchronousAdapter) {
			if (!component.simplifiable) {
				// Queues have to be introduced 
				logger.info("Wrapping adapter " + name)
				val wrapper = component.wrapAsynchronousComponent
				wrapper.addWrapperComponentAnnotation // Adding wrapper annotation
				_package.components.add(0, wrapper)
				 // Renaming manually due to Scheduled-Adapter extension
				modelUnfolder.renameInstancesAccordingToWrapping(wrapper, component)
			}
			else {
				logger.info("Adapter " + name + " does not have to be wrapped")
			}
		}
		
		// Transforming parameters if there are any - after wrapping!
		val firstComponent = _package.firstComponent
		firstComponent.transformTopComponentParameters(topComponentArguments)
		
		// Saving the package as VIATRA will NOT return matches if the models are not in the same ResourceSet
		val flattenedModelUri = URI.createFileURI(targetFolderUri +
				File.separator + fileNameExtensionless.unfoldedPackageFileName)
		_package.normalSave(flattenedModelUri)
		
		// Reading the model from disk as this is the easy way of reloading the necessary ResourceSet
		_package = flattenedModelUri.normalLoad as Package
		val resource = _package.eResource
		val resourceSet = resource.resourceSet
		// Optimizing - removing unfireable transitions
		if (optimize) {
			val transitionOptimizer = new SystemReducer(resourceSet)
			transitionOptimizer.execute
		}
		
		// Saving the Package of the unfolded model
		resource.save
		
		return _package.components.head
	}
	
	protected def transformTopComponentParameters(Component component, List<? extends Expression> arguments) {
		if (arguments.nullOrEmpty) {
			return
		}
		val _package = component.containingPackage
		val parameters = component.parameterDeclarations
		logger.info("Argument size: " + arguments.size + " - parameter size: " + parameters.size)
		checkState(arguments.size <= parameters.size)
		// For code generation, not all (actually zero) parameters have to be bound
		_package.annotations += createTopComponentArgumentsAnnotation => [
			it.arguments += arguments.map[it.clone]
		]
		
		_package.constantDeclarations += parameters.extractParameters(
			parameters.map['''__«it.name»__'''], arguments)
	}
	
	def removeAnnotations(Component component) {
		// Removing annotations only from the models; they remain saved on disk
		val newPackage = component.containingPackage
		newPackage.getAllContentsOfType(AdaptiveContractAnnotation).forEach[it.remove]
		newPackage.getAllContentsOfType(StateContractAnnotation).forEach[it.remove]
	}
	
	def getLogger() {
		return logger
	}
}
