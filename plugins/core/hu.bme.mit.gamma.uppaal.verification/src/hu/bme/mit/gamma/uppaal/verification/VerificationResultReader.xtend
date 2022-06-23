/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.verification

import java.util.Scanner
import java.util.logging.Level
import java.util.logging.Logger

class VerificationResultReader implements Runnable {
	
	final Scanner scanner
	
	volatile boolean isCancelled = false
	volatile boolean error = false
	
	final Logger logger = Logger.getLogger("GammaLogger")
	
	new(Scanner scanner) {
		this.scanner = scanner;
	}
	
	override void run() {
		while (!isCancelled && scanner.hasNext) {
			val line = scanner.nextLine()
			line.checkError
			logger.log(Level.INFO, line)
		}
	}
	
	private def checkError(String line) {
		val trimmedLine = line.trim
		if (trimmedLine
				.startsWith("Out of memory")) {
			error = true
		}
	}
	
	def void cancel() {
		this.isCancelled = true
	}
	
	def isError() {
		return error
	}
	
}