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
		
		val model = fileUtil.loadString(modelFile)
		val query = fileUtil.loadString(queryFile)
		
		var i = 0
		var modelsWithLtl = new ArrayList<File> 
		for (singleQuery : query.split(System.lineSeparator).reject[it.nullOrEmpty]) {
			val ltl = '''ltl ltl_«i» { «singleQuery» }'''
			val modelWithLtl = model + "\n" + ltl
			val fileWithQuery = new File(modelFile.parent, fileUtil.getExtensionlessName(modelFile) + "-" + i + "-LTL.pml")
			modelsWithLtl.add(fileWithQuery)
			fileUtil.saveString(fileWithQuery, modelWithLtl)
			i++
		}
		
		argument.sanitizeArgument
		
		return verifier.verifyQuery(gammaPackage, argument, modelsWithLtl.get(0), queryFile)
	}
	
	override getDefaultArguments() {
		return #[ "-search -a" ]
	}
	
	protected override String getArgumentPattern() {
		return "(-[a-z]+( )*)*"
	}
}