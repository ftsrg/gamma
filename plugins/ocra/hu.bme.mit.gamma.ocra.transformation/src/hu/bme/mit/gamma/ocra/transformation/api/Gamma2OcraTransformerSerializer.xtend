/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ocra.transformation.api

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.ocra.transformation.ModelSerializer
import hu.bme.mit.gamma.ocra.transformation.OcraVerifier
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.util.FileUtil
import java.io.File
import java.util.List

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*


class Gamma2OcraTransformerSerializer {
	//
	protected final Component component
	protected final List<? extends Expression> arguments
	protected final String targetFolderUri
	protected final String fileName
	//
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	//
	
	new(Component component, String targetFolderUri, String fileName) {
		this(component, #[], targetFolderUri, fileName)
	}
	
	new(Component component, List<? extends Expression> arguments,
			String targetFolderUri, String fileName) {
		this.component = component
		this.arguments = arguments
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
	}
	
	def execute() {
		// Normal transformation
		val gammaToOcraTransformer = ModelSerializer.INSTANCE
		val ocraVerifier = new OcraVerifier
		val ocraString = gammaToOcraTransformer.execute(component.containingPackage) // TODO arguments?
		
		val ocraFile = new File(targetFolderUri + File.separator + fileName.ocraFileName)
		ocraFile.saveString(ocraString)
		ocraVerifier.verifyQuery(ocraFile)	
	}
}