/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.transformation.util

import hu.bme.mit.gamma.property.model.PropertyPackage
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.transformation.util.annotations.AnnotatablePreprocessableElements
import hu.bme.mit.gamma.transformation.util.annotations.ModelAnnotatorPropertyGenerator
import hu.bme.mit.gamma.util.GammaEcoreUtil

class ModelSlicerModelAnnotatorPropertyGenerator {
	
	protected final Component newTopComponent
	protected final String targetFolderUri
	protected final String fileName
	// Slicing
	protected final PropertyPackage propertyPackage
	// Annotation
	protected final AnnotatablePreprocessableElements annotatableElements
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	new(Component newTopComponent, PropertyPackage propertyPackage,
			AnnotatablePreprocessableElements annotatableElements,
			String targetFolderUri, String fileName) {
		this.newTopComponent = newTopComponent
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
		//
		this.propertyPackage = propertyPackage
		this.annotatableElements = annotatableElements
	}
	
	def execute() {
		// Slicing
		val slicer = new PropertyUnfolderModelSlicer(newTopComponent, propertyPackage, false)
		slicer.execute
		// Annotation
		val annotatorAndPropertyGenerator =
				new ModelAnnotatorPropertyGenerator(newTopComponent, annotatableElements)
		val result = annotatorAndPropertyGenerator.execute
		val propertyPackage = result.generatedPropertyPackage
		if (propertyPackage !== null) {
			ecoreUtil.normalSave(propertyPackage, targetFolderUri, fileName.hiddenEmfPropertyFileName)
		}
		return result
	}
	
}