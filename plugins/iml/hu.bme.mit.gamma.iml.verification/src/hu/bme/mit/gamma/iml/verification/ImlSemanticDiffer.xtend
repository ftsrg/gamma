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

import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.OpaqueExpression
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.transformation.util.StatechartEcoreUtil
import hu.bme.mit.gamma.transformation.util.UnfoldedExecutionTraceBackAnnotator
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.util.ScannerLogger
import java.io.File
import java.util.List
import java.util.Map
import java.util.Map.Entry
import java.util.Scanner
import java.util.logging.Logger

abstract class ImlSemanticDiffer {
	//
	public static final String IMANDRA_TEMPORARY_COMMAND_FOLDER = ".imandra"
	protected final String DIFF_FUNCTION_NAME = "trans"
	protected final String NEW_DIFF_FUNCTION_NAME = DIFF_FUNCTION_NAME + 2
	//
	protected static final String INVARIANT_DELIM = " " + ImlApiHelper.CONSTRAINT_DELIM + System.lineSeparator
	//
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final StatechartEcoreUtil statechartEcoreUtil = StatechartEcoreUtil.INSTANCE
	protected final Logger logger = Logger.getLogger("GammaLogger")
	//
	
	def ExecutionTrace execute(Object traceability, File modelFile, File modelFile2) {
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
		
		val cmd1 = ImlApiHelper.getDecomposeCall(
		'''
			«model»
			«diffFunction»
		''', DIFF_FUNCTION_NAME, DIFF_PREDICATE_NAME)
		
		val cmd2 = ImlApiHelper.getDecomposeCall(
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
			return diff.backAnnotate(traceability)
		}
		
		return null
	}
	
	protected def execute(File grandparentFile, String cmd) {
		val parentFile = grandparentFile + File.separator + IMANDRA_TEMPORARY_COMMAND_FOLDER
		val nameSuffix = Thread.currentThread.name.replace(":", "").replace(" ", "_")
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
		}
	}
	
	protected def backAnnotate(Map<String, Entry<String, String>> diff, Object traceability) {
		if (traceability !== null) {
			val diffAdapter = new SemanticDiffAdapter
			val diffTrace = diffAdapter.execute(diff)
//			val diffTrace = diffAdapter.exampleDiff // Test
			println(diffTrace)
			
			val gammaPackage = traceability as Package
			val scanner = new Scanner(diffTrace)
			val expressionParser = new ImlExpressionParser(gammaPackage, scanner)
			
			val expressions = expressionParser.execute
			
			val trace = gammaPackage.components.head.createTrace
			val step = trace.addStep
			step.asserts += expressions
			
			// Back-annotating trace
			val unfoldedComponent = trace.component
			if (statechartEcoreUtil.existsOriginalComponent(unfoldedComponent)) {
				val originalComponent = statechartEcoreUtil.loadAndReplaceToOriginalComponent(unfoldedComponent)
				val backAnnotator = new UnfoldedExecutionTraceBackAnnotator(trace, originalComponent)
				val orignalTrace = backAnnotator.execute
				return orignalTrace
			}
			//
			
			return trace
		}
		
		return null
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
	
	protected def postprocessSemanticDiff(ExecutionTrace trace) {
		if (trace.steps.size > 1) {
			trace.steps.removeFirstElement // No need for 'init'
		}
		for (assertion : trace.steps.map[it.asserts].flatten) {
			for (equality : assertion.getSelfAndAllContentsOfType(EqualityExpression)) {
				val rhs = equality.rightOperand
				// Addressing havocs
				if (rhs instanceof OpaqueExpression) {
					val expression = rhs.expression
					val split = expression.split("_")
					// Havoc "heuristics"
					if (split.size > 1 && split.lastElement.matches("[0-9]+")) {
						rhs.expression = "Anything"
					}
				}
			}
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
				.replace('''let «DIFF_FUNCTION_NAME» ''', '''let «NEW_DIFF_FUNCTION_NAME» ''')
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
			this.constraints = constraints.trimLine.sort // We use this as key; must be sorted: 'canonical' representation
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
		protected static def changeTopmostSemicolons(String string) {
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
		
		//
		
		protected def sort(String line) {
			val sortable = newArrayList
			sortable += line.split(ImlApiHelper.CONSTRAINT_DELIM).map[it.trim]
			sortable.sortInplace
			val result = sortable.join(ImlApiHelper.CONSTRAINT_DELIM)
			return result
		}
		
	}
	
	static class SemanticDiffParser {
		//
		Decomposition decomposition1
		Decomposition decomposition2
		//
		protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
		//
		
		new(Decomposition decomposition) {
			this(decomposition, decomposition)
		}
		
		new(Decomposition decomposition1, Decomposition decomposition2) {
			this.decomposition1 = decomposition1
			this.decomposition2 = decomposition2
		}
		
		def execute() {
			if (decomposition1 === decomposition2) {
				return executeSameRegions
			}
			return executeDifferentRegions
		}
		
		def executeSameRegions() {
			return decomposition1.extractDiff
					.splitConstraints
		}
		
		def executeDifferentRegions() {
			return decomposition1.extractDiff(decomposition2)
						.splitConstraints
		}
		
		//
		
		protected def extractDiff(Decomposition decomposition) {
			val diffs = newLinkedHashMap
			
			val regions = decomposition.getRegions
			for (region : regions) {
				val constraints = region.getConstraints
				
				val invariants = region.invariant
				val parsedInvariants  = invariants.deleteFirstAndLast
				
				val splitInvariants = parsedInvariants.splitOnDelim
				val originalInvariant = splitInvariants.head
				val newInvariant = splitInvariants.lastElement
				
				val parsedOriginalInvariants = Region.changeTopmostSemicolons(originalInvariant)
				val parsedNewInvariants = Region.changeTopmostSemicolons(newInvariant)
				
				val invariantDiff = parsedOriginalInvariants.extractDiff(parsedNewInvariants) // Diffing the invariants
				
				diffs += constraints -> invariantDiff
			}
			
			return diffs
		}
		
		protected def extractDiff(Decomposition result1, Decomposition result2) {
			// Maybe a standalone Diff lib would work better?
			val diffs = newLinkedHashMap
			
			for (constraints1 : result1.constraints) {
				val invariant2 = result2.getInvariant(constraints1) // Constraints shall be 'canonically' represented
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
			
			return Map.entry(invariants1.joinOnDelim, invariants2.joinOnDelim)
		}

		protected def splitInvariant(String result) {
			if (result.nullOrEmpty) {
				return newArrayList
			}
			
			val parsedResult = result.getStringBetweenChars("{", "}")
			val split = newArrayList
			split += parsedResult.splitOnDelim
			
			return split
		}
		
		protected def splitConstraints(Map<String, Entry<String, String>> diff) {
			val diffs = newLinkedHashMap
			
			for (constraint : diff.keySet) {
				val splitConstraint = constraint.splitOnDelim
						.map[it.parenthesize] // For parsing later
						.joinOnDelim
				val value = diff.get(constraint)
				
				diffs += splitConstraint -> value
			}
			
			return diffs
		}
		
		protected def splitOnDelim(String value) {
			return value.split(ImlApiHelper.CONSTRAINT_DELIM) // See region 'changeExternalSemicolons'
					.map[it.trim]
					.reject[it.nullOrEmpty] // Reject "" if any
		}
		
		protected def joinOnDelim(Iterable<String> strings) {
			return strings.join(INVARIANT_DELIM)
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
					println(S + constraint.replace(System.lineSeparator, System.lineSeparator + S))
					println(S + invariant.replace(System.lineSeparator, System.lineSeparator + S))
					println
				}
				
				return
			}
			
			for (constraint : diffs.keySet) {
				val value = diffs.get(constraint)
				
				val invariant1 = value.key
				val invariant2 = value.value
				
				println(S + "Constraint:")
				println(S + S + constraint.replace(System.lineSeparator, System.lineSeparator + S + S))
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
		protected final String ENV = "e"
		protected final String DELIM = ";"
		// Check semantics!
		protected final Map<String, String> preprocessElements = #{
			''' «REC».''' -> " ",
			''' «ENV».''' -> " ",
			'''(«REC».''' -> "(",
			'''(«ENV».''' -> "("
		} // Note: '''«REC».''' -> "" would not work, see e.g., 'M_enum_type_var.ERROR'
		//
		protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
		//
		
		def String execute(Map<String, Entry<String, String>> diff) {
			// TODO validation
			val preprocessedDiff = diff.preprocessSemanticDiff
			val adaptedSemanticDiff = preprocessedDiff.adaptSemanticDiff
			return adaptedSemanticDiff
		}
		
		//
		
		protected def preprocessSemanticDiff(Map<String, Entry<String, String>> diff) {
			val preprocessedDiff = <String, Entry<String, String>>newLinkedHashMap
			
			for (entry : diff.entrySet) {
				var key = entry.key
				var valueKey = entry.value.key
				var valueValue = entry.value.value
				
				for (element : preprocessElements.entrySet) {
					val preprocKey = element.key
					val preprocValue = element.value
					
					key = key.replace(preprocKey, preprocValue)
					valueKey = valueKey.replace(preprocKey, preprocValue)
					valueValue = valueValue.replace(preprocKey, preprocValue)
				}
				
				preprocessedDiff += key -> Map.entry(valueKey, valueValue)
			}
			
			return preprocessedDiff
		}
		
		protected def String adaptSemanticDiff(Map<String, Entry<String, String>> diff) {
			var count = 1
			return '''
				«FOR entry : diff.entrySet»
					"--- Region «count++» ---"
					"- Constraints:"
					«entry.key.parseDelim»
					"- Original invariant:"
					«entry.value.key.parseDelim»
					"- New invariant:"
					«entry.value.value.parseDelim»
				«ENDFOR»
			'''
		}
		
		protected def parseDelim(String value) {
			return value.replace(INVARIANT_DELIM, System.lineSeparator)
		}
		
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
					_red_light_state_Example_ControllerStatechart = true <> false
				};
				{
					};
				{
					_subtraffic_light_Example_ControllerStatechart = M_Subtraffic_light_Example_ControllerStatechart.L_red_on;
					_green_light_state_Example_ControllerStatechart = _red_light_state_Example_ControllerStatechart + 1
				}
			]
		'''
		
	}
	
}