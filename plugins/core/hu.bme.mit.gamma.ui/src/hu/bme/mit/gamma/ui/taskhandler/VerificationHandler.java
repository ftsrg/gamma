/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui.taskhandler;

import static com.google.common.base.Preconditions.checkArgument;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map.Entry;
import java.util.Queue;
import java.util.Set;
import java.util.logging.Level;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.querygenerator.serializer.PropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.ThetaPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.UppaalPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.XSTSUppaalPropertySerializer;
import hu.bme.mit.gamma.theta.verification.ThetaVerifier;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.testgeneration.java.TestGenerator;
import hu.bme.mit.gamma.trace.util.TraceUtil;
import hu.bme.mit.gamma.transformation.util.reducer.CoveredPropertyReducer;
import hu.bme.mit.gamma.uppaal.verification.UppaalVerifier;
import hu.bme.mit.gamma.util.FileUtil;
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
		PropertySerializer propertySerializer = null;
		for (AnalysisLanguage analysisLanguage : languagesSet) {
			switch (analysisLanguage) {
				case UPPAAL:
					verificationTask = UppaalVerification.INSTANCE;
					propertySerializer = UppaalPropertySerializer.INSTANCE;
					break;
				case THETA:
					verificationTask = ThetaVerification.INSTANCE;
					propertySerializer = ThetaPropertySerializer.INSTANCE;
					break;
				case XSTS_UPPAAL:
					verificationTask = XSTSUppaalVerification.INSTANCE;
					propertySerializer = XSTSUppaalPropertySerializer.INSTANCE;
					break;
				default:
					throw new IllegalArgumentException("Currently only UPPAAL and Theta are supported.");
			}
		}
		String filePath = verification.getFileName().get(0);
		File modelFile = new File(filePath);
		boolean isOptimize = verification.isOptimize();
		String packageName = verification.getPackageName().get(0);
		
		List<String> queryFileLocations = new ArrayList<String>();
		// String locations
		queryFileLocations.addAll(verification.getQueryFiles());
		// Retrieved traces
		List<ExecutionTrace> retrievedTraces = new ArrayList<ExecutionTrace>();
		
		// Execution based on property models
		Queue<StateFormula> stateFormulas = new LinkedList<StateFormula>();
		for (PropertyPackage propertyPackage : verification.getPropertyPackages()) {
			for (CommentableStateFormula formula : propertyPackage.getFormulas()) {
				stateFormulas.add(formula.getFormula());
			}
		}
		while (!stateFormulas.isEmpty()) {
			StateFormula formula = stateFormulas.poll();
			String serializedFormula = propertySerializer.serialize(formula);
			// Saving the string
			File file = modelFile;
			String fileName = fileUtil.toHiddenFileName(fileUtil.changeExtension(file.getName(), "pd"));
			File queryFile = new File(file.getParentFile().toString() + File.separator + fileName);
			fileUtil.saveString(queryFile, serializedFormula);
			queryFile.deleteOnExit();
			
			ExecutionTrace trace = execute(verificationTask, modelFile, queryFile, retrievedTraces, isOptimize);
			
			// Checking if some of the unchecked properties are already covered
			if (trace != null && isOptimize) {
				CoveredPropertyReducer reducer = new CoveredPropertyReducer(stateFormulas, retrievedTraces);
				List<StateFormula> coveredProperties = reducer.execute();
				if (coveredProperties.size() > 0) {
					StringBuilder covered = new StringBuilder();
					for (StateFormula coveredProperty : coveredProperties) {
						covered.append(propertySerializer.serialize(coveredProperty) + System.lineSeparator());
					}
					logger.log(Level.INFO, "Some properties are already covered: " + covered);
					stateFormulas.removeAll(coveredProperties);
				}
			}
		}
		// Execution based on string queries
		for (String queryFileLocation : queryFileLocations) {
			logger.log(Level.INFO, "Checking " + queryFileLocation + "...");
			File queryFile = new File(queryFileLocation);
			execute(verificationTask, modelFile, queryFile,	retrievedTraces, isOptimize);
		}
		// Optimization again on the retrieved tests
		if (isOptimize) {
			traceUtil.removeCoveredExecutionTraces(retrievedTraces);
		}
		// Serializing
		for (ExecutionTrace trace : retrievedTraces) {
			serializeTest(trace, packageName);
		}
		
	}

	protected ExecutionTrace execute(AbstractVerification verificationTask, File modelFile,
			File queryFile, List<ExecutionTrace> retrievedTraces, boolean isOptimize) {
		ExecutionTrace trace = verificationTask.execute(modelFile, queryFile);
		// Maybe there is no trace
		if (trace != null) {
			if (isOptimize) {
				logger.log(Level.INFO, "Optimizing trace...");
				if (!retrievedTraces.isEmpty()) {
					if (traceUtil.isCovered(trace, retrievedTraces)) {
						return null; // We do not return a trace, as it is already covered
					}
				}
				// Checking individual trace
				traceUtil.removeCoveredSteps(trace);
			}
			if (!trace.getSteps().isEmpty()) {
				retrievedTraces.add(trace);
			}
		}
		return trace;
	}
	
	protected void serializeTest(ExecutionTrace trace, String basePackage) throws IOException {
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
	
}

abstract class AbstractVerification {

	protected FileUtil fileUtil = FileUtil.INSTANCE;
	protected GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	public abstract ExecutionTrace execute(File modelFile, File queryFile);
	
}

class UppaalVerification extends AbstractVerification {
	// Singleton
	public static final UppaalVerification INSTANCE = new UppaalVerification();
	protected UppaalVerification() {}
	//
	@Override
	public ExecutionTrace execute(File modelFile, File queryFile) {
		String packageFileName =
				fileUtil.toHiddenFileName(fileUtil.changeExtension(modelFile.getName(), "g2u"));
		EObject gammaTrace = ecoreUtil.normalLoad(modelFile.getParent(), packageFileName);
		UppaalVerifier verifier = new UppaalVerifier();
		return verifier.verifyQuery(gammaTrace, "-C -T -t0", modelFile, queryFile, true, true);
	}

}

class XSTSUppaalVerification extends AbstractVerification {
	// Singleton
	public static final XSTSUppaalVerification INSTANCE = new XSTSUppaalVerification();
	protected XSTSUppaalVerification() {}
	//
	@Override
	public ExecutionTrace execute(File modelFile, File queryFile) {
		String packageFileName =
				fileUtil.toHiddenFileName(fileUtil.changeExtension(modelFile.getName(), "gsm"));
		EObject gammaPackage = ecoreUtil.normalLoad(modelFile.getParent(), packageFileName);
		UppaalVerifier verifier = new UppaalVerifier();
		return verifier.verifyQuery(gammaPackage, "-C -T -t0", modelFile, queryFile, true, true);
	}

}

class ThetaVerification extends AbstractVerification {
	// Singleton
	public static final ThetaVerification INSTANCE = new ThetaVerification();
	protected ThetaVerification() {}
	//
	@Override
	public ExecutionTrace execute(File modelFile, File queryFile) {
		String packageFileName =
				fileUtil.toHiddenFileName(fileUtil.changeExtension(modelFile.getName(), "gsm"));
		EObject gammaPackage = ecoreUtil.normalLoad(modelFile.getParent(), packageFileName);
		ThetaVerifier verifier = new ThetaVerifier();
		String queries = fileUtil.loadString(queryFile);
		return verifier.verifyQuery(gammaPackage, "", modelFile, queries, true, true);
	}
	
}
