package hu.bme.mit.gamma.nuxmv.verification

import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import java.util.Scanner
import java.util.logging.Level
import java.io.FileOutputStream
import java.io.BufferedWriter
import java.io.OutputStreamWriter

class NuxmvVerifier extends AbstractVerifier {
	
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	
	// save trace to file
	protected val saveTrace = true
	
	override verifyQuery(Object traceability, String parameters, File modelFile, File queryFile) {
		val model = fileUtil.loadString(modelFile)
		val query = fileUtil.loadString(queryFile)

		var Result result = null
		var modelWithQueries = model
		
		//adding all the queries to the end of the model file
		for (singleQuery : query.split(System.lineSeparator).reject[it.nullOrEmpty]) {
			//TODO: check if the query is LTL or CTL
			val isLTL = true
			var _query = ''
			if (isLTL) {
				_query = '''«System.lineSeparator»LTLSPEC«System.lineSeparator»  «singleQuery»'''
			} else {
				_query = '''«System.lineSeparator»CTLSPEC«System.lineSeparator»  «singleQuery»'''
			}
			
			modelWithQueries += _query
		}
		
		val rootGenFolder = new File(modelFile.parent, "." + fileUtil.getExtensionlessName(modelFile))
		rootGenFolder.mkdirs
		// Save model with all the queries
		val tmpGenFolder = new File(rootGenFolder + File.separator + fileUtil.getExtensionlessName(modelFile) + "-" + System.currentTimeMillis.toString)
		tmpGenFolder.mkdirs
			
		// save model with LTL
		val fileWithQueries = new File(tmpGenFolder, fileUtil.getExtensionlessName(modelFile) + ".smv")
		fileWithQueries.deleteOnExit
		fileUtil.saveString(fileWithQueries, modelWithQueries)
			
		val newResult = verify(traceability, parameters, fileWithQueries)
		val oldTrace = result?.trace
		val newTrace = newResult?.trace
		if (oldTrace === null) {
			result = newResult
		} else if (newTrace !== null) {
			oldTrace.extend(newTrace)
			result = new Result(ThreeStateBoolean.UNDEF, oldTrace)
		}
			
		// Setting for deletion after the exe has been generated
		tmpGenFolder.forceDeleteOnExit
		rootGenFolder.forceDeleteOnExit
		
		return result
	}
	
	private def Result verify(Object traceability, String parameters, File modelFile) {
//		var Scanner resultReader = null
//		try {
//			// Directory where executing the command
//			val execFolder = modelFile.parentFile
//			
//			// spin -search -a PromelaFile.pml
//			val splitParameters = parameters.split("\\s+")
//			val searchCommand = #["nuXmv"] + splitParameters + #[modelFile.name /* see exec work-dir */]
//
//			
//			// Executing the command
//			logger.log(Level.INFO, "Executing command: " + searchCommand.join(" "))
//			process = Runtime.getRuntime().exec(searchCommand, null, execFolder)
//			val outputStream = process.inputStream
//			// Reading the result of the command
//			resultReader = new Scanner(outputStream)
//			
//			// save result of command
//			val outputFile = new File(execFolder, ".output.txt")
//			outputFile.deleteOnExit
//			var outputString = ""
//			while (resultReader.hasNext) {
//				outputString += resultReader.nextLine + System.lineSeparator
//			}
//			fileUtil.saveString(outputFile, outputString)
//			
//			if (!trailFile.exists) {
//				// No proof/counterexample
//				super.result = ThreeStateBoolean.TRUE
//				// Adapting result
//				super.result = super.result.adaptResult
//				return new Result(result, null)
//			}
//			
//			super.result = ThreeStateBoolean.FALSE
//			// Adapting result
//			super.result = super.result.adaptResult
//			
//			// Executing the trace command
//			logger.log(Level.INFO, "Executing command: " + traceCommand.join(" "))
//			process = Runtime.getRuntime().exec(traceCommand, null, execFolder)
//			
//			val traceOutputStream = process.inputStream
//			// Reading the result of the command
//			resultReader = new Scanner(traceOutputStream)
//			
//			// save trace
//			if (saveTrace) {
//				// Trace file
//				val traceFile = new File(modelFile.traceFile)
//				traceFile.delete
//				traceFile.deleteOnExit
//				
//				val fos = new FileOutputStream(traceFile)
//				val bw = new BufferedWriter(new OutputStreamWriter(fos))
//				
//				while (resultReader.hasNext) {
//					bw.write(resultReader.nextLine)
//					bw.write(System.lineSeparator)
//				}
//				bw.close
//				
//				resultReader = new Scanner(traceFile)
//			}
//			
//			val gammaPackage = traceability as Package
//			val backAnnotator = new TraceBackAnnotator(gammaPackage, resultReader)
//			val trace = backAnnotator.execute
//			
//			return new Result(result, trace)
//		} finally {
//			resultReader?.close
//		}
	}
}