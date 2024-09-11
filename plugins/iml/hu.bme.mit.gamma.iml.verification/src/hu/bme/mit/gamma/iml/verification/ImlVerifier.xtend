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
package hu.bme.mit.gamma.iml.verification

import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.ScannerLogger
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import java.util.Scanner

class ImlVerifier extends AbstractVerifier {
	//
	protected final static extension FileUtil fileUtil = FileUtil.INSTANCE
	//
	
	override verifyQuery(Object traceability, String parameters, File modelFile, File queryFile) {
		val query = fileUtil.loadString(queryFile)
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
		val modelString = fileUtil.loadString(modelFile)
		
		val command = query.substring(0, query.indexOf("("))
		val commandelssQuery = query.substring(command.length)
		
		val parentFile = modelFile.parentFile
		val pythonFile = new File(parentFile + File.separator + '''.imandra-commands-«Thread.currentThread.name».py''')
		pythonFile.deleteOnExit
		
		val serializedPython = '''
			import imandra
			
			with imandra.session() as session:
				session.eval("""«System.lineSeparator»«modelString»""")
				result = session.«command»("«commandelssQuery»")
				print(result)
		'''
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
			errorReader = new ScannerLogger(new Scanner(process.errorReader), false)
			errorReader.start
			
			val resultPattern = '''(.*Refuted.*)|(.*Proved.*)|(.*Instance (not )?found.*)'''
			var resultFound = false
			result = ThreeStateBoolean.UNDEF
			while (!resultFound && resultReader.hasNextLine) {
				val line = resultReader.nextLine
				if (!line.nullOrEmpty) { // No header printing
					logger.info("Imandra: " + line)
				}
				if (line.matches(resultPattern)) {
					resultFound = true
					if (line.contains("Proved") || line.contains("Instance found")) {
						result  = ThreeStateBoolean.TRUE
					}
					else if (line.contains("Refuted") || line.contains("Instance not found")) {
						result  = ThreeStateBoolean.FALSE
					} // In case of any other outcome, the result will remain undef
				}
			}
			if (!resultFound) {
				logger.severe("Imandra could not verify the model with the property: " + query)
				val errorScanner = new Scanner(process.errorReader)
				while (errorScanner.hasNext) {
					logger.severe("Imandra: " + errorScanner.nextLine)
				}
			}
			
//			val gammaPackage = traceability as Package
//			val backAnnotator = new TraceBackAnnotator(gammaPackage, resultReader)
//			val trace = backAnnotator.synchronizeAndExecute
			
			traceResult = new Result(result, null)
			
			logger.info("Quitting Imandra session")
		} finally {
			resultReader?.close
			errorReader?.cancel
			cancel
		}
		
		return traceResult
	}
	
	override getTemporaryQueryFilename(File modelFile) {
		return "." + modelFile.extensionlessName + ".i"
	}
	
	//
	
	override getHelpCommand() {
		return #["python3", "-h"]
//		return #["imandra-cli", "-h"]
	}
	
	override getUnavailableBackendMessage() {
		return "The command line tool of Imandra ('Imandra') cannot be found. " +
				"Imandra can be downloaded from 'https://www.imandra.ai/'. "
	}
	
}