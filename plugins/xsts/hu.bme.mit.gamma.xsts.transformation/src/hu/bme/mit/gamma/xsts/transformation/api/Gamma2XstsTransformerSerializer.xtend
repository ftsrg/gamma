/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation.api

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.lowlevel.xsts.transformation.TransitionMerging
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.transformation.util.ModelSlicerModelAnnotatorPropertyGenerator
import hu.bme.mit.gamma.transformation.util.annotations.AnnotatablePreprocessableElements
import hu.bme.mit.gamma.transformation.util.annotations.DataflowCoverageCriterion
import hu.bme.mit.gamma.transformation.util.annotations.InteractionCoverageCriterion
import hu.bme.mit.gamma.transformation.util.preprocessor.AnalysisModelPreprocessor
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.transformation.GammaToXstsTransformer
import hu.bme.mit.gamma.xsts.transformation.InitialStateSetting
import hu.bme.mit.gamma.xsts.transformation.serializer.ActionSerializer
import java.io.File
import java.util.List

class Gamma2XstsTransformerSerializer {
	
	protected final Component component
	protected final List<Expression> arguments
	protected final String targetFolderUri
	protected final String fileName
	protected final Integer schedulingConstraint
	// Configuration
	protected final boolean optimize
	protected final TransitionMerging transitionMerging
	// Slicing
	protected final PropertyPackage slicingProperties
	// Annotation
	protected final AnnotatablePreprocessableElements annotatableElements
	// Initial state
	protected final PropertyPackage initialState
	protected final InitialStateSetting initialStateSetting
	
	protected final AnalysisModelPreprocessor preprocessor = AnalysisModelPreprocessor.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	protected final extension ActionSerializer actionSerializer = ActionSerializer.INSTANCE
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	
	new(Component component, String targetFolderUri, String fileName) {
		this(component, #[], targetFolderUri, fileName)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName) {
		this(component, arguments, targetFolderUri, fileName, null)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName,
			Integer schedulingConstraint) {
		this(component, arguments, targetFolderUri, fileName, schedulingConstraint,
			true, TransitionMerging.HIERARCHICAL,
			null, new AnnotatablePreprocessableElements(null, null, null, null, null,
				InteractionCoverageCriterion.EVERY_INTERACTION, InteractionCoverageCriterion.EVERY_INTERACTION,
				null, DataflowCoverageCriterion.ALL_USE,
				null, DataflowCoverageCriterion.ALL_USE),
			null, null)
	}
	
	new(Component component, List<Expression> arguments,
			String targetFolderUri, String fileName,
			Integer schedulingConstraint,
			boolean optimize,
			TransitionMerging transitionMerging,
			PropertyPackage slicingProperties,
			AnnotatablePreprocessableElements annotatableElements,
			PropertyPackage initialState, InitialStateSetting initialStateSetting) {
		this.component = component
		this.arguments = arguments
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
		this.schedulingConstraint = schedulingConstraint
		//
		this.optimize = optimize
		this.transitionMerging = transitionMerging
		//
		this.slicingProperties = slicingProperties
		//
		this.annotatableElements = annotatableElements
		//
		this.initialState = initialState
		this.initialStateSetting = initialStateSetting
	}
	
	def void execute() {
		val gammaPackage = StatechartModelDerivedFeatures.getContainingPackage(component)
		// Preprocessing
		val newTopComponent = preprocessor.preprocess(gammaPackage, arguments, targetFolderUri, fileName, optimize)
		val newGammaPackage = StatechartModelDerivedFeatures.getContainingPackage(newTopComponent)
		// Slicing and Property generation
		val slicerAnnotatorAndPropertyGenerator = new ModelSlicerModelAnnotatorPropertyGenerator(
				newTopComponent,
				slicingProperties,
				annotatableElements,
				targetFolderUri, fileName)
		slicerAnnotatorAndPropertyGenerator.execute
		val gammaToXSTSTransformer = new GammaToXstsTransformer(
			schedulingConstraint, true, true,
			transitionMerging, initialState, initialStateSetting)
		// Normal transformation
		val xSts = gammaToXSTSTransformer.execute(newGammaPackage)
		// EMF
		xSts.normalSave(targetFolderUri, fileName.emfXStsFileName)
		// String
		val xStsFile = new File(targetFolderUri + File.separator + fileName.xtextXStsFileName)
		val xStsString = xSts.serializeXsts
		xStsFile.saveString(xStsString)
	}
	
}