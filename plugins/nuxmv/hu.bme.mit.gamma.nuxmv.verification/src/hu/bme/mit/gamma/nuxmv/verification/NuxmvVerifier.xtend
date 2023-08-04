/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.nuxmv.verification

import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import java.util.Scanner
import java.util.logging.Level

class NuxmvVerifier extends AbstractVerifier {
	//
	public static final String CHECK_UNTIMED_LTL = "check_ltlspec_ic3 -p"
	public static final String CHECK_UNTIMED_LTL_AS_INVAR = "check_property_as_invar_ic3 -L"
	
	public static final String CHECK_TIMED_LTL = "timed_check_ltlspec -p"
	public static final String CHECK_TIMED_INVAR = "timed_check_invar -p"
	
	public static final String NUXMV_SETUP_UNTIMED = "go_msat"
	public static final String NUXMV_SETUP_TIMED = /*"time_setup" + System.lineSeparator +*/ "go_time"
	
	//
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	
	// save trace to file
	protected val saveTrace = true
	
	override verifyQuery(Object traceability, String parameters, File modelFile, File queryFile) {
		val query = fileUtil.loadString(queryFile)
		var Result result = null
		
		// Adding all the queries to the end of the model file
		for (singleQuery : query.split(System.lineSeparator).reject[it.nullOrEmpty]) {
			//
			val isPropertyConvertible = modelFile.isConvertibleIntoInvariant(singleQuery, parameters)
			//
			val possiblyCovertedParameters = (isPropertyConvertible && parameters == CHECK_UNTIMED_LTL) ?
					CHECK_UNTIMED_LTL_AS_INVAR : parameters // TODO timed
			
			//
			val newResult = traceability.verifyQuery(possiblyCovertedParameters, modelFile, singleQuery)
			//
			
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
	
	// set on_failure_script_quits
	// set input_file "C:\Users\grben\eclipse_ws\fbk_ws\runtime-New_configuration\MyAsyncProject\NuSMV3-XSAP\Files\AOCS.smv"
	// go_msat
	// set default_trace_plugin 1 // This will make the trace contain all variables, not just the delta
	// check_invar_ic3 -i -p "(signal < 12.0) IN AOCS"
	// show_traces -p 4 -o "C:\Users\grben\eclipse_ws\fbk_ws\runtime-New_configuration\Temp\nuXmv_538c61488341a235\result_26ee62675985ecf2.xml"
	// quit
	override verifyQuery(Object traceability, String parameters, File modelFile, String query) {
		val extension queryAdapter = new LtlQueryAdapter
		//
		val adaptedQuery = query.adaptQuery
		val modelCheckingCommand = '''«parameters» "«adaptedQuery»"''' // "parameters" contains the -p/-L flag
		// Creating the configuration file
		val parentFile = modelFile.parent
		val commandFile = new File(parentFile + File.separator + '''.nuXmv-commands-«Thread.currentThread.name».cmd''')
		commandFile.deleteOnExit
		
		val serializedCommand = '''
			set on_failure_script_quits
			set input_file "«modelFile.absolutePath»"
			«parameters.setupCommand»
			set default_trace_plugin 1
			«modelCheckingCommand»
			quit
		'''
		fileUtil.saveString(commandFile, serializedCommand)
		
		// nuXmv [-time] -source commands.cmd
		val commandExtension = parameters.commandLineArgumentExtension
		val nuXmvCommandExtension = commandExtension.nullOrEmpty ? #[] : #[commandExtension]
		val nuXmvCommand = #["nuXmv"] + nuXmvCommandExtension + #["-source", commandFile.absolutePath]
		logger.log(Level.INFO, "Running nuXmv: " + nuXmvCommand.join(" "))
		
		var Scanner resultReader = null
		
		var Result traceResult = null
		
		try {
			process = Runtime.getRuntime().exec(nuXmvCommand)
			
			// Reading the result of the command
			resultReader = new Scanner(process.inputReader)
			
			val resultPattern = '''.*specification.*is.*'''
			var resultFound = false
			result  = ThreeStateBoolean.UNDEF
			while (!resultFound && resultReader.hasNextLine) {
				val line = resultReader.nextLine
				logger.log(Level.INFO, "nuXmv: " + line)
				if (line.matches(resultPattern)) {
					resultFound = true
					if (line.endsWith("true")) {
						result  = ThreeStateBoolean.TRUE
					}
					else if (line.endsWith("false")) {
						result  = ThreeStateBoolean.FALSE
					} // In case of any other outcome, the result will remain undef
				}
			}
			if (!resultFound) {
				logger.log(Level.SEVERE, "nuXmv could not verify the model with the property: " + query)
			}
			result = result.adaptResult
			//
			
			val gammaPackage = traceability as Package
			val backAnnotator = new TraceBackAnnotator(gammaPackage, resultReader)
			val trace = backAnnotator.execute
			
			traceResult = new Result(result, trace)
			
			logger.log(Level.INFO, "Quitting nuXmv shell")
		} finally {
			resultReader?.close
			cancel
		}
		
		return traceResult
	}
	
	override getTemporaryQueryFilename(File modelFile) {
		return "." + modelFile.extensionlessName + ".s"
	}
	
	//
	
	protected def isConvertibleIntoInvariant(File modelFile, String query, String argument) {
		val extension queryAdapter = new LtlQueryAdapter // We expect a CTL property
		//
		val parentFile = modelFile.parent
		val commandFile = new File(parentFile + File.separator + '''.nuXmv-invar-«Thread.currentThread.name».cmd''')
		commandFile.deleteOnExit
		
		val serializedCommand = '''
			set on_failure_script_quits
			set input_file "«modelFile.absolutePath»"
			«argument.setupCommand»
			convert_property_to_invar -l -p "«query.adaptQuery»"
			show_property -n 0 -F tabular
			quit
		'''
		fileUtil.saveString(commandFile, serializedCommand)
		
		val commandExtension = argument.commandLineArgumentExtension
		val nuXmvCommandExtension = commandExtension.nullOrEmpty ? #[] : #[commandExtension]
		val nuXmvCommand = #["nuXmv"] + nuXmvCommandExtension + #["-source", commandFile.absolutePath]
		logger.log(Level.INFO, "Running nuXmv to convert property to invariance: " + nuXmvCommand.join(" "))
		
		var Scanner resultReader = null
		
		try {
			val PROPERTY_START = "000 :"
			val PARSING_ERROR = "Parsing error:"
			val ERROR = "Error:"
			
			val process = Runtime.getRuntime().exec(nuXmvCommand)
			resultReader = new Scanner(process.inputReader)
			var line = ""
			while (!line.startsWith(PROPERTY_START) &&
					!line.startsWith(PARSING_ERROR) && !line.startsWith(ERROR)) {
				line = resultReader.nextLine
				logger.log(Level.OFF, "nuXmv: " + line)
			}
			if (line.startsWith(PROPERTY_START)) {
//				return line.substring(PROPERTY_START.length)
				logger.log(Level.INFO, "Property is convertible to safety property: " + line.substring(PROPERTY_START.length))
				return true
			}
			else {
				logger.log(Level.INFO, "Property is not convertible to safety property")
				return false
			}
		} catch (Exception e) {
			return false
		} finally {
			resultReader?.close
		}
	}
	
	//
	
	protected def getSetupCommand(String argument) {
		switch (argument) {
			case CHECK_UNTIMED_LTL, case CHECK_UNTIMED_LTL_AS_INVAR:
				return NUXMV_SETUP_UNTIMED
			case CHECK_TIMED_LTL, case CHECK_TIMED_INVAR:
				return NUXMV_SETUP_TIMED
			default:
				return NUXMV_SETUP_UNTIMED
		}
	}
	
	protected def getCommandLineArgumentExtension(String argument) {
		switch (argument) {
			case CHECK_TIMED_LTL, case CHECK_TIMED_INVAR:
				return "-time"
			default:
				return ""
		}
	}
	
}