package hu.bme.mit.gamma.ui.taskhandler;

import static com.google.common.base.Preconditions.checkArgument;

import java.io.File;
import java.io.IOException;
import java.util.HashSet;
import java.util.Map.Entry;
import java.util.logging.Level;
import java.util.Set;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.theta.verification.ThetaVerifier;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.TraceUtil;
import hu.bme.mit.gamma.trace.testgeneration.java.TestGenerator;
import hu.bme.mit.gamma.uppaal.verification.UppaalVerifier;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class VerificationHandler extends TaskHandler {

	protected String testFolderUri;
	protected TraceUtil traceUtil = TraceUtil.INSTANCE;
	
	public VerificationHandler(IFile file) {
		super(file);
	}
	
	public void execute(Verification verification) throws IOException {
		setVerification(verification);
		Set<AnalysisLanguage> languagesSet = new HashSet<AnalysisLanguage>(verification.getLanguages());
		checkArgument(languagesSet.size() == 1);
		AbstractVerification verificationTask = null;
		for (AnalysisLanguage analysisLanguage : languagesSet) {
			switch (analysisLanguage) {
				case UPPAAL:
					verificationTask = new UppaalVerification();
					break;
				case THETA:
					verificationTask = new ThetaVerification();
					break;
				default:
					throw new IllegalArgumentException("Currently only UPPAAL and Theta are supported.");
			}
		}
		String filePath = verification.getFileName().get(0);
		File modelFile = new File(filePath);
		
		for (String queryFileLocation : verification.getQueryFiles()) {
			logger.log(Level.INFO, "Checking " + queryFileLocation + "...");
			File queryFile = new File(queryFileLocation);
			
			ExecutionTrace trace = verificationTask.execute(modelFile, queryFile);
			
			if (verification.isOptimize()) {
				logger.log(Level.INFO, "Optimizing trace...");
				traceUtil.removeCoveredSteps(trace);
			}
			
			String basePackage = verification.getPackageName().get(0);
			String traceFolder = targetFolderUri;
			
			Entry<String, Integer> fileNamePair = fileUtil.getFileName(new File(traceFolder), "ExecutionTrace", "get");
			String fileName = fileNamePair.getKey();
			Integer id = fileNamePair.getValue();
			saveModel(trace, traceFolder, fileName);
			
			String className = fileUtil.getExtensionlessName(fileName).replace(id.toString(), "");
			className += "Simulation" + id;
			TestGenerator testGenerator = new TestGenerator(trace, basePackage, className);
			String testCode = testGenerator.execute();
			String testFolder = testFolderUri;
			fileUtil.saveString(testFolder + File.separator + testGenerator.getPackageName().replaceAll("\\.", "/") +
					File.separator + className + ".java", testCode);
		}
	}

	private void setVerification(Verification verification) {
		if (verification.getPackageName().isEmpty()) {
			verification.getPackageName().add(file.getProject().getName().toLowerCase());
		}
		if (verification.getTestFolder().isEmpty()) {
			verification.getTestFolder().add("test-gen");
		}
		// Setting the attribute, the test folder is a RELATIVE path now from the project
		testFolderUri = URI.decode(projectLocation + File.separator + verification.getTestFolder().get(0));
		File file = ecoreUtil.getFile(verification.eResource()).getParentFile();
		// Setting the file paths
		verification.getFileName().replaceAll(it -> fileUtil.exploreRelativeFile(file, it).toString());
		// Setting the query paths
		verification.getQueryFiles().replaceAll(it -> fileUtil.exploreRelativeFile(file, it).toString());
	}
	
	abstract class AbstractVerification {
		protected GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
		public abstract ExecutionTrace execute(File modelFile, File queryFile);
	}
	
	class UppaalVerification extends AbstractVerification {

		@Override
		public ExecutionTrace execute(File modelFile, File queryFile) {
			String packageFileName =
					fileUtil.toHiddenFileName(fileUtil.changeExtension(modelFile.getName(), "g2u"));
			EObject gammaTrace = ecoreUtil.normalLoad(modelFile.getParent(), packageFileName);
			UppaalVerifier verifier = new UppaalVerifier();
			return verifier.verifyQuery(gammaTrace, "-C -T -t0", modelFile, queryFile, true, true);
		}

	}
	
	class ThetaVerification extends AbstractVerification {

		@Override
		public ExecutionTrace execute(File modelFile, File queryFile) {
			String packageFileName =
					fileUtil.toHiddenFileName(fileUtil.changeExtension(modelFile.getName(), "gsm"));
			EObject gammaPackage = ecoreUtil.normalLoad(modelFile.getParent(), packageFileName);
			ThetaVerifier verifier = new ThetaVerifier();
			return verifier.verifyQuery(gammaPackage, "", modelFile, queryFile, true, true);
		}
		
	}
	
}
