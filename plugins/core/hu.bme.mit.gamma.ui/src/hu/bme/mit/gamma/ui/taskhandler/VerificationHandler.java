/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
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
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Queue;
import java.util.Set;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;

import com.google.common.base.Stopwatch;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.GenmodelModelFactory;
import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.genmodel.model.TestGeneration;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.nuxmv.verification.NuxmvVerification;
import hu.bme.mit.gamma.plantuml.serialization.SvgSerializer;
import hu.bme.mit.gamma.plantuml.transformation.TraceToPlantUmlTransformer;
import hu.bme.mit.gamma.promela.verification.PromelaVerification;
import hu.bme.mit.gamma.property.derivedfeatures.PropertyModelDerivedFeatures;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.property.util.PropertyUtil;
import hu.bme.mit.gamma.querygenerator.serializer.AbstractReferenceSerializer;
import hu.bme.mit.gamma.querygenerator.serializer.NuxmvPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.PromelaPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.PropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.ThetaPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.UppaalPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.XstsUppaalPropertySerializer;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
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
import hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures;
import hu.bme.mit.gamma.xsts.model.XSTS;
import hu.bme.mit.gamma.xsts.util.XstsActionUtil;

public class VerificationHandler extends TaskHandler {

	protected boolean serializeTraces; // Denotes whether traces are serialized
	protected boolean serializeTest; // Denotes whether test code is generated
	protected String testFolderUri;
	// targetFolderUri is traceFolderUri 
	protected String packageName; // Set in setVerification
	protected String svgFileName; // Set in setVerification
	protected ProgrammingLanguage programmingLanguage; // Set in setVerification
	protected final String traceFileName = "ExecutionTrace";
	protected final String testFileName = traceFileName + "Simulation";
	
	protected TimeSpecification timeout = null;
	
	//
	
	protected PropertySerializer propertySerializer = null;
	
	//
	
	protected final List<ExecutionTrace> traces = new ArrayList<ExecutionTrace>();
	
	//
	
	protected final TraceUtil traceUtil = TraceUtil.INSTANCE;
	protected final PropertyUtil propertyUtil = PropertyUtil.INSTANCE;
	protected final XstsActionUtil xStsUtil = XstsActionUtil.INSTANCE;
	protected final StatechartEcoreUtil statechartEcoreUtil = StatechartEcoreUtil.INSTANCE;
	protected final ExecutionTraceSerializer serializer = ExecutionTraceSerializer.INSTANCE;
	
	//
	
	public VerificationHandler(IFile file) {
		this(file, true);
	}
	
	public VerificationHandler(IFile file, boolean serializeTraces) {
		super(file);
		this.serializeTraces = serializeTraces;
	}
	
	//
	
	public boolean isExecutable(Verification verification) {
		AbstractVerification verificationInstance = getVerification(verification);
		return verificationInstance.isBackendAvailable();
	}
	
	public boolean isExecutable(AnalysisLanguage language) {
		AbstractVerification verificationInstance = getVerification(language);
		return verificationInstance.isBackendAvailable();
	}
	
	public String getUnavailableBackendMessage(AnalysisLanguage language) {
		AbstractVerification verificationInstance = getVerification(language);
		return verificationInstance.getUnavailableBackendMessage();
	}
	
	//
	
	public void execute(Verification verification) throws IOException, InterruptedException {
		// Setting target folder
		setProjectLocation(verification); // Before the target folder
		setTargetFolder(verification);
		//
		setVerification(verification);
		Set<AnalysisLanguage> languagesSet = new LinkedHashSet<AnalysisLanguage>(
				verification.getAnalysisLanguages());
		checkArgument(languagesSet.size() == 1);
		List<String> verificationArguments = verification.getVerificationArguments();
		
		boolean distinguishStringFormulas = false;
		
		AbstractVerification verificationTask = null;
		propertySerializer = null;
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
				case NUXMV:
					verificationTask = NuxmvVerification.INSTANCE;
					propertySerializer = NuxmvPropertySerializer.INSTANCE;
					break;
				default:
					throw new IllegalArgumentException(analysisLanguage + " is not supported");
			}
		}
		String filePath = verification.getFileName().get(0);
		File modelFile = new File(filePath);
		
		//
		String emfModelFilePath = fileNamer.getEmfXStsUri(filePath);
		File emfModelFile = new File(emfModelFilePath);
		XSTS xSts = null;
		try {
			xSts = (XSTS) ecoreUtil.normalLoad(emfModelFile);
		} catch (RuntimeException e) {
			// The EMF xSts model is not found
		}
		//
		
		boolean isOptimize = verification.isOptimize();
		
		// Retrieved traces
		List<VerificationResult> retrievedVerificationResults = new ArrayList<VerificationResult>();
		List<ExecutionTrace> retrievedTraces = new ArrayList<ExecutionTrace>();
		
		// Map for collecting both supported property representations
		Map<String, StateFormula> formulas = new LinkedHashMap<String, StateFormula>();
		// LinkedHashMap needed to match .get and .json files
		
		// Serializing property formulas
		for (PropertyPackage propertyPackage : verification.getPropertyPackages()) {
			// Handle wrapped "atomic" components
			Component component = propertyPackage.getComponent();
			if (StatechartModelDerivedFeatures.needsWrapping(component)) {
				propertyUtil.extendFormulasWithWrapperInstance(propertyPackage);
			}
			//
			for (CommentableStateFormula formula : propertyPackage.getFormulas()) {
				StateFormula stateFormula = formula.getFormula();
				//
				adjustProperty(stateFormula, xSts);
				//
				String serializedFormula = propertySerializer.serialize(stateFormula);
				formulas.put(serializedFormula, stateFormula);
			}
			//
			if (StatechartModelDerivedFeatures.needsWrapping(component)) {
				propertyUtil.removeFirstInstanceFromFormulas(propertyPackage);
			}
			//
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
		
		// Checking if some of the unchecked properties are already covered by stored traces
		if (isOptimize) {
			removeCoveredProperties(formulaQueue);
		}
		
		boolean areAllPropertiesInvariants = verification.getQueryFiles().isEmpty() &&
				verification.getPropertyPackages().stream()
					.allMatch(it -> PropertyModelDerivedFeatures.areAllPropertiesInvariants(it));
		String[] arguments = verificationArguments.isEmpty() ?
				(areAllPropertiesInvariants ?
						verificationTask.getDefaultArgumentsForInvarianceChecking(modelFile) : 
							verificationTask.getDefaultArguments(modelFile)) :
					verificationArguments.toArray(new String[verificationArguments.size()]);
		
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
			
			// Adding comment to connect the trace with the property
			if (trace != null) {
				traceUtil.addComment(trace, serializedFormula);
			}
			
			TimeUnit timeUnit = TimeUnit.MILLISECONDS;
			long elapsed = stopwatch.elapsed(timeUnit);
			String elapsedString = elapsed + " " + timeUnit;
			
			retrievedVerificationResults.add(
				new VerificationResult(
					serializedFormula, verificationResult, arguments, elapsedString));
			
			// Checking if some of the unchecked properties are already covered
			if (isOptimize) {
				removeCoveredProperties(trace, formulaQueue);
			}
		}
		if (isOptimize) {
			// Optimization again on the retrieved tests (front to back and vice versa)
			traceUtil.removeCoveredExecutionTraces(retrievedTraces);
		}
		
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
		
		traces.addAll(retrievedTraces);
		
		if (serializeTraces) { // After 'traces.add...'
			serializeTraces(programmingLanguage);
		}
		
		// Note that .get and .json postfix ids will not match if optimization is applied
		for (VerificationResult verificationResult : retrievedVerificationResults) {
			serializer.serialize(targetFolderUri, traceFileName, verificationResult);
		}
	}
	
	//
	
	private void adjustProperty(StateFormula formula, XSTS xSts) {
		// Event references
		List<ComponentInstanceEventReferenceExpression> eventReferences =
				ecoreUtil.getAllContentsOfType(formula, ComponentInstanceEventReferenceExpression.class);
		for (ComponentInstanceEventReferenceExpression eventReference : eventReferences) {
			Port port = eventReference.getPort();
			Event event = eventReference.getEvent();
			
			StatechartDefinition statechart = StatechartModelDerivedFeatures.getContainingStatechart(port);
			if (statechart != null) {
				List<RaiseEventAction> raiseEvents = ecoreUtil.getAllContentsOfType(statechart, RaiseEventAction.class);
				boolean hasEventRaise = raiseEvents.stream()
							.anyMatch(it -> it.getPort() == port && // To support different interface resource loadings
								it.getEvent().getName().equals(event.getName()));
				
				if (!hasEventRaise) {
					ecoreUtil.replace(
							expressionFactory.createFalseExpression(), eventReference);
					logger.info("Removing reference to event " + port.getName() + "." + event.getName() + " in property");
				}
			}
		}
		
		// State references
		if (xSts != null) {
			AbstractReferenceSerializer referenceSerializer = propertySerializer
					.getPropertyExpressionSerializer().getReferenceSerializer();
			
			List<ComponentInstanceStateReferenceExpression> stateReferences =
					ecoreUtil.getAllContentsOfType(formula, ComponentInstanceStateReferenceExpression.class);
			for (ComponentInstanceStateReferenceExpression stateReference : stateReferences) {
				boolean removedState = false;
				
				ComponentInstanceReferenceExpression instance = stateReference.getInstance();
				Region region = stateReference.getRegion();
				State state = stateReference.getState();
				
				String variableName = referenceSerializer.getId(region, instance);
				String enumLiteralName = referenceSerializer.getXStsId(state);
				try {
					VariableDeclaration regionVariable = xStsUtil.checkVariable(xSts, variableName);
					EnumerationTypeDefinition type = (EnumerationTypeDefinition)
							XstsDerivedFeatures.getTypeDefinition(regionVariable);
					List<EnumerationLiteralDefinition> literals = type.getLiterals();
					
					removedState = literals.stream().noneMatch(
							it -> it.getName().equals(enumLiteralName));
				} catch (IllegalArgumentException e) {
					// No such variable
					removedState = true;
				}
				
				if (removedState) {
					ecoreUtil.replace(
							expressionFactory.createFalseExpression(), stateReference);
					logger.info("Removing reference to state " + region.getName() + "." + state.getName() + " in property");
				}
			}
		}
		// Note that variable references cannot be handled like this, as they can be (and are) removed  if their value
		// is known every time they are references (but this value can change), e.g., a:= 1; b := a + 2; a := 3; b := a + 4;
	}
	
	protected void removeCoveredProperties2(Collection<? extends CommentableStateFormula> formulas) {
		Collection<Entry<?, StateFormula>> wrappedFormulas = new ArrayList<Entry<?, StateFormula>>();
		
		final String dummyKey = "";
		for (CommentableStateFormula commentableStateFormula : formulas) {
			StateFormula formula = commentableStateFormula.getFormula();
			Entry<?, StateFormula> entry = Map.entry(dummyKey, formula);
			
			wrappedFormulas.add(entry);
		}
		//
		removeCoveredProperties(wrappedFormulas);
		//
		formulas.removeIf(it -> !wrappedFormulas.contains(Map.entry(dummyKey, it.getFormula())));
	}
	
	protected void removeCoveredProperties(Collection<? extends Entry<?, StateFormula>> formulas) {
		removeCoveredProperties(traces, formulas);
	}
	
	private void removeCoveredProperties(Collection<? extends ExecutionTrace> traces,
			Collection<? extends Entry<?, StateFormula>> formulas) {
		for (ExecutionTrace trace : traces) {
			removeCoveredProperties(trace, formulas);
		}
	}

	private void removeCoveredProperties(ExecutionTrace trace,
			Collection<? extends Entry<?, StateFormula>> formulas) {
		if (trace != null) {
			List<StateFormula> stateFormulas = formulas.stream()
					.map(it -> it.getValue())
					.filter(it -> it != null)
					.collect(Collectors.toList()); // Not null state formulas
			CoveredPropertyReducer reducer = new CoveredPropertyReducer(stateFormulas, trace);
			List<StateFormula> coveredProperties = reducer.execute();
			
			for (StateFormula coveredProperty : coveredProperties) {
				String serializedProperty = propertySerializer.serialize(coveredProperty);
				logger.info("Property already covered: " + serializedProperty);
				formulas.removeIf(it -> it.getValue() == coveredProperty);
			}
		}
	}
	
	//
	
	protected Result execute(AbstractVerification verificationTask, File modelFile,
			File queryFile, List<ExecutionTrace> retrievedTraces, boolean isOptimize) throws InterruptedException {
		return this.execute(verificationTask, modelFile, queryFile,
				new String[0], retrievedTraces, isOptimize);
	}
	
	protected Result execute(AbstractVerification verificationTask, File modelFile, File queryFile,
			String[] arguments, List<ExecutionTrace> retrievedTraces, boolean isOptimize) throws InterruptedException {
		long timeoutInMilliseconds = (timeout == null) ? -1 : expressionEvaluator.evaluateInteger(
				StatechartModelDerivedFeatures.getTimeInMilliseconds(timeout));
		// If arguments are empty, we execute a task with default arguments
		Result result = (arguments.length == 0) ?
				verificationTask.execute(modelFile, queryFile, timeoutInMilliseconds, TimeUnit.MILLISECONDS) :
					verificationTask.execute(modelFile, queryFile, arguments, timeoutInMilliseconds, TimeUnit.MILLISECONDS);
		
		ExecutionTrace trace = result.getTrace();
		// Maybe there is no trace
		if (trace != null) {
			if (isOptimize) {
				logger.info("Checking if trace is already covered by previous traces...");
				if (traceUtil.isCovered(trace, retrievedTraces)) {
					logger.info("Trace is already covered");
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
		List<String> packageNames = verification.getPackageName();
		if (packageNames.isEmpty()) {
			this.packageName = file.getProject().getName().toLowerCase();
			packageNames.add(packageName);
		}
		List<String> testFolders = verification.getTestFolder();
		if (testFolders.isEmpty()) {
			testFolders.add("test-gen");
		}
		List<String> svgFileNames = verification.getSvgFileName();
		if (!svgFileNames.isEmpty()) {
			this.svgFileName = svgFileNames.get(0);
		}
		List<ProgrammingLanguage> programmingLanguages = verification.getProgrammingLanguages();
		if (programmingLanguages.isEmpty()) {
			this.serializeTest = false;
		}
		else {
			this.programmingLanguage = programmingLanguages.get(0);
			this.serializeTest = true;
			// Setting the attribute, the test folder is a RELATIVE path now from the project
			this.testFolderUri = URI.decode(projectLocation + File.separator + testFolders.get(0));
		}
		Resource resource = verification.eResource();
		File file = (resource != null) ?
				ecoreUtil.getFile(resource).getParentFile() : // If Verification is contained in a resource
					fileUtil.toFile(super.file).getParentFile(); // If Verification is created in Java
		// Setting the file paths
		verification.getFileName().replaceAll(it -> fileUtil.exploreRelativeFile(file, it).toString());
		// Setting the query paths
		verification.getQueryFiles().replaceAll(it -> fileUtil.exploreRelativeFile(file, it).toString());
		// Setting the timeout
		this.timeout = verification.getTimeout();
	}
	
	protected AbstractVerification getVerification(Verification verification) {
		Set<AnalysisLanguage> languagesSet = new LinkedHashSet<AnalysisLanguage>(
				verification.getAnalysisLanguages());
		AnalysisLanguage analysisLanguage = javaUtil.getLast(languagesSet);
		return getVerification(analysisLanguage);
	}

	protected AbstractVerification getVerification(AnalysisLanguage analysisLanguage) {
		switch (analysisLanguage) {
			case UPPAAL:
				return UppaalVerification.INSTANCE;
			case THETA:
				return ThetaVerification.INSTANCE;
			case XSTS_UPPAAL:
				return XstsUppaalVerification.INSTANCE;
			case PROMELA:
				return PromelaVerification.INSTANCE;
			case NUXMV:
				return NuxmvVerification.INSTANCE;
			default:
				throw new IllegalArgumentException(analysisLanguage + " is not supported");
		}
	}
	
	//
	
	public List<ExecutionTrace> getTraces() {
		return traces;
	}
	
	public void optimizeTraces() {
		// Optimization again on the retrieved tests (front to back and vice versa)
		traceUtil.removeCoveredExecutionTraces(traces);
	}
	
	public void serializeTraces(ProgrammingLanguage programmingLanguage) throws IOException {
		// Serializing
		String testFolderUri = serializeTest ? this.testFolderUri : null;
		String testFileName = serializeTest ? this.testFileName : null;
		String packageName = serializeTest ? this.packageName : null;
		for (ExecutionTrace trace : traces) {
			serializer.serialize(targetFolderUri, traceFileName, svgFileName,
					testFolderUri, testFileName, packageName, trace,
					file, programmingLanguage);
		}
	}
	
	public ProgrammingLanguage getProgrammingLanguage() {
		return this.programmingLanguage;
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
		
		public void serialize(String traceFolderUri, String traceFileName, ExecutionTrace trace, IFile file, ProgrammingLanguage programmingLanguage) throws IOException {
			this.serialize(traceFolderUri, traceFileName, null, null, null, trace, file, programmingLanguage);
		}
		
		public void serialize(String traceFolderUri, String traceFileName,
				String testFolderUri, String testFileName, String basePackage, ExecutionTrace trace,
				IFile file, ProgrammingLanguage programmingLanguage) throws IOException {
			this.serialize(traceFolderUri, traceFileName, null, testFolderUri, testFileName, basePackage, trace, file, programmingLanguage);
		}
		
		public void serialize(String traceFolderUri, String traceFileName, String svgFileName,
				String testFolderUri, String testFileName, String basePackage, ExecutionTrace trace,
				IFile file, ProgrammingLanguage programmingLanguage) throws IOException {
			
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
				TestGeneration testGeneration = GenmodelModelFactory.eINSTANCE.createTestGeneration();
				testGeneration.setExecutionTrace(trace);
				
				String className = testFileName + id;
				testGeneration.getFileName().add(className);
				testGeneration.getProgrammingLanguages().add(programmingLanguage);
				
				TestGenerationHandler testGenerationHandler = new TestGenerationHandler(file);
				testGenerationHandler.execute(testGeneration, basePackage);
			
//				TestGenerator testGenerator = new TestGenerator(trace, basePackage, className);
//				String testCode = testGenerator.execute();
//				String packageUri = testGenerator.getPackageName().replaceAll("\\.", "/");
//				fileUtil.saveString(testFolderUri + File.separator + packageUri +
//					File.separator + className + ".java", testCode);
			}
		}

		protected void serializeJavaTestCase(String testFolderUri, String basePackage,
				String className, ExecutionTrace trace) {
			TestGenerator testGenerator = new TestGenerator(trace, basePackage, className);
			String testCode = testGenerator.execute();
			String packageUri = testGenerator.getPackageName().replaceAll("\\.", "/");
			fileUtil.saveString(testFolderUri + File.separator + packageUri +
				File.separator + className + ".java", testCode);
		}
		
		// Serialization of test cases for additional programming languages here...
		
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