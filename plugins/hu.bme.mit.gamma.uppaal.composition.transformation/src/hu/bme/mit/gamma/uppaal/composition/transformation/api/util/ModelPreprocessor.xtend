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
package hu.bme.mit.gamma.uppaal.composition.transformation.api.util

import hu.bme.mit.gamma.statechart.model.Package
import hu.bme.mit.gamma.statechart.model.StatechartDefinition
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import java.io.File
import java.util.Collections

import static extension hu.bme.mit.gamma.statechart.model.derivedfeatures.StatechartModelDerivedFeatures.*

class ModelPreprocessor {
	
	protected val preprocessor = new hu.bme.mit.gamma.transformation.util.ModelPreprocessor
	protected extension StatechartUtil statechartUtil = new StatechartUtil
	
	def preprocess(Package gammaPackage, File containingFile) {
		val topComponent = preprocessor.preprocess(gammaPackage, containingFile)
		val resource = topComponent.eResource
		val _package = topComponent.getContainingPackage
		// Transforming unhandled transitions to two transitions connected by a choice
		val unhandledTransitionTransformer = new UnhandledTransitionTransformer
		_package.components
			.filter(StatechartDefinition)
			.forEach[unhandledTransitionTransformer.execute(it)]
		// Saving the Package of the unfolded model
		resource.save(Collections.EMPTY_MAP)
		return _package.components.head
	}
	
	def getLogger() {
		return preprocessor.logger
	}
	
}