package hu.bme.mit.gamma.promela.verification

import hu.bme.mit.gamma.verification.util.AbstractVerification
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File
import java.util.ArrayList

class PromelaVerification extends AbstractVerification {
	// Singleton
	public static final PromelaVerification INSTANCE = new PromelaVerification
	protected new() {}
	
	override Result execute(File modelFile, File queryFile, String[] arguments) {
		val fileName = modelFile.name
		val packageFileName = fileName.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val verifier = new PromelaVerifier
		val argument = arguments.head
		
		argument.sanitizeArgument
		
		val model = fileUtil.loadString(modelFile)
		val query = fileUtil.loadString(queryFile)
		
		val queries = query.split(System.lineSeparator).reject[it.nullOrEmpty]
		if (!queries.isEmpty) {
			var i = 0
			var modelsWithLtl = new ArrayList<File>
			var resultList = new ArrayList<Result>
			for (singleQuery : queries) {
				val ltl = '''ltl ltl_«i» { «singleQuery» }'''
				val modelWithLtl = model + "\n" + ltl
				val tmpGenFolder = new File(modelFile.parent, "." + fileUtil.getExtensionlessName(modelFile) + File.separator + '''«i»-LTL''')
				tmpGenFolder.mkdirs
				val fileWithQuery = new File(tmpGenFolder, fileUtil.getExtensionlessName(modelFile) + "-" + i + "-LTL.pml")
				fileUtil.saveString(fileWithQuery, modelWithLtl)
				modelsWithLtl += fileWithQuery
				val result = verifier.verifyQuery(gammaPackage, argument, modelsWithLtl.get(0), queryFile)
				resultList += result
				
				i++
			}
			return resultList.get(0)
		} else {
			val tmpGenFolder = new File(modelFile.parent, "." + fileUtil.getExtensionlessName(modelFile) + File.separator + '''NO-LTL''')
			tmpGenFolder.mkdirs
			val file = new File(tmpGenFolder, fileUtil.getExtensionlessName(modelFile) + "-NO-LTL.pml")
			fileUtil.saveString(file, model)
			
			//val verifier = new PromelaVerifier
			return verifier.verifyQuery(gammaPackage, argument, file, queryFile)
		}
	}
	
	override getDefaultArguments() {
		return #[ "-search -a" ]
	}
	
	protected override String getArgumentPattern() {
		return "(-[a-z]+( )*)*"
	}
}