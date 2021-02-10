package hu.bme.mit.gamma.theta.verification

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.util.InterruptableCallable
import hu.bme.mit.gamma.util.ThreadRacer
import hu.bme.mit.gamma.verification.util.AbstractVerification
import java.io.File
import java.util.logging.Level

class ThetaVerification extends AbstractVerification {
	// Singleton
	public static final ThetaVerification INSTANCE = new ThetaVerification
	protected new() {}
	//
	
	override ExecutionTrace execute(File modelFile, File queryFile) {
		val fileName = modelFile.name
		val packageFileName = fileName.unfoldedPackageFileName
		val gammaPackage = ecoreUtil.normalLoad(modelFile.parent, packageFileName)
		val queries = fileUtil.loadString(queryFile)
		val defaultParameter = ""
		
//		ThetaVerifier verifier = new ThetaVerifier()
//		return verifier.verifyQuery(gammaPackage, defaultParameter, modelFile, queries, true, true)
		
		// --domain PRED_CART --refinement SEQ_ITP // default
		// --domain EXPL --refinement SEQ_ITP --maxenum 250
		val defaultParameters = #[
			defaultParameter,
			"--domain EXPL --refinement SEQ_ITP --maxenum 250"
		]
		val racer = new ThreadRacer<ExecutionTrace>
		val callables = <InterruptableCallable<ExecutionTrace>>newArrayList
		for (parameter : defaultParameters) {
			val verifier = new ThetaVerifier
			callables += new InterruptableCallable<ExecutionTrace> {
				override ExecutionTrace call() {
					logger.log(Level.INFO, '''Starting Theta on thread «Thread.currentThread.name» with "«parameter»"''')
					val trace = verifier.verifyQuery(
						gammaPackage, parameter, modelFile, queries, true, true)
					logger.log(Level.INFO, '''Thread «Thread.currentThread.name» with "«parameter»" has won''')
					return trace
				}
				override void cancel() {
					verifier.cancel
					logger.log(Level.INFO, '''Theta verification instance with "«parameter»" has been cancelled''')
				}
			}
		}
		return racer.execute(callables)
	}
	
}