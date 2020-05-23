package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import java.util.Scanner
import java.util.logging.Level

class ThetaVerifier extends AbstractVerifier {
	
	override ExecutionTrace verifyQuery(Object traceability, String parameters, File modelFile,
			File queryFile, boolean log, boolean storeOutput) {
		var Scanner resultReader = null
		try {
			// java -jar theta-xsts-cli.jar --model trafficlight.xsts --property red_green.prop
			val command = "java -jar theta-xsts-cli.jar " + parameters + " --model \"" + modelFile.toString + "\" --property \"" + queryFile.canonicalPath + "\""
			// Executing the command
			logger.log(Level.INFO, "Executing command: " + command)
			process =  Runtime.getRuntime().exec(command)
			val outputStream = process.inputStream
			resultReader = new Scanner(outputStream)
			while (resultReader.hasNext) {
				logger.log(Level.INFO, resultReader.nextLine)
			}
			return null
		} finally {
			resultReader.close
		}
	}
	
}