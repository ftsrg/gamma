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
package hu.bme.mit.gamma.util

import java.util.Scanner
import java.util.logging.Level
import java.util.logging.Logger

class ScannerLogger implements Runnable {
	
	final Scanner scanner
	
	volatile boolean isCancelled = false
	volatile boolean error = false
	
	final String errorLine
	
	final Logger logger = Logger.getLogger("GammaLogger")
	
	//
	
	protected Thread thread
	
	//
	
	new(Scanner scanner) {
		this(scanner, null)
	}
	
	new(Scanner scanner, String errorLine) {
		this.scanner = scanner
		this.errorLine = errorLine
	}
	
	override void run() {
		while (!isCancelled && scanner.hasNext) {
			val line = scanner.nextLine
			if (errorLine !== null) {
				line.checkError
			}
			logger.log(Level.INFO, line)
		}
	}
	
	private def checkError(String line) {
		val trimmedLine = line.trim
		if (trimmedLine
				.startsWith(errorLine)) {
			error = true
		}
	}
	
	def void cancel() {
		this.isCancelled = true
		if (thread !== null) {
			thread.interrupt
		}
	}
	
	def isError() {
		return error
	}
	
	// 
	
	def start() {
		thread = new Thread(this)
		thread.start
	}
	
}