package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.verification.util.AbstractVerification
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result
import java.io.File

class UppaalVerification extends AbstractVerification {
	// Singleton
	public static final UppaalVerification INSTANCE = new UppaalVerification
	protected new() {}
	//
	
	override Result execute(File modelFile, File queryFile) {
		val fileName = modelFile.name
		val packageFileName = fileName.gammaUppaalTraceabilityFileName
		val gammaTrace = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val verifier = new UppaalVerifier
		val parameter = parameters.head
		return verifier.verifyQuery(gammaTrace, parameter, modelFile, queryFile)
	}
	
	override getParameters() {
		return #[ "-C -T -t0" ]
	}

}
