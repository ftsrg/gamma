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
import java.util.Scanner

class ImlVerifier extends AbstractVerifier {
	//
	protected final static extension FileUtil fileUtil = FileUtil.INSTANCE
	//
	
	override verifyQuery(Object traceability, String parameters, File modelFile, File queryFile) {
		val query = fileUtil.loadString(queryFile)
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
		val modelString = fileUtil.loadString(modelFile)
		
		val command = query.substring(0, query.indexOf("("))
		val commandelssQuery = query.substring(command.length)
		
		val parentFile = modelFile.parentFile
		val pythonFile = new File(parentFile + File.separator + '''.imandra-commands-«Thread.currentThread.name».py''')
		pythonFile.deleteOnExit
		
		val serializedPython = getTracedCode(modelString, command, parameters, commandelssQuery)
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
			errorReader = new ScannerLogger(new Scanner(process.errorReader), "ValueError: ",  true)
			errorReader.start
			
			result = ThreeStateBoolean.UNDEF
			
			val gammaPackage = traceability as Package
			val backAnnotator = new TraceBackAnnotator(gammaPackage, resultReader)
			val trace = backAnnotator.synchronizeAndExecute
			
			if (!errorReader.error) {
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
		}
		
		return traceResult
	}
	
	protected def String getBasicCode(String modelString, String command, String commandlessQuery) '''
		import imandra
		
		with imandra.session() as session:
			session.eval("""«System.lineSeparator»«modelString»""")
			result = session.«command»("«commandlessQuery»")
			print(result)
	'''
	
	protected def String getTracedCode(String modelString, String command, String arguments, String commandlessQuery) '''
		import imandra.auth
		import imandra.instance
		import imandra_http_api_client
		
		# Starting an Imandra instance
		
		auth = imandra.auth.Auth()
		instance = imandra.instance.create(auth, None, "imandra-http-api")
		
		config = imandra_http_api_client.Configuration(
		    host = instance['new_pod']['url'],
		    access_token = instance['new_pod']['exchange_token'],
		)
		
		# Doing the low-level call to the API
		
		src = """
			«modelString»;;
			#trace trans;;
			«command»«IF !arguments.nullOrEmpty» «arguments» «ENDIF»(«commandlessQuery»);; (* Looks for trace *)
		"""
		# run init CX.e # We do not have to replay this trace (e due to 'fun e')
		
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
		    except ApiException as e:
		        print("Exception when calling DefaultApi->eval_with_http_info: %s\n" % e)
		
		# json parse the raw_data yourself and take the raw_stdio
		
		import json
		raw_response = json.loads(api_response.raw_data)
		print(raw_response.get("raw_stdio"))
		
		# Delete the Imandra instance
		
		imandra.instance.delete(auth, instance['new_pod']['id'])
	'''
	
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
	
	//
	
	protected def getDebuggingTrace() {
		return new Scanner('''
			- : e list -> bool = <fun>
			trans <--
			  {_SecondaryPolice_police_Out_controller_control = false;
			   _PriorityPolice_police_Out_controller_control = false;
			   _PoliceInterrupt_police_In_controller_control = false;
			   _PriorityControl_toggle_Out_controller_control = false;
			   _SecondaryControl_toggle_Out_controller_control = false;
			   _main_region_controller_control = M_Main_region_Controller.L_Operating;
			   _operating_controller_control = M_Operating_Controller.L_Init;
			   _r_controller_control = M_R_Controller.L_G_;
			   _SecondaryPreparesTimeout3_controller_control = 0;
			   _LightCommands_displayNone_Out_prior_trafficLightCtrl = false;
			   _LightCommands_displayYellow_Out_prior_trafficLightCtrl = false;
			   _LightCommands_displayGreen_Out_prior_trafficLightCtrl = false;
			   _Control_toggle_In_prior_trafficLightCtrl = false;
			   _PoliceInterrupt_police_In_prior_trafficLightCtrl = false;
			   _LightCommands_displayRed_Out_prior_trafficLightCtrl = true;
			   _main_region_prior_trafficLightCtrl =
			    M_Main_region_TrafficLightCtrl.L_Normal;
			   _interrupted_prior_trafficLightCtrl =
			    M_Interrupted_TrafficLightCtrl.L___Inactive__;
			   _normal_prior_trafficLightCtrl = M_Normal_TrafficLightCtrl.L_Red;
			   _c_prior_trafficLightCtrl = 0; _b_prior_trafficLightCtrl = 0;
			   _a_prior_trafficLightCtrl = false;
			   _BlinkingYellowTimeout3_prior_trafficLightCtrl = 500;
			   _Control_toggle_In_second_trafficLightCtrl = false;
			   _LightCommands_displayNone_Out_second_trafficLightCtrl = false;
			   _LightCommands_displayYellow_Out_second_trafficLightCtrl = false;
			   _PoliceInterrupt_police_In_second_trafficLightCtrl = false;
			   _LightCommands_displayRed_Out_second_trafficLightCtrl = true;
			   _LightCommands_displayGreen_Out_second_trafficLightCtrl = false;
			   _main_region_second_trafficLightCtrl =
			    M_Main_region_TrafficLightCtrl.L_Normal;
			   _normal_second_trafficLightCtrl = M_Normal_TrafficLightCtrl.L_Red;
			   _interrupted_second_trafficLightCtrl =
			    M_Interrupted_TrafficLightCtrl.L___Inactive__;
			   _a_second_trafficLightCtrl = false; _c_second_trafficLightCtrl = 0;
			   _b_second_trafficLightCtrl = 0;
			   _BlinkingYellowTimeout3_second_trafficLightCtrl = 500;
			   _master_messageQueueOfcontroller =
			    M_EventIdTypeOfmaster_messageQueueOfcontroller.L__1;
			   _master_messageQueueOfprior =
			    [M_EventIdTypeOfmaster_messageQueueOfprior.L__1];
			   _master_messageQueueOfsecond = []}
			trans -->
			  {_SecondaryPolice_police_Out_controller_control = false;
			   _PriorityPolice_police_Out_controller_control = false;
			   _PoliceInterrupt_police_In_controller_control = false;
			   _PriorityControl_toggle_Out_controller_control = false;
			   _SecondaryControl_toggle_Out_controller_control = false;
			   _main_region_controller_control = M_Main_region_Controller.L_Operating;
			   _operating_controller_control = M_Operating_Controller.L_PriorityPrepares;
			   _r_controller_control = M_R_Controller.L___Inactive__;
			   _SecondaryPreparesTimeout3_controller_control = 0;
			   _LightCommands_displayNone_Out_prior_trafficLightCtrl = false;
			   _LightCommands_displayYellow_Out_prior_trafficLightCtrl = false;
			   _LightCommands_displayGreen_Out_prior_trafficLightCtrl = true;
			   _Control_toggle_In_prior_trafficLightCtrl = false;
			   _PoliceInterrupt_police_In_prior_trafficLightCtrl = false;
			   _LightCommands_displayRed_Out_prior_trafficLightCtrl = false;
			   _main_region_prior_trafficLightCtrl =
			    M_Main_region_TrafficLightCtrl.L_Normal;
			   _interrupted_prior_trafficLightCtrl =
			    M_Interrupted_TrafficLightCtrl.L___Inactive__;
			   _normal_prior_trafficLightCtrl = M_Normal_TrafficLightCtrl.L_Green;
			   _c_prior_trafficLightCtrl = 0; _b_prior_trafficLightCtrl = 0;
			   _a_prior_trafficLightCtrl = true;
			   _BlinkingYellowTimeout3_prior_trafficLightCtrl = 500;
			   _Control_toggle_In_second_trafficLightCtrl = false;
			   _LightCommands_displayNone_Out_second_trafficLightCtrl = false;
			   _LightCommands_displayYellow_Out_second_trafficLightCtrl = false;
			   _PoliceInterrupt_police_In_second_trafficLightCtrl = false;
			   _LightCommands_displayRed_Out_second_trafficLightCtrl = true;
			   _LightCommands_displayGreen_Out_second_trafficLightCtrl = false;
			   _main_region_second_trafficLightCtrl =
			    M_Main_region_TrafficLightCtrl.L_Normal;
			   _normal_second_trafficLightCtrl = M_Normal_TrafficLightCtrl.L_Red;
			   _interrupted_second_trafficLightCtrl =
			    M_Interrupted_TrafficLightCtrl.L___Inactive__;
			   _a_second_trafficLightCtrl = false; _c_second_trafficLightCtrl = 0;
			   _b_second_trafficLightCtrl = 0;
			   _BlinkingYellowTimeout3_second_trafficLightCtrl = 500;
			   _master_messageQueueOfcontroller =
			    M_EventIdTypeOfmaster_messageQueueOfcontroller.L_EMPTY;
			   _master_messageQueueOfprior =
			    [M_EventIdTypeOfmaster_messageQueueOfprior.L__1];
			   _master_messageQueueOfsecond = []}
			trans <--
			  {_SecondaryPolice_police_Out_controller_control = false;
			   _PriorityPolice_police_Out_controller_control = false;
			   _PoliceInterrupt_police_In_controller_control = false;
			   _PriorityControl_toggle_Out_controller_control = false;
			   _SecondaryControl_toggle_Out_controller_control = false;
			   _main_region_controller_control = M_Main_region_Controller.L_Operating;
			   _operating_controller_control = M_Operating_Controller.L_PriorityPrepares;
			   _r_controller_control = M_R_Controller.L___Inactive__;
			   _SecondaryPreparesTimeout3_controller_control = 0;
			   _LightCommands_displayNone_Out_prior_trafficLightCtrl = false;
			   _LightCommands_displayYellow_Out_prior_trafficLightCtrl = false;
			   _LightCommands_displayGreen_Out_prior_trafficLightCtrl = true;
			   _Control_toggle_In_prior_trafficLightCtrl = false;
			   _PoliceInterrupt_police_In_prior_trafficLightCtrl = false;
			   _LightCommands_displayRed_Out_prior_trafficLightCtrl = false;
			   _main_region_prior_trafficLightCtrl =
			    M_Main_region_TrafficLightCtrl.L_Normal;
			   _interrupted_prior_trafficLightCtrl =
			    M_Interrupted_TrafficLightCtrl.L___Inactive__;
			   _normal_prior_trafficLightCtrl = M_Normal_TrafficLightCtrl.L_Green;
			   _c_prior_trafficLightCtrl = 0; _b_prior_trafficLightCtrl = 0;
			   _a_prior_trafficLightCtrl = true;
			   _BlinkingYellowTimeout3_prior_trafficLightCtrl = 500;
			   _Control_toggle_In_second_trafficLightCtrl = false;
			   _LightCommands_displayNone_Out_second_trafficLightCtrl = false;
			   _LightCommands_displayYellow_Out_second_trafficLightCtrl = false;
			   _PoliceInterrupt_police_In_second_trafficLightCtrl = false;
			   _LightCommands_displayRed_Out_second_trafficLightCtrl = true;
			   _LightCommands_displayGreen_Out_second_trafficLightCtrl = false;
			   _main_region_second_trafficLightCtrl =
			    M_Main_region_TrafficLightCtrl.L_Normal;
			   _normal_second_trafficLightCtrl = M_Normal_TrafficLightCtrl.L_Red;
			   _interrupted_second_trafficLightCtrl =
			    M_Interrupted_TrafficLightCtrl.L___Inactive__;
			   _a_second_trafficLightCtrl = false; _c_second_trafficLightCtrl = 0;
			   _b_second_trafficLightCtrl = 0;
			   _BlinkingYellowTimeout3_second_trafficLightCtrl = 500;
			   _master_messageQueueOfcontroller =
			    M_EventIdTypeOfmaster_messageQueueOfcontroller.L__1;
			   _master_messageQueueOfprior =
			    [M_EventIdTypeOfmaster_messageQueueOfprior.L__1];
			   _master_messageQueueOfsecond = []}
			trans -->
			  {_SecondaryPolice_police_Out_controller_control = false;
			   _PriorityPolice_police_Out_controller_control = false;
			   _PoliceInterrupt_police_In_controller_control = false;
			   _PriorityControl_toggle_Out_controller_control = false;
			   _SecondaryControl_toggle_Out_controller_control = false;
			   _main_region_controller_control = M_Main_region_Controller.L_Operating;
			   _operating_controller_control = M_Operating_Controller.L_Secondary;
			   _r_controller_control = M_R_Controller.L___Inactive__;
			   _SecondaryPreparesTimeout3_controller_control = 0;
			   _LightCommands_displayNone_Out_prior_trafficLightCtrl = false;
			   _LightCommands_displayYellow_Out_prior_trafficLightCtrl = true;
			   _LightCommands_displayGreen_Out_prior_trafficLightCtrl = false;
			   _Control_toggle_In_prior_trafficLightCtrl = false;
			   _PoliceInterrupt_police_In_prior_trafficLightCtrl = false;
			   _LightCommands_displayRed_Out_prior_trafficLightCtrl = false;
			   _main_region_prior_trafficLightCtrl =
			    M_Main_region_TrafficLightCtrl.L_Normal;
			   _interrupted_prior_trafficLightCtrl =
			    M_Interrupted_TrafficLightCtrl.L___Inactive__;
			   _normal_prior_trafficLightCtrl = M_Normal_TrafficLightCtrl.L_Yellow;
			   _c_prior_trafficLightCtrl = 0; _b_prior_trafficLightCtrl = 4;
			   _a_prior_trafficLightCtrl = true;
			   _BlinkingYellowTimeout3_prior_trafficLightCtrl = 500;
			   _Control_toggle_In_second_trafficLightCtrl = false;
			   _LightCommands_displayNone_Out_second_trafficLightCtrl = false;
			   _LightCommands_displayYellow_Out_second_trafficLightCtrl = false;
			   _PoliceInterrupt_police_In_second_trafficLightCtrl = false;
			   _LightCommands_displayRed_Out_second_trafficLightCtrl = false;
			   _LightCommands_displayGreen_Out_second_trafficLightCtrl = true;
			   _main_region_second_trafficLightCtrl =
			    M_Main_region_TrafficLightCtrl.L_Normal;
			   _normal_second_trafficLightCtrl = M_Normal_TrafficLightCtrl.L_Green;
			   _interrupted_second_trafficLightCtrl =
			    M_Interrupted_TrafficLightCtrl.L___Inactive__;
			   _a_second_trafficLightCtrl = true; _c_second_trafficLightCtrl = 0;
			   _b_second_trafficLightCtrl = 0;
			   _BlinkingYellowTimeout3_second_trafficLightCtrl = 500;
			   _master_messageQueueOfcontroller =
			    M_EventIdTypeOfmaster_messageQueueOfcontroller.L_EMPTY;
			   _master_messageQueueOfprior =
			    [M_EventIdTypeOfmaster_messageQueueOfprior.L__1];
			   _master_messageQueueOfsecond = []}
			trans <--
			  {_SecondaryPolice_police_Out_controller_control = false;
			   _PriorityPolice_police_Out_controller_control = false;
			   _PoliceInterrupt_police_In_controller_control = false;
			   _PriorityControl_toggle_Out_controller_control = false;
			   _SecondaryControl_toggle_Out_controller_control = false;
			   _main_region_controller_control = M_Main_region_Controller.L_Operating;
			   _operating_controller_control = M_Operating_Controller.L_Secondary;
			   _r_controller_control = M_R_Controller.L___Inactive__;
			   _SecondaryPreparesTimeout3_controller_control = 0;
			   _LightCommands_displayNone_Out_prior_trafficLightCtrl = false;
			   _LightCommands_displayYellow_Out_prior_trafficLightCtrl = true;
			   _LightCommands_displayGreen_Out_prior_trafficLightCtrl = false;
			   _Control_toggle_In_prior_trafficLightCtrl = false;
			   _PoliceInterrupt_police_In_prior_trafficLightCtrl = false;
			   _LightCommands_displayRed_Out_prior_trafficLightCtrl = false;
			   _main_region_prior_trafficLightCtrl =
			    M_Main_region_TrafficLightCtrl.L_Normal;
			   _interrupted_prior_trafficLightCtrl =
			    M_Interrupted_TrafficLightCtrl.L___Inactive__;
			   _normal_prior_trafficLightCtrl = M_Normal_TrafficLightCtrl.L_Yellow;
			   _c_prior_trafficLightCtrl = 0; _b_prior_trafficLightCtrl = 4;
			   _a_prior_trafficLightCtrl = true;
			   _BlinkingYellowTimeout3_prior_trafficLightCtrl = 500;
			   _Control_toggle_In_second_trafficLightCtrl = false;
			   _LightCommands_displayNone_Out_second_trafficLightCtrl = false;
			   _LightCommands_displayYellow_Out_second_trafficLightCtrl = false;
			   _PoliceInterrupt_police_In_second_trafficLightCtrl = false;
			   _LightCommands_displayRed_Out_second_trafficLightCtrl = false;
			   _LightCommands_displayGreen_Out_second_trafficLightCtrl = true;
			   _main_region_second_trafficLightCtrl =
			    M_Main_region_TrafficLightCtrl.L_Normal;
			   _normal_second_trafficLightCtrl = M_Normal_TrafficLightCtrl.L_Green;
			   _interrupted_second_trafficLightCtrl =
			    M_Interrupted_TrafficLightCtrl.L___Inactive__;
			   _a_second_trafficLightCtrl = true; _c_second_trafficLightCtrl = 0;
			   _b_second_trafficLightCtrl = 0;
			   _BlinkingYellowTimeout3_second_trafficLightCtrl = 500;
			   _master_messageQueueOfcontroller =
			    M_EventIdTypeOfmaster_messageQueueOfcontroller.L__1;
			   _master_messageQueueOfprior =
			    [M_EventIdTypeOfmaster_messageQueueOfprior.L__1];
			   _master_messageQueueOfsecond = []}
			trans -->
			  {_SecondaryPolice_police_Out_controller_control = false;
			   _PriorityPolice_police_Out_controller_control = false;
			   _PoliceInterrupt_police_In_controller_control = false;
			   _PriorityControl_toggle_Out_controller_control = false;
			   _SecondaryControl_toggle_Out_controller_control = false;
			   _main_region_controller_control = M_Main_region_Controller.L_Operating;
			   _operating_controller_control = M_Operating_Controller.L_SecondaryPrepares;
			   _r_controller_control = M_R_Controller.L___Inactive__;
			   _SecondaryPreparesTimeout3_controller_control = 0;
			   _LightCommands_displayNone_Out_prior_trafficLightCtrl = false;
			   _LightCommands_displayYellow_Out_prior_trafficLightCtrl = false;
			   _LightCommands_displayGreen_Out_prior_trafficLightCtrl = false;
			   _Control_toggle_In_prior_trafficLightCtrl = false;
			   _PoliceInterrupt_police_In_prior_trafficLightCtrl = false;
			   _LightCommands_displayRed_Out_prior_trafficLightCtrl = true;
			   _main_region_prior_trafficLightCtrl =
			    M_Main_region_TrafficLightCtrl.L_Normal;
			   _interrupted_prior_trafficLightCtrl =
			    M_Interrupted_TrafficLightCtrl.L___Inactive__;
			   _normal_prior_trafficLightCtrl = M_Normal_TrafficLightCtrl.L_Red;
			   _c_prior_trafficLightCtrl = 0; _b_prior_trafficLightCtrl = 4;
			   _a_prior_trafficLightCtrl = true;
			   _BlinkingYellowTimeout3_prior_trafficLightCtrl = 500;
			   _Control_toggle_In_second_trafficLightCtrl = false;
			   _LightCommands_displayNone_Out_second_trafficLightCtrl = false;
			   _LightCommands_displayYellow_Out_second_trafficLightCtrl = true;
			   _PoliceInterrupt_police_In_second_trafficLightCtrl = false;
			   _LightCommands_displayRed_Out_second_trafficLightCtrl = false;
			   _LightCommands_displayGreen_Out_second_trafficLightCtrl = false;
			   _main_region_second_trafficLightCtrl =
			    M_Main_region_TrafficLightCtrl.L_Normal;
			   _normal_second_trafficLightCtrl = M_Normal_TrafficLightCtrl.L_Yellow;
			   _interrupted_second_trafficLightCtrl =
			    M_Interrupted_TrafficLightCtrl.L___Inactive__;
			   _a_second_trafficLightCtrl = true; _c_second_trafficLightCtrl = 0;
			   _b_second_trafficLightCtrl = 4;
			   _BlinkingYellowTimeout3_second_trafficLightCtrl = 500;
			   _master_messageQueueOfcontroller =
			    M_EventIdTypeOfmaster_messageQueueOfcontroller.L_EMPTY;
			   _master_messageQueueOfprior = []; _master_messageQueueOfsecond = []}
			module CX : sig val e : e list end
			Instance (after 38 steps, 10.477s):
			let e : e list =
			  let (_x_0 : e)
			      = {_eventId_master_messageQueueOfcontroller_1334575416_1563506344 =
			         M_EventIdTypeOfmaster_messageQueueOfcontroller.L__1}
			  in [_x_0; _x_0; _x_0]
		''')
	}
	
}