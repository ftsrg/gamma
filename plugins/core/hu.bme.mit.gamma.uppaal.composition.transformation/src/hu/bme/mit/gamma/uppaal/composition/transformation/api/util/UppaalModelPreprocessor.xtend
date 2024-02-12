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

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.transformation.util.preprocessor.AnalysisModelPreprocessor
import java.util.Collections
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class UppaalModelPreprocessor extends AnalysisModelPreprocessor {
	// Singleton
	public static final UppaalModelPreprocessor INSTANCE =  new UppaalModelPreprocessor
	protected new() {}
	//
	
	override preprocess(Package gammaPackage, List<? extends Expression> topComponentArguments,
			String targetFolderUri, String fileName, boolean optimize) {
		val topComponent = super.preprocess(gammaPackage, topComponentArguments,
			targetFolderUri, fileName, optimize)
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
	
}