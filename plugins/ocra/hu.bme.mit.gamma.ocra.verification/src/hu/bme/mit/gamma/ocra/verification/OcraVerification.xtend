package hu.bme.mit.gamma.ocra.verification

import hu.bme.mit.gamma.querygenerator.serializer.NuxmvPropertySerializer
import hu.bme.mit.gamma.trace.model.impl.ExecutionTraceImpl
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerification
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File
import java.io.IOException
import java.util.Scanner
import java.util.concurrent.TimeUnit
import javax.xml.parsers.DocumentBuilderFactory

class OcraVerification extends AbstractVerification {
	// Singleton
	public static final OcraVerification INSTANCE = new OcraVerification

	protected new() {
	}

	//
	override protected getTraceabilityFileName(String fileName) {
		return "ocra/" + fileName.getOcraFileName
	}

	override protected createVerifier() {
		return new OcraVerifier
	}

	override getDefaultArguments() {
		return #[OcraVerifier.SET_OCRA_TIMED]
	}

	override protected getArgumentPattern() {
		return ".*" // TODO
	}

	override protected createPropertySerializer() {
		return NuxmvPropertySerializer.INSTANCE
	}

	override Result execute(File modelFile, File queryFile, String[] arguments, long timeout,
		TimeUnit unit) throws InterruptedException {

		val ocraPath = System.getenv("OCRA_HOME") + File.separator + "ocra-win64.exe"

		try {
			val commandFile = createVerificationQuery(modelFile, arguments, ocraPath)

			val ocraCommand = #[ocraPath] + #["-source", commandFile.absolutePath]
			val process = Runtime.getRuntime().exec(ocraCommand, null, modelFile.parentFile)

			// Create input and error readers
			val inputReader = new Scanner(process.inputStream)
			val errorReader = new Scanner(process.errorStream)

			// Read and print the process output
			println("=== Standard Output ===")
			while (inputReader.hasNextLine) {
				println(inputReader.nextLine)
			}

			// Read and print the process errors
			println("=== Error Output ===")
			while (errorReader.hasNextLine) {
				println(errorReader.nextLine)
			}

			// Close the readers
			inputReader.close
			errorReader.close

			// Collect all "argument_log.xml" files
			val parentPath = modelFile.parent
			val filesToCheck = arguments.map [ argument |
				new File(parentPath + File.separator + argument + "_log.xml")
			]

			// Check if any of the files contain "NOT_OK"
			if (containsNotOkResult(filesToCheck) == ThreeStateBoolean.TRUE) {
				return new Result(ThreeStateBoolean.FALSE, execTrace)
			}

		} catch (IOException e) {
			e.printStackTrace
		}
		return new Result(ThreeStateBoolean.TRUE, execTrace)
	}

	def ExecutionTraceImpl getExecTrace() {
		return null as ExecutionTraceImpl
	}

	def File createVerificationQuery(File modelFile, String[] arguments, String ocraPath) {
		val parentPath = modelFile.parent
		val commandFile = new File(parentPath + File.separator + '''.ocra-commands-«Thread.currentThread.name».cmd''')
		commandFile.deleteOnExit
		val serializedCommand = '''
			set on_failure_script_quits 0
			set ocra_timed 1
			set default_trace_plugin 1
			ocra_check_syntax -i «modelFile.absolutePath»
			«FOR argument : arguments»
				ocra_check_implementation -I «argument».smv -f xml -o «argument»_log.xml
			«ENDFOR»
			quit
		'''
		fileUtil.saveString(commandFile, serializedCommand)

		return commandFile
	}

	def ThreeStateBoolean containsNotOkResult(File[] files) {
		try {
			// Create an XML Document Builder
			val factory = DocumentBuilderFactory.newInstance
			val builder = factory.newDocumentBuilder

			// Iterate through each file
			for (file : files) {
				// Parse the XML file
				val document = builder.parse(file)
				document.documentElement.normalize

				// Check for <Value value="NOT_OK"/> in the XML
				val values = document.getElementsByTagName("Value")
				if (values.length != 0) {
					for (i : 0 .. (values.length - 1)) {
						val valueNode = values.item(i)
						if (valueNode.getAttributes?.getNamedItem("value")?.nodeValue == "NOT_OK") {
							return ThreeStateBoolean.TRUE
						}
					}
				}
			}
		} catch (Exception e) {
			e.printStackTrace
		}
		// Return false if no NOT_OK result is found
		return ThreeStateBoolean.FALSE
	}

}
