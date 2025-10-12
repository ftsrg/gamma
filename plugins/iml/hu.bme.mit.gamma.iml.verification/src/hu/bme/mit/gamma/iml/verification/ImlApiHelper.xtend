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

import java.util.List
import java.util.Map

class ImlApiHelper {
	
	protected static final String RET_VALUE = "- : "
	public static final String CX_START = "module CX :"
	public static final String CX_INIT_VAR = ImlApiHelper.RET_VALUE + "t =" // Used to be 'module CX :' before refactor
	public static final String CX_TRACE_VAR = ImlApiHelper.RET_VALUE + "t list ="
	
	protected static val MODULE_PREFIX = "M." // Given by Imandra
	
	static def String getInvariantCall(String model, String command, String commandlessQuery) {
		val DEFAULT_TIMEOUT = 300
		return model.getInvariantCall(command, commandlessQuery, DEFAULT_TIMEOUT)
	}
	
	/* ImandraX (new Imandra) - IMANDRA_API_KEY environment variable must be set */
	static def String getInvariantCall(String model, String command, String commandlessQuery, long timeout) '''
		from imandrax_api import Client
		# from imandra.core import Client
		
		def get_eval_res(eval, i=0):
			return eval.eval_results[i].value_as_ocaml
			
		def print_eval_res(eval, i=0):
			return print(get_eval_res(eval, i))
		
		client = Client(auth_token="«System.getenv("IMANDRA_API_KEY")»", url="https://api.dev.imandracapital.com/internal/imandrax", timeout=«timeout»)
		# client = Client(timeout=«timeout»)
		
		client.eval_src("""
			«model»
			«commandlessQuery.utilityMethods»
		""")
		check_res = client.«command»_src("«commandlessQuery»")
		«val attr = command.modelAttribute»
		if hasattr(check_res, '«attr»') and check_res.«attr».model.src:
			CX = check_res.«attr».model.src
			client.eval_src(CX)
			
			client.eval_src("let path = collect_path «
				FOR inputsOfLevels : commandlessQuery
					.parseInputsOfLevels
					.discardInputsAfterLoops(command) // Discarding events (path parts) after the first loop
					.values»«
						FOR inputOfLevels : inputsOfLevels»«
							IF inputOfLevels != "[]"»«MODULE_PREFIX»«inputOfLevels»«
							ELSE»[]«ENDIF» «ENDFOR»«ENDFOR»")
			
			eval_init_res = client.eval_src("eval(init)")
			log = client.eval_src("eval(log_run init path)")
			
			print("«CX_START»") # Metadata related to the trace
			print("«CX_INIT_VAR»")
			print_eval_res(eval_init_res)
			print("«CX_TRACE_VAR»")
			print_eval_res(log)
	'''
	
	protected static def getModelAttribute(String command) {
		return (command == "verify") ? "refuted" : "sat"
	}
	
	protected static def getUtilityMethods(String query) { // TODO move to Prop-ser
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
	
	protected static def parseInputs(String query) {
		val FUN = "fun"
		val ARROW = "->"
		
		val funIndex = query.indexOf(FUN)
		val lastIndex = query.indexOf(ARROW)
		val input = query.substring(funIndex + FUN.length, lastIndex).trim
		
		return input
	}
	
	protected static def parseInputsOfLevels(String query) {
		val input = query.parseInputs
		val inputs = input.split("\\s")
		// Sorted map needed!
		val inputsOfLevels = inputs.groupBy[
				Integer.valueOf(it.split("\\_").get(1))] // TODO based on ImlPropertySerializer.getInputId
		
		return inputsOfLevels
	}
	
	protected static def discardInputsAfterLoops(Map<Integer, List<String>> inputsOfLevels, String command) {
		val loopOperators = (command.contains("verify")) ?
				#[ "F", "U", "SR" ] : #[ "G", "R", "WU" ]
		for (level : inputsOfLevels.keySet) {
			val inputs = inputsOfLevels.get(level)
			if (inputs.exists[
					loopOperators.contains(it.split("\\_").get(2))]) {// TODO based on ImlPropertySerializer.getInputId
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
	
	static def String getBasicInvariantCall(String parameters, String modelString, String command, String commandlessQuery) {
		val arguments = parameters.parseArguments
		val callArguments = arguments.key
		val postCallArguments = arguments.value
		
		return ImlApiHelper.getBasicCall('''
			«modelString»;;
			«commandlessQuery.utilityMethods»
			«command»«IF !callArguments.nullOrEmpty» «callArguments» «ENDIF»(«commandlessQuery»)«postCallArguments»;;
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
	
	protected static def parseArguments(String arguments) {
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
	
	/**
	 * For this call, the caller has to be logged in via the Imandra CLI (old Imandra).
	 */
	protected static def String getBasicCall(String src) '''
		import sys
		import imandra.api.auth
		import imandra.api.instance
		import imandra_http_api_client
		
		# Starting an Imandra instance
		
		auth = imandra.api.auth.Auth()
		auth.ensure_folder()
		auth.ensure_token()
		auth.ensure_zone()
		
		instance = imandra.api.instance.create(auth, None, "imandra-http-api")
		
		config = imandra_http_api_client.Configuration(
			host = instance['new_pod']['url'],
			access_token = instance['new_pod']['exchange_token'],
		)
		
		# Doing the low-level call to the API
		
		src = """
			«src»
		"""
		
		with imandra_http_api_client.ApiClient(config) as api_client:
			api_instance = imandra_http_api_client.DefaultApi(api_client)
			req = {
				"src": src,
				"syntax": "iml",
				"hints": {
					"method": {
						"type": "auto"
					}
				}
			}
			request_src = imandra_http_api_client.EvalRequestSrc.from_dict(req)
			try:
				api_response = api_instance.eval_with_http_info(request_src)
			except Exception as e:
				print("Exception when calling DefaultApi->eval_with_http_info: %s\n" % e)
		
		# json parse the raw_data yourself and take the raw_stdio
		
		import json
		raw_response = json.loads(api_response.raw_data)
		
		print(raw_response.get("raw_stdio"))
		
		error = raw_response.get("error")
		if error != None:
			print(error, file=sys.stderr)
		
		# Delete all alive Imandra instances (note: not thread-safe)
		
		alive_instances = imandra.api.instance.list(auth)
		for alive_instance in alive_instances:
			imandra.api.instance.delete(auth, alive_instance['pod_id'])
	'''
	
	public static val REGION_START = "> Region"
	public static val CONSTRAINT_START = "Constraints:"
	public static val INVARIANT_START = "Invariant:"
	public static val CONSTRAINT_DELIM = "@"
	
	static def String getDecomposeCall(String model, String decomposeFunctionName) {
		return model.getDecomposeCall(decomposeFunctionName, null)
	}
	
	/**
	 * For this call, the IMANDRA_API_KEY variable has to be set.
	 */
	static def String getDecomposeCall(String model, String decomposeFunctionName, String assumingFunctionName) '''
		import imandrax_api.lib as xtypes
		from imandra.core import Client
«««		from imandra.core import Client, xtypes
		
		client = Client()
		
		client.eval_src("""
			«model»
		""")
		
		decomposition = client.decompose("«decomposeFunctionName»"«
				IF assumingFunctionName !== null», "«assumingFunctionName»"«ENDIF», prune=True, ctx_simp=True)
		art = xtypes.read_artifact_data(data=decomposition.artifact.data, kind=decomposition.artifact.kind)
		regions = []
		
		for region in art.regions:
			raw = dict(dict(region.meta).get('str').arg)
			parsed_region = {
				'constraints': [c.arg for c in raw['constraints'].arg],
				'invariant': raw['invariant'].arg,
				'model': dict([(k,v.arg) for (k,v) in raw['model'].arg]),
				'model_eval': raw['model_eval'].arg
			}
			regions.append(parsed_region)
		
		n = 0
		for region in regions:
			n = n + 1
			print("«REGION_START»", n, "-" * 10 + "\n«CONSTRAINT_START»")
			for constraint in region['constraints']:
				print("  ", constraint.strip(), "«CONSTRAINT_DELIM»")
			print("«INVARIANT_START»", "\n  ", region['invariant'])
	'''
	
}