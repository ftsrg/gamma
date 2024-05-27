/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace
import hu.bme.mit.gamma.util.ScannerLogger
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import java.util.Scanner

class UppaalVerifier extends AbstractVerifier {
	
	protected ScannerLogger resultLogger = null // Created one for each execution
	
	override Result verifyQuery(Object traceability, String parameters,
			File uppaalFile, File uppaalQueryFile) {
		var Scanner resultReader = null
		var Scanner traceReader = null
		val actualUppaalQuery = uppaalQueryFile.loadString
		try {
			// verifyta -t0 -T TestOneComponent.xml asd.q 
			val command = #["verifyta"] + parameters.split("\\s+") +
					#[uppaalFile.canonicalPath, uppaalQueryFile.canonicalPath]
			
			// Executing the command
			logger.info("Executing command: " + command.join(" "))
			process = Runtime.getRuntime().exec(command)
			val outputStream = process.inputStream
			val errorStream = process.errorStream
			
			// Reading the result of the command
			resultReader = new Scanner(outputStream)
			resultLogger = new ScannerLogger(resultReader, "Out of memory", 2 /* UPPAAL-specific */)
			resultLogger.start
			traceReader = new Scanner(errorStream)
			
			if (isCancelled || Thread.currentThread.interrupted) {
				// If the process is killed, this is where it can be checked
				throw new NotBackannotatedException(ThreeStateBoolean.UNDEF)
			}
			if (!traceReader.hasNext()) {
				if (resultLogger.error) {
					// E.g. out of memory
					throw new NotBackannotatedException(ThreeStateBoolean.UNDEF)
				}
				// No back annotation of empty lines
				throw new NotBackannotatedException(
						actualUppaalQuery.handleEmptyLines)
			}
			val backAnnotator = if (traceability instanceof G2UTrace) {
				new UppaalBackAnnotator(traceability, traceReader)
			}
			else if (traceability instanceof Package) {
				new XstsUppaalBackAnnotator(traceability, traceReader)
			}
			else {
				throw new IllegalStateException("Not known traceability element: " + traceability)
			}
			val traceModel = backAnnotator.synchronizeAndExecute
			
			val lines = resultLogger.concatenateLines
			result =
			if (lines.contains("Formula is NOT satisfied")) {
				ThreeStateBoolean.FALSE
			} else if (lines.contains("Formula is satisfied")) {
				ThreeStateBoolean.TRUE
			} else {
				ThreeStateBoolean.UNDEF
			}
			
			return new Result(result, traceModel)
		} catch (EmptyTraceException e) {
			result = handleEmptyLines(actualUppaalQuery)
			return new Result(result, null)
		} catch (NotBackannotatedException e) {
			result = e.result
			return new Result(result, null)
		} catch (Exception e) {
			throw e
		} finally {
			resultReader?.close
			traceReader?.close
			resultLogger?.cancel
			cancel
		}
	}
	
	/**
	 * Returns the correct verification answer when there is no generated trace by the UPPAAL.
	 */
	private def ThreeStateBoolean handleEmptyLines(String uppaalQuery) {
		if (uppaalQuery.startsWith("A[]") || uppaalQuery.startsWith("A<>") || uppaalQuery.contains("-->")) {
			// In the case of A, empty trace means the requirement is met
			return ThreeStateBoolean.TRUE
		}
		// In the case of E, empty trace means the requirement is not met
		return ThreeStateBoolean.FALSE
	}
	
	override cancel() {
		resultLogger?.cancel
		super.cancel
	}
	
	override getHelpCommand() {
		return #["verifyta", "-h"]
	}
	
	override getUnavailableBackendMessage() {
		return "The command line tool of UPPAAL ('verifyta') cannot be found. " +
				"UPPAAL can be downloaded from 'https://uppaal.org/downloads/'. " +
				"Make sure to add the folder containing the 'verifyta' bin to your path environment variable."
	}
	
}
