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

import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.plantuml.serialization.SvgSerializer;
import hu.bme.mit.gamma.plantuml.transformation.TraceToPlantUmlTransformer;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.querygenerator.serializer.PropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.ThetaPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.UppaalPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.XstsUppaalPropertySerializer;
import hu.bme.mit.gamma.theta.verification.ThetaVerification;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.testgeneration.java.TestGenerator;
import hu.bme.mit.gamma.trace.util.TraceUtil;
import hu.bme.mit.gamma.transformation.util.reducer.CoveredPropertyReducer;
import hu.bme.mit.gamma.uppaal.verification.UppaalVerification;
import hu.bme.mit.gamma.uppaal.verification.XstsUppaalVerification;
import hu.bme.mit.gamma.verification.util.AbstractVerification;
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result;

public class VerificationHandler extends TaskHandler {

	protected String testFolderUri;
	// targetFolderUri is traceFolderUri 
	protected String svgFileName; // Set in setVerification
	protected final String traceFileName = "ExecutionTrace";
	protected final String testFileName = traceFileName + "Simulation";
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
					verificationTask = XstsUppaalVerification.INSTANCE;
					propertySerializer = XstsUppaalPropertySerializer.INSTANCE;
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
				CoveredPropertyReducer reducer = new CoveredPropertyReducer(stateFormulas, trace);
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
		Result result = verificationTask.execute(modelFile, queryFile);
		ExecutionTrace trace = result.getTrace();
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
		
		// Model
		Entry<String, Integer> fileNamePair = fileUtil.getFileName(new File(traceFolder),
				traceFileName, "get");
		String fileName = fileNamePair.getKey();
		Integer id = fileNamePair.getValue();
		saveModel(trace, traceFolder, fileName);
		
		// SVG
		if (svgFileName != null) {
			TraceToPlantUmlTransformer transformer = new TraceToPlantUmlTransformer(trace);
			String plantUmlString = transformer.execute();
			SvgSerializer serializer = SvgSerializer.INSTANCE;
			String svg = serializer.serialize(plantUmlString);
			String svgFileNameWithId = svgFileName + id;
			fileUtil.saveString(traceFolder + File.separator + svgFileNameWithId + ".svg", svg);
		}
		
		// Test
		String className = testFileName + id;
		
		TestGenerator testGenerator = new TestGenerator(trace, basePackage, className);
		String testCode = testGenerator.execute();
		String testFolder = testFolderUri;
		String packageUri = testGenerator.getPackageName().replaceAll("\\.", "/");
		fileUtil.saveString(testFolder + File.separator + packageUri +
			File.separator + className + ".java", testCode);
	}
	
	private void setVerification(Verification verification) {
		if (verification.getPackageName().isEmpty()) {
			verification.getPackageName().add(file.getProject().getName().toLowerCase());
		}
		if (verification.getTestFolder().isEmpty()) {
			verification.getTestFolder().add("test-gen");
		}
		if (!verification.getSvgFileName().isEmpty()) {
			this.svgFileName = verification.getSvgFileName().get(0);
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