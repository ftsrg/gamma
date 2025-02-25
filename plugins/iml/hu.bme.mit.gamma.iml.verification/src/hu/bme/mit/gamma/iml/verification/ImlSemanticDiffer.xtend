/********************************************************************************
 * Copyright (c) 2024-2025 Contributors to the Gamma project
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
		
		val diffParameters = src.extractTransFunctionParameters
		val diffArguments = diffParameters.extractTransFunctionArguments
		
		val DIFF_PREDICATE_NAME = "diff"
		val diffFunction = '''
			let «DIFF_PREDICATE_NAME» «diffParameters» = ((«
				DIFF_FUNCTION_NAME» «diffArguments») <> («NEW_DIFF_FUNCTION_NAME» «diffArguments»));;
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
		
		val decomposition1 = grandparentFile.execute(cmd1)
		val decomposition2 = grandparentFile.execute(cmd2)
		
		val parser = new SemanticDiffParser(decomposition1, decomposition2)
		parser.execute
		
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
		val decomposition = new Decomposition
		val regions = decomposition.getRegions
		
		var state = ParseRegionStates.CONSTRAINT
		
		val constraints = new StringBuilder
		val invariant = new StringBuilder
		while (result.hasNextLine) {
			val line = result.nextLine.trim
			if (line.startsWith(ImlApiHelper.REGION_START)) {
				if (!constraints.empty) {
					regions += new Region(constraints.toString, invariant.toString)
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
		
		regions += new Region(constraints.toString, invariant.toString)
		
		//
//		val lastRegion = regions.lastElement // "Instance killed"
//		val lastInvariant = lastRegion.invariant
//		var lastIndex = (lastInvariant.lastIndexOf("}") < 0) ? lastInvariant.length : lastInvariant.lastIndexOf("}") + 1
//		lastRegion.invariant = lastInvariant.substring(0, lastIndex)
//		regions.removeFirstElement // "Instance created"
		//
		
		return decomposition
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
	
	protected def extractTransFunctionParameters(String src) {
		val FUNCTION_NAME = "trans"
		val START_STRING = '''let «FUNCTION_NAME»'''
		val END_STRING = "="
		
		val transIndex = src.indexOf(START_STRING)
		val firstIndex = src.indexOf("(", transIndex)
		val lastIndex = src.indexOf(END_STRING, transIndex)
		
		val parameters = src.substring(firstIndex, lastIndex).trim
		
		return parameters
	}
	
	protected def extractTransFunctionArguments(String transFunctionParameters) {
		val arguments = new StringBuilder
		
		val char leftPar = '('
		val char colon = ':'
		
		var previousParenthesis = 0
		for (var i = 0; i < transFunctionParameters.length; i++) {
			var charAt = transFunctionParameters.charAt(i)
			if (charAt == leftPar) {
				previousParenthesis = i
			}
			else if (charAt == colon) {
				val argument = transFunctionParameters.substring(previousParenthesis + 1, i).trim
				arguments.append(argument + " ")
			}
		}
		
		return arguments.toString.trim
	}
	
	//
	
	static class Decomposition {
		//
		List<Region> regions = newArrayList
		//
		def getRegions() {
			return regions
		}
		
		def getConstraints() {
			return regions.map[it.getConstraints].toList
		}
		
		def getInvaraint(String constraints) {
			return regions.findFirst[it.constraints == constraints]?.invariant
		}
		
	}
	
	static class Region {
		//
		String constraints
		String invariant
		//
		new(String constraints, String invariant) {
			this.constraints = constraints.trimLine
			this.invariant = invariant.trimLine
		}
		
		def getConstraints() {
			return constraints
		}
		
		def getInvariant() {
			return invariant
		}
		
		def void setInvariant(String invariant) {
			this.invariant = invariant
		}
		
		//
		
		protected def trimLine(String line) {
			return line.trim.replaceAll("\\s+", " ")
		}
		
	}
	
	static class SemanticDiffParser {
		//
		Decomposition decomposition1
		Decomposition decomposition2
		//
		new(Decomposition decomposition1, Decomposition decomposition2) {
			this.decomposition1 = decomposition1
			this.decomposition2 = decomposition2
		}
		
		def execute() {
			val diff = decomposition1.extractDiff(decomposition2)
			diff.print
		}
		
		//
		
		protected def extractDiff(Decomposition result1, Decomposition result2) {
			// Maybe a standalone Diff lib would work better?
			val diffs = newLinkedHashMap
			
			for (constraints1 : result1.constraints) {
				val invariant2 = result2.getInvaraint(constraints1)
				if (invariant2 !== null) {
					val invariant1 = result1.getInvaraint(constraints1)
					// Found an entry where constraints are the same
					val diff = invariant1.extractDiff(invariant2) // Diffing the invariants
					diffs += constraints1 -> diff
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
			
			val invert = true // If true, invariants are not duplicated for different constraints
			if (invert) {
				val semDiffs = newLinkedHashMap
				for (entries : diffs.entrySet) {
					val key = entries.key
					val value = entries.value
					
					val invariant1 = value.key
					val invariant2 = value.value
					
					val invariant = '''
						Original invariant:
						  «invariant1.join(System.lineSeparator + "  ")»
						New invariant:
						  «invariant2.join(System.lineSeparator + "  ")»
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
					println
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
				println
			}
		}
		
	}
	
}