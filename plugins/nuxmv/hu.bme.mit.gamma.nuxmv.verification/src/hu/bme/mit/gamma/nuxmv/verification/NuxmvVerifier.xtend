/********************************************************************************
 * Copyright (c) 2023-2024 Contributors to the Gamma project
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
import hu.bme.mit.gamma.util.ScannerLogger
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import java.util.Scanner

class NuxmvVerifier extends AbstractVerifier {
	//
	public static final String CHECK_UNTIMED_LTL = "check_ltlspec_ic3 -p"
	public static final String CHECK_UNTIMED_INVAR = "check_invar_ic3 -p"
	public static final String CHECK_UNTIMED_LTL_AS_INVAR = "check_property_as_invar_ic3 -L" // Currently unused
	
	public static final String CHECK_TIMED_LTL = "timed_check_ltlspec -p"
	public static final String CHECK_TIMED_INVAR = "timed_check_invar -a 1 -p" // -a 1 enables abstraction/refinement; needed for integers
	
	public static final String NUXMV_SETUP_UNTIMED = "go_msat"
	public static final String NUXMV_SETUP_TIMED = /*"time_setup" + System.lineSeparator +*/ "go_time"
	
	public static final String NUXMV_TEMPORARY_COMMAND_FOLDER = ".nuXmv"
	
	//
	protected final static extension FileUtil fileUtil = FileUtil.INSTANCE
	//
	
	override verifyQuery(Object traceability, String parameters, File modelFile, File queryFile) {
		val query = fileUtil.loadString(queryFile)
		var Result result = null
		
		// Adding all the queries to the end of the model file
		for (singleQuery : query.splitLines) {
			//
			val conversionResult = modelFile.convertToInvariant(singleQuery, parameters)
			val convertedProperty = conversionResult?.key
			val isPropertyInverted = conversionResult?.value?.booleanValue
			val isPropertyUnconvertible = convertedProperty.nullOrEmpty
			//
			
			val possiblyCovertedParameters = if (isPropertyUnconvertible) {
				parameters
			} else if (parameters == CHECK_UNTIMED_LTL) {
				CHECK_UNTIMED_INVAR
			} else if (parameters == CHECK_TIMED_LTL) {
				CHECK_TIMED_INVAR
			} else {
				parameters
			}
			
			val possiblyConvertedProperty = (isPropertyUnconvertible) ? singleQuery : convertedProperty
			
			//
			var newResult = traceability.verifyQuery(possiblyCovertedParameters, modelFile, possiblyConvertedProperty)
			if (isPropertyInverted) { // Needed due to potential invar adaptation
				newResult = newResult.invert // Adaptation
			}
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
	
	override verifyQuery(Object traceability, String parameters, File modelFile, String query) {
		val extension queryAdapter = new LtlQueryAdapter
		//
		val adaptedQuery = query.adaptQuery
		val modelCheckingCommand = '''«parameters» "«adaptedQuery»"''' // "parameters" contains the -p/-L flag
		// Creating the configuration file
		val parentFile = modelFile.parent + File.separator + NUXMV_TEMPORARY_COMMAND_FOLDER
		val commandFile = new File(parentFile, '''.nuXmv-commands-«Thread.currentThread.name».cmd''')
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
		logger.info("Running nuXmv: " + nuXmvCommand.join(" "))
		
		var Scanner resultReader = null
		var ScannerLogger errorReader = null
		var Result traceResult = null
		
		try {
			process = Runtime.getRuntime().exec(nuXmvCommand)
			
			// Reading the result of the command
			resultReader = new Scanner(process.inputReader)
			errorReader = new ScannerLogger(new Scanner(process.errorReader), true)
			errorReader.start
			
			val resultPattern = '''(.*invariant.*is.*)|(.*specification.*is.*)'''
			var resultFound = false
			result  = ThreeStateBoolean.UNDEF
			while (!resultFound && resultReader.hasNextLine) {
				val line = resultReader.nextLine
				if (!line.nullOrEmpty && !line.startsWith("***")) { // No header printing
					logger.info("nuXmv: " + line)
				}
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
				logger.severe("nuXmv could not verify the model with the property: " + query)
			}
			result = result.adaptResult
			//
			
			val gammaPackage = traceability as Package
			val backAnnotator = new TraceBackAnnotator(gammaPackage, resultReader)
			val trace = backAnnotator.synchronizeAndExecute
			
			traceResult = new Result(result, trace)
			
			logger.info("Quitting nuXmv shell")
		} finally {
			resultReader?.close
			errorReader?.cancel
			cancel
		}
		
		return traceResult
	}
	
	override getTemporaryQueryFilename(File modelFile) {
		return "." + modelFile.extensionlessName + ".s"
	}
	
	//
	
	protected def convertToInvariant(File modelFile, String query, String argument) {
		val parentFile = modelFile.parent + File.separator + NUXMV_TEMPORARY_COMMAND_FOLDER
		val isTimedModel = modelFile.timedModel
		
		val commandExtension = argument.commandLineArgumentExtension
		val nuXmvCommandExtension = commandExtension.nullOrEmpty ? #[] : #[commandExtension]
		
		val extension queryAdapter = new LtlQueryAdapter // We expect a CTL property
		
		val discretizedModelPath = modelFile.extendAndHideFileName("-untimed")
		if (isTimedModel) {
			// For timed models, we cannot use the convert_property_to_invar command, so we have to convert them first
			val discretizationCommand = '''
				set on_failure_script_quits
				set input_file "«modelFile.absolutePath»"
				«NUXMV_SETUP_TIMED»
				write_untimed_model -o "«discretizedModelPath.absolutePath»"
				quit
			'''
			
			val commandFile = new File(parentFile, '''.nuXmv-discretization-«Thread.currentThread.name».cmd''')
			fileUtil.saveString(commandFile, discretizationCommand)
			commandFile.deleteOnExit
			
			val nuXmvCommand = #["nuXmv"] + nuXmvCommandExtension + #["-source", commandFile.absolutePath]
			logger.info("Running nuXmv to discretize timed model: " + nuXmvCommand.join(" "))
			
			val process = Runtime.getRuntime().exec(nuXmvCommand)
			process.waitFor
		}

		val checkableModel = isTimedModel ? discretizedModelPath : modelFile
		//
		val commandFile = new File(parentFile, '''.nuXmv-invar-«Thread.currentThread.name».cmd''')
		commandFile.deleteOnExit
		
		val serializedCommand = '''
			set on_failure_script_quits
			set input_file "«checkableModel.absolutePath»"
			«NUXMV_SETUP_UNTIMED /* Always, as we cannot use the below convert command for timed models */»
			convert_property_to_invar -l -p "«query.adaptQuery»"
			show_property -n 0 -F tabular
			quit
		'''
		fileUtil.saveString(commandFile, serializedCommand)
		
		val nuXmvCommand = #["nuXmv", "-source", commandFile.absolutePath] // No 'nuXmvCommandExtension' - always untimed SMV model
		logger.info("Running nuXmv to convert property to invariance: " + nuXmvCommand.join(" "))
		
		var Scanner resultReader = null
		var ScannerLogger errorReader = null
		
		try {
			val PROPERTY_START = "000 :"
			val PARSING_ERROR = "Parsing error:"
			val ERROR = "Error:"
			
			val process = Runtime.getRuntime().exec(nuXmvCommand)
			resultReader = new Scanner(process.inputReader)
			errorReader = new ScannerLogger(new Scanner(process.errorReader), false)
			errorReader.start
			
			var line = ""
			while (!line.startsWith(PROPERTY_START) &&
					!line.startsWith(PARSING_ERROR) && !line.startsWith(ERROR)) {
				line = resultReader.nextLine
				if (!line.nullOrEmpty && !line.startsWith("***")) { // No header printing
					logger.info("nuXmv: " + line)
				}
			}
			if (line.startsWith(PROPERTY_START)) {
				val convertedProperty = line.substring(PROPERTY_START.length)
				logger.info("Property is convertible to safety property: " + convertedProperty)
				return convertedProperty -> queryAdapter.queryInverted
			}
			else {
				logger.info("Property is not convertible to safety property")
				return null
			}
		} catch (Exception e) {
			return null
		} finally {
			resultReader?.close
			errorReader?.cancel
		}
	}
	
	//
	
	protected def getSetupCommand(String argument) {
		switch (argument) {
			case CHECK_UNTIMED_LTL,
			case CHECK_UNTIMED_LTL_AS_INVAR:
				return NUXMV_SETUP_UNTIMED
			case CHECK_TIMED_LTL,
			case CHECK_TIMED_INVAR:
				return NUXMV_SETUP_TIMED
			default:
				return NUXMV_SETUP_UNTIMED
		}
	}
	
	protected def getCommandLineArgumentExtension(String argument) {
		switch (argument) {
			case CHECK_TIMED_LTL,
			case CHECK_TIMED_INVAR:
				return "-time"
			default:
				return ""
		}
	}
	
	//
	
	protected static def isTimedModel(File modelFile) {
		val firstLine = fileUtil.loadFirstLine(modelFile).trim
		return firstLine.startsWith("@TIME_DOMAIN") && firstLine.endsWith("continuous")
	}
	
	override getHelpCommand() {
		return #["nuXmv", "-h"]
	}
	
	override getUnavailableBackendMessage() {
		return "The command line tool of nuXmv ('nuXmv') cannot be found. " +
				"nuXmv can be downloaded from 'https://nuxmv.fbk.eu/download.html'. " +
				"Make sure to add the folder containing the 'nuXmv' bin to your path environment variable " +
					"(for detailed instructions, see 'https://github.com/ftsrg/gamma/blob/master/plugins/nuxmv/README.md')."
	}
	
}