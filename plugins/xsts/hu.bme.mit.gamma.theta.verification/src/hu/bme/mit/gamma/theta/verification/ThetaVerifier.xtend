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
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import java.util.Scanner
import java.util.logging.Level

class ThetaVerifier extends AbstractVerifier {
	
	override ExecutionTrace verifyQuery(Object traceability, String parameters, File modelFile,
			File queryFile, boolean log, boolean storeOutput) {
		var Scanner resultReader = null
		try {
			// java -jar theta-xsts-cli.jar --model trafficlight.xsts --property red_green.prop --loglevel RESULT
			val command = "java -jar theta-xsts-cli.jar " + parameters + " --model \"" + modelFile.toString + "\" --property \"" + queryFile.canonicalPath + "\" --loglevel RESULT"
			// Executing the command
			logger.log(Level.INFO, "Executing command: " + command)
			process =  Runtime.getRuntime().exec(command)
			val outputStream = process.inputStream
			resultReader = new Scanner(outputStream)
			while (resultReader.hasNext) {
				// (SafetyResult Safe) or (SafetyResult Unsafe)
				logger.log(Level.INFO, resultReader.nextLine)
			}
			return null
		} finally {
			resultReader.close
		}
	}
	
}