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

import com.google.gson.GsonBuilder
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.OpaqueExpression
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer
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
	protected static final String DIFF_FUNCTION_NAME = "trans"
	protected static final String NEW_DIFF_FUNCTION_NAME = DIFF_FUNCTION_NAME + 2
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
	
	abstract def ExecutionTrace execute(Object traceability, File modelFile, File modelFile2)
	
	//
	
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
	
	protected def extractTransFunctionParameters(String src) {
		val FUNCTION_NAME = DIFF_FUNCTION_NAME
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
	
	def printJson(ExecutionTrace trace) {
		val gson = new GsonBuilder().disableHtmlEscaping().create();
		val regions = trace.parseRegions
		
		val jsonRegions = gson.toJson(regions)
		return jsonRegions
	}
	
	protected def parseRegions(ExecutionTrace trace) {
		val elements = trace.steps.head.asserts
		return elements.parseRegions
	}
	
	protected def parseRegions(Iterable<? extends Expression> elements) {
		val extension serializer = ExpressionSerializer.INSTANCE
		
		val regions = newArrayList
		
		val constraints = new StringBuilder
		val invariants = new StringBuilder
		
		var currentBuilder = constraints
		
		for (element : elements) {
			val string = element.serialize
					.deleteAll("\"")
			switch (string) {
				case string.startsWith(SemanticDiffAdapter.REGION): {
					regions += Region.of(constraints.toString, invariants.toString)
					constraints.length = 0
					invariants.length = 0
				}
				case SemanticDiffAdapter.CONSTRAINTS:
					currentBuilder = constraints
				case SemanticDiffAdapter.O_INVARIANT:
					currentBuilder = invariants
				case SemanticDiffAdapter.V_INVARIANT:
					currentBuilder = invariants
				default:
					currentBuilder.append(string + ";")
			}
		}
		regions.removeFirstElement // Empty region
		regions += Region.of(constraints.toString, invariants.toString) // Last region
		
		return regions
	}
	
	//
	
	static class SignatureAligner {
		//
		protected final String src
		protected final String src2
		//
		
		new(String src, String src2) {
			this.src = src
			this.src2 = src2
		}
		
		def execute() '''
			«mergeEnums.serializeModules»
			
			«mergeRecords.serializeRecords»
			
			«trans»
			«trans2»
		'''
		
		protected def mergeEnums() {
			val scanner = new Scanner(src)
			val scanner2 = new Scanner(src2)
			
			val modules = scanner.parseModules
			val modules2 = scanner2.parseModules
			
			return modules.mergeStructures(modules2)
		}
		
		protected def parseModules(Scanner scanner) {
			val M = "module"
			
			val modules = newHashMap
			var line = ""
			while (scanner.hasNextLine && (line = scanner.nextLine).startsWith(M)) {
				val name = line.substring(M.length, line.indexOf('=')).trim
				val literals =  line.substring(line.lastIndexOf('=') + 1, line.indexOf("end"))
					.split('\\|').map[it.trim].reject[it.nullOrEmpty].toList
				
				modules += name -> literals
			}
			
			return modules
		}
		
		protected def mergeRecords() {
			val scanner = new Scanner(src)
			val scanner2 = new Scanner(src2)
			
			val records = scanner.parseRecords
			val records2 = scanner2.parseRecords
			
			return records.mergeStructures(records2)
		}
		
		protected def parseRecords(Scanner scanner) {
			val records = newHashMap
			
			var insideRecord = false
			var line = ""
			var fields = #[]
			while (scanner.hasNextLine) {
				line = scanner.nextLine.trim
				if (line.startsWith("type")) {
					insideRecord = true
					val name = line.substring("type nonrec".length, line.indexOf("=")).trim
					fields = newArrayList
					records += name -> fields
				}
				else if (line.startsWith("}")) {
					insideRecord = false
				}
				else if (insideRecord) {
					fields += line // ';' remains at the end
				}
			}
			
			return records
		}
		
		protected def mergeStructures(Map<String, ? extends List<String>> lhs, Map<String, ? extends List<String>> rhs) {
			val merge = newHashMap
			
			for (name : lhs.keySet) {
				val mergedLiterals = newLinkedHashSet
				mergedLiterals += lhs.get(name)
				if (rhs.containsKey(name)) {
					mergedLiterals += rhs.get(name)
				}
				merge += name -> mergedLiterals
			}
			
			return merge
		}
		
		protected def serializeModules(Map<String, ? extends Iterable<String>> modules) '''
			«FOR name : modules.keySet»
				module «name» = struct type t = «FOR literal : modules.get(name) SEPARATOR ' | '»«literal»«ENDFOR» end
			«ENDFOR»
		'''
		
		protected def serializeRecords(Map<String, ? extends Iterable<String>> records) '''
			«FOR name : records.keySet SEPARATOR System.lineSeparator»
				type nonrec «name» = {
					«FOR literal : records.get(name)»
						«literal»
					«ENDFOR»
				}
			«ENDFOR»
		'''
		
		protected def getTrans() {
			src.behavior
		}
		
		protected def getTrans2() {
			val template = '''let «DIFF_FUNCTION_NAME» ('''
			val newTemplate = '''let «NEW_DIFF_FUNCTION_NAME» ('''
			
			return src2.behavior
					.replace(template, newTemplate)
		}
		
		protected def getBehavior(String src) {
			val start = src.indexOf("let h_") // Omitting "init"
			val end = src.indexOf("let env (")
			return src.substring(start, end)
		}
		
	}
	
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
			this.constraints = constraints.trimLine.sort // We use this as key in one of the subclasses; must be sorted: 'canonical' representation
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
		
		def static of(String constraints, String invariant) { // No changes
			val region = new Region(constraints, invariant)
			region.invariant = invariant
			return region
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
				val parsedInvariants = invariants.deleteFirstAndLast
				
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
			
			val invert = false // If true, the same invariants are not duplicated for different constraints
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
		protected static final String REGION = "--- Region "
		protected static final String CONSTRAINTS = "- Constraints:"
		protected static final String O_INVARIANT = "- Original invariant:"
		protected static final String V_INVARIANT = "- New invariant:"
		
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
			// Potential validation could be added here
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
					"«REGION»«count++» ---"
					"«CONSTRAINTS»"
					«entry.key.parseDelim»
					"«O_INVARIANT»"
					«entry.value.key.parseDelim»
					"«V_INVARIANT»"
					«entry.value.value.parseDelim»
				«ENDFOR»
			'''
		}
		
		protected def parseDelim(String value) {
			return value.replace(INVARIANT_DELIM, System.lineSeparator)
		}
		
		protected def String getExampleDiff() '''
			"--- Region 1 ---"
			"- Constraints:"
			
			"- Original invariant:"
			
			"- New invariant:"
			
		'''
		
	}
	
}