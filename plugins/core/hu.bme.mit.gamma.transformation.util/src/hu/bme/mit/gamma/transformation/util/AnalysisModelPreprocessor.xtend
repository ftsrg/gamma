/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.contract.AdaptiveContractAnnotation
import hu.bme.mit.gamma.statechart.contract.StateContractAnnotation
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.io.File
import java.util.Collections
import java.util.List
import java.util.logging.Level
import java.util.logging.Logger
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.util.EcoreUtil

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class AnalysisModelPreprocessor {
	
	protected val logger = Logger.getLogger("GammaLogger")
	protected final extension StatechartUtil statechartUtil = new StatechartUtil
	protected final extension GammaEcoreUtil ecoreUtil = new GammaEcoreUtil
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	
	def preprocess(Package gammaPackage, List<Expression> topComponentArguments, File containingFile) {
		val component = gammaPackage.components.head
		val parameters = component.parameterDeclarations
		checkState(parameters.size == topComponentArguments.size)
		for (var i = 0; i < parameters. size; i++) {
			val parameter = parameters.get(i)
			val argument = topComponentArguments.get(i).clone(true, true)
			logger.log(Level.INFO, "Saving top component argument for " + parameter.name)
			gammaPackage.topComponentArguments += argument
			// Deleting because the parameter variables are not needed
			argument.change(parameter, component)
		}
		return gammaPackage.preprocess(containingFile)
	}
	
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
			logger.log(Level.INFO, "Wrapping statechart " + component)
			_package.components.add(0, component.wrapSynchronousComponent)
		}
		// Saving the package, because VIATRA will NOT return matches if the models are not in the same ResourceSet
		val flattenedModelFileName = "." + fileNameExtensionless + ".gsm"
		val flattenedModelUri = URI.createFileURI(parentFolder + File.separator + flattenedModelFileName)
		normalSave(_package, flattenedModelUri)
		// Reading the model from disk as this is the easy way of reloading the necessary ResourceSet
		_package = flattenedModelUri.normalLoad as Package
		val resource = _package.eResource
		val resourceSet = resource.resourceSet
		// Optimizing - removing unfireable transitions
		val transitionOptimizer = new SystemReducer(resourceSet)
		transitionOptimizer.execute
		// Saving the Package of the unfolded model
		resource.save(Collections.EMPTY_MAP)
		return _package.components.head
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
