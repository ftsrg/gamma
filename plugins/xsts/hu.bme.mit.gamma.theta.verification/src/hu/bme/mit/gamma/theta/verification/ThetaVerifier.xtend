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
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import java.util.Scanner

import static com.google.common.base.Preconditions.checkState

class ThetaVerifier extends AbstractVerifier {
	//
	protected final extension ThetaQueryAdapter thetaQueryAdapter = ThetaQueryAdapter.INSTANCE
	protected final extension ThetaValidator thetaValidator = ThetaValidator.INSTANCE
	
	final String ENVIRONMENT_VARIABLE_FOR_THETA_JAR = "THETA_XSTS_CLI_PATH"
	final String PROP_KEYWORD = "prop"
	
	final String SAFE = "SafetyResult Safe"
	final String UNSAFE = "SafetyResult Unsafe"
	//
	
	override Result verifyQuery(Object traceability, String parameters, File modelFile, String queries) {
		var Result result = null
		for (singleQuery : queries.splitLines) {
			// Supporting multiple queries in separate files
			val parsedQuery = singleQuery.adaptQuery
			val wrappedQuery = '''
				«PROP_KEYWORD» {
					«parsedQuery»
				}
			'''
			val newResult = super.verifyQuery(traceability, parameters, modelFile, wrappedQuery)
			val oldTrace = result?.trace
			val newTrace = newResult?.trace
			if (oldTrace === null) {
				result = newResult
			}
			else if (newTrace !== null) {
				oldTrace.extend(newTrace)
				result = new Result(ThreeStateBoolean.UNDEF, oldTrace)
			}
		}
		
		return result
	}
	
	override Result verifyQuery(Object traceability, String parameters, File modelFile, File queryFile) {
		// Checking if the query file contains more queries
		val queries = fileUtil.loadString(queryFile).trim
		if (!queries.startsWith(PROP_KEYWORD)) {
			// Processing of queries and indirect recursion
			return traceability.verifyQuery(parameters, modelFile, queries)
		}
		//
		
		var Scanner resultReader = null
		var Scanner traceFileScanner = null
		try {
			ENVIRONMENT_VARIABLE_FOR_THETA_JAR.validate
			// The 'THETA_XSTS_CLI_PATH' environment variable has to be set to the respective file path
			val jar = System.getenv(ENVIRONMENT_VARIABLE_FOR_THETA_JAR)
			// java -jar %THETA_XSTS_CLI_PATH% --model trafficlight.xsts --property red_green.prop
			val traceFile = new File(modelFile.traceFile)
			traceFile.delete // So no invalid/old cex is parsed if this actual process does not generate one
			traceFile.deleteOnExit // So the cex with this random name does not remain on disk
			
			val splitParameters = parameters.split("\\s+")
			val command = newArrayList
			command += #["java", "-jar", jar]
			if (!parameters.nullOrEmpty && !splitParameters.empty) {
				command += splitParameters // Some environments do not accept a space
				// due to the join(" ") after the non-existing parameter
			}
			command +=
				#["--model", modelFile.canonicalPath, "--property", queryFile.canonicalPath,
					"--cex", traceFile.canonicalPath, "--stacktrace"]
			// Executing the command
			logger.info("Executing command: " + command.join(" "))
			process = Runtime.getRuntime().exec(command)
			
			val outputStream = process.inputStream
			resultReader = new Scanner(outputStream)
			var line = ""
			while (resultReader.hasNext) {
				// (SafetyResult Safe) or (SafetyResult Unsafe)
				line = resultReader.nextLine
				logger.info(line)
			}
			// Variable 'line' contains the last line of the output - the result
			if (line.contains(SAFE)) {
				super.result = ThreeStateBoolean.TRUE
			}
			else if (line.contains(UNSAFE)) {
				super.result = ThreeStateBoolean.FALSE
			}
			else {
				// Some kind of error or interruption (cancel) by another (winner) process
				logger.warning(line)
				if (isCancelled || Thread.currentThread.interrupted) {
					return new Result(ThreeStateBoolean.UNDEF, null)
				}
				else {
					throw new IllegalArgumentException(line)
				}
			}
			// Adapting result
			super.result = super.result.adaptResult
			if (!traceFile.exists) {
				// No proof/counterexample
				return new Result(result, null)
			}
			
			val gammaPackage = traceability as Package
			traceFileScanner = new Scanner(traceFile)
			val trace = gammaPackage.backAnnotate(traceFileScanner)
			
			return new Result(result, trace)
		} finally {
			resultReader?.close
			traceFileScanner?.close
			cancel
		}
	}
	
	protected def backAnnotate(Package gammaPackage, Scanner traceFileScanner) {
		val backAnnotator = new TraceBackAnnotator(gammaPackage, traceFileScanner)
		// Must be synchronized due to the non-thread-safe VIATRA engine
		return backAnnotator.synchronizeAndExecute
	}
	
	override getTemporaryQueryFilename(File modelFile) {
		return "." + modelFile.extensionlessName + ".prop"
	}
	
	def getTraceFile(File modelFile) {
		// Thread.currentThread.name is needed to prevent race conditions
		return modelFile.parent + File.separator + modelFile.extensionlessName.toHiddenFileName +
			"-" + Thread.currentThread.name + ".cex"
	}
	
}

class ThetaQueryAdapter {
	public static ThetaQueryAdapter INSTANCE = new ThetaQueryAdapter
	private new() {}
	// Singleton
	final String EF = "E<>"
	final String AG = "A[]"
	
	extension FileUtil fileUtil = FileUtil.INSTANCE
	boolean invert
	
	def adaptQuery(File queryFile) {
		return queryFile.loadString.adaptQuery
	}
	
	def adaptQuery(String query) {
		if (query.startsWith("E<>")) {
			invert = true
			return "!(" + query.substring(EF.length) + ")"
		}
		if (query.startsWith("A[]")) {
			invert = false
			return query.substring(AG.length)
		}
		throw new IllegalArgumentException("Not supported operator: " + query)
	}
	
	def adaptResult(ThreeStateBoolean thetaResult) {
		if (thetaResult === null) {
			// If the process is cancelled, the result will be null
			return ThreeStateBoolean.UNDEF
		}
		if (invert) {
			return thetaResult.opposite
		}
		return thetaResult
	}
	
}

class ThetaValidator {
	public static ThetaValidator INSTANCE = new ThetaValidator
	private new() {}
	// Singleton
	
	def validate(String thetaEnvironmentVariable) {
		val jar = System.getenv(thetaEnvironmentVariable)
		val thetaJarFile = new File(jar)
		checkState(thetaJarFile.exists && !thetaJarFile.directory, "The environment variable " + 
				thetaEnvironmentVariable + " does not refer to a valid jar file: " + jar)
	}
	
}