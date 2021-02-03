package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.verification.util.AbstractVerification
import java.io.File

class UppaalVerification extends AbstractVerification {
	// Singleton
	public static final UppaalVerification INSTANCE = new UppaalVerification
	protected new() {}
	//
	
	override ExecutionTrace execute(File modelFile, File queryFile) {
		val fileName = modelFile.name
		val packageFileName = fileName.gammaUppaalTraceabilityFileName
		val gammaTrace = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val verifier = new UppaalVerifier
		return verifier.verifyQuery(gammaTrace, "-C -T -t0", modelFile, queryFile, true, true)
	}

}
