/********************************************************************************
 * Copyright (c) 2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.iml.verification

import java.io.File

class ImlRegionDecomposer extends ImlSemanticDiffer {
	
	def execute(Object traceability, File modelFile) {
		return execute(traceability, modelFile, null)
	}
	
	override execute(Object traceability, File modelFile, File modelFile2) {
		val grandparentFile = modelFile.parentFile
		val src = modelFile.loadString
		
		val cmd = ImlApiHelper.getDecomposeCall(src, DIFF_FUNCTION_NAME)
		
		///
		
		val decomposition = grandparentFile.execute(cmd)
		
		val parser = new SemanticDiffParser(decomposition, false)
		val diff = parser.executeSingleRegion
		parser.print(diff)
		
		val trace = diff.backAnnotate(traceability)
		
		return trace
	}
	
}