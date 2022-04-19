/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
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
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Queue;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.logging.Level;
import java.util.stream.Collectors;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;

import com.google.common.base.Stopwatch;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.plantuml.serialization.SvgSerializer;
import hu.bme.mit.gamma.plantuml.transformation.TraceToPlantUmlTransformer;
import hu.bme.mit.gamma.promela.verification.PromelaVerification;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.querygenerator.serializer.PromelaPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.PropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.ThetaPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.UppaalPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.XstsUppaalPropertySerializer;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.theta.verification.ThetaVerification;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.testgeneration.java.TestGenerator;
import hu.bme.mit.gamma.trace.util.TraceUtil;
import hu.bme.mit.gamma.transformation.util.GammaFileNamer;
import hu.bme.mit.gamma.transformation.util.StatechartEcoreUtil;
import hu.bme.mit.gamma.transformation.util.UnfoldedExecutionTraceBackAnnotator;
import hu.bme.mit.gamma.transformation.util.reducer.CoveredPropertyReducer;
import hu.bme.mit.gamma.ui.taskhandler.VerificationHandler.ExecutionTraceSerializer.VerificationResult;
import hu.bme.mit.gamma.uppaal.verification.UppaalVerification;
import hu.bme.mit.gamma.uppaal.verification.XstsUppaalVerification;
import hu.bme.mit.gamma.util.FileUtil;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;
import hu.bme.mit.gamma.verification.util.AbstractVerification;
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result;

public class VerificationHandler extends TaskHandler {

	protected boolean serializeTest; // Denotes whether test code is generated
	protected String testFolderUri;
	// targetFolderUri is traceFolderUri 
	protected String svgFileName; // Set in setVerification
	protected final String traceFileName = "ExecutionTrace";
	protected final String testFileName = traceFileName + "Simulation";
	
	//
	
	protected final List<ExecutionTrace> traces = new ArrayList<ExecutionTrace>();
	
	//
	
	protected final TraceUtil traceUtil = TraceUtil.INSTANCE;
	protected final StatechartEcoreUtil statechartEcoreUtil = StatechartEcoreUtil.INSTANCE;
	protected final ExecutionTraceSerializer serializer = ExecutionTraceSerializer.INSTANCE;
	
	public VerificationHandler(IFile file) {
		super(file);
	}
	
	public void execute(Verification verification) throws IOException {
		// Setting target folder
		setTargetFolder(verification);
		//
		setVerification(verification);
		Set<AnalysisLanguage> languagesSet = new LinkedHashSet<AnalysisLanguage>(
				verification.getAnalysisLanguages());
		checkArgument(languagesSet.size() == 1);
		List<String> verificationArguments = verification.getVerificationArguments();
		
		boolean distinguishStringFormulas = false;
		
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
					distinguishStringFormulas = true;
					break;
				case XSTS_UPPAAL:
					verificationTask = XstsUppaalVerification.INSTANCE;
					propertySerializer = XstsUppaalPropertySerializer.INSTANCE;
					break;
				case PROMELA:
					verificationTask = PromelaVerification.INSTANCE;
					propertySerializer = PromelaPropertySerializer.INSTANCE;
					break;
				default:
					throw new IllegalArgumentException("Currently only UPPAAL and Theta are supported");
			}
		}
		
		String[] arguments = verificationArguments.isEmpty() ?
				verificationTask.getDefaultArguments() :
					verificationArguments.toArray(new String[verificationArguments.size()]);
		
		String filePath = verification.getFileName().get(0);
		File modelFile = new File(filePath);
		boolean isOptimize = verification.isOptimize();
		String packageName = verification.getPackageName().get(0);
		
		// Retrieved traces
		List<VerificationResult> retrievedVerificationResults = new ArrayList<VerificationResult>();
		List<ExecutionTrace> retrievedTraces = new ArrayList<ExecutionTrace>();
		
		// Map for collecting both supported property representations
		Map<String, StateFormula> formulas = new LinkedHashMap<String, StateFormula>();
		// LinkedHashMap needed to match .get and .json files
		
		// Serializing property formulas
		for (PropertyPackage propertyPackage : verification.getPropertyPackages()) {
			for (CommentableStateFormula formula : propertyPackage.getFormulas()) {
				StateFormula stateFormula = formula.getFormula();
				String serializedFormula = propertySerializer.serialize(stateFormula);
				formulas.put(serializedFormula, stateFormula);
			}
		}
		// Retrieving string formulas
		for (String queryFileLocation : verification.getQueryFiles()) {
			File queryFile = new File(queryFileLocation);
			String formulaFileString = fileUtil.loadString(queryFile);
			if (distinguishStringFormulas) {
				String[] lines = formulaFileString.split(System.lineSeparator());
				for (String line : lines) {
					formulas.put(line, null);
				}
			}
			else {
				// UPPAAL would benefit from the merging of all query files into one string
				formulas.put(formulaFileString, null);
			}
		}
		
		// Creating a queue to enable property removal during optimization 
		Queue<Entry<String, StateFormula>> formulaQueue = new LinkedList<Entry<String, StateFormula>>();
		formulaQueue.addAll(formulas.entrySet());
		
		// Execution
		while (!formulaQueue.isEmpty()) {
			Entry<String, StateFormula> formula = formulaQueue.poll();
			String serializedFormula = formula.getKey();
			
			// Saving the string
			File file = modelFile;
			String fileName = fileNamer.getHiddenSerializedPropertyFileName(file.getName());
			File queryFile = new File(file.getParentFile().toString() + File.separator + fileName);
			fileUtil.saveString(queryFile, serializedFormula);
			queryFile.deleteOnExit();
			
			Stopwatch stopwatch = Stopwatch.createStarted();
			
			Result result = execute(verificationTask, modelFile, queryFile, arguments,
					retrievedTraces, isOptimize);
			ExecutionTrace trace = result.getTrace();
			ThreeStateBoolean verificationResult = result.getResult();
			
			stopwatch.stop();
			TimeUnit timeUnit = TimeUnit.MILLISECONDS;
			long elapsed = stopwatch.elapsed(timeUnit);
			String elapsedString = elapsed + " " + timeUnit;
			
			retrievedVerificationResults.add(
				new VerificationResult(
					serializedFormula, verificationResult, arguments, elapsedString));
			
			// Checking if some of the unchecked properties are already covered
			if (trace != null && isOptimize) {
				List<StateFormula> stateFormulas = formulaQueue.stream()
						.map(it -> it.getValue())
						.filter(it -> it != null)
						.collect(Collectors.toList()); // Not null state formulas
				CoveredPropertyReducer reducer = new CoveredPropertyReducer(stateFormulas, trace);
				List<StateFormula> coveredProperties = reducer.execute();
				
				for (StateFormula coveredProperty : coveredProperties) {
					String serializedProperty = propertySerializer.serialize(coveredProperty);
					logger.log(Level.INFO, "Property already covered: " + serializedProperty);
					formulaQueue.removeIf(it -> it.getValue() == coveredProperty);
				}
				
			}
		}
		if (isOptimize) {
			// Optimization again on the retrieved tests (front to back and vice versa)
			traceUtil.removeCoveredExecutionTraces(retrievedTraces);
		}
		
		// Serializing
		String testFolderUri = serializeTest ? this.testFolderUri : null;
		String testFileName = serializeTest ? this.testFileName : null;
		
		// Back-annotating
		if (verification.isBackAnnotateToOriginal()) {
			List<ExecutionTrace> backAnnotatedTraces = new ArrayList<ExecutionTrace>();
			for (ExecutionTrace trace : retrievedTraces) {
				Component newComponent = trace.getComponent();
				Component originalComponent = statechartEcoreUtil.loadAndReplaceToOriginalComponent(newComponent);
				UnfoldedExecutionTraceBackAnnotator backAnnotator =
						new UnfoldedExecutionTraceBackAnnotator(trace, originalComponent);
				ExecutionTrace orignalTrace = backAnnotator.execute();
				backAnnotatedTraces.add(orignalTrace);
			}
			retrievedTraces.clear();
			retrievedTraces.addAll(backAnnotatedTraces);
		}
		
		for (ExecutionTrace trace : retrievedTraces) {
			serializer.serialize(targetFolderUri, traceFileName, svgFileName,
					testFolderUri, testFileName, packageName, trace);
		}
		traces.addAll(retrievedTraces);
		
		// Note that .get and .json postfix ids will not match if optimization is applied
		for (VerificationResult verificationResult : retrievedVerificationResults) {
			serializer.serialize(targetFolderUri, traceFileName, verificationResult);
		}
	}
	
	protected Result execute(AbstractVerification verificationTask, File modelFile,
			File queryFile, List<ExecutionTrace> retrievedTraces, boolean isOptimize) {
		return this.execute(verificationTask, modelFile, queryFile,
				new String[0], retrievedTraces, isOptimize);
	}
	
	protected Result execute(AbstractVerification verificationTask, File modelFile, File queryFile,
			String[] arguments, List<ExecutionTrace> retrievedTraces, boolean isOptimize) {
		// If arguments are empty, we execute a task with default arguments
		Result result = (arguments.length == 0) ? verificationTask.execute(modelFile, queryFile) :
			verificationTask.execute(modelFile, queryFile, arguments);
		
		ExecutionTrace trace = result.getTrace();
		// Maybe there is no trace
		if (trace != null) {
			if (isOptimize) {
				logger.log(Level.INFO, "Checking if trace is already covered by previous traces...");
				if (traceUtil.isCovered(trace, retrievedTraces)) {
					logger.log(Level.INFO, "Trace is already covered");
					return new Result(result.getResult(), null);
					// We do not return a trace as it is already covered
				}
				// Checking individual trace
				traceUtil.removeCoveredSteps(trace);
			}
			if (!trace.getSteps().isEmpty()) {
				retrievedTraces.add(trace);
			}
		}
		return result;
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
		if (verification.getProgrammingLanguages().isEmpty()) {
			this.serializeTest = false;
		}
		else {
			this.serializeTest = true;
			// Setting the attribute, the test folder is a RELATIVE path now from the project
			this.testFolderUri = URI.decode(projectLocation + File.separator + verification.getTestFolder().get(0));
		}
		Resource resource = verification.eResource();
		File file = (resource != null) ?
				ecoreUtil.getFile(resource).getParentFile() : // If Verification is contained in a resource
					fileUtil.toFile(super.file).getParentFile(); // If Verification is created in Java
		// Setting the file paths
		verification.getFileName().replaceAll(it -> fileUtil.exploreRelativeFile(file, it).toString());
		// Setting the query paths
		verification.getQueryFiles().replaceAll(it -> fileUtil.exploreRelativeFile(file, it).toString());
	}
	
	//
	
	public List<ExecutionTrace> getTraces() {
		return traces;
	}
	
	//
	
	public static class ExecutionTraceSerializer {
		//
		public static ExecutionTraceSerializer INSTANCE = new ExecutionTraceSerializer();
		protected ExecutionTraceSerializer() {}
		//
		protected final Gson gson = new GsonBuilder().disableHtmlEscaping().create();
		protected final FileUtil fileUtil = FileUtil.INSTANCE;
		protected final ModelSerializer serializer = ModelSerializer.INSTANCE;
		
		public void serialize(String traceFolderUri, String traceFileName, ExecutionTrace trace) throws IOException {
			this.serialize(traceFolderUri, traceFileName, null, null, null, trace);
		}
		
		public void serialize(String traceFolderUri, String traceFileName,
				String testFolderUri, String testFileName, String basePackage, ExecutionTrace trace) throws IOException {
			this.serialize(traceFolderUri, traceFileName, null, testFolderUri, testFileName, basePackage, trace);
		}
		
		public void serialize(String traceFolderUri, String traceFileName, String svgFileName,
				String testFolderUri, String testFileName, String basePackage, ExecutionTrace trace) throws IOException {
			
			// Model
			Entry<String, Integer> fileNamePair = fileUtil.getFileName(new File(traceFolderUri),
					traceFileName, GammaFileNamer.EXECUTION_XTEXT_EXTENSION);
			String fileName = fileNamePair.getKey();
			Integer id = fileNamePair.getValue();
			serializer.saveModel(trace, traceFolderUri, fileName);
			
			// SVG
			if (svgFileName != null) {
				TraceToPlantUmlTransformer transformer = new TraceToPlantUmlTransformer(trace);
				String plantUmlString = transformer.execute();
				SvgSerializer serializer = SvgSerializer.INSTANCE;
				String svg = serializer.serialize(plantUmlString);
				String svgFileNameWithId = svgFileName + id;
				fileUtil.saveString(traceFolderUri + File.separator + svgFileNameWithId + ".svg", svg);
			}
			
			// Test
			boolean serializeTest = testFolderUri != null && testFileName != null && basePackage != null;
			if (serializeTest) {
				String className = testFileName + id;
				
				TestGenerator testGenerator = new TestGenerator(trace, basePackage, className);
				String testCode = testGenerator.execute();
				String packageUri = testGenerator.getPackageName().replaceAll("\\.", "/");
				fileUtil.saveString(testFolderUri + File.separator + packageUri +
					File.separator + className + ".java", testCode);
			}
		}
		
		public void serialize(String resultFolderUri, String resultFileName,
				VerificationResult result) throws IOException {
			File folder = new File(resultFolderUri);
			Entry<String, Integer> fileNamePair = fileUtil.getFileName(folder,
					resultFileName, GammaFileNamer.VERIFICATION_RESULT_EXTENSION);
			String fileName = fileNamePair.getKey();
			String jsonResult = gson.toJson(result);
			fileUtil.saveString(resultFolderUri + File.separator + fileName, jsonResult);
		}
		
		@SuppressWarnings("unused")
		public static class VerificationResult {
			
			private String query;
			private ThreeStateBoolean result;
			private String[] parameters;
			private String executionTime;
			
			public VerificationResult(String query, ThreeStateBoolean result) {
				this(query, result, null, null);
			}
			
			public VerificationResult(String query, ThreeStateBoolean result,
					String[] parameters, String executionTime) {
				this.query = query;
				this.result = result;
				this.parameters = parameters;
				this.executionTime = executionTime;
			}
			
		}
		
	}
	
}