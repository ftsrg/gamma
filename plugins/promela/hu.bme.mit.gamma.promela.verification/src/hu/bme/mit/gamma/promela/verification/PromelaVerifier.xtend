/********************************************************************************
 * Copyright (c) 2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.promela.verification

import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import java.util.ArrayList
import java.util.Scanner
import java.util.logging.Level

class PromelaVerifier extends AbstractVerifier {
	
	extension FileUtil fileUtil = FileUtil.INSTANCE
	protected final extension PromelaQueryAdapter promelaQueryAdapter = PromelaQueryAdapter.INSTANCE
	
	override Result verifyQuery(Object traceability, 
		String parameters, File modelFile,	File queryFile
	) {
		val model = fileUtil.loadString(modelFile)
		val query = fileUtil.loadString(queryFile)
		
		var modelWithLtls = model
		var i = 0
		for (singleQuery : query.split(System.lineSeparator).reject[it.nullOrEmpty]) {
			// Supporting multiple queries in separate files
			val ltl = '''«System.lineSeparator»ltl ltl_«i» { «singleQuery.adaptQuery» }'''
			modelWithLtls += ltl
			i++
		}
		
		// root temporary folder
		val rootGenFolder = new File(modelFile.parent, "." + fileUtil.getExtensionlessName(modelFile))
		rootGenFolder.deleteOnExit
		rootGenFolder.mkdirs
		// save model with all LTL
		val tmpGenFolder = new File(rootGenFolder + File.separator + fileUtil.getExtensionlessName(modelFile) + "-LTL" + System.currentTimeMillis.toString)
		tmpGenFolder.deleteOnExit
		tmpGenFolder.mkdirs
		
		// save model with LTL
		val fileWithLtl = new File(tmpGenFolder, fileUtil.getExtensionlessName(modelFile) + "-LTL.pml")
		fileWithLtl.deleteOnExit
		fileUtil.saveString(fileWithLtl, modelWithLtls)
		
		var resultList = new ArrayList<Result>
		for (var j = 0; j < i; j++) {
			val result = verify(traceability, parameters, fileWithLtl)
			resultList += result
		}
		
		// now return just one result
		return resultList.get(0)
	}
	
	private def Result verify(Object traceability, String parameters, File modelFile) {
		var Scanner resultReader = null
		var Scanner traceFileScanner = null
		try {
			// Directory where executing the command
			val execFolder = modelFile.parentFile
			// spin -search -a PromelaFile.pml
			val command = '''spin «parameters» «modelFile.canonicalPath.escapePath»'''
			
			// trail file
			val trailFile = new File(modelFile.trailFile)
			trailFile.delete
			trailFile.deleteOnExit
			// pan file
			val panFile = new File(modelFile.panFile)
			panFile.delete
			panFile.deleteOnExit
			
			// Executing the command
			logger.log(Level.INFO, "Executing command: " + command)
			process = Runtime.getRuntime().exec(command, null, execFolder)
			val outputStream = process.inputStream
			// Reading the result of the command
			resultReader = new Scanner(outputStream)
			
			// save result of command
			val outputFile = new File(execFolder, ".output.txt")
			outputFile.deleteOnExit
			var outputString = ""
			while (resultReader.hasNext) {
				outputString += resultReader.nextLine + System.lineSeparator
			}
			fileUtil.saveString(outputFile, outputString)
			
			if (!trailFile.exists) {
				// No proof/counterexample
				super.result = ThreeStateBoolean.TRUE
				// Adapting result
				super.result = super.result.adaptResult
				return new Result(result, null)
			}
			
			super.result = ThreeStateBoolean.FALSE
			// Adapting result
			super.result = super.result.adaptResult
			
			// spin -t -p PromelaFile.pml
			val traceCommand = '''spin -t -p -g -l -w «modelFile.canonicalPath.escapePath»'''
			// Trace file
			val traceFile = new File(modelFile.traceFile)
			traceFile.delete
			traceFile.deleteOnExit
			// Never claim file
			val nvrFile = new File(execFolder, "_spin_nvr.tmp")
			nvrFile.delete
			nvrFile.deleteOnExit
			
			// Executing the trace command
			logger.log(Level.INFO, "Executing command: " + traceCommand)
			process = Runtime.getRuntime().exec(traceCommand, null, execFolder)
			val traceOutputStream = process.inputStream
			// Reading the result of the command
			resultReader = new Scanner(traceOutputStream)
			
			// save result of command
			val traceOutputFile = new File(modelFile.traceFile)
			traceOutputFile.deleteOnExit
			var traceString = ""
			while (resultReader.hasNext) {
				traceString += resultReader.nextLine + System.lineSeparator
			}
			fileUtil.saveString(traceOutputFile, traceString)
			
			val gammaPackage = traceability as Package
			traceFileScanner = new Scanner(traceFile)
			val backAnnotator = new TraceBackAnnotator(gammaPackage, traceFileScanner)
			val trace = backAnnotator.execute
			
			return new Result(result, trace)
		} finally {
			if (resultReader !== null) {
				resultReader.close
			}
			if (traceFileScanner !== null) {
				traceFileScanner.close
			}
		}
	}
	
	override cancel() {
		super.cancel
	}
	
	def getTrailFile(File modelFile) {
		return modelFile.parent + File.separator + modelFile.name + 
				".trail"
	}
	
	def getTraceFile(File modelFile) {
		return modelFile.parent + File.separator + modelFile.name + 
				".pmltrace"
	}
	
	def getPanFile(File modelFile) {
		return modelFile.parent + File.separator + "pan"
	}
}

class PromelaQueryAdapter {
	public static PromelaQueryAdapter INSTANCE = new PromelaQueryAdapter
	private new() {}
	// Singleton
	final String E = "E"
	final String A = "A"
	
	extension FileUtil fileUtil = FileUtil.INSTANCE
	boolean invert;
	
	def adaptQuery(File queryFile) {
		return queryFile.loadString.adaptQuery
	}
	
	def adaptQuery(String query) {
		if (query.startsWith("E")) {
			invert = true
			return "!(" + query.substring(E.length) + " )"
		}
		if (query.startsWith("A")) {
			invert = false
			return query.substring(A.length)
		}
		invert = false
		return query
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
}