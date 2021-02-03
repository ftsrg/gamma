package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.verification.util.AbstractVerification
import java.io.File

class XSTSUppaalVerification extends AbstractVerification {
	// Singleton
	public static final XSTSUppaalVerification INSTANCE = new XSTSUppaalVerification
	protected new() {}
	//
	
	override ExecutionTrace execute(File modelFile, File queryFile) {
		val fileName = modelFile.name
		val packageFileName = fileName.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val verifier = new UppaalVerifier
		return verifier.verifyQuery(gammaPackage, "-C -T -t0", modelFile, queryFile, true, true)
	}

}