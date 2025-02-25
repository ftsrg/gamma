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
		
		# Delete the Imandra instance
		
		imandra.api.instance.delete(auth, instance['new_pod']['id'])
	'''
	
	public static val REGION_START = "> Region"
	public static val CONSTRAINT_START = "Constraints:"
	public static val INVARIANT_START = "Invariant:"
	public static val CONSTRAINT_DELIM = ";"
	
	/**
	 * For this call, the IMANDRA_API_KEY variable has to be set.
	 */
	static def String getDecompoiseCall(String model, String decomposeFunctionName, String assumingFunctionName) '''
		from imandra.core import Client
		
		client = Client()
		
		client.eval_src("""
			«model»
		""")
		
		decomposition = client.decompose("«decomposeFunctionName»"«
				IF assumingFunctionName !== null», "«assumingFunctionName»"«ENDIF»)
		
		for n, region in enumerate(decomposition.regions_str):
			print("«REGION_START»", n, "-" * 10 + "\n«CONSTRAINT_START»")
			for c in region.constraints_str:
				print("  ", c.strip(), "«CONSTRAINT_DELIM»")
			print("«INVARIANT_START»", "\n  ", region.invariant_str.strip())
	'''
	
}