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

import hu.bme.mit.gamma.statechart.interface_.Package
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
	protected static final String INVARIANT_DELIM = " " + ImlApiHelper.CONSTRAINT_DELIM + System.lineSeparator
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
		val diff = parser.execute
		parser.print(diff)
		
		if (traceability !== null) {
			val diffAdapter = new SemanticDiffAdapter
//			val diffTrace = diffAdapter.execute(diff) // TODO
			val diffTrace = diffAdapter.exampleDiff
			println(diffTrace)
			
			val gammaPackage = traceability as Package
			val scanner = new Scanner(diffTrace)
			val backAnnotator = new TraceBackAnnotator(gammaPackage, scanner)
			val trace = backAnnotator.execute
			// TODO support state configurations
			// TODO support constraints
			
			return trace
		}
		
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
		
		def getInvariant(String constraints) {
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
			this.invariant = invariant.trimLine.changeTopmostSemicolons
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
		
		// Needed for invariant parsing
		protected def changeTopmostSemicolons(String string) {
			val builder = new StringBuilder
			
			val char semicolon = ';'
			val char openBracket = '{'
			val char closedBracket = '}'
			
			var openBracketCount = 0
			for (var i = 0; i < string.length; i++) {
				val charAt = string.charAt(i)
				if (charAt == openBracket) {
					openBracketCount++
				}
				else if (charAt == closedBracket) {
					openBracketCount--
				}
				
				// 
				if (openBracketCount <= 1 && charAt == semicolon) {
					builder.append(ImlApiHelper.CONSTRAINT_DELIM)
				}
				else {
					builder.append(charAt)
				}
			}
			
			return builder.toString
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
			return diff
		}
		
		//
		
		protected def extractDiff(Decomposition result1, Decomposition result2) {
			// Maybe a standalone Diff lib would work better?
			val diffs = newLinkedHashMap
			
			for (constraints1 : result1.constraints) {
				val invariant2 = result2.getInvariant(constraints1)
				if (invariant2 !== null) {
					val invariant1 = result1.getInvariant(constraints1)
					// Found an entry where constraints are the same
					val invariantDiff = invariant1.extractDiff(invariant2) // Diffing the invariants
					diffs += constraints1 -> invariantDiff
				}
			}
			
			return diffs
		}
		
		protected def extractDiff(String result1, String result2) {
			val invariants1 = result1.splitInvariant
			val invariants2 = result2.splitInvariant
			
			val intersection = newHashSet
			intersection += invariants1
			intersection.retainAll(invariants2)
			
			invariants1 -= intersection
			invariants2 -= intersection
			
			return Map.entry(invariants1.join(INVARIANT_DELIM), invariants2.join(INVARIANT_DELIM))
		}

		protected def splitInvariant(String result) {
			val firstI = result.indexOf("{")
			val lastI = result.lastIndexOf("}")
			
			val parsedResult = result.substring(firstI + 1, lastI)
			val split = newArrayList
			split += parsedResult.split(ImlApiHelper.CONSTRAINT_DELIM) // See region 'changeExternalSemicolons'
					.map[it.trim]
					.reject[it.nullOrEmpty] // Reject "" if any
					
			return split
		}
		
		//
	
		def print(Map<String, ? extends Entry<String, String>> diffs) {
			println("Semantic diff:")
			val S = "  "
			
			val invert = true // If true, the same invariants are not duplicated for different constraints
			if (invert) {
				val C = "- "
				val semDiffs = newLinkedHashMap
				for (entries : diffs.entrySet) {
					val actualConstraint = C + entries.key
					val value = entries.value
					
					val invariant1 = value.key
					val invariant2 = value.value
					
					val invariant = '''
						Original invariant:
						«S»«invariant1»
						New invariant:
						«S»«invariant2»
					'''
					if (semDiffs.containsKey(invariant)) {
						val constraint = semDiffs.get(invariant)
						semDiffs.replace(invariant, #[constraint, actualConstraint].join(System.lineSeparator))
					}
					else {
						semDiffs += invariant -> actualConstraint
					}
				}
				
				for (invariant : semDiffs.keySet) {
					val constraint = semDiffs.get(invariant)
					
					println(S + "Constraints:")
					println(S + constraint.replaceAll(System.lineSeparator, System.lineSeparator + S))
					println(S + invariant.replaceAll(System.lineSeparator, System.lineSeparator + S))
					println
				}
				
				return
			}
			
			for (constraint : diffs.keySet) {
				val value = diffs.get(constraint)
				
				val invariant1 = value.key
				val invariant2 = value.value
				
				println(S + "Constraint:")
				println(S + S + constraint.replaceAll(System.lineSeparator, System.lineSeparator + S + S))
				println(S + "Original invariant:")
				println(S + S + invariant1)
				println(S + "New invariant:")
				println(S + S + invariant2)
				println
			}
		}
		
	}
	
	static class SemanticDiffAdapter {
		//
		protected final String REC = "r"
		//
		
		def String execute(Map<String, Entry<String, String>> diff) {
			// TODO validation
			val preprocessedDiff = diff.preprocessSemanticDiff
			return preprocessedDiff.adaptSemanticDiff
		}
		
		//
		
		
		protected def preprocessSemanticDiff(Map<String, Entry<String, String>> diff) {
			val preprocessedDiff = <String, Entry<String, String>>newLinkedHashMap
			
			for (entry : diff.entrySet) {
				val key = entry.key.replace(''' «REC».''', " ")
				val valueKey = entry.value.key.replace(''' «REC».''', " ")
				val valueValue = entry.value.value.replace(''' «REC».''', " ")
				
				preprocessedDiff += key -> Map.entry(valueKey, valueValue)
			}
			
			return preprocessedDiff
		}
		
		protected def String adaptSemanticDiff(Map<String, Entry<String, String>> diff) '''
			«TraceBackAnnotator.CX_START»
			«TraceBackAnnotator.COUNTEREXAMPLE_INIT_VAR»
			{
			
			}
			«TraceBackAnnotator.COUNTEREXAMPLE_TRACE_VAR»
			«TraceBackAnnotator.STATE_CHANGE2 /*[{*/»
				«FOR entry : diff.entrySet SEPARATOR ';' + System.lineSeparator + TraceBackAnnotator.STATE_CHANGE»
	«««					TODO constraints - input events
					};
					«TraceBackAnnotator.STATE_CHANGE /*{*/»
						«entry.value.key.replace(INVARIANT_DELIM, ";" + System.lineSeparator)»
						«entry.value.value.replace(INVARIANT_DELIM, ";" + System.lineSeparator)»
					}
				«ENDFOR»
			]
		'''
		
		protected def String getExampleDiff() '''
			module CX :
			- : t =
			{
			
			}
			- : t list =
			[{
					};
				{
					_subtraffic_light_Example_ControllerStatechart = M_Subtraffic_light_Example_ControllerStatechart.L_red_on;
					_red_light_state_Example_ControllerStatechart = true
				};
				{
					};
				{
					_subtraffic_light_Example_ControllerStatechart = M_Subtraffic_light_Example_ControllerStatechart.L_red_on;
					_green_light_state_Example_ControllerStatechart = _red_light_state_Example_ControllerStatechart
				}
			]
		'''
		
	}
	
}