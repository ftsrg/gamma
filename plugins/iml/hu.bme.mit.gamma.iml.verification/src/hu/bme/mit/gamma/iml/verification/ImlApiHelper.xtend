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

class ImlApiHelper {
	
	@Deprecated
	static def String getInvariantCall(String model, String command, String commandlessQuery) '''
		import imandra
		
		with imandra.session() as session:
			session.eval("""«System.lineSeparator»«model»""")
			result = session.«command»("«commandlessQuery»")
			print(result)
	'''
	
	/**
	 * For this call, the caller has to be logged in via the Imandra CLI.
	 */
	static def String getBasicCall(String src) '''
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