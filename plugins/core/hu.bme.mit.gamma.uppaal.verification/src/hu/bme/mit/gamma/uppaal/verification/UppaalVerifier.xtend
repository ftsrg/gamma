/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
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
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import java.util.Scanner
import java.util.logging.Level

class UppaalVerifier extends AbstractVerifier {
	
	VerificationResultReader verificationResultReader = null // Created one for each execution
	
	override Result verifyQuery(Object traceability, String parameters,
			File uppaalFile, File uppaalQueryFile) {
		var Scanner resultReader = null
		var Scanner traceReader = null
		val actualUppaalQuery = uppaalQueryFile.loadString
		try {
			// verifyta -t0 -T TestOneComponent.xml asd.q 
			var String[] command = #["verifyta"] + parameters.split(" ") + #[uppaalFile.canonicalPath, uppaalQueryFile.canonicalPath]
			
			// Executing the command
			logger.log(Level.INFO, "Executing command: " + command)
			process =  Runtime.getRuntime().exec(command)
			val outputStream = process.inputStream
			val errorStream = process.errorStream
			// Reading the result of the command
			resultReader = new Scanner(outputStream)
			verificationResultReader = new VerificationResultReader(resultReader)
			val thread = new Thread(verificationResultReader)
			thread.start
			traceReader = new Scanner(errorStream)
			if (isCancelled) {
				// If the process is killed, this is where it can be checked
				throw new NotBackannotatedException(ThreeStateBoolean.UNDEF)
			}
			if (!traceReader.hasNext()) {
				// No back annotation of empty lines
				throw new NotBackannotatedException(handleEmptyLines(actualUppaalQuery))
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
			val traceModel = backAnnotator.execute
			result = actualUppaalQuery.handleEmptyLines.opposite
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
			resultReader.close
			traceReader.close
			verificationResultReader.cancel
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
		verificationResultReader.cancel
		super.cancel
	}
	
}
