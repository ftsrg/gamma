/********************************************************************************
 * Copyright (c) 2018-2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.util

import java.util.LinkedList
import java.util.Scanner
import java.util.logging.Level
import java.util.logging.Logger

class ScannerLogger implements Runnable {
	
	final Scanner scanner
	
	volatile boolean isCancelled = false
	volatile boolean error = false
	
	final Iterable<String> errorLines
	
	//
	
	final int storedLineCapacity
	final boolean printLines
	final LinkedList<String> lines = newLinkedList
	
	//
	
	final Logger logger = Logger.getLogger("GammaLogger")
	
	//
	
	protected Thread thread
	
	//
	
	new(Scanner scanner) {
		this(scanner, #[])
	}
	
	new(Scanner scanner, boolean printLines) {
		this(scanner, #[], printLines)
	}
	
	new(Scanner scanner, String errorLine) {
		this(scanner, #[errorLine])
	}
	
	new(Scanner scanner, Iterable<String> errorLines) {
		this(scanner, errorLines, 0, true)
	}
	
	new(Scanner scanner, String errorLine, boolean printLines) {
		this(scanner, #[errorLine], printLines)
	}
	
	new(Scanner scanner, Iterable<String> errorLines, boolean printLines) {
		this(scanner, errorLines, 0, printLines)
	}
	
	new(Scanner scanner, int storedLineCapacity) {
		this(scanner, #[], storedLineCapacity, true)
	}
	
	new(Scanner scanner, String errorLine, int storedLineCapacity) {
		this(scanner, errorLine, storedLineCapacity, true)
	}
	
	new(Scanner scanner, String errorLine, int storedLineCapacity, boolean printLines) {
		this(scanner, #[errorLine], storedLineCapacity, printLines)
	}
	
	new(Scanner scanner, Iterable<String> errorLines, int storedLineCapacity, boolean printLines) {
		this.scanner = scanner
		this.errorLines = errorLines
		this.storedLineCapacity = storedLineCapacity
		this.printLines = printLines
	}
	
	override void run() {
		while (!isCancelled && scanner.hasNext) {
			val line = scanner.nextLine
			
			if (!errorLines.nullOrEmpty) {
				line.checkError
				line.storeLine
			}
			
			val logLevel = (error) ? Level.SEVERE : Level.WARNING
			if (printLines) {
				logger.log(logLevel, line)
//				println(line)
			}
		}
	}
	
	private def checkError(String line) {
		val trimmedLine = line.trim
		for (errorLine : errorLines) {
			if (trimmedLine
					.startsWith(errorLine)) {
				error = true
			}
		}
	}
	
	def void cancel() {
		this.isCancelled = true
		this.scanner?.close
		if (thread !== null) {
			thread.interrupt
		}
	}
	
	def isError() {
		return error
	}
	
	protected def storeLine(String line) {
		if (storedLineCapacity <= 0) {
			return
		}
		if (lines.size >= storedLineCapacity) {
			lines.poll
		}
		lines.add(line)
	}
	
	def getLine(int i) {
		val reversedIndex = i - storedLineCapacity
		return lines.get(reversedIndex)
	}
	
	def getFirstStoredLine() {
		return lines.poll
	}
	
	def concatenateLines() {
		if (lines.empty) {
			return ""
		}
		return lines.reduce[p1, p2 | p1 + p2]
	}
	
	// 
	
	def start() {
		thread = new Thread(this)
		thread.start
	}
	
	def join() {
		thread.join
	}
	
}