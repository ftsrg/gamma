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
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.util.ScannerLogger
import java.io.File
import java.util.List
import java.util.Map
import java.util.Map.Entry
import java.util.Scanner
import java.util.logging.Logger

class ImlSemanticDiffer {
	//
	public static final String IMANDRA_TEMPORARY_COMMAND_FOLDER = ".imandra"
	final String DIFF_FUNCTION_NAME = "trans"
	final String NEW_DIFF_FUNCTION_NAME = DIFF_FUNCTION_NAME + 2
	//
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	protected final ImlPythonApiHelper pythonApiHelper = ImlPythonApiHelper.INSTANCE
	protected final Logger logger = Logger.getLogger("GammaLogger")
	//
	
	def execute(Object traceability, File modelFile, File modelFile2) {
		val grandparentFile = modelFile.parentFile
		val src = modelFile.loadString
		val src2 = modelFile2.loadString
		
		val trans2 = src2.extractTransFunction
		
		val model = '''
			«src»
			«trans2»
		'''
		
		val DIFF_PREDICATE_NAME = "diff"
		val diffFunction = '''
			let «DIFF_PREDICATE_NAME» (r : t) = ((«DIFF_FUNCTION_NAME» r) <> («NEW_DIFF_FUNCTION_NAME» r));;
		'''
		
		val cmd1 = ImlApiHelper.getDecompoiseCall(
		'''
			«model»
			«diffFunction»
		''', DIFF_FUNCTION_NAME, DIFF_PREDICATE_NAME)
		
		val cmd2 = ImlApiHelper.getDecompoiseCall(
		'''
			«model»
			«diffFunction»
		''', NEW_DIFF_FUNCTION_NAME, DIFF_PREDICATE_NAME)
		
		///
		
		val result1 = grandparentFile.execute(cmd1)
//		Thread.sleep(10000)
		val result2 = grandparentFile.execute(cmd2)
		
		val diff = result1.extractDiff(result2)
		
		diff.print
		
		return null
	}
	
	protected def execute(File grandparentFile, String cmd) {
		val parentFile = grandparentFile + File.separator + IMANDRA_TEMPORARY_COMMAND_FOLDER
		val nameSuffix = Thread.currentThread.name.replaceAll(":", "").replaceAll(" ", "_")
		val pythonFile = new File(parentFile, '''.imandra-commands-«nameSuffix».py''')
		pythonFile.deleteOnExit
		pythonFile.saveString(cmd)
		
		// python3 .\imandra-test.py
		val imandraCommand = #["python3", pythonFile.absolutePath]
		logger.info("Running Imandra: " + imandraCommand.join(" "))
		
		var Scanner resultReader = null
		var ScannerLogger errorReader = null
		var Process process = null
		try {
			process = Runtime.getRuntime().exec(imandraCommand)
			
			// Reading the result of the command
			resultReader = new Scanner(process.inputReader)
			errorReader = new ScannerLogger(
					new Scanner(process.errorReader),
					#["imandra_http_api_client.exceptions.ServiceException", "HTTP Error", "urllib.error.HTTPError", "ValueError"],
					true)
			errorReader.start
			
			val result = resultReader.parseRegion
			if (errorReader.error) {
				throw new IllegalArgumentException("Region decomposition error")
			}
			
			return result
		} finally {
			logger.info("Quitting Imandra session")
			
			resultReader?.close
			errorReader?.cancel
			process?.destroy
			
			pythonApiHelper?.killImandraInstances
		}
	}
	
	enum ParseRegionStates { CONSTRAINT, INVARIANT }
	protected def parseRegion(Scanner result) {
		val regions = newLinkedHashMap
		
		var state = ParseRegionStates.CONSTRAINT
		
		val constraints = new StringBuilder
		val invariant = new StringBuilder
		while (result.hasNextLine) {
			val line = result.nextLine.trim
			if (line.startsWith(ImlApiHelper.REGION_START)) {
				if (!constraints.empty) {
					regions += constraints.toString -> invariant.toString
				}
				constraints.length = 0
				invariant.length = 0
			}
			else if (line.startsWith(ImlApiHelper.CONSTRAINT_START)) {
				state = ParseRegionStates.CONSTRAINT
			}
			else if (line.startsWith(ImlApiHelper.INVARIANT_START)) {
				state = ParseRegionStates.INVARIANT
			}
			else {
				val builder = (state == ParseRegionStates.CONSTRAINT) ? constraints : invariant
				builder.append(line + System.lineSeparator)
			}
		}
		
		regions += constraints.toString -> invariant.toString
		
		//
		val lastKey = regions.keySet.lastElement // "Instance killed"
		val lastValue = regions.get(lastKey)
		var lastIndex = (lastValue.lastIndexOf("}") < 0) ? lastValue.length : lastValue.lastIndexOf("}") + 1
		regions.replace(lastKey, lastValue.substring(0, lastIndex))
		val firstKey = regions.keySet.head // "Instance created"
		regions.keySet.remove(firstKey)
		//
		
		return regions
	}
	
	protected def extractDiff(Map<String, String> result1, Map<String, String> result2) {
		// Maybe a standalone Diff lib would work better?
		val diffs = newLinkedHashMap
		
		for (key1 : result1.keySet) {
			val value2 = result2.get(key1)
			if (value2 !== null) {
				val value1 = result1.get(key1)
				// Found an entry where constraints are the same
				val diff = value1.extractDiff(value2) // Diffing the invariants
				diffs += key1 -> diff
			}
		}
		
		return diffs
	}
	
	protected def extractDiff(String result1, String result2) {
		val entries1 = result1.splitInvariant
		val entries2 = result2.splitInvariant
		
		val intersection = newHashSet
		intersection += entries1
		intersection.retainAll(entries2)
		
		entries1 -= intersection
		entries2 -= intersection
		
		return Map.entry(entries1, entries2)
	}

	protected def splitInvariant(String result) {
		val firstI = result.indexOf("{")
		val lastI = result.indexOf("}")
		
		val parsedResult = result.substring(firstI + 1, lastI)
		val split = newArrayList
		split += parsedResult.split(";")
				.map[it.trim]
				
		return split
	}
	
	//
	
	protected def print(Map<String, ? extends Entry<? extends List<String>, ? extends List<String>>> diffs) {
		println("Semantic diff:")
		
		val invert = true
		if (invert) {
			val semDiffs = newLinkedHashMap
			for (entries : diffs.entrySet) {
				val key = entries.key
				val value = entries.value
				
				val invariant = '''
					Original invariant:
					  «value.key.join(System.lineSeparator + "  ")»
					New invariant:
					  «value.value.join(System.lineSeparator + "  ")»
				'''
				if (semDiffs.containsKey(invariant)) {
					val constraint = semDiffs.get(invariant)
					semDiffs.replace(invariant, #[constraint, key]
							.join(System.lineSeparator + "Constraint:" + System.lineSeparator))
				}
				else {
					semDiffs += invariant -> key
				}
			}
			
			for (invariant : semDiffs.keySet) {
				val constraint = semDiffs.get(invariant)
				
				println("  Constraint:")
				println("    " + constraint.replaceAll(System.lineSeparator, System.lineSeparator + "    "))
				println("  " + invariant.replaceAll(System.lineSeparator, System.lineSeparator + "  "))
				println()
			}
			
			return
		}
		
		for (constraint : diffs.keySet) {
			val value = diffs.get(constraint)
			
			val invariant1 = value.key
			val invariant2 = value.value
			
			println("  Constraint:")
			println("    " + constraint.replaceAll(System.lineSeparator, System.lineSeparator + "    "))
			println("  Original invariant:")
			println("    " + invariant1.join(System.lineSeparator + "    "))
			println("  New invariant:")
			println("    " + invariant2.join(System.lineSeparator + "    "))
			println()
		}
	}
	
	//
	
	protected def extractTransFunction(String src) {
		val START_FUNCTION_NAME = "init"
		val START_STRING = '''let «START_FUNCTION_NAME» ='''
		
		val start = src.indexOf(START_STRING)
		val offset = START_STRING.length
		val end = src.indexOf("let env ")
		
		val newStart = '''let «START_FUNCTION_NAME»2 ='''
		
		val newSrc = newStart + src.substring(start + offset, end)
				.replaceAll('''let «DIFF_FUNCTION_NAME» ''', '''let «NEW_DIFF_FUNCTION_NAME» ''')
		return newSrc
	}
	
}