package hu.bme.mit.gamma.ui.taskhandler.verification;

import java.io.File;
import java.util.ArrayList;
import java.util.Collection;
import java.util.logging.Level;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.theta.verification.ThetaVerifier;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.util.InterruptableRunnable;
import hu.bme.mit.gamma.util.ThreadRacer;

public class ThetaVerification extends AbstractVerification {
	// Singleton
	public static final ThetaVerification INSTANCE = new ThetaVerification();
	protected ThetaVerification() {}
	//
	@Override
	public ExecutionTrace execute(File modelFile, File queryFile) {
		String fileName = modelFile.getName();
		String packageFileName = fileNamer.getUnfoldedPackageFileName(fileName);
		EObject gammaPackage = ecoreUtil.normalLoad(modelFile.getParent(), packageFileName);
		String queries = fileUtil.loadString(queryFile);
		String defaultParameter = "";
		
//		ThetaVerifier verifier = new ThetaVerifier();
//		return verifier.verifyQuery(gammaPackage, defaultParameter, modelFile, queries, true, true);
		
		// --domain PRED_CART --refinement SEQ_ITP // default
		// --domain EXPL --refinement SEQ_ITP --maxenum 250
		String[] defaultParameters = {defaultParameter,
				"--domain EXPL --refinement SEQ_ITP --maxenum 250"};
		ThreadRacer<ExecutionTrace> racer = new ThreadRacer<ExecutionTrace>();
		Collection<InterruptableRunnable> runnables = new ArrayList<InterruptableRunnable>();
		for (String parameter : defaultParameters) {
			ThetaVerifier verifier = new ThetaVerifier();
			InterruptableRunnable runnable = new InterruptableRunnable() {
				@Override
				public void run() {
					try {
						logger.log(Level.INFO, "Starting " + parameter);
						ExecutionTrace trace = verifier.verifyQuery(
							gammaPackage, parameter, modelFile, queries, true, true);
						racer.setObject(trace);
						logger.log(Level.INFO, parameter + " ended");
					} catch (Exception e) {
						// Every kind of exception, as we do not know where the interrupt comes
						logger.log(Level.INFO, parameter + " has been interrupted");
					}
				}
				@Override
				public void interrupt() {
					verifier.cancel();
				}
			};
			runnables.add(runnable);
		}
		return racer.execute(runnables);
	}
	
}