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
package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.transformation.util.GammaFileNamer
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import java.io.BufferedWriter
import java.io.File
import java.io.FileWriter
import java.util.ArrayList
import java.util.List
import java.util.Scanner
import java.util.logging.Level
import java.util.logging.Logger

class ThetaTraceGenerator {

	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE

	protected volatile boolean isCancelled
	protected Process process
	protected ThreeStateBoolean result

	final String ENVIRONMENT_VARIABLE_FOR_THETA_JAR = "THETA_XSTS_CLI_PATH"
	protected final Logger logger = Logger.getLogger("GammaLogger")

	def List<ExecutionTrace> execute(File modelFile, boolean fullTraces, List<String> variableList,
			boolean noTransitionCoverage, boolean useAbstraction) {
		val packageFileName = modelFile.name.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)

		return generateTraces(gammaPackage, modelFile, fullTraces, variableList,
				noTransitionCoverage, useAbstraction)
	}

	private def List<ExecutionTrace> generateTraces(Object traceability, File modelFile, boolean fullTraces,
			List<String> variableList, boolean noTransitionCoverage, boolean useAbstraction) {
		val traceDir = new File(modelFile.parent + File.separator + "traces")
		cleanFolder(traceDir)
		val jar = System.getenv(ENVIRONMENT_VARIABLE_FOR_THETA_JAR)
		var command = #["java", "-jar", jar] +
			#["--stacktrace", "--tracegen", "--search", "DFS", "--model", modelFile.canonicalPath, "--property",
				modelFile.canonicalPath] // essential arguments are --tracegen, -- model and --property
		if (fullTraces) {
			command = command + #["--get-full-traces"]
		}
		if (useAbstraction) {
			val varListFile = new File(modelFile.parent + File.separator + "variableList.txt")
			varListFile.createNewFile()
			val writer = new BufferedWriter(new FileWriter(varListFile))

			for (String varName : variableList) {
				writer.append(varName)
				writer.newLine()
			}

			writer.close()
			command = command + #["--variable-list", modelFile.parent + File.separator + "variableList.txt"]
		}
		if (noTransitionCoverage) {
			command = command + #["--no-transition-coverage"]
		}

		logger.log(Level.INFO, "Executing command: " + command.join(" "))
		process = Runtime.getRuntime().exec(command)
		val outputStream = process.inputStream
		var resultReader = new Scanner(outputStream)
		var line = ""
		while (resultReader.hasNext) {
			// (SafetyResult Safe) or (SafetyResult Unsafe)
			line = resultReader.nextLine
			logger.log(Level.INFO, line)
		}

		val traceList = new ArrayList<ExecutionTrace>
		val gammaPackage = traceability as Package
		if (traceDir.listFiles() !== null) {
			for (File tf : traceDir.listFiles()) {
				if (tf.name.endsWith(".trace")) {
					var traceFileScanner = new Scanner(tf)
					traceList.add(gammaPackage.backAnnotate(traceFileScanner))
				}
			}
		}
		return traceList
	}

	protected def backAnnotate(Package gammaPackage, Scanner traceFileScanner) {
		val backAnnotator = new TraceBackAnnotator(gammaPackage, traceFileScanner)
		// Must be synchronized due to the non-thread-safe VIATRA engine
		return backAnnotator.synchronizeAndExecute
	}

	private def cleanFolder(File folder) {
		val files = folder.listFiles()
		if (files !== null) {
			for (File f : files) {
				if (f.isDirectory()) {
					deleteFolder(f)
				} else {
					f.delete()
				}
			}
		}
	}

	private def void deleteFolder(File folder) {
		val files = folder.listFiles()
		if (files !== null) {
			for (File f : files) {
				if (f.isDirectory()) {
					deleteFolder(f)
				} else {
					f.delete()
				}
			}
		}
		folder.delete()
	}

	def getProcess() {
		return process
	}

	def cancel() {
		isCancelled = true
		if (process !== null) {
			process.destroyForcibly
			try {
				// Waiting for process to end
				process.waitFor
			} catch (InterruptedException e) {}
		}
	}
}
