/********************************************************************************
 * Copyright (c) 2023-2024 Contributors to the Gamma project
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
import static com.google.common.base.Preconditions.checkState;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Scanner;
import java.util.Set;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IncrementalProjectBuilder;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.InequalityExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.CodeGeneration;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.ModelMutation;
import hu.bme.mit.gamma.genmodel.model.ModelReference;
import hu.bme.mit.gamma.genmodel.model.MutationBasedTestGeneration;
import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.mutation.ModelMutator.MutationHeuristics;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.property.util.PropertyUtil;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
import hu.bme.mit.gamma.statechart.composite.SchedulableCompositeComponent;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.InterfaceRealization;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.UnfoldedPackageAnnotation;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;
import hu.bme.mit.gamma.trace.model.Step;
import hu.bme.mit.gamma.transformation.util.GammaFileNamer;
import hu.bme.mit.gamma.ui.taskhandler.VerificationHandler.ExecutionTraceSerializer;
import hu.bme.mit.gamma.util.ScannerLogger;

public class MutationBasedTestGenerationHandler extends TaskHandler {
	//
	protected String packageName;
	protected String traceFolderUri;
	protected String testFolderUri;
	protected String traceFileName;
	protected String testFileName;
	protected ProgrammingLanguage programmingLanguage;
	
	//
	protected final String ENVIRONMENT_VARIABLE_FOR_JUNIT_JAR = "JUNIT";
	protected final int MAX_TEST_RUN = 10;
	//
	protected final PropertyUtil propertyUtil = PropertyUtil.INSTANCE;
	protected final ExecutionTraceSerializer traceSerializer = ExecutionTraceSerializer.INSTANCE;
	//
	
	public MutationBasedTestGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(MutationBasedTestGeneration mutationBasedTestGeneration)
				throws IOException, InterruptedException, CoreException {
		// Setting target folder
		setProjectLocation(mutationBasedTestGeneration); // Before the target folder
		setTargetFolder(mutationBasedTestGeneration);
		//
		setModelBasedMutationTestGeneration(mutationBasedTestGeneration);
		//
		
		String targetFolder = javaUtil.getOnlyElement(
				mutationBasedTestGeneration.getTargetFolder());
		String fileName = javaUtil.getOnlyElement(
				mutationBasedTestGeneration.getFileName());
		
		AnalysisModelTransformation analysisModelTransformation = mutationBasedTestGeneration.getAnalysisModelTransformation();
		List<String> analysisTargetFolders = analysisModelTransformation.getTargetFolder();
		analysisTargetFolders.clear();
		analysisTargetFolders.add(targetFolder);
		
		ComponentReference model = (ComponentReference) analysisModelTransformation.getModel();
		Component component = (Component) GenmodelDerivedFeatures.getModel(model);
		
		Expression mutationCount = mutationBasedTestGeneration.getIterationCount();
		int iterationCount = expressionEvaluator.evaluateInteger(mutationCount);
		ModelMutation modelMutation = factory.createModelMutation();
		modelMutation.setModel(
				ecoreUtil.clone(model));
		modelMutation.setIterationCount(
				propertyUtil.toIntegerLiteral(1)); // Generating mutants one by one
		List<String> mutationTargetFolders = modelMutation.getTargetFolder();
		mutationTargetFolders.clear();
		mutationTargetFolders.add(targetFolder);
		
		// Heuristics computation if specified
		List<String> patternClassNames = mutationBasedTestGeneration.getPatternClassNames();
		MutationHeuristics mutationHeuristics = patternClassNames.isEmpty() ?
				new MutationHeuristics() :
				new MutationHeuristics(patternClassNames, getBinUri());
		
		Map<State, Integer> stateFrequency = mutationHeuristics.getStateFrequency();
		List<String> traceFolderPaths = mutationBasedTestGeneration.getTraceFolders();
		for (String traceFolderPath : traceFolderPaths) { // May be empty
			File traceFolder = new File(traceFolderPath);
			if (traceFolder.exists()) {
				calculateTraceMetrics(traceFolder, stateFrequency);
			}
		}
		
		// In a cycle to support mutation based on generated tests
		ModelMutationHandler modelMutationHandler =  new ModelMutationHandler(file, mutationHeuristics);
		for (int i = 0; i < iterationCount; i++) {
			List<Package> mutatedModels = modelMutationHandler.getMutatedModels();
			
			final String testFileNamePattern = mutationBasedTestGeneration.getTestClassNamePattern(); // E.g., ".*TraceSimulation[0-9]*.*"
			Collection<Package> unnecessaryMutants = new ArrayList<Package>();
			Collection<Package> checkedMutants = new LinkedHashSet<Package>();
			
			// Checking if present tests kill any of the mutants
			modelMutationHandler.setMutationIteration(1); // Generate new ones for these
			int testRunCount = 0;
			do {
				unnecessaryMutants.clear();
				modelMutationHandler.execute(modelMutation);
				
				Collection<Package> checkableMutants = new LinkedHashSet<Package>(mutatedModels);
				checkableMutants.removeAll(checkedMutants); // To prevent unnecessary testing
				unnecessaryMutants.addAll(
						killMutantsWithExistingTests(
								component, checkableMutants, testFileNamePattern));
				checkedMutants.addAll(checkableMutants);
				int unnecessaryMutantCount = unnecessaryMutants.size();
				logger.info("Found " + unnecessaryMutantCount + " mutants killed by existing tests in iteration " + i + "/" + testRunCount);
				
				mutatedModels.removeAll(unnecessaryMutants); // Tests already kill these mutants
				modelMutationHandler.setMutationIteration(unnecessaryMutantCount); // Generate new ones for these
				testRunCount++;
			}
			while (!unnecessaryMutants.isEmpty() && testRunCount < MAX_TEST_RUN);
			// End of mutant check based on already generated tests
			//
		
			// Generating test based on the newly generated mutant
			Package mutatedModel = javaUtil.getLast(mutatedModels);
			// Handling these packages as if they were not unfolded (as the original component is not) 
			mutatedModel.getAnnotations().removeIf(it -> it instanceof UnfoldedPackageAnnotation);
			ecoreUtil.save(mutatedModel);
			//
			
			Component mutatedTopComponent = StatechartModelDerivedFeatures.getFirstComponent(mutatedModel);
			
			//
			SchedulableCompositeComponent compositeOriginal = propertyUtil.wrapComponent(component);
			@SuppressWarnings("unchecked")
			List<ComponentInstance> originalComponents = (List<ComponentInstance>)
					StatechartModelDerivedFeatures.getDerivedComponents(compositeOriginal);
			String originalComponentInstanceName = "original";
			for (ComponentInstance originalComponent : originalComponents) {
				originalComponent.setName(originalComponentInstanceName);
			}
			List<Port> originalInputPorts = StatechartModelDerivedFeatures.getAllPortsWithInput(compositeOriginal);
			List<Port> originalOutputPorts = StatechartModelDerivedFeatures.getAllPortsWithOutput(compositeOriginal);
			//
			
			//
			SchedulableCompositeComponent compositeMutant = propertyUtil.wrapComponent(mutatedTopComponent);
			List<Port> mutantInputPorts = StatechartModelDerivedFeatures.getAllPortsWithInput(compositeMutant);
			List<Port> mutantInternalPorts = StatechartModelDerivedFeatures.getAllInternalPorts(compositeMutant);
			List<Port> mutantOutputPorts = StatechartModelDerivedFeatures.getAllPortsWithOutput(compositeMutant);
			checkState(javaUtil.containsNone(mutantInputPorts, mutantOutputPorts), "A port contains both input and output events");
			
			List<Port> mergableMutantPorts = new ArrayList<Port>(mutantInternalPorts);
			mergableMutantPorts.addAll(mutantOutputPorts);
			for (Port port : mergableMutantPorts) {
				String name = port.getName();
				port.setName(
						javaUtil.matchFirstCharacterCapitalization(
								"mutant" + javaUtil.toFirstCharUpper(name),  name));
			}
			
			List<? extends ComponentInstance> mutantComponents = StatechartModelDerivedFeatures.getDerivedComponents(compositeMutant);
			for (ComponentInstance mutantComponent : mutantComponents) {
				mutantComponent.setName("mutant");
			}
			//
			
			// Merging the two models
			compositeOriginal.getPorts().addAll(mergableMutantPorts);
			
			originalComponents.addAll(mutantComponents);
			
			compositeOriginal.getPortBindings().addAll(
					compositeMutant.getPortBindings());
			compositeOriginal.getChannels().addAll(
					compositeMutant.getChannels());
			
			ecoreUtil.change(originalInputPorts, mutantInputPorts, compositeOriginal);
			
			Package newMergedPackage = propertyUtil.wrapIntoPackageAndAddImports(compositeOriginal);
			String newFileName = fileName + "_Mutant_" + i;
			String newPackageFileName = fileUtil.toHiddenFileName(
					fileNamer.getPackageFileName(newFileName));
			
			serializer.saveModel(newMergedPackage, targetFolderUri, newPackageFileName);
			
			// Create EF property
			List<Expression> orOperends = new ArrayList<Expression>();
			for (int j = 0; j < originalOutputPorts.size(); j++) {
				Port originalOutputPort = originalOutputPorts.get(j);
				Port mutantOutputPort = mutantOutputPorts.get(j);
				
				Interface _interface = StatechartModelDerivedFeatures.getInterface(originalOutputPort);
				checkState(ecoreUtil.helperEquals(_interface,
						StatechartModelDerivedFeatures.getInterface(mutantOutputPort)),
						"Interfaces are not the same");
				InterfaceRealization mutantInterfaceRealization = mutantOutputPort.getInterfaceRealization();
				mutantInterfaceRealization.setInterface(_interface); // Not correct: consider the contained component port interfaces, too?
				
				List<Event> outputEvents = StatechartModelDerivedFeatures.getOutputEvents(originalOutputPort);
				for (Event outputEvent : outputEvents) {
					ComponentInstanceEventReferenceExpression originalReference =
							propertyUtil.createSystemEventReference(originalOutputPort, outputEvent);
					ComponentInstanceEventReferenceExpression mutantReference =
							propertyUtil.createSystemEventReference(mutantOutputPort, outputEvent);
					if (originalReference != null && mutantReference != null) {
						InequalityExpression inequality = propertyUtil
								.createInequalityExpression(originalReference, mutantReference);
						orOperends.add(inequality);
					}
					
					for (ParameterDeclaration eventParameter : outputEvent.getParameterDeclarations()) {
						ComponentInstanceEventParameterReferenceExpression originalParameterReference =
								propertyUtil.createSystemParameterReference(originalOutputPort, outputEvent, eventParameter);
						ComponentInstanceEventParameterReferenceExpression mutantParameterReference =
								propertyUtil.createSystemParameterReference(mutantOutputPort, outputEvent, eventParameter);
						if (originalParameterReference != null && mutantParameterReference != null) {
							InequalityExpression parameterInequality = propertyUtil
									.createInequalityExpression(originalParameterReference, mutantParameterReference);
							orOperends.add(parameterInequality);
						}
					}
				}
			}
			Expression or = propertyUtil.wrapIntoOrExpression(orOperends);
			if (or == null) {
				throw new IllegalStateException("Null expression");
			}
			StateFormula mutantKillingProperty = propertyUtil.createEF(
					propertyUtil.createAtomicFormula(or));
			
			PropertyPackage propertyPackage = propertyUtil.wrapFormula(compositeOriginal, mutantKillingProperty);
			ecoreUtil.normalSave(propertyPackage, targetFolderUri, "." + newFileName + ".gpd");
			
			analysisModelTransformation.setPropertyPackage(propertyPackage);
			
			// Analysis model transformation & verification
			analysisModelTransformation.getFileName().clear();
			model.setComponent(compositeOriginal);
			
			AnalysisModelTransformationAndVerificationHandler transformationHandler =
					new AnalysisModelTransformationAndVerificationHandler(file,
							true, true, false, null);
			transformationHandler.execute(analysisModelTransformation);
			
			analysisModelTransformation.setPropertyPackage(null);
			
			// Post-processing traces: projection to original component
			List<ExecutionTrace> traces = transformationHandler.getTraces();
			for (ExecutionTrace trace : traces) {
				List<RaiseEventAct> eventRaises = ecoreUtil.getAllContentsOfType(trace, RaiseEventAct.class);
				for (RaiseEventAct act : eventRaises) {
					Port systemPort = act.getPort();
					Collection<PortBinding> portBindings = StatechartModelDerivedFeatures.getPortBindings(systemPort);
					boolean foundOriginal = false;
					for (PortBinding portBinding : portBindings) {
						InstancePortReference instancePortReference = portBinding.getInstancePortReference();
						ComponentInstance instance = instancePortReference.getInstance();
						String instanceName = instance.getName();
						Port port = instancePortReference.getPort();
						if (instanceName.equals(originalComponentInstanceName)) {
							// Original port
							act.setPort(port);
							foundOriginal = true;
						}
					}
					if (!foundOriginal) {
						// Mutant port
						ecoreUtil.removeContainmentChainUntilType(act, Step.class);
					}
				}
				
				List<ComponentInstanceReferenceExpression> instanceReferences =
						TraceModelDerivedFeatures.getFirstComponentInstanceReferenceExpressions(trace);
				for (ComponentInstanceReferenceExpression instanceReference : instanceReferences) {
					ComponentInstance componentInstance = instanceReference.getComponentInstance();
					String instanceName = componentInstance.getName();
					if (instanceName.equals(originalComponentInstanceName)) {
						// Original instance
						ComponentInstanceReferenceExpression child = instanceReference.getChild();
						ecoreUtil.replace(child, instanceReference);
					}
					else {
						// Mutant instance
						ecoreUtil.removeContainmentChainUntilType(instanceReference, Step.class);
					}
				}

				trace.setComponent(component);
				trace.setImport(
						StatechartModelDerivedFeatures.getContainingPackage(trace.getComponent()));
				
				// Traces and tests are not serialized
				traceSerializer.serialize(traceFolderUri, traceFileName, null, testFolderUri,
						testFileName, packageName, trace, file, programmingLanguage);
				
				// Extend trace metrics - used when another mutation is conducted
				extendTraceMetrics(stateFrequency, trace);
			}
		}
		
	}
	
	//

	private Collection<Package> killMutantsWithExistingTests(Component originalTopComponent, Collection<? extends Package> mutatedModels,
				String testFilePattern) throws CoreException, IOException {
		List<Package> unnecessaryMutations = new ArrayList<Package>();
		
		if (testFilePattern != null) {
			Set<Component> allOriginalComponents = StatechartModelDerivedFeatures.getSelfAndAllComponents(originalTopComponent);
			// Compile tests once if not using the bin folder
			IProject project = file.getProject();
			
			CodeGeneration codeGeneration = factory.createCodeGeneration();
			codeGeneration.getProgrammingLanguages().add(ProgrammingLanguage.JAVA);
			for (Package mutatedModel : mutatedModels) {
				String mutatedPackageName = mutatedModel.getName();
				List<Package> mutantImports = new ArrayList<Package>(mutatedModel.getImports());
				
				List<Component> components = mutatedModel.getComponents();
				Component mutatedComponent = components.stream().filter(it ->
						StatechartModelDerivedFeatures.isMutant(it)).findFirst().get();
				//
				Component originalComponent = null;
				if (mutatedComponent == StatechartModelDerivedFeatures.getFirstComponent(mutatedModel)) {
					originalComponent = originalTopComponent;
				}
				else {
					for (Component aComponent : allOriginalComponents) {
						boolean sameComponent = mutatedComponent.getName().equals(aComponent.getName());
						if (sameComponent) {
							if (originalComponent != null) {
								throw new IllegalStateException("Already found original component: " + originalComponent);
							}
							originalComponent = aComponent;
						}
					}
				}
				//
				Package originalComponentPackage = StatechartModelDerivedFeatures.getContainingPackage(originalComponent);
				String originalComponentPackageName = originalComponentPackage.getName();
				List<Package> originalImports = new ArrayList<Package>(originalComponentPackage.getImports());
				
				// Adjusting mutation model
				mutatedModel.setName(originalComponentPackageName);
				mutatedModel.getImports().clear();
				mutatedModel.getImports().addAll(originalImports);
				
				// Generate code for component
				codeGeneration.setComponent(mutatedComponent);
				CodeGenerationHandler handler = new CodeGenerationHandler(file);
				String packageName = project.getName();
				handler.execute(codeGeneration, packageName);
				project.build(IncrementalProjectBuilder.FULL_BUILD,
						"org.eclipse.jdt.core.javabuilder", null, new NullProgressMonitor());
				
				// Reinstating original mutation model
				mutatedModel.setName(mutatedPackageName);
				mutatedModel.getImports().clear();
				mutatedModel.getImports().addAll(mutantImports);
				
				// Running tests to see if mutant can be killed
				// java -jar C:\Users\grben\git\gamma\plugins\mutation\mutation-bin\junit-platform-console-standalone-1.9.3.jar -cp bin -c hu.bme.mit.gamma.tutorial.finish.tutorial.ExecutionTraceSimulation5 -c hu.bme.mit.gamma.tutorial.finish.tutorial.ExecutionTraceSimulation7
				String jUnit = System.getenv(ENVIRONMENT_VARIABLE_FOR_JUNIT_JAR);
				String binFolderName = "bin";
				String binFolderPath = projectLocation + File.separator + binFolderName;
				File binFolder = new File(binFolderPath);
				List<File> binFiles = fileUtil.getAllContainedFiles(binFolder);
				
				List<String> commandElements = new ArrayList<String>(
						List.of("java", "-jar", jUnit, "-cp", binFolderPath));
				final String CLASS_ENDING = ".class";
				for (String binFilePath : binFiles.stream()
							.map(it -> it.getAbsolutePath())
							.filter(it -> it.matches(testFilePattern) && it.endsWith(CLASS_ENDING) && !it.contains("$")).toList()) {
					String javaClassName = binFilePath.substring(1 + binFolderPath.length())
								.replaceAll("\\\\", ".").replaceAll("/", ".");
					javaClassName = javaClassName.substring(0,
							javaClassName.length() - CLASS_ENDING.length());
					
					commandElements.addAll(
							List.of("-c", javaClassName));
				}
				String[] command = commandElements.stream().toArray(String[] ::new);
				Runtime runtime = Runtime.getRuntime();
				Process jUnitProcess = runtime.exec(command);
				
				Scanner jUnitOutput = new Scanner(jUnitProcess.getInputStream());
				
				ScannerLogger logger = new ScannerLogger(jUnitOutput, "Failures (", false);
				logger.start();
				logger.join();
				
				if (logger.isError()) {
					unnecessaryMutations.add(mutatedModel);
				}
				
				// Restoring original code
				codeGeneration.setComponent(originalComponent);
				handler.execute(codeGeneration, packageName);
				project.build(IncrementalProjectBuilder.INCREMENTAL_BUILD,
						"org.eclipse.jdt.core.javabuilder", null, new NullProgressMonitor());
			}
		}
		
		return unnecessaryMutations;
	}
	
	//
	
	private Map<State, Integer> calculateTraceMetrics(File file, Map<State, Integer> metrics) {
		if (file != null) {
			File[] traceFiles = file.listFiles(it -> it.getName().endsWith(
					"." + GammaFileNamer.EXECUTION_XTEXT_EXTENSION));
			if (traceFiles != null) {
				for (File traceFile : traceFiles) {
					ExecutionTrace trace = (ExecutionTrace) ecoreUtil.normalLoad(traceFile);
					extendTraceMetrics(metrics, trace);
				}
			}
		}
		
		return metrics;
	}

	private void extendTraceMetrics(Map<State, Integer> metrics, ExecutionTrace trace) {
		List<Step> steps = TraceModelDerivedFeatures.getAllSteps(trace);
		
		for (Step step : steps) {
			List<ComponentInstanceStateReferenceExpression> instanceStates =
					TraceModelDerivedFeatures.getInstanceStateConfigurations(step);
			
			for (var instanceState : instanceStates) {
				State state = instanceState.getState();
				javaUtil.increment(metrics, state);
			}
		}
	}
	
	//
	
	private void setModelBasedMutationTestGeneration(
			MutationBasedTestGeneration mutationBasedTestGeneration) {
		Resource resource = mutationBasedTestGeneration.eResource();
		File javaFile = (resource != null) ?
				ecoreUtil.getFile(resource).getParentFile() : // If Verification is contained in a resource
					fileUtil.toFile(super.file).getParentFile(); // If Verification is created in Java
		
		List<String> fileNames = mutationBasedTestGeneration.getFileName();
		checkArgument(fileNames.size() <= 1);
		if (fileNames.isEmpty()) {
			AnalysisModelTransformation analysisModelTransformation =
					mutationBasedTestGeneration.getAnalysisModelTransformation();
			ModelReference model = analysisModelTransformation.getModel();
			EObject sourceModel = GenmodelDerivedFeatures.getModel(model);
			String containingFileName = getContainingFileName(sourceModel);
			String fileName = getNameWithoutExtension(containingFileName);
			fileNames.add(fileName);
		}
		// Setting the file path
		List<String> traceFolders = mutationBasedTestGeneration.getTraceFolders();
		traceFolders.replaceAll(it -> fileUtil.isValidRelativeFile(javaFile, it) ?
			fileUtil.exploreRelativeFile(javaFile, it).toString() : it);
		
		List<String> packageNames = mutationBasedTestGeneration.getPackageName();
		List<String> testFolders = mutationBasedTestGeneration.getTestFolder();
		checkArgument(packageNames.size() <= 1);
		checkArgument(testFolders.size() <= 1);
		if (packageNames.isEmpty()) {
			packageNames.add(
					file.getProject().getName().toLowerCase());
		}
		if (testFolders.isEmpty()) {
			testFolders.add("test-gen");
		}
		
		List<ProgrammingLanguage> programmingLanguages = mutationBasedTestGeneration.getProgrammingLanguages();
		this.programmingLanguage = programmingLanguages.isEmpty() ? null : programmingLanguages.get(0);
		
		this.packageName = packageNames.get(0);
		this.traceFileName = GammaFileNamer.EXECUTION_TRACE_FILE_NAME;
		this.traceFolderUri = URI.decode(projectLocation + File.separator + "trace");
		// Setting the attribute, the test folder is a RELATIVE path now from the project
		String testFolder = testFolders.get(0);
		this.testFolderUri = URI.decode(projectLocation + File.separator + testFolder);
		this.testFileName = traceFileName + "Simulation";
	}

}
