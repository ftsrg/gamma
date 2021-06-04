package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.verification.util.AbstractVerification
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File

class XstsUppaalVerification extends AbstractVerification {
	// Singleton
	public static final XstsUppaalVerification INSTANCE = new XstsUppaalVerification
	protected new() {}
	//
	
	override Result execute(File modelFile, File queryFile) {
		val fileName = modelFile.name
		val packageFileName = fileName.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val verifier = new UppaalVerifier
		return verifier.verifyQuery(gammaPackage, "-C -T -t0", modelFile, queryFile)
	}

}