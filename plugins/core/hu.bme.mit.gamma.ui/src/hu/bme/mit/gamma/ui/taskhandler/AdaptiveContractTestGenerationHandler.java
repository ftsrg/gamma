/********************************************************************************
 * Copyright (c) 2020-2023 Contributors to the Gamma project
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
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;

import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.AdaptiveContractTestGeneration;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.Constraint;
import hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint;
import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.scenario.trace.generator.ScenarioStatechartTraceGenerator;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.contract.StateContractAnnotation;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StateAnnotation;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;
import hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;
import hu.bme.mit.gamma.trace.model.Step;
import hu.bme.mit.gamma.trace.util.TraceUtil;
import hu.bme.mit.gamma.transformation.util.GammaFileNamer;
import hu.bme.mit.gamma.ui.taskhandler.VerificationHandler.ExecutionTraceSerializer;

public class AdaptiveContractTestGenerationHandler extends TaskHandler {
	//
	protected String packageName;
	protected String testFolderUri;
	protected String traceFileName;
	protected String testFileName;
	//
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	protected final ExecutionTraceSerializer serializer = ExecutionTraceSerializer.INSTANCE;
	protected final TraceUtil traceUtil = TraceUtil.INSTANCE;

	//
	public AdaptiveContractTestGenerationHandler(IFile file) {
		super(file);
	}

	public void execute(AdaptiveContractTestGeneration testGeneration) throws IOException, InterruptedException {
		// Setting target folder
		setProjectLocation(testGeneration); // Before the target folder
		setTargetFolder(testGeneration);
		//
		checkArgument(testGeneration.getProgrammingLanguages().size() == 1,
				"A single programming language must be specified: " + testGeneration.getProgrammingLanguages());
		checkArgument(testGeneration.getProgrammingLanguages().get(0) == ProgrammingLanguage.JAVA,
				"Currently only Java is supported");
		setAdaptiveContractTestGeneration(testGeneration);

		AnalysisModelTransformation modelTransformation = testGeneration.getModelTransformation();
		AnalysisLanguage analysisLanguage = modelTransformation.getLanguages().get(0);
		AnalysisModelTransformationHandler handler = new AnalysisModelTransformationHandler(file);
		handler.execute(modelTransformation);

		String plainFileName = modelTransformation.getFileName().get(0);
		
		String modelFileName = handler.getFileName(plainFileName, analysisLanguage);
		String modelFileUri = handler.getTargetFolderUri() + File.separator + modelFileName;

		String propertyFileName = fileNamer.getHiddenPropertyFileName(plainFileName);
		PropertyPackage propertyPackage = (PropertyPackage) ecoreUtil.normalLoad(
				handler.getTargetFolderUri(), propertyFileName);

		// Temporary trace model folder
		final String temporaryTraceFolderName = ".temporary-trace-folder"; // Checking if it already exists

		Verification verification = factory.createVerification();
		verification.getAnalysisLanguages().add(analysisLanguage);
		// No programming languages, we do not need temporary test classes
		verification.getFileName().add(modelFileUri);
		verification.getPropertyPackages().add(propertyPackage);
		verification.getTargetFolder().add(temporaryTraceFolderName);

		VerificationHandler verificationHandler = new VerificationHandler(file);
		verificationHandler.execute(verification);

		// Reading the resulting traces and then deleting them
		List<ExecutionTrace> testsTraces = new ArrayList<ExecutionTrace>();
		File temporaryTraceFolder = new File(verificationHandler.getTargetFolderUri());
		for (File traceFile : getTraceFiles(temporaryTraceFolder)) {
			ExecutionTrace adaptiveTrace = (ExecutionTrace) ecoreUtil.normalLoad(traceFile);
			StatechartDefinition adaptiveContract = (StatechartDefinition) GenmodelDerivedFeatures
					.getModel(modelTransformation);
			Component monitoredComponent = StatechartModelDerivedFeatures.getMonitoredComponent(adaptiveContract);

			// Back-annotating ports: unfolded statechart -> adaptive statechart -> original component
			for (RaiseEventAct act : ecoreUtil.getAllContentsOfType(adaptiveTrace, RaiseEventAct.class)) {
				Port newPort = act.getPort();
				Port originalPort = backAnnotatePort(monitoredComponent, newPort);
				act.setPort(originalPort);
			}

			// Back-annotating the final states: unfolded statechart -> adaptive statechart
			Set<State> adaptiveStates = new HashSet<State>();
			Step lastStep = TraceModelDerivedFeatures.getLastStep(adaptiveTrace);
			Map<SynchronousComponentInstance, Set<State>> instanceStateConfigurations =
					TraceModelDerivedFeatures.groupInstanceStateConfigurations(lastStep);
			for (SynchronousComponentInstance instance : instanceStateConfigurations.keySet()) {
				Set<State> newStates = instanceStateConfigurations.get(instance);
				adaptiveStates.addAll(backAnnotateStates(adaptiveContract, newStates));
			}

			// Clearing unnecessary data
			traceUtil.clearAsserts(adaptiveTrace, ComponentInstanceStateReferenceExpression.class);
			traceUtil.clearAsserts(adaptiveTrace, ComponentInstanceVariableReferenceExpression.class);
			// Targeting the reference to the monitored component
			adaptiveTrace.setImport(StatechartModelDerivedFeatures.getContainingPackage(monitoredComponent));
			adaptiveTrace.setComponent(monitoredComponent);

			// Extending the trace with the scenario testing
			for (State contractState : adaptiveStates) {
				// Extending trace of the adaptive contract with tests derived from the contracts of these states
				for (StateAnnotation annotation : contractState.getAnnotations()) {
					if (annotation instanceof StateContractAnnotation) {
						StateContractAnnotation stateContractAnnotation = (StateContractAnnotation) annotation;
						StatechartDefinition contract = stateContractAnnotation.getContractStatechart();
						ExecutionTrace clonedAdaptiveTrace = ecoreUtil.clone(adaptiveTrace);
						Constraint constraint = testGeneration.getModelTransformation().getConstraint();
						int schedulingConstraint = 0;
						if (constraint instanceof OrchestratingConstraint) {
							OrchestratingConstraint orchestratingConstraint = (OrchestratingConstraint) constraint;
							TimeSpecification minimumPeriod = orchestratingConstraint.getMinimumPeriod();
							schedulingConstraint = statechartUtil.evaluateMilliseconds(minimumPeriod);
						}
						ScenarioStatechartTraceGenerator traceGenerator = new ScenarioStatechartTraceGenerator(
								contract, stateContractAnnotation.getArguments(), schedulingConstraint);
						List<ExecutionTrace> staticTraces = traceGenerator.execute();
						for (ExecutionTrace staticTrace : staticTraces) {
						    ExecutionTrace mergedTrace = ecoreUtil.clone(clonedAdaptiveTrace);
						    mergedTrace.getAnnotations().clear();
						    mergedTrace.getAnnotations().addAll(staticTrace.getAnnotations());
						    if (!TraceModelDerivedFeatures.hasAssertInFirstStep(staticTrace)) {
						    	mergedTrace.getSteps().addAll(staticTrace.getSteps()
										.subList(1, staticTrace.getSteps().size()));
						    }
						    else {
						    	List<Step> steps = staticTrace.getSteps();
						    	traceUtil.removeScheduleAndReset(steps.get(0));
						    	mergedTrace.getSteps().addAll(steps);
						    }
							testsTraces.add(mergedTrace);
						}
					}
					// Branch to be removed: just to test now the workflow
//					else {
//						testsTraces.add(ecoreUtil.clone(adaptiveTrace));
//					}
				}
			}
		}
		fileUtil.forceDelete(temporaryTraceFolder);

		
		ProgrammingLanguage programmingLanguage = testGeneration.getProgrammingLanguages().get(0);
		// Serializing traces
		for (ExecutionTrace testTrace : testsTraces) {
			serializer.serialize(targetFolderUri, traceFileName,
					testFolderUri, testFileName, packageName, testTrace,
					file, programmingLanguage);
		}
	}

	// Load traces
	
	protected List<File> getTraceFiles(File temporaryTraceFolder) {
		List<File> traceFiles = new ArrayList<File>();
		for (File temporaryFile : temporaryTraceFolder.listFiles()) {
			String extension = fileUtil.getExtension(temporaryFile);
			if (extension.equals(GammaFileNamer.EXECUTION_XTEXT_EXTENSION) ||
					extension.equals(GammaFileNamer.EXECUTION_EMF_EXTENSION)) {
				traceFiles.add(temporaryFile);
			}
		}
		return traceFiles;
	}
	
	// Port from unfolded statechart -> adaptive statechart -> original component

	protected Port backAnnotatePort(Component originalComponent, Port newPort) {
		for (Port originalPort : StatechartModelDerivedFeatures.getAllPorts(originalComponent)) {
			if (areEqual(originalPort, newPort)) {
				return originalPort;
			}
		}
		throw new IllegalArgumentException("Not found port: " + newPort);
	}

	protected boolean areEqual(Port originalPort, Port newPort) {
		return ecoreUtil.helperEquals(originalPort, newPort);
	}

	// State from unfolded statechart -> adaptive statechart

	protected Set<State> backAnnotateStates(StatechartDefinition originalStatechart,
			Collection<State> newStates) {
		Set<State> originalStates = new HashSet<State>();
		for (State newState : newStates) {
			originalStates.add(backAnnotateState(originalStatechart, newState));
		}
		return originalStates;
	}

	protected State backAnnotateState(StatechartDefinition originalStatechart, State newState) {
		for (State originalState : StatechartModelDerivedFeatures.getAllStates(originalStatechart)) {
			if (areEqual(originalState, newState)) {
				return originalState;
			}
		}
		throw new IllegalArgumentException("Not found state: " + newState);
	}

	protected boolean areEqual(State originalState, State newState) {
		List<State> originalAncestors = StatechartModelDerivedFeatures.getAncestorsAndSelf(originalState);
		// Note the - in the string to be a 100% sure, that cannot be contained by state
		// names
		String originalName = originalAncestors.stream().map(it -> it.getName())
				.reduce("", (a, b) -> a + "-" + b);
		List<State> newAncestors = StatechartModelDerivedFeatures.getAncestorsAndSelf(newState);
		String newName = newAncestors.stream().map(it -> it.getName())
				.reduce("", (a, b) -> a + "-" + b);
		return originalName.equals(newName);
	}

	// Settings

	private void setAdaptiveContractTestGeneration(AdaptiveContractTestGeneration testGeneration) {
		List<String> packageNames = testGeneration.getPackageName();
		List<String> fileNames = testGeneration.getFileName();
		List<String> testFolders = testGeneration.getTestFolder();
		checkArgument(packageNames.size() <= 1);
		checkArgument(fileNames.size() <= 1);
		checkArgument(testFolders.size() <= 1);
		if (packageNames.isEmpty()) {
			packageNames.add(
					file.getProject().getName().toLowerCase());
		}
		if (fileNames.isEmpty()) {
			fileNames.add(GammaFileNamer.EXECUTION_TRACE_FILE_NAME);
		}
		if (testFolders.isEmpty()) {
			testFolders.add("test-gen");
		}
		this.packageName = packageNames.get(0);
		this.traceFileName = fileNames.get(0);
		// Setting the attribute, the test folder is a RELATIVE path now from the
		// project
		String testFolder = testFolders.get(0);
		this.testFolderUri = URI.decode(projectLocation + File.separator + testFolder);
		this.testFileName = traceFileName + "Simulation";
		// TargetFolder set in setTargetFolder
	}

}