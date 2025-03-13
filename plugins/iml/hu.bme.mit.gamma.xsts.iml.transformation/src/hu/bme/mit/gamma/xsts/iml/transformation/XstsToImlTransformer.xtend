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
package hu.bme.mit.gamma.xsts.iml.transformation

import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.iml.transformation.serialization.ModelSerializer
import hu.bme.mit.gamma.xsts.model.HavocAction
import hu.bme.mit.gamma.xsts.model.XSTS
import java.io.File

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class XstsToImlTransformer {
	protected final String targetFolderUri
	protected final String fileName
	protected final XSTS xSts
	
	protected final extension ModelSerializer modelSerializer = ModelSerializer.INSTANCE
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	new(File file) {
		this.targetFolderUri = file.parent
		this.fileName = file.extensionlessName
		this.xSts = targetFolderUri.normalLoad(file.name) as XSTS
	}
	
	new(XSTS xSts, String targetFolderUri, String fileName) {
		this.xSts = xSts
		this.targetFolderUri = targetFolderUri
		this.fileName = fileName
	}
	
	def void execute() {
		validate
		val imlFile = new File(targetFolderUri + File.separator + fileName.imlImandraFileName)
		val imlString = xSts.serializeIml
		imlFile.saveString(imlString)
	}
	
	//
	
	protected def void validate() {
		val initHavocs = xSts.initializingAction.getSelfAndAllContentsOfType(HavocAction)
		if (!initHavocs.empty) {
			throw new IllegalArgumentException("Havoc actions are not supported in the initial transition")
		}
	}
	
}