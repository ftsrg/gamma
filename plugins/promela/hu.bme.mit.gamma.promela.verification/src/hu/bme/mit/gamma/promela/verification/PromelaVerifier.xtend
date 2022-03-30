package hu.bme.mit.gamma.promela.verification

import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import java.util.Scanner
import java.util.logging.Level
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean

class PromelaVerifier extends AbstractVerifier {
	
	override Result verifyQuery(Object traceability, 
		String parameters, File modelFile,	File queryFile
	) {
		var Scanner resultReader = null
		var Scanner traceFileScanner = null
		try {
			// Directory where executing the command
			val execFolder = modelFile.parentFile
			// spin -run PromelaFile.pml
			val command = '''spin «parameters» «modelFile.canonicalPath.escapePath»'''
			// Trace file
			val traceFile = new File(modelFile.traceFile)
			//traceFile.delete // So no invalid/old .trail is parsed if this actual process does not generate one
			//traceFile.deleteOnExit // So the .trail with this random name does not remain on disk
			// Executing the command
			logger.log(Level.INFO, "Executing command: " + command)
			process = Runtime.getRuntime().exec(command, null, execFolder)
			val outputStream = process.inputStream
			// Reading the result of the command
			resultReader = new Scanner(outputStream) 
			while (resultReader.hasNext) {
				println(resultReader.nextLine)
			}
			if (!traceFile.exists) {
				// No proof/counterexample
				return new Result(ThreeStateBoolean.TRUE, null)
			}
			return new Result(ThreeStateBoolean.FALSE, null)
		} finally {
			if (resultReader !== null) {
				resultReader.close
			}
			if (traceFileScanner !== null) {
				traceFileScanner.close
			}
		}
	}
	
	override cancel() {
		super.cancel
	}
	
	def getTraceFile(File modelFile) {
		return modelFile.parent + File.separator + modelFile.name + 
				".trail";
	}
}