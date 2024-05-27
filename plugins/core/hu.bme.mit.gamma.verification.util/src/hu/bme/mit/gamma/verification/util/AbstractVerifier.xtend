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
import java.util.List
import java.util.logging.Logger
import org.eclipse.xtend.lib.annotations.Data

abstract class AbstractVerifier {
	//
	protected volatile boolean isCancelled
	protected Process process
	protected ThreeStateBoolean result
	
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	protected final GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	protected extension FileUtil fileUtil = FileUtil.INSTANCE
	protected extension PathEscaper pathEscaper = PathEscaper.INSTANCE
	protected extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	
	//
	
	def isBackendAvailable() {
		try {
			helpCommand.startBackend
		}
		catch (Throwable t) {
			if (t.isUnstartableProcessException) {
				return false
			}
		}
		return true
	}
	
	def void startBackend(List<String> command) {
		var Process process = null
		try {
			process = Runtime.getRuntime().exec(command)
		} finally {
			process?.destroyForcibly
		}
	}
	
	protected abstract def List<String> getHelpCommand()
	
	protected abstract def String getUnavailableBackendMessage()
	
	//
	
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
		
		final String F = "F"
		final String G = "G"
		
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
				// For some reason, nuXmv cannot make !(F...) an invariant property, so we adapt even more
				if (trimmedQuery.startsWith(E + F)) {
					return "G(!(" + trimmedQuery.substring((E + F).length) + "))"
				}
				if (trimmedQuery.startsWith(E + " " + F)) {
					return "G(!(" + trimmedQuery.substring((E + " " + F).length) + "))"
				}
				// Default
				return "!(" + trimmedQuery.substring(E.length) + ")"
			}
			if (trimmedQuery.startsWith(A)) {
				invert = false
				return trimmedQuery.substring(A.length)
			}
			
			invert = false
			return trimmedQuery
		}
		
		def adaptInvariantQuery(String query) {
			val trimmedQuery = query.trim.deparenthesize
			
			if (!trimmedQuery.startsWith(A) && !trimmedQuery.startsWith(E)) {
				// It is an invariant query
				return "G(" + trimmedQuery + ")";
			}
			
			return trimmedQuery
		}
		
		def adaptLtlOrInvariantQuery(String query) {
			// p & q -> G(p & q)
			// E F (p & q) -> G(p & q)
			return query.adaptInvariantQuery.adaptQuery
		}
		
		def adaptLtlOrInvariantQueryToReachability(String query) {
			// G(p & q) -> (p & q)
			val gQuery = query.adaptLtlOrInvariantQuery
			if (!gQuery.startsWith(G)) {
				throw new IllegalArgumentException("Not expected query form: " + query)
			}
			return "!(" + gQuery.substring(G.length) + ")"
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
		
		//
		
		def isQueryInverted() {
			return invert
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
			if (result === null) {
				return this // We cannot do anything with null parameters
			}
			
			val newTrace = result.trace
			val extendedTrace = (trace === null) ? newTrace : {
				trace.extend(newTrace)
				trace
			}
			
			return new Result(ThreeStateBoolean.UNDEF, extendedTrace)
		}
		
		def invert() {
			return new Result(result.opposite, trace)
		}
		
	}
	
}