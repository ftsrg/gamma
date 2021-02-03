package hu.bme.mit.gamma.ui.taskhandler.verification;

import java.io.File;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.uppaal.verification.UppaalVerifier;

public class UppaalVerification extends AbstractVerification {
	// Singleton
	public static final UppaalVerification INSTANCE = new UppaalVerification();
	protected UppaalVerification() {}
	//
	@Override
	public ExecutionTrace execute(File modelFile, File queryFile) {
		String fileName = modelFile.getName();
		String packageFileName = fileNamer.getGammaUppaalTraceabilityFileName(fileName);
		EObject gammaTrace = ecoreUtil.normalLoad(modelFile.getParent(), packageFileName);
		UppaalVerifier verifier = new UppaalVerifier();
		return verifier.verifyQuery(gammaTrace, "-C -T -t0", modelFile, queryFile, true, true);
	}

}
