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

import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.util.ScannerLogger
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import java.util.List
import java.util.Map
import java.util.Scanner

class ImlVerifier extends AbstractVerifier {
	//
	public static final String IMANDRA_TEMPORARY_COMMAND_FOLDER = ".imandra"
	//
	protected final static extension FileUtil fileUtil = FileUtil.INSTANCE
	protected final ImlPythonApiHelper pythonApiHelper = ImlPythonApiHelper.INSTANCE
	//
	
	override verifyQuery(Object traceability, String parameters, File modelFile, File queryFile) {
		val query = queryFile.loadString
		var Result result = null
		
		for (singleQuery : query.splitLines) {
			var newResult = traceability.verifyQuery(parameters, modelFile, singleQuery)
			
			val oldTrace = result?.trace
			val newTrace = newResult?.trace
			if (oldTrace === null) {
				result = newResult
			}
			else if (newTrace !== null) {
				oldTrace.extend(newTrace)
				result = new Result(ThreeStateBoolean.UNDEF, oldTrace)
			}
		}
		
		return result
	}
	
	override verifyQuery(Object traceability, String parameters, File modelFile, String query) {
		val modelString = modelFile.loadString
		
		val command = query.substring(0, query.indexOf("("))
		val commandelssQuery = query.substring(command.length)
		
		val arguments = parameters.parseArguments
		val argument = arguments.key
		val postArgument = arguments.value
		
		val parentFile = modelFile.parentFile + File.separator + IMANDRA_TEMPORARY_COMMAND_FOLDER
		val pythonFile = new File(parentFile, '''.imandra-commands-«Thread.currentThread.name».py''')
		pythonFile.deleteOnExit
		
		val serializedPython = modelString.getImlApiCode(command, argument, postArgument, commandelssQuery)
		fileUtil.saveString(pythonFile, serializedPython)
		
		// python3 .\imandra-test.py
		val imandraCommand = #["python3", pythonFile.absolutePath]
		logger.info("Running Imandra: " + imandraCommand.join(" "))
		
		var Scanner resultReader = null
		var ScannerLogger errorReader = null
		var Result traceResult = null
		
		try {
			process = Runtime.getRuntime().exec(imandraCommand)
			
			// Reading the result of the command
			resultReader = new Scanner(process.inputReader)
			errorReader = new ScannerLogger(
					new Scanner(process.errorReader),
					#["imandra_http_api_client.exceptions.ServiceException", "HTTP Error", "urllib.error.HTTPError", "ValueError", "Error:"],
					4,
					false) // Set to 'true' for debugging
			errorReader.start
			
			result = ThreeStateBoolean.UNDEF
			
			val gammaPackage = traceability as Package
			val backAnnotator = new TraceBackAnnotator(gammaPackage, resultReader)
			val trace = backAnnotator.synchronizeAndExecute
			
			// Checking for loops (e.g., A F)
			trace?.createCycleIfPossible
			//
			
			val noCounterExample = errorReader.concatenateLines.contains("Type error (env): Unbound module CX")
			if (!errorReader.error || noCounterExample) { // Expected: no counterexample
				if (trace === null && command.contains("verify") || trace !== null && command.contains("instance")) {
					result = ThreeStateBoolean.TRUE
				}
				else if (trace !== null && command.contains("verify") || trace === null && command.contains("instance")) {
					result = ThreeStateBoolean.FALSE
				}
			}
			
			traceResult = new Result(result, trace)
			
			logger.info("Quitting Imandra session")
		} finally {
			resultReader?.close
			errorReader?.cancel
			cancel
			
			pythonApiHelper?.killImandraInstances
		}
		
		return traceResult
	}
	
	protected def String getImlApiCode(String modelString, String command,
			String arguments, String postArguments, String commandlessQuery) {
		return ImlApiHelper.getBasicCall('''
			«modelString»;;
			«commandlessQuery.utilityMethods»
			«command»«IF !arguments.nullOrEmpty» «arguments» «ENDIF»(«commandlessQuery»)«postArguments»;;
			#print_length 10000;;
			#print_depth 10000;;
			init;;
			let path = collect_path «FOR inputsOfLevels : commandlessQuery
				.parseInputsOfLevels
				.discardInputsAfterLoops(command) // Discarding events (path parts) after the first loop
				.values»«
					FOR inputOfLevels : inputsOfLevels»«IF inputOfLevels != "[]"»CX.«inputOfLevels»«ELSE»[]«ENDIF» «ENDFOR»«ENDFOR»in
			log_run init path;;
		''')
	}
	
	protected def getUtilityMethods(String query) { // TODO move to Prop-ser
		val builder = new StringBuilder
		
		if (query.contains("exists_prefix ")) {
			builder.append('''
				let rec exists_prefix r e p =
					match e with
					| [] -> p r (* Last element will be checked, too *)
					| hd :: tl -> p r || (* At least one element (note the ||) *)
						let r = run_cycle r hd in (* Run r based on the head *)
						exists_prefix r tl p (* Check the tail *)
				[@@adm e];; (* Needed by Imandra to prove termination *)
			''')
		}
		if (query.contains("exists_real_prefix ") || query.contains("ends_in_real_loop ") ||
				query.contains("ends_in_loop ")) {
			builder.append('''
				let rec exists_real_prefix r e p =
					match e with
					| [] -> false (* No p r check *)
					| [_] -> p r (* 1 last element will be unchecked *)
					| hd :: tl -> p r || (* At least two elements (note the ||) *)
						let r = run_cycle r hd in (* Run r based on the head *)
						exists_real_prefix r tl p (* Check the tail *)
				[@@adm e];; (* Needed by Imandra to prove termination *)
			''')
		}
		if (query.contains("forall_prefix ")) {
			builder.append('''
				let rec forall_prefix r e p =
					match e with
					| [] -> p r (* Last element will be checked *)
					| hd :: tl -> p r && (* At least one element (note the &&) *)
						let r = run_cycle r hd in (* Run r based on the head *)
						forall_prefix r tl p (* Check the tail *)
				[@@adm e];; (* Needed by Imandra to prove termination *)
			''')
		}
		if (query.contains("forall_real_prefix ")) {
			builder.append('''
				let rec forall_real_prefix r e p =
					match e with
					| [] -> true (* No p r check *)
					| [_] -> p r (* 1 last element will be unchecked *)
					| hd :: tl -> p r && (* At least two elements (note the &&) *)
						let r = run_cycle r hd in (* Run r based on the head *)
						forall_real_prefix r tl p (* Check the tail *)
				[@@adm e];; (* Needed by Imandra to prove termination *)
			''')
		}
		if (query.contains("is_one_prefix_of_other ")) {
			builder.append('''
				let rec is_one_prefix_of_other l r =
					if l = [] || r = []
					then true
					else
						List.hd l = List.hd r && is_one_prefix_of_other (List.tl l) (List.tl r);;
			''')
		}
		if (query.contains("ends_in_real_loop ")) {
//			builder.append('''
//				let rec get_last_element l =
//					match l with
//					| [] -> raise exception
//					| [last] -> ([], last)
//					| hd :: tl ->
//						let (sub_hd, last) = get_last_element tl in
//						(hd :: sub_hd, last);;
//			''')
			builder.append('''
				let ends_in_real_loop r e =
					match e with
					| [] -> false
					| _ ->
						let e_reversed = List.rev e in
						match e_reversed with
						| [] -> false (* Unreachable *)
						| tl :: hd_reversed -> let hd = List.rev hd_reversed in
							let before_final_state = run r hd in
							let final_state = run_cycle before_final_state tl in
							before_final_state <> final_state &&
								exists_real_prefix r e (fun r -> r = final_state);;
			''') // We do not the last state and before last state to be equal
//			builder.append('''
//				let ends_in_real_loop r e =
//					let end_state = run r e in
//					exists_real_prefix r e (fun r -> r = end_state);;
//			''')
		}
		if (query.contains("ends_in_loop ")) {
			builder.append('''
				let ends_in_loop r e =
					match e with
					| [] -> false
					| [hd] -> false
					| _ ->
						let final_state = run r e in
						exists_real_prefix r e (fun r -> r = final_state);;
			''')
		}
		if (query.contains("get_e_prefix_leading_to ")) {
			builder.append('''
				let rec get_e_prefix_leading_to r e r_=
					match e with
					| [] -> [] (* Should be unreachable *)
					| hd :: tl ->
						let r = run_cycle r hd in
						if r = r_ then
							[hd]
						else
							hd :: get_e_prefix_leading_to r tl r_
				[@@adm e];;
			''')
		}
		builder.append('''
			let rec select_longest list_of_lists =
				match list_of_lists with
				| [] -> []
				| hd::tl ->
					let so_far_longest = select_longest tl in
					if List.length hd >= List.length so_far_longest then
						hd
					else
						so_far_longest;;
		''')
		
		var count = 0
		builder.append('''
			let collect_path «query.parseInputs» =
				let path_«count++» = [] in
				«FOR inputsOfLevel : query.parseInputsOfLevels.values»
					let path_«count++» = path_«count - 2» @ select_longest [«
						FOR inputOfLevel : inputsOfLevel SEPARATOR ';'»«IF inputOfLevel.contains("_X_") /* TODO based on ImlPropertySerializer.getInputId */»[«inputOfLevel»]«ELSE»«inputOfLevel»«ENDIF»«ENDFOR»] in
				«ENDFOR»
				path_«count - 1»;;
		''')
		
		return builder.toString
	}
	
	protected def parseArguments(String arguments) {
		val argument = new StringBuilder
		val postArgument = new StringBuilder
		
		val splits = arguments.split("\\s") // Split based on any whitespace
		for (split : splits) {
			if (split.startsWith("[") && split.endsWith("]")) { // [@@auto]
				postArgument.append(split + " ")
			}
			else {
				argument.append(split + " ")
			}
		}
		
		return argument.toString.trim -> postArgument.toString.trim
	}
	
	protected def parseInputs(String query) {
		val funKeyword = "fun"
		val funIndex = query.indexOf(funKeyword)
		val lastIndex = query.indexOf("->")
		val input = query.substring(funIndex + funKeyword.length, lastIndex).trim
		return input
	}
	
	protected def parseInputsOfLevels(String query) {
		val input = query.parseInputs
		val inputs = input.split("\\s")
		// Sorted map needed!
		val inputsOfLevels = inputs.groupBy[Integer.valueOf(it.split("\\_").get(1))] // TODO based on ImlPropertySerializer.getInputId
		return inputsOfLevels
	}
	
	protected def discardInputsAfterLoops(Map<Integer, List<String>> inputsOfLevels, String command) {
		val loopOperators = (command.contains("verify")) ? #[ "F", "U", "SR" ] : #[ "G", "R", "WU" ]
		for (level : inputsOfLevels.keySet) {
			val inputs = inputsOfLevels.get(level)
			if (inputs.exists[loopOperators.contains(it.split("\\_").get(2))]) {// TODO based on ImlPropertySerializer.getInputId
				for (greaterLevel : inputsOfLevels.keySet.filter[it > level]) {
					val discardableInputs = inputsOfLevels.get(greaterLevel)
					val size = discardableInputs.size
					discardableInputs.clear
					for (var i = 0; i < size; i++) {
						discardableInputs += "[]" // Empty lists
					}
				}
				return inputsOfLevels
			}
		}
		return inputsOfLevels
	}
	
	//
	
	override getTemporaryQueryFilename(File modelFile) {
		return "." + modelFile.extensionlessName + ".i"
	}
	
	override getHelpCommand() {
		return #["python3", "-h"]
//		return #["imandra-cli", "-h"]
	}
	
	override getUnavailableBackendMessage() {
		return "The command line tool of Imandra ('Imandra') cannot be found. " +
				"Imandra can be downloaded from 'https://www.imandra.ai/'. "
	}
	
}