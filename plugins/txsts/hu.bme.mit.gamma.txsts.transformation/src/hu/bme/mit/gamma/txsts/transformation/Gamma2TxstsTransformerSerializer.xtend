/********************************************************************************
 * Copyright (c) 2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/

package hu.bme.mit.gamma.txsts.transformation

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.lowlevel.xsts.transformation.TransitionMerging
import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.transformation.util.ModelSlicerModelAnnotatorPropertyGenerator
import hu.bme.mit.gamma.transformation.util.annotations.AnnotatablePreprocessableElements
import hu.bme.mit.gamma.txsts.transformation.serializer.ModelSerializer
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.transformation.InitialStateSetting
import hu.bme.mit.gamma.xsts.transformation.api.Gamma2XstsTransformerSerializer
import java.io.File
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class Gamma2TxstsTransformerSerializer extends Gamma2XstsTransformerSerializer {
	
	protected final extension ModelSerializer modelSerializer = ModelSerializer.INSTANCE
	
	new(Component component, List<? extends Expression> arguments, String targetFolderUri, String fileName, Integer minSchedulingConstraint, Integer maxSchedulingConstraint, boolean optimize, boolean optimizeArray, boolean optimizeMessageQueues, boolean optimizeEnvironmentalMessageQueues, TransitionMerging transitionMerging, PropertyPackage slicingProperties, AnnotatablePreprocessableElements annotatableElements, PropertyPackage initialState, InitialStateSetting initialStateSetting) {
		super(component, arguments, targetFolderUri, fileName, minSchedulingConstraint, maxSchedulingConstraint, optimize, optimizeArray, optimizeMessageQueues, optimizeEnvironmentalMessageQueues, transitionMerging, slicingProperties, annotatableElements, initialState, initialStateSetting)
	}

	override void execute() {
		val gammaPackage = component.containingPackage
		// Preprocessing
		val newTopComponent = preprocessor.preprocess(gammaPackage,
				arguments, targetFolderUri, fileName, optimize)
		val newGammaPackage = newTopComponent.containingPackage
		// Slicing and Property generation
		val slicerAnnotatorAndPropertyGenerator = new ModelSlicerModelAnnotatorPropertyGenerator(
				newTopComponent,
				slicingProperties,
				annotatableElements,
				targetFolderUri, fileName)
		slicerAnnotatorAndPropertyGenerator.execute
		val gammaToTXSTSTransformer = new GammaToTxstsTransformer(
			minSchedulingConstraint, maxSchedulingConstraint,
			true, true, optimizeArray,
			optimizeMessageQueues, optimizeEnvironmentalMessageQueues,
			transitionMerging, initialState, initialStateSetting)
		// Normal transformation
		val xSts = gammaToTXSTSTransformer.execute(newGammaPackage)
		// EMF
		xSts.normalSave(targetFolderUri, fileName.emfXStsFileName)
		// String
		xSts.serializeAndSaveTxSts
	}
	
	def serializeAndSaveTxSts(XSTS xSts) {
		xSts.serializeAndSaveTxSts(false)
	}
	
	def serializeAndSaveTxSts(XSTS xSts, boolean serializePrimedVariables) {
		val txstsFile = new File(targetFolderUri + File.separator + fileName.xtextXStsFileName)
		val txstsString = xSts.serializeTxsts
		txstsFile.saveString(txstsString)
	}

}