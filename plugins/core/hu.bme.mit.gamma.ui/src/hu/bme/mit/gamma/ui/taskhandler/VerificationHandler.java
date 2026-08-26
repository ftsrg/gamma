/********************************************************************************
 * Copyright (c) 2018-2026 Contributors to the Gamma project
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
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.ListIterator;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Queue;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;

import com.google.common.base.Stopwatch;
import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import hu.bme.mit.gamma.expression.model.EnumerationLiteralDefinition;
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition;
import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.ExecutionMode;
import hu.bme.mit.gamma.genmodel.model.GenmodelModelFactory;
import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.genmodel.model.TestGeneration;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.iml.verification.ImlVerification;
import hu.bme.mit.gamma.nuxmv.verification.NuxmvVerification;
import hu.bme.mit.gamma.ocra.verification.OcraVerification;
import hu.bme.mit.gamma.plantuml.serialization.SvgSerializer;
import hu.bme.mit.gamma.plantuml.transformation.TraceToPlantUmlTransformer;
import hu.bme.mit.gamma.promela.verification.PromelaVerification;
import hu.bme.mit.gamma.property.derivedfeatures.PropertyModelDerivedFeatures;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.property.util.PropertyUtil;
import hu.bme.mit.gamma.querygenerator.serializer.AbstractReferenceSerializer;
import hu.bme.mit.gamma.querygenerator.serializer.ImlPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.NuxmvPropertySerializer;
import hu.bme.mit.gamma.querygenerator.serializer.OcraPropertySerializer;
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
import hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.util.TraceUtil;
import hu.bme.mit.gamma.transformation.util.GammaFileNamer;
import hu.bme.mit.gamma.transformation.util.StatechartEcoreUtil;
import hu.bme.mit.gamma.transformation.util.UnfoldedExecutionTraceBackAnnotator;
import hu.bme.mit.gamma.transformation.util.reducer.CoveredPropertyReducer;
import hu.bme.mit.gamma.ui.taskhandler.VerificationHandler.ExecutionTraceSerializer.VerificationResult;
import hu.bme.mit.gamma.uppaal.verification.UppaalVerification;
import hu.bme.mit.gamma.uppaal.verification.XstsUppaalVerification;
import hu.bme.mit.gamma.util.FileUtil;
import hu.bme.mit.gamma.util.InterruptableCallable;
import hu.bme.mit.gamma.util.ThreadRacer;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;
import hu.bme.mit.gamma.verification.util.AbstractVerification;
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result;
import hu.bme.mit.gamma.verification.util.CompletenessCheckPostprocessor;
import hu.bme.mit.gamma.verification.util.DeadlockCheckPostprocessor;
import hu.bme.mit.gamma.verification.util.DeadlockStateCheckPostprocessor;
import hu.bme.mit.gamma.verification.util.DeterminismCheckPostprocessor;
import hu.bme.mit.gamma.verification.util.InteractionCheckPostprocessor;
import hu.bme.mit.gamma.verification.util.OrthogonalLeafStateCombinationCheckPostprocessor;
import hu.bme.mit.gamma.verification.util.OrthogonalStateCombinationCheckPostprocessor;
import hu.bme.mit.gamma.verification.util.StateReachabilityCheckPostprocessor;
import hu.bme.mit.gamma.verification.util.TransitionExecutabilityCheckPostprocessor;
import hu.bme.mit.gamma.verification.util.TransitionPairExecutabilityCheckPostprocessor;
import hu.bme.mit.gamma.verification.util.TrapStateCheckPostprocessor;
import hu.bme.mit.gamma.verification.util.VerificationPostprocessor;
import hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures;
import hu.bme.mit.gamma.xsts.model.XSTS;
import hu.bme.mit.gamma.xsts.util.XstsActionUtil;

public class VerificationHandler extends TaskHandler {
	
	protected final boolean setSerializeResults; // Set externally: denotes whether JSON results are serialized
	protected final boolean setSerializeTraces; // Set externally: denotes whether traces are serialized
	protected boolean serializeResults; // Comes in Verification: denotes whether JSON results are serialized
	protected boolean serializeTraces; // Comes in Verification: denotes whether traces are serialized
	protected boolean serializeTest; // Denotes whether test code is generated
	protected String testFolderUri;
	// targetFolderUri is traceFolderUri 
	protected String packageName; // Set in setVerification
	protected String svgFileName; // Set in setVerification
	protected ProgrammingLanguage programmingLanguage; // Set in setVerification
	protected String traceFileName = "ExecutionTrace";
	protected String testedFileName;
	
	protected TimeSpecification timeout = null;
	
	protected AbstractVerification verificationTask = null;
	protected PropertySerializer propertySerializer = null;
	protected final VerificationPostprocessor verificationPostprocessor;
	
	protected final List<ExecutionTrace> traces = new ArrayList<ExecutionTrace>();
	protected final Set<Result> optimizedResults = new LinkedHashSet<Result>();
	protected final Set<VerificationResult> optimizedVerificationResults = new LinkedHashSet<VerificationResult>();
	protected final Set<Result> allResults = new LinkedHashSet<Result>();
	protected final Set<VerificationResult> allVerificationResults = new LinkedHashSet<VerificationResult>();
	
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
		this(file, serializeTraces, null);
	}
	
	public VerificationHandler(IFile file, VerificationPostprocessor verificationPostprocessor) {
		this(file, true, verificationPostprocessor);
	}
	
	public VerificationHandler(IFile file, boolean serializeTraces, VerificationPostprocessor verificationPostprocessor) {
		this(file, true, serializeTraces, verificationPostprocessor);
	}
	
	public VerificationHandler(IFile file, boolean serializeResults, boolean serializeTraces,
			VerificationPostprocessor verificationPostprocessor) {
		super(file);
		this.setSerializeResults = serializeResults;
		this.setSerializeTraces = serializeTraces;
		this.verificationPostprocessor = verificationPostprocessor;
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
	
	public Entry<InterruptableCallable<VerificationHandler>, Verification> wrap(
			Verification verification, AnalysisLanguage analysisLanguage) {
		return wrap(verification, analysisLanguage, false, false); // By default: no serialization to prevent race conditions
	}
	
	public Entry<InterruptableCallable<VerificationHandler>, Verification> wrap(
			Verification verification, AnalysisLanguage analysisLanguage,
			boolean setSerializeResults, boolean setSerializeTraces) {
		Verification verification2 = ecoreUtil.clone(verification);
		verification2.getAnalysisLanguages().clear();
		verification2.getAnalysisLanguages().add(analysisLanguage);
		
		VerificationHandler verificationHandler2 = new VerificationHandler(file, setSerializeResults, setSerializeTraces, null);
		InterruptableCallable<VerificationHandler> verificationCall = new InterruptableCallable<VerificationHandler>() {
			public VerificationHandler call() throws Exception {
				verificationHandler2.executeOnce(verification2);
				logger.info(analysisLanguage + " has finished");
				return verificationHandler2; // Dummy
			}
			public void cancel() {
				verificationHandler2.cancel();
				logger.info(analysisLanguage + " has been canceled");
			}
		};
		
		return Map.entry(verificationCall, verification2);
	}
	
	//
	
	public void execute(Verification verification) throws IOException, InterruptedException {
		List<AnalysisLanguage> analysisLanguages = verification.getAnalysisLanguages();
		List<AnalysisLanguage> originalLanguages = new ArrayList<AnalysisLanguage>(analysisLanguages);
		if (analysisLanguages.isEmpty()) {
			logger.info("Setting smart verification");
			analysisLanguages.add(AnalysisLanguage.SMART);
		}
		
		List<AnalysisLanguage> specificLanguagesView = new ArrayList<AnalysisLanguage>(analysisLanguages);
		if (specificLanguagesView.contains(AnalysisLanguage.SMART_ALL)) {
			specificLanguagesView = getAllSmartAnalysisLanguages();
		}
		
		if (specificLanguagesView.size() <= 1) {
			executeOnce(verification); // Default mode (single language or smart, non smart-all)
			return;
		}
		
		ExecutionMode executionMode = verification.getExecutionMode();
		if (executionMode == ExecutionMode.SEQUENTIAL || executionMode == ExecutionMode.PARALLEL) {
			// Parallel execution
			List<InterruptableCallable<VerificationHandler>> callables = new ArrayList<>();
			
			for (AnalysisLanguage analysisLanguage : specificLanguagesView) {
				var wrap = wrap(verification, analysisLanguage);
				InterruptableCallable<VerificationHandler> callable = wrap.getKey();
				callables.add(callable);
			}
			
			int threadNum = (executionMode == ExecutionMode.PARALLEL) ? specificLanguagesView.size() : 1 /* Sequential */;
			try (ExecutorService executor = Executors.newFixedThreadPool(threadNum)) {
				var results = executor.invokeAll(callables); // Blocking call
				for (Future<VerificationHandler> future : results) {
					VerificationHandler handler = future.resultNow();
					addAllResults(handler);
				}
			}
		}
		else if (executionMode == ExecutionMode.RACING) {
			if (verification.isOptimize() || GenmodelDerivedFeatures.getFormulaCount(verification) <= 1) {
				// Racing: all properties jointly
				List<InterruptableCallable<VerificationHandler>> verificationCalls = new ArrayList<InterruptableCallable<VerificationHandler>>();
				for (AnalysisLanguage analysisLanguage : specificLanguagesView) {
					Entry<InterruptableCallable<VerificationHandler>, Verification> entry = wrap(verification, analysisLanguage);
					InterruptableCallable<VerificationHandler> verificationCall = entry.getKey();
					verificationCalls.add(verificationCall);
				}
				ThreadRacer<VerificationHandler> threadRacer = new ThreadRacer<VerificationHandler>(verificationCalls);
				VerificationHandler winnerHandler = threadRacer.execute();
				
				addAllResults(winnerHandler);
			}
			else {
				// Racing: property by property
				for (PropertyPackage propertyPackage : verification.getPropertyPackages()) {
					PropertyPackage propertyPackage2 = ecoreUtil.clone(propertyPackage);
					List<CommentableStateFormula> formulas2 = propertyPackage2.getFormulas();
					List<CommentableStateFormula> allFormulas = new ArrayList<CommentableStateFormula>(formulas2);
					for (CommentableStateFormula formula : allFormulas) {
						List<InterruptableCallable<VerificationHandler>> verificationCalls = new ArrayList<InterruptableCallable<VerificationHandler>>();
						
						formulas2.clear();
						formulas2.add(formula);
						
						for (AnalysisLanguage analysisLanguage : specificLanguagesView) {
							Entry<InterruptableCallable<VerificationHandler>, Verification> entry = wrap(verification, analysisLanguage);
							InterruptableCallable<VerificationHandler> verificationCall = entry.getKey();
							Verification verification2 = entry.getValue();
							
							verification2.getPropertyPackages().clear();
							verification2.getPropertyPackages().add(propertyPackage2);
							
							verificationCalls.add(verificationCall);
						}
						
						ThreadRacer<VerificationHandler> threadRacer = new ThreadRacer<VerificationHandler>(verificationCalls);
						VerificationHandler winnerHandler = threadRacer.execute();
						
						addAllResults(winnerHandler);
					}
				}
			}
		}
		else {
			throw new IllegalArgumentException("Not known execution mode: " + executionMode);
		}
		
		setAll(verification);
		doSetSerialization();
		analysisLanguages.clear();
		analysisLanguages.addAll(originalLanguages); // Restore original
	}
	
	protected void executeOnce(Verification verification) throws IOException, InterruptedException {
		setAll(verification);
		
		List<AnalysisLanguage> languagesSet = verification.getAnalysisLanguages();
		int size = languagesSet.size();
		checkArgument(size == 1, size);
		List<String> verificationArguments = verification.getVerificationArguments();
		
		boolean distinguishStringFormulas = false;
		
		verificationTask = null;
		propertySerializer = null;
		AnalysisLanguage analysisLanguage = languagesSet.getFirst();
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
			case IML:
				verificationTask = ImlVerification.INSTANCE;
				propertySerializer = ImlPropertySerializer.INSTANCE;
				break;
			case OCRA:
				verificationTask = OcraVerification.INSTANCE;
				propertySerializer = OcraPropertySerializer.INSTANCE;
				break;
			default:
				throw new IllegalArgumentException(analysisLanguage + " is not supported");
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
		
		// Retrieved verification results and traces
		List<Result> results = new ArrayList<Result>();
		List<ExecutionTrace> retrievedTraces = new ArrayList<ExecutionTrace>(); // Derivable from verificationResults
		List<VerificationResult> derivedVerificationResults = new ArrayList<VerificationResult>();
		
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
			
			for (CommentableStateFormula formula : propertyPackage.getFormulas()) {
				StateFormula stateFormula = formula.getFormula();
				//
				adjustProperty(stateFormula, xSts);
				//
				String serializedFormula = propertySerializer.serialize(stateFormula);
				formulas.put(serializedFormula, stateFormula);
			}
			
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
			String fileName = fileNamer.getHiddenSerializedPropertyFileName(
					fileUtil.getExtensionlessName(file) + "-" + verificationTask.getBackendName());
			String queryFilePath = file.getParentFile().toString() + File.separator + fileName;
			File queryFile = new File(queryFilePath);
			fileUtil.saveString(queryFile, serializedFormula);
			queryFile.deleteOnExit();
			
			Stopwatch stopwatch = Stopwatch.createStarted();
			
			Result result = execute(verificationTask, modelFile, queryFile, arguments,
					retrievedTraces, isOptimize);
			
			stopwatch.stop();
			
			// Trying to fetch the original property
			result = result.clone(
					formulas.get(serializedFormula));
			
			results.add(result);
			ExecutionTrace trace = result.getTrace();
			ThreeStateBoolean verificationResult = result.getResult();
			
			logger.info("Verification result: " + verificationResult);
			
			// Adding comment to connect the trace with the property
			if (trace != null) {
				traceUtil.addComment(trace, serializedFormula);
			}
			
			TimeUnit timeUnit = TimeUnit.MILLISECONDS;
			long elapsed = stopwatch.elapsed(timeUnit);
			String elapsedString = elapsed + " " + timeUnit;
			
			String modelPath = ecoreUtil.getPlatformUri(modelFile).toPlatformString(true);
			derivedVerificationResults.add(
				new VerificationResult(modelPath,
					serializedFormula, verificationResult, arguments, elapsedString));
			
			// Checking if some of the unchecked properties are already covered
			if (isOptimize) {
				removeCoveredProperties(trace, formulaQueue);
			}
		}
		if (isOptimize) {
			// Optimization again on the retrieved tests (front to back and vice versa)
			Collection<ExecutionTrace> removedTraces = traceUtil.removeCoveredExecutionTraces(retrievedTraces);
			results.removeIf(it -> removedTraces.contains(it.getTrace()));
		}
		
		// Back-annotation
		if (verification.isBackAnnotateToOriginal()) {
			List<ExecutionTrace> backAnnotatedTraces = new ArrayList<ExecutionTrace>();
			for (ExecutionTrace trace : retrievedTraces) {
				Component newComponent = trace.getComponent();
				Component originalComponent = statechartEcoreUtil.loadAndReplaceToOriginalComponent(newComponent);
				
				UnfoldedExecutionTraceBackAnnotator backAnnotator =
						new UnfoldedExecutionTraceBackAnnotator(trace, originalComponent);
				ExecutionTrace orignalTrace = backAnnotator.execute();
				
				backAnnotatedTraces.add(orignalTrace);
				
				// Changing in the results list
				for (int i = 0; i < results.size(); i++) {
					Result result = results.get(i);
					if (result.getTrace() == trace) {
						Result newResult = result.clone(orignalTrace);
						results.set(i, newResult);
					}
				}
			}
			
			retrievedTraces.clear();
			retrievedTraces.addAll(backAnnotatedTraces);
		}
		
		// Serialization
		allVerificationResults.addAll(derivedVerificationResults);
		allVerificationResults.addAll(optimizedVerificationResults);
		
		traces.addAll(retrievedTraces);
		
		allResults.addAll(results);
		allResults.addAll(optimizedResults);
		
		doSetSerialization();
	}
	
	protected void doSetSerialization() throws IOException {
		if (serializeResults && setSerializeResults) {
			serializeResults();
		}
		if (serializeTraces && setSerializeTraces) {
			serializeTraces();
		}
		if (verificationPostprocessor != null) {
			verificationPostprocessor.execute(allResults);
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
		
		removeCoveredProperties(wrappedFormulas);
		
		formulas.removeIf(it -> !wrappedFormulas.contains(
				Map.entry(dummyKey, it.getFormula())));
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
		List<StateFormula> allCoveredProperties = new ArrayList<StateFormula>();
		
		if (trace != null) {
			List<StateFormula> stateFormulas = formulas.stream()
					.map(it -> it.getValue())
					.filter(it -> it != null)
					.toList(); // Not null state formulas
			CoveredPropertyReducer reducer = new CoveredPropertyReducer(stateFormulas, trace);
			List<StateFormula> coveredProperties = reducer.execute();
			
			for (StateFormula coveredProperty : coveredProperties) {
				String serializedProperty = propertySerializer.serialize(coveredProperty);
				logger.info("Property already covered: " + serializedProperty);
				allCoveredProperties.add(coveredProperty);
			}
		}
		
		formulas.removeIf(it -> allCoveredProperties.contains(it.getValue()));
		
		// Registering optimized properties
		for (StateFormula coveredProperty : allCoveredProperties) {
			boolean result = PropertyModelDerivedFeatures.getBooleanResultIfTraceExists(coveredProperty);
			ThreeStateBoolean value = ThreeStateBoolean.of(result);
			
			Result optimizedResult = new Result(coveredProperty, value, null);
			optimizedResults.add(optimizedResult);
			
			File modelFile = ecoreUtil.getFile(trace.getComponent());
			String modelPath = ecoreUtil.getPlatformUri(modelFile).toPlatformString(true);
			String serializedProperty = propertySerializer.serialize(coveredProperty);
			VerificationResult optimizedVerificationResult = new VerificationResult(modelPath, serializedProperty, value);
			optimizedVerificationResults.add(optimizedVerificationResult);
		}
	}
	
	//
	
	public void cancel() {
		if (verificationTask != null) {
			verificationTask.cancel();
		}
	}
	
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
	
	protected void setAll(Verification verification) {
		// Setting target folder
		setProjectLocation(verification); // Before the target folder
		setTargetFolder(verification);
		//
		setVerification(verification);
	}
	
	private void setVerification(Verification verification) {
		List<AnalysisLanguage> analysisLanguages = verification.getAnalysisLanguages();
		setSmartAnalysisLanguages(analysisLanguages);
		
		List<String> traceFileNames = verification.getFileName2();
		if (!traceFileNames.isEmpty()) {
			this.traceFileName = traceFileNames.get(0);
		}
		List<String> packageNames = verification.getPackageName();
		if (packageNames.isEmpty()) {
			this.packageName = file.getProject().getName().toLowerCase();
			packageNames.add(packageName);
		}
		List<String> testFolders = verification.getTestFolder();
		if (testFolders.isEmpty()) {
			testFolders.add("test-gen");
		}
		List<String> testedFileName = verification.getTestedFileName();
		if (!testedFileName.isEmpty()) {
			this.testedFileName = testedFileName.get(0);
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
		this.serializeResults = verification.isSerializeResults();
		this.serializeTraces = verification.isSerializeTraces();
		Resource resource = verification.eResource();
		File file = (resource != null) ?
				ecoreUtil.getFile(resource).getParentFile() : // If Verification is contained in a resource
					fileUtil.toFile(super.file).getParentFile(); // If Verification is created in Java
		// Setting the file paths
		List<String> fileNames = verification.getFileName();
		for (int i = 0; i < fileNames.size(); i++) {
			String fileName = fileNames.get(i);
			if (!fileUtil.hasExtension(fileName)) {
				AnalysisLanguage language = analysisLanguages.getFirst();
				String newFileName = fileUtil.changeExtension(fileName,
						fileNamer.getFileExtension(language));
				logger.info("Setting file extension: " + newFileName);
				fileNames.set(i, newFileName);
			}
		}
		fileNames.replaceAll(it -> fileUtil.exploreRelativeFile(file, it).toString());
		if (1 < analysisLanguages.size()) {
			fileNames.replaceAll(it -> fileUtil.getExtensionlessName(it));
		}
		// Setting the query paths
		verification.getQueryFiles().replaceAll(it -> fileUtil.exploreRelativeFile(file, it).toString());
		// Setting the timeout
		this.timeout = verification.getTimeout();
	}
	
	protected AbstractVerification getVerification(Verification verification) {
		Collection<AnalysisLanguage> languagesSet = verification.getAnalysisLanguages();
		AnalysisLanguage analysisLanguage = javaUtil.getLastElement(languagesSet);
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
			case IML:
				return ImlVerification.INSTANCE;
			default:
				throw new IllegalArgumentException(analysisLanguage + " is not supported");
		}
	}
	
	protected VerificationPostprocessor createVerificationPostprocessor(Verification verification) {
		List<PropertyPackage> propertyPackages = verification.getPropertyPackages();
		if (!propertyPackages.isEmpty()) {
			PropertyPackage propertyPackage = propertyPackages.getFirst();
			List<String> coverages = propertyPackage.getCoverages();
			if (!coverages.isEmpty()) {
				String coverage = coverages.getFirst();
				String shortCoverage = coverage.replace("Coverage", "");
				switch (shortCoverage) {
					case "State": return new StateReachabilityCheckPostprocessor();
					case "Transition": return new TransitionExecutabilityCheckPostprocessor();
					case "TransitionPair": return new TransitionPairExecutabilityCheckPostprocessor();
					case "OutEvent" : return null;
					case "Interaction" : return new InteractionCheckPostprocessor();
					case "InteractionDataflow" : return null;
					case "Dataflow" : return null;
					case "TrapState" : return new TrapStateCheckPostprocessor(null);
					case "UnstableState" : return null;
					case "OrthogonalLeafStateCombination" : return new OrthogonalStateCombinationCheckPostprocessor(null);
					case "OrthogonalStateCombination" : return new OrthogonalLeafStateCombinationCheckPostprocessor(null);
					case "DeadlockState" : return new DeadlockStateCheckPostprocessor(null);
					case "Deadlock" : return new DeadlockCheckPostprocessor();
					case "NonDeterministicTransition" : return new DeterminismCheckPostprocessor();
					case "Completeness" : return new CompletenessCheckPostprocessor(null);
					case "QueueOverflow" : return null;
					
					default: return null;
				}
			}
		}
		return null;
	}
	
	//
	
	protected void addAllResults(Collection<? extends VerificationHandler> verificationHandlers) {
		for (VerificationHandler verificationHandler : verificationHandlers) {
			addAllResults(verificationHandler);
		}
	}
	
	protected void addAllResults(VerificationHandler verificationHandler) {
		traces.addAll(verificationHandler.traces);
		allVerificationResults.addAll(verificationHandler.allVerificationResults);
		allResults.addAll(verificationHandler.allResults);
	}
	
	public List<ExecutionTrace> getTraces() {
		return traces;
	}
	
	public VerificationPostprocessor getVerificationPostprocessor() {
		return verificationPostprocessor;
	}
	
	public void optimizeTraces() {
		// Optimization again on the retrieved tests (front to back and vice versa)
		traceUtil.removeCoveredExecutionTraces(traces);
	}
	
	public void serializeResults() throws IOException {
		serializer.serialize(targetFolderUri, traceFileName, allVerificationResults);
	}
	
	public void serializeTraces() throws IOException {
		serializeTraces(programmingLanguage);
	}
	
	public void serializeTraces(ProgrammingLanguage programmingLanguage) throws IOException {
		// Serializing
		String testFolderUri = serializeTest ? this.testFolderUri : null;
		String testFileName = serializeTest ? this.getTestFileName() : null;
		String testedFileName = serializeTest ? this.testedFileName : null;
		String packageName = serializeTest ? this.packageName : null;
		for (ExecutionTrace trace : traces) {
			serializer.serialize(targetFolderUri, traceFileName, svgFileName,
					testFolderUri, testFileName, testedFileName, packageName, trace,
					file, programmingLanguage);
		}
	}
	
	public String getTestFileName() {
		return traceFileName + "Simulation";
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
			this.serialize(traceFolderUri, traceFileName, null, testFolderUri, testFileName,
					null, basePackage, trace, file, programmingLanguage);
		}
		
		public void serialize(String traceFolderUri, String traceFileName, String svgFileName,
				String testFolderUri, String testFileName, String testedFileName,
				String basePackage, ExecutionTrace trace,
				IFile file, ProgrammingLanguage programmingLanguage) throws IOException {
			// Model
			File traceFolder = new File(traceFolderUri);
			String baseFileName = traceFileName;
			Integer id = getCorrespondingIndex(traceFolder, trace);
			if (id == null) {
				id = getNextIndex(traceFolderUri, traceFileName);
			}
			
			String fileName = baseFileName + id + "." + GammaFileNamer.EXECUTION_XTEXT_EXTENSION;
			serializer.saveModel(trace, traceFolderUri, fileName);
			
			// SVG
			if (svgFileName != null) {
				TraceToPlantUmlTransformer transformer = new TraceToPlantUmlTransformer(trace);
				String plantUmlString = transformer.execute();
				SvgSerializer serializer = SvgSerializer.INSTANCE;
				String svg = serializer.serialize(plantUmlString);
				String svgFileNameWithId = svgFileName + id;
				String path = traceFolderUri + File.separator + svgFileNameWithId + ".svg";
				fileUtil.saveString(path, svg);
			}
			
			// Test
			boolean serializeTest = testFolderUri != null && testFileName != null && basePackage != null;
			if (serializeTest) {
				TestGeneration testGeneration = GenmodelModelFactory.eINSTANCE.createTestGeneration();
				testGeneration.setExecutionTrace(trace);
				if (testedFileName != null) {
					testGeneration.getFileName2().add(testedFileName);
				}
				
				String className = testFileName + id;
				testGeneration.getFileName().add(className);
				testGeneration.getProgrammingLanguages().add(programmingLanguage);
				
				TestGenerationHandler testGenerationHandler = new TestGenerationHandler(file);
				testGenerationHandler.execute(testGeneration, basePackage);
			}
		}
		
		protected File getCorrespondingJsonFile(File traceFolder, ExecutionTrace trace) {
			String comment = TraceModelDerivedFeatures.getComment(trace);
			
			File[] jsonFiles = traceFolder.listFiles(
					it -> fileUtil.getExtension(it).equals("json"));
			if (jsonFiles != null) {
				List<File> sortedJsonFiles = fileUtil.sortIndexedFiles(
						Arrays.asList(jsonFiles));
				ListIterator<File> iterator = sortedJsonFiles.listIterator(sortedJsonFiles.size());
				while (iterator.hasPrevious()) {
					try {
						File jsonFile = iterator.previous();
						FileReader reader = new FileReader(jsonFile);
						VerificationResult result = gson.fromJson(reader, VerificationResult.class);
						String query = result.getQuery();
						if (query.equals(comment)) {
							return jsonFile; // Depends on iteration order (see sorting/reversing above)
						}
					} catch (Exception e) {}
				}
			}
			
			return null;
		}
		
		protected Integer getCorrespondingIndex(File traceFolder, ExecutionTrace trace) {
			File jsonFile = getCorrespondingJsonFile(traceFolder, trace);
			if (jsonFile != null) {
				return fileUtil.getIndex(jsonFile);
			}
			
			return null;
		}
		
		protected Integer getNextIndex(String folder, String fileName) {
			Entry<String, Integer> fileNamePair = fileUtil.getFileName(folder,
					fileName, GammaFileNamer.VERIFICATION_RESULT_EXTENSION);
			Entry<String, Integer> fileNamePair2 = fileUtil.getFileName(folder,
					fileName, GammaFileNamer.EXECUTION_XTEXT_EXTENSION);
			int id = Integer.max(fileNamePair.getValue(), fileNamePair2.getValue());
			return id;
		}
		
		public void serialize(String resultFolderUri, String resultFileName,
				Collection<? extends VerificationResult> results) throws IOException {
			for (VerificationResult result : results) {
				serialize(resultFolderUri, resultFileName, result);
			}
		}
		
		public void serialize(String resultFolderUri, String resultFileName,
				VerificationResult result) throws IOException {
			int id = getNextIndex(resultFolderUri, resultFileName);
			String jsonResult = gson.toJson(result);
			String path = resultFolderUri + File.separator + resultFileName + id + "." + GammaFileNamer.VERIFICATION_RESULT_EXTENSION;
			fileUtil.saveString(path, jsonResult);
		}
		
		@SuppressWarnings("unused")
		public static class VerificationResult {
			
			private String modelPath;
			private String query;
			private ThreeStateBoolean result;
			private String[] parameters;
			private String executionTime;
			
			public VerificationResult(String modelPath, String query, ThreeStateBoolean result) {
				this(modelPath, query, result, null, null);
			}
			
			public VerificationResult(String modelPath, String query, ThreeStateBoolean result,
					String[] parameters, String executionTime) {
				this.modelPath = modelPath;
				this.query = query;
				this.result = result;
				this.parameters = parameters;
				this.executionTime = executionTime;
			}
			
			public String getQuery() {
				return query;
			}
			
		}
		
	}
	
}