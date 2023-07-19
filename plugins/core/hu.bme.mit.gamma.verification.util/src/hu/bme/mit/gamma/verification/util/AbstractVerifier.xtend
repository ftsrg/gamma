/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.util.PathEscaper
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import java.io.File
import java.util.logging.Logger
import org.eclipse.xtend.lib.annotations.Data

abstract class AbstractVerifier {
	
	protected volatile boolean isCancelled
	protected Process process
	protected ThreeStateBoolean result
	
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	protected final GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	protected extension FileUtil codeGeneratorUtil = FileUtil.INSTANCE
	protected extension PathEscaper pathEscaper = PathEscaper.INSTANCE
	protected extension TraceUtil traceUtil = TraceUtil.INSTANCE
	
	def Result verifyQuery(Object traceability, String parameters, File modelFile, String query) {
		// Writing the query to a temporary file
		val parentFolder = modelFile.parent
		val tempQueryFile = new File(parentFolder + File.separator + modelFile.temporaryQueryFilename)
		tempQueryFile.saveString(query)
		tempQueryFile.deleteOnExit
		
		val result = verifyQuery(traceability, parameters, modelFile, tempQueryFile)
		
		return result
	}
	
	def abstract Result verifyQuery(Object traceability, String parameters, File modelFile,	File queryFile)
	
	def cancel() {
		if (!isCancelled) {
			isCancelled = true
			if (process !== null) {
				process.destroyForcibly
				try {
					// Waiting for process to end
					process.waitFor
				} catch (InterruptedException e) {}
			}
		}
	}
	
	def getProcess() {
		return process
	}
	
	def getResult() {
		return result
	}
	
	protected def getTemporaryQueryFilename(File modelFile) {
		return fileNamer.getHiddenSerializedPropertyFileName(modelFile.name)
	}
	
	//
	
	static class LtlQueryAdapter {
		final String A = "A"
		final String E = "E"
		
		boolean invert;
		
		//
		protected final extension FileUtil fileUtil = FileUtil.INSTANCE
		protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
		
		//
		
		def adaptQuery(File queryFile) {
			return queryFile.loadString.adaptQuery
		}
		
		def adaptQuery(String query) {
			val trimmedQuery = query.trim.deparenthesize
			
			if (trimmedQuery.startsWith(E)) {
				invert = true
				return "!(" + trimmedQuery.substring(E.length) + ")"
			}
			if (trimmedQuery.startsWith(A)) {
				invert = false
				return trimmedQuery.substring(A.length)
			}
			
			invert = false
			return trimmedQuery
		}
		
		def adaptResult(ThreeStateBoolean promelaResult) {
			if (promelaResult === null) {
				// If the process is cancelled, the result will be null
				return ThreeStateBoolean.UNDEF
			}
			if (invert) {
				return promelaResult.opposite
			}
			return promelaResult
		}
		
	}
	
	//
	
	@Data
	static class Result {
		ThreeStateBoolean result
		ExecutionTrace trace
		//
		protected extension TraceUtil traceUtil = TraceUtil.INSTANCE
		//
		def extend(Result result) {
			val newTrace = result.trace
			val extendedTrace = (trace === null) ? newTrace : {
				trace.extend(newTrace)
				trace
			}
			return new Result(ThreeStateBoolean.UNDEF, extendedTrace)
		}
		
	}
	
}