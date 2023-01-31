/********************************************************************************
 * Copyright (c) 2021-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.uppaal.transformation.api

import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.uppaal.serializer.UppaalModelSerializer
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.uppaal.transformation.XstsToUppaalTransformer

class Xsts2UppaalTransformerSerializer {
	
	protected final XSTS xSts
	protected final String targetFolderUri
	protected final String fileName
	
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE;
	
	new(XSTS xSts, String targetFolderUri, String fileName) {
		this.xSts = xSts
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
	}
	
	def execute() {
		val xStsToUppaalTransformer = new XstsToUppaalTransformer(xSts)
		val nta = xStsToUppaalTransformer.execute
		nta.normalSave(targetFolderUri, fileName.emfUppaalFileName)
		// Serializing the NTA model to XML
		UppaalModelSerializer.saveToXML(nta, targetFolderUri, fileName.xmlUppaalFileName);
	}
	
}