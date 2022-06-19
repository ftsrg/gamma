package hu.bme.mit.gamma.theta.verification

import java.util.List
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import java.util.ArrayList
import java.io.File
import java.util.Scanner
import java.util.logging.Level
import hu.bme.mit.gamma.statechart.interface_.Package
import java.util.logging.Logger
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.transformation.util.GammaFileNamer

class ThetaTraceGenerator {
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE	
	protected final extension GammaFileNamer fileNamer = GammaFileNamer.INSTANCE
	
	protected volatile boolean isCancelled
	protected Process process
	protected ThreeStateBoolean result	

	final String ENVIRONMENT_VARIABLE_FOR_THETA_JAR = "THETA_XSTS_CLI_PATH"
	protected final Logger logger = Logger.getLogger("GammaLogger")
	
	def List<ExecutionTrace> execute(File modelFile) {
		val packageFileName = modelFile.name.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		
		return generateTraces(gammaPackage, modelFile)
	}
	
	private def List<ExecutionTrace> generateTraces(Object traceability, File modelFile) {
		val traceDir = new File(modelFile.parent + File.separator + "traces")
		val jar = System.getenv(ENVIRONMENT_VARIABLE_FOR_THETA_JAR)
		val command = #["java", "-jar", jar] + #["--model", modelFile.canonicalPath, "--stacktrace", "--tracegen", "--property null"]
		logger.log(Level.INFO, "Executing command: " + command.join(" "))
		process = Runtime.getRuntime().exec(command)
		val outputStream = process.inputStream
		var resultReader = new Scanner(outputStream)
		
		val traceList = new ArrayList<ExecutionTrace>
		val gammaPackage = traceability as Package
		if(traceDir.listFiles() !== null) {
			for(File tf : traceDir.listFiles()) {
				var traceFileScanner = new Scanner(tf)
				traceList.add(gammaPackage.backAnnotate(traceFileScanner))
			}				
		}
		return traceList
	}
	
	protected def backAnnotate(Package gammaPackage, Scanner traceFileScanner) {
		// Must be synchronized due to the non-thread-safe VIATRA engine
		synchronized (TraceBackAnnotator.getEngineSynchronizationObject) {
			val backAnnotator = new TraceBackAnnotator(gammaPackage, traceFileScanner)
			return backAnnotator.execute
		}
	}
	
	def getProcess() {
		return process
	}
	
	def cancel() {
		isCancelled = true
		if (process !== null) {
			process.destroyForcibly
			try {
				// Waiting for process to end
				process.waitFor
			} catch (InterruptedException e) {}
		}
	}
}