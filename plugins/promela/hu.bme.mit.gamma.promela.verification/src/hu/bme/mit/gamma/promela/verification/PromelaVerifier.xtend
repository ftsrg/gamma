package hu.bme.mit.gamma.promela.verification

import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import java.util.Scanner
import java.util.logging.Level
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import java.io.FileWriter
import hu.bme.mit.gamma.util.FileUtil
import java.util.ArrayList

class PromelaVerifier extends AbstractVerifier {
	
	extension FileUtil fileUtil = FileUtil.INSTANCE
	protected final extension PromelaQueryAdapter promelaQueryAdapter = PromelaQueryAdapter.INSTANCE
	
	override Result verifyQuery(Object traceability, 
		String parameters, File modelFile,	File queryFile
	) {
		val model = fileUtil.loadString(modelFile)
		val query = fileUtil.loadString(queryFile)
		
		var modelWithLtls = model
		var i = 0
		for (singleQuery : query.split(System.lineSeparator).reject[it.nullOrEmpty]) {
			// Supporting multiple queries in separate files
			val ltl = '''«System.lineSeparator»ltl ltl_«i» { «singleQuery.adaptQuery» }'''
			modelWithLtls += ltl
			i++
		}
		
		// save model with all LTL
		val tmpGenFolder = new File(modelFile.parent, "." + fileUtil.getExtensionlessName(modelFile) + File.separator + '''«i»-LTL''')
		tmpGenFolder.deleteOnExit
		tmpGenFolder.mkdirs
		val fileWithLtl = new File(tmpGenFolder, fileUtil.getExtensionlessName(modelFile) + "-LTL.pml")
		fileWithLtl.deleteOnExit
		fileUtil.saveString(fileWithLtl, modelWithLtls)
		
		var resultList = new ArrayList<Result>
		for (var j = 0; j < i; j++) {
			val result = verify(traceability, parameters, fileWithLtl)
			resultList += result
		}
		
		// now return just one result
		return resultList.get(0)
	}
	
	private def Result verify(Object traceability, String parameters, File modelFile) {
		var Scanner resultReader = null
		var Scanner traceFileScanner = null
		try {
			// Directory where executing the command
			val execFolder = modelFile.parentFile
			// spin -search -a PromelaFile.pml
			val command = '''spin «parameters» «modelFile.canonicalPath.escapePath»'''
			// Trace file
			val traceFile = new File(modelFile.traceFile)
			traceFile.delete
			traceFile.deleteOnExit
			// Executing the command
			logger.log(Level.INFO, "Executing command: " + command)
			process = Runtime.getRuntime().exec(command, null, execFolder)
			val outputStream = process.inputStream
			// Reading the result of the command
			resultReader = new Scanner(outputStream)
			// save result of command
			val outputFile = new File(execFolder, ".output.txt")
			outputFile.deleteOnExit
			val out = new FileWriter(outputFile)
			while (resultReader.hasNext) {
				val line = resultReader.nextLine
				out.write(line + System.lineSeparator)
			}
			out.flush
			out.close
			
			// Adapting result
			super.result = super.result.adaptResult
			if (!traceFile.exists) {
				// No proof/counterexample
				return new Result(result, null)
			}
			return new Result(result, null)
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

class PromelaQueryAdapter {
	public static PromelaQueryAdapter INSTANCE = new PromelaQueryAdapter
	private new() {}
	// Singleton
	final String E = "E"
	final String A = "A"
	
	extension FileUtil fileUtil = FileUtil.INSTANCE
	boolean invert;
	
	def adaptQuery(File queryFile) {
		return queryFile.loadString.adaptQuery
	}
	
	def adaptQuery(String query) {
		if (query.startsWith("E")) {
			invert = true
			return "!(" + query.substring(E.length) + " )"
		}
		if (query.startsWith("A")) {
			invert = false
			return query.substring(A.length)
		}
		throw new IllegalArgumentException("Not supported operator: " + query)
	}
	
	def adaptResult(ThreeStateBoolean promelaResult) {
		if (promelaResult === null) {
			// If the process is cancelled, the result will be null
			return ThreeStateBoolean.UNDEF
		}
		if (invert) {
			return promelaResult.opposite
		}
		return promelaResult
	}
}