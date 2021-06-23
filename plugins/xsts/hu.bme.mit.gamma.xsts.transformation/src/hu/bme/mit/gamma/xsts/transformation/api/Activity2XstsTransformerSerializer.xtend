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

import hu.bme.mit.gamma.activity.model.ActivityDeclaration
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures
import hu.bme.mit.gamma.transformation.util.AnalysisModelPreprocessor
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.transformation.ActivityToXstsTransformer
import hu.bme.mit.gamma.xsts.transformation.serializer.ActionSerializer
import java.io.File

class Activity2XstsTransformerSerializer {
	
	protected final ActivityDeclaration activity
	protected final String targetFolderUri
	protected final String fileName
	// Slicing
	
	protected final AnalysisModelPreprocessor preprocessor = AnalysisModelPreprocessor.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	protected final extension ActionSerializer actionSerializer = ActionSerializer.INSTANCE
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	
	new(ActivityDeclaration activity, String targetFolderUri, String fileName) {
		this.activity = activity
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
	}
	
	def void execute() {
		val gammaPackage = StatechartModelDerivedFeatures.getContainingPackage(activity) // shares Package with Statechart
		
		val activityToXSTSTransformer = new ActivityToXstsTransformer(true)
		// Normal transformation
		val xSts = activityToXSTSTransformer.execute(gammaPackage)
		// EMF
		xSts.normalSave(targetFolderUri, fileName.emfXStsFileName)
		val xStsFile = new File(targetFolderUri + File.separator + fileName.xtextXStsFileName)
		val xStsString = xSts.serializeXSTS
		xStsFile.saveString(xStsString)
		
		gammaPackage.normalSave(targetFolderUri, fileName.unfoldedPackageFileName) // saving traceability package
	}
	
}
