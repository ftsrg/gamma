package hu.bme.mit.gamma.nuxmv.verification

import hu.bme.mit.gamma.verification.util.AbstractVerification
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File

class NuxmvVerification extends AbstractVerification {
	// Singleton
	public static final NuxmvVerification INSTANCE = new NuxmvVerification
	protected new() {}
	
	override Result execute(File modelFile, File queryFile, String[] arguments) {
		val fileName = modelFile.name
		val packageFileName = fileName.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val verifier = new NuxmvVerifier
		val argument = arguments.head
		
		argument.sanitizeArgument
		
		return verifier.verifyQuery(gammaPackage, argument, modelFile, queryFile)
	}
	
	override getDefaultArguments() {
		return #['']
	}
	
	override protected getArgumentPattern() {
		return "(-([A-Za-z_])*([0-9])*(=)?([0-9])*( )*)*"
	}
	
}