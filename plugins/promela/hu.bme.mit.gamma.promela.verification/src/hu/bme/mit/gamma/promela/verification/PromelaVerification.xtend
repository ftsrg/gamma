package hu.bme.mit.gamma.promela.verification

import hu.bme.mit.gamma.verification.util.AbstractVerification
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File

class PromelaVerification extends AbstractVerification {
	// Singleton
	public static final PromelaVerification INSTANCE = new PromelaVerification
	protected new() {}
	
	protected final extension PromelaQueryAdapter promelaQueryAdapter = PromelaQueryAdapter.INSTANCE
	
	override Result execute(File modelFile, File queryFile, String[] arguments) {
		val fileName = modelFile.name
		val packageFileName = fileName.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val verifier = new PromelaVerifier
		val argument = arguments.head
		
		argument.sanitizeArgument
		
		return verifier.verifyQuery(gammaPackage, argument, modelFile, queryFile)
	}
	
	override getDefaultArguments() {
		return #[ "-search -a" ]
	}
	
	protected override String getArgumentPattern() {
		return "(-[a-z]+( )*)*"
	}
}