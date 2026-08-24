/********************************************************************************
 * Copyright (c) 2024-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.iml.verification

import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.util.ScannerLogger
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import java.util.Scanner

class ImlVerifier extends AbstractVerifier {
	//
	public static final String IMANDRA_TEMPORARY_COMMAND_FOLDER = ".imandra"
	//
	
	new(Long timeout) {
		super(timeout)
	}
	
	//
	
	override verifyQuery(Object traceability, String parameters, File modelFile, File queryFile) {
		val query = queryFile.loadString
		var Result result = null
		
		for (singleQuery : query.splitLines) {
			var newResult = traceability.verifyQuery(parameters, modelFile, singleQuery)
			
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
	
	override verifyQuery(Object traceability, String parameters, File modelFile, String query) {
		val modelString = modelFile.loadString
		
		val command = query.substring(0, query.indexOf("("))
		val commandlessQuery = query.substring(command.length)
		
		val parentFile = modelFile.parentFile + File.separator + IMANDRA_TEMPORARY_COMMAND_FOLDER
		val pythonFile = new File(parentFile, '''.imandra-commands-«Thread.currentThread.name».py''')
		pythonFile.deleteOnExit
		
		// "Old" Imandra API vs. ImandraX API
		val serializedPython = ImlApiHelper.getBasicInvariantCall(parameters, modelString, command, commandlessQuery)
//		val serializedPython = (timeoutSet) ?
//				ImlApiHelper.getInvariantCall(modelString, command, commandlessQuery, timeout) :
//				ImlApiHelper.getInvariantCall(modelString, command, commandlessQuery)
		fileUtil.saveString(pythonFile, serializedPython)
		
		// python3 .\imandra-test.py
		val imandraCommand = #["python3", pythonFile.absolutePath]
		logger.info("Running Imandra: " + imandraCommand.join(" "))
		
		var Scanner resultReader = null
		var ScannerLogger errorReader = null
		var Result traceResult = null
		
		try {
			process = Runtime.getRuntime().exec(imandraCommand)
			
			// Reading the result of the command
			resultReader = new Scanner(process.inputReader)
			errorReader = new ScannerLogger(
					new Scanner(process.errorReader),
					#["imandra_http_api_client.exceptions.ServiceException", "HTTP Error",
						"urllib.error.HTTPError", "ValueError", "Error:", "TimeoutError:",
						"NameError: name 'api_response' is not defined"],
					4,
					false) // Set to 'true' for debugging
			errorReader.start
			
			result = ThreeStateBoolean.UNDEF
			
			val gammaPackage = traceability as Package
			val backAnnotator = new TraceBackAnnotator(gammaPackage, resultReader)
			val trace = backAnnotator.synchronizeAndExecute
			
			// Checking for loops (e.g., A F)
			trace?.createCycleIfPossible
			//
			
			val noCounterExample = errorReader.concatenateLines.contains("Type error (env): Unbound module CX")
			if (!errorReader.error || noCounterExample) { // Expected: no counterexample
				if (trace === null && command.contains("verify") || trace !== null && command.contains("instance")) {
					result = ThreeStateBoolean.TRUE
				}
				else if (trace !== null && command.contains("verify") || trace === null && command.contains("instance")) {
					result = ThreeStateBoolean.FALSE
				}
			}
			
			traceResult = new Result(result, trace)
			
			logger.info("Quitting Imandra session")
		} catch (Exception e) {
			logger.warning("Exception thrown: " + e)
			throw e
		} finally {
			resultReader?.close
			errorReader?.cancel
			cancel
		}
		
		return traceResult
	}
	
	//
	
	override getTemporaryQueryFilename(File modelFile) {
		return "." + modelFile.extensionlessName + ".i"
	}
	
	override getHelpCommand() {
		return #["python3", "-h"]
//		return #["imandra-cli", "-h"]
	}
	
	override getUnavailableBackendMessage() {
		return "The Imandra Python API is unavailable; see installation instructions at " +
				"'https://github.com/ftsrg/gamma/tree/dev/plugins/iml#setup'"
	}
	
	override protected getAnalysisLanguage() {
		return "IML"
	}
	
}