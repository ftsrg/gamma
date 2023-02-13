package hu.bme.mit.gamma.nuxmv.verification

import hu.bme.mit.gamma.util.FileUtil
import hu.bme.mit.gamma.verification.util.AbstractVerifier
import java.io.File
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean

class NuxmvVerifier extends AbstractVerifier {
	
	protected final extension FileUtil fileUtil = FileUtil.INSTANCE
	
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
		
	}
}