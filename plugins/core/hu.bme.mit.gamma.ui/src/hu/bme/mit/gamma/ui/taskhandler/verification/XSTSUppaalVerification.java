package hu.bme.mit.gamma.ui.taskhandler.verification;

import java.io.File;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.uppaal.verification.UppaalVerifier;

public class XSTSUppaalVerification extends AbstractVerification {
	// Singleton
	public static final XSTSUppaalVerification INSTANCE = new XSTSUppaalVerification();
	protected XSTSUppaalVerification() {}
	//
	@Override
	public ExecutionTrace execute(File modelFile, File queryFile) {
		String fileName = modelFile.getName();
		String packageFileName = fileNamer.getUnfoldedPackageFileName(fileName);
		EObject gammaPackage = ecoreUtil.normalLoad(modelFile.getParent(), packageFileName);
		UppaalVerifier verifier = new UppaalVerifier();
		return verifier.verifyQuery(gammaPackage, "-C -T -t0", modelFile, queryFile, true, true);
	}

}
