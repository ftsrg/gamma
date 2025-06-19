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

class ImlComposerSemanticDiffer extends ImlSemanticDiffer {
	//
	protected final String C = "c"
	protected final String O = "o"
	protected final String V = "v"
	protected final String T = "t"
	protected final String R = "r"
	protected final String COMPOSITE_DIFF_FUNCTION_NAME = DIFF_FUNCTION_NAME + "_" + NEW_DIFF_FUNCTION_NAME
	//
	
	override execute(Object traceability, File modelFile, File modelFile2) {
		val grandparentFile = modelFile.parentFile
		val src = modelFile.loadString
		val src2 = modelFile2.loadString
		
		val modelAligner = new SignatureAligner(src, src2, traceability)
		val model = modelAligner.execute
		
		val diffParameters = src.extractTransFunctionParameters
		val diffArguments = diffParameters.extractTransFunctionArguments
		
		val composition = '''
			 type «C» = {
			   «O» : «T»;
			   «V» : «T»;
			 }
			 
			 let «COMPOSITE_DIFF_FUNCTION_NAME» «diffParameters» = {
			 	«O» = «DIFF_FUNCTION_NAME» «diffArguments»;
			 	«V» = «NEW_DIFF_FUNCTION_NAME» «diffArguments»;
			 }
		'''
		
		val DIFF_PREDICATE_NAME = "diff"
		val diffFunction = '''
			let «DIFF_PREDICATE_NAME» «diffParameters» =
				match «COMPOSITE_DIFF_FUNCTION_NAME» «diffArguments» with
				| { «O»; «V»; } -> «O» <> «V»;;
		'''
		
		val cmd = ImlApiHelper.getDecomposeCall(
		'''
			«model»
			«composition»
			«diffFunction»
		''', COMPOSITE_DIFF_FUNCTION_NAME, DIFF_PREDICATE_NAME)
		
		///
		
		val decomposition = grandparentFile.execute(cmd)
		
		val parser = new SemanticDiffParser(decomposition)
		val diff = parser.execute
		parser.print(diff)
		
		val trace = diff.backAnnotate(traceability)
		
		return trace
	}
	
}