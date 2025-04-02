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

class ImlDoubleCallSemanticDiffer extends ImlSemanticDiffer {
	
	override execute(Object traceability, File modelFile, File modelFile2) {
		val grandparentFile = modelFile.parentFile
		val src = modelFile.loadString
		val src2 = modelFile2.loadString
		
		val trans2 = src2.extractTransFunction
		
		val model = '''
			«src»
			«trans2»
		'''
		
		val diffParameters = src.extractTransFunctionParameters
		val diffArguments = diffParameters.extractTransFunctionArguments
		
		val DIFF_PREDICATE_NAME = "diff"
		val diffFunction = '''
			let «DIFF_PREDICATE_NAME» «diffParameters» = ((«
				DIFF_FUNCTION_NAME» «diffArguments») <> («NEW_DIFF_FUNCTION_NAME» «diffArguments»));;
		'''
		
		val cmd1 = ImlApiHelper.getDecomposeCall(
		'''
			«model»
			«diffFunction»
		''', DIFF_FUNCTION_NAME, DIFF_PREDICATE_NAME)
		
		val cmd2 = ImlApiHelper.getDecomposeCall(
		'''
			«model»
			«diffFunction»
		''', NEW_DIFF_FUNCTION_NAME, DIFF_PREDICATE_NAME)
		
		///
		
		val decomposition1 = grandparentFile.execute(cmd1)
		val decomposition2 = grandparentFile.execute(cmd2)
		
		val parser = new SemanticDiffParser(decomposition1, decomposition2)
		val diff = parser.execute
		parser.print(diff)
		
		val trace = diff.backAnnotate(traceability)
		
		return trace
	}
	
}