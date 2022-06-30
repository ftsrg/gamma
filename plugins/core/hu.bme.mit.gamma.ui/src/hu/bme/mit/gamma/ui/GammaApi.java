/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.IWorkspaceRoot;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.core.runtime.Path;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.util.EcoreUtil;

import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.AdaptiveBehaviorConformanceChecking;
import hu.bme.mit.gamma.genmodel.model.AdaptiveContractTestGeneration;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.CodeGeneration;
import hu.bme.mit.gamma.genmodel.model.EventPriorityTransformation;
import hu.bme.mit.gamma.genmodel.model.GenModel;
import hu.bme.mit.gamma.genmodel.model.InterfaceCompilation;
import hu.bme.mit.gamma.genmodel.model.PhaseStatechartGeneration;
import hu.bme.mit.gamma.genmodel.model.Slicing;
import hu.bme.mit.gamma.genmodel.model.StatechartCompilation;
import hu.bme.mit.gamma.genmodel.model.StatechartContractGeneration;
import hu.bme.mit.gamma.genmodel.model.StatechartContractTestGeneration;
import hu.bme.mit.gamma.genmodel.model.Task;
import hu.bme.mit.gamma.genmodel.model.TestGeneration;
import hu.bme.mit.gamma.genmodel.model.TraceReplayModelGeneration;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.genmodel.model.YakinduCompilation;
import hu.bme.mit.gamma.ui.taskhandler.AdaptiveBehaviorConformanceCheckingHandler;
import hu.bme.mit.gamma.ui.taskhandler.AdaptiveContractTestGenerationHandler;
import hu.bme.mit.gamma.ui.taskhandler.AnalysisModelTransformationAndVerificationHandler;
import hu.bme.mit.gamma.ui.taskhandler.AnalysisModelTransformationHandler;
import hu.bme.mit.gamma.ui.taskhandler.CodeGenerationHandler;
import hu.bme.mit.gamma.ui.taskhandler.EventPriorityTransformationHandler;
import hu.bme.mit.gamma.ui.taskhandler.InterfaceCompilationHandler;
import hu.bme.mit.gamma.ui.taskhandler.OptimizerAndVerificationHandler;
import hu.bme.mit.gamma.ui.taskhandler.PhaseGenerationHandler;
import hu.bme.mit.gamma.ui.taskhandler.SlicingHandler;
import hu.bme.mit.gamma.ui.taskhandler.StatechartCompilationHandler;
import hu.bme.mit.gamma.ui.taskhandler.StatechartContractGenerationHandler;
import hu.bme.mit.gamma.ui.taskhandler.StatechartContractTestGenerationHandler;
import hu.bme.mit.gamma.ui.taskhandler.TestGenerationHandler;
import hu.bme.mit.gamma.ui.taskhandler.TraceReplayModelGenerationHandler;
import hu.bme.mit.gamma.ui.taskhandler.VerificationHandler;
import hu.bme.mit.gamma.ui.util.DefaultResourceSetCreator;
import hu.bme.mit.gamma.ui.util.DefaultTaskHook;
import hu.bme.mit.gamma.ui.util.ResourceSetCreator;
import hu.bme.mit.gamma.ui.util.TaskHook;

public class GammaApi {
	//
	protected Logger logger = Logger.getLogger("GammaLogger");
	//
	
	/**
	 * Executes the Gamma tasks based on the ggen model specified by the fullPath parameter,
	 *  e.g., /hu.bme.mit.gamma.tutorial.start/model/Controller/Controller.ggen.
	 * @param fileWorkspaceRelativePath IFile.fullPath method of the file containing the ggen model
	 * @throws Exception 
	 */
	public void run(String fileWorkspaceRelativePath) throws Exception {
		run(fileWorkspaceRelativePath, DefaultTaskHook.INSTANCE);
	}
	
	public void run(String fileWorkspaceRelativePath, TaskHook hook) throws Exception {
		run(fileWorkspaceRelativePath, DefaultResourceSetCreator.INSTANCE, hook);
	}
	
	public void run(String fileWorkspaceRelativePath, ResourceSetCreator resourceSetCreator) throws Exception {
		run(fileWorkspaceRelativePath, resourceSetCreator, DefaultTaskHook.INSTANCE);
	}
	
	public void run(String fileWorkspaceRelativePath,
			ResourceSetCreator resourceSetCreator, TaskHook hook) throws Exception {
		URI fileURI = URI.createPlatformResourceURI(fileWorkspaceRelativePath, true);
		// Eclipse magic: URI -> IFile
		IWorkspaceRoot workspaceRoot = ResourcesPlugin.getWorkspace().getRoot();
		IFile file = workspaceRoot.getFile(new Path(fileURI.toPlatformString(true)));
		IProject project = file.getProject();
		// Multiple compilations due to the dependencies between models
		final int MAX_ITERATION_COUNT = 6;
		for (int i = 0; i < MAX_ITERATION_COUNT; ++i) {
			// To support different implementations
			ResourceSet resourceSet = resourceSetCreator.createResourceSet();
			//
			Resource resource = resourceSet.getResource(fileURI, true);
			// Assume that the resource has a single object as content
			EObject content = resource.getContents().get(0);
			// Resolve all is needed if there are proxys referring to different resources:
			// if we remove containers from the element tree that contain references to other resources
			// they will be broken - theoretically, this call should not require too much resource
			EcoreUtil.resolveAll(resourceSet);
			if (content instanceof GenModel) {
				GenModel genmodel = (GenModel) content;
				// WARNING: workspace location and imported project locations are not to be confused
				// Sorting: InterfaceCompilation < StatechartCompilation < else does not work as the generated models are not reloaded
				List<Task> tasks = orderTasks(genmodel, i);
				for (Task task : tasks) {
					// Initializing the hook for potential measurements
					hook.startTaskProcess(task);
					//
					for (int j = 0; j < hook.getIterationCount(); j++) {
						// Iteration start
						hook.startIteration();
						//
						if (task instanceof YakinduCompilation) {
							if (task instanceof InterfaceCompilation) {
								logger.log(Level.INFO, "The Yakindu-Gamma interface transformation has been started");
								InterfaceCompilation interfaceCompilation = (InterfaceCompilation) task;
								InterfaceCompilationHandler handler = new InterfaceCompilationHandler(file);
								handler.execute(interfaceCompilation);
								logger.log(Level.INFO, "The Yakindu-Gamma interface transformation has been finished");
							}
							else if (task instanceof StatechartCompilation) {
								logger.log(Level.INFO, "The Yakindu-Gamma transformation has been started");
								StatechartCompilation statechartCompilation = (StatechartCompilation) task;
								StatechartCompilationHandler handler = new StatechartCompilationHandler(file);
								handler.execute(statechartCompilation);
								logger.log(Level.INFO, "The Yakindu-Gamma transformation has been finished");
							}
						} else {
							final String projectName = project.getName().toLowerCase();
							if (task instanceof CodeGeneration) {
								CodeGeneration codeGeneration = (CodeGeneration) task;
								logger.log(Level.INFO, "The code generation has been started");
								CodeGenerationHandler handler = new CodeGenerationHandler(file);
								handler.execute(codeGeneration, projectName);
								logger.log(Level.INFO, "The code generation has been finished");
							}
							else if (task instanceof AnalysisModelTransformation) {
								logger.log(Level.INFO, "The analyis transformation has been started");
								AnalysisModelTransformation analysisModelTransformation = (AnalysisModelTransformation) task;
								// Maybe different classes should be created for distinction?
								if (GenmodelDerivedFeatures.isVerifyAnalysisTask(analysisModelTransformation)) {
									AnalysisModelTransformationAndVerificationHandler handler =
												new AnalysisModelTransformationAndVerificationHandler(file);
									handler.execute(analysisModelTransformation);
								}
								else {
									AnalysisModelTransformationHandler handler = new AnalysisModelTransformationHandler(file);
									handler.execute(analysisModelTransformation);
								}
								logger.log(Level.INFO, "The analysis transformation has been finished");
							}
							else if (task instanceof TestGeneration) {
								logger.log(Level.INFO, "The test generation has been started");
								TestGeneration testGeneration = (TestGeneration) task;
								TestGenerationHandler handler = new TestGenerationHandler(file);
								handler.execute(testGeneration, projectName);
								logger.log(Level.INFO, "The test generation has been finished");
							}
							else if (task instanceof Verification) {
								logger.log(Level.INFO, "The verification has been started");
								Verification verification = (Verification) task;
								// Maybe different classes should be created for distinction?
								if (GenmodelDerivedFeatures.isOptimizableVerificationTask(verification)) {
									OptimizerAndVerificationHandler handler = new OptimizerAndVerificationHandler(file);
									handler.execute(verification);
								}
								else {
									VerificationHandler handler = new VerificationHandler(file);
									handler.execute(verification);
								}
								logger.log(Level.INFO, "The verification has been finished");
							}
							else if (task instanceof Slicing) {
								logger.log(Level.INFO, "The slicing has been started");
								Slicing slicing = (Slicing) task;
								SlicingHandler handler = new SlicingHandler(file);
								handler.execute(slicing);
								logger.log(Level.INFO, "The slicing has been finished");
							}
							else if (task instanceof TraceReplayModelGeneration) {
								logger.log(Level.INFO, "The test replay model generation has been started");
								TraceReplayModelGeneration traceReplayModelGeneration = (TraceReplayModelGeneration) task;
								TraceReplayModelGenerationHandler handler = new TraceReplayModelGenerationHandler(file);
								handler.execute(traceReplayModelGeneration);
								logger.log(Level.INFO, "The test replay model generation has been finished");
							}
							else if (task instanceof AdaptiveContractTestGeneration) {
								logger.log(Level.INFO, "The adaptive contract test generation has been started");
								AdaptiveContractTestGeneration testGeneration = (AdaptiveContractTestGeneration) task;
								AdaptiveContractTestGenerationHandler handler = new AdaptiveContractTestGenerationHandler(file);
								handler.execute(testGeneration);
								logger.log(Level.INFO, "The adaptive contract test generation has been finished");
							}
							else if (task instanceof AdaptiveBehaviorConformanceChecking) {
								logger.log(Level.INFO, "The adaptive behavior conformance checking has been started");
								AdaptiveBehaviorConformanceChecking conformanceChecking = (AdaptiveBehaviorConformanceChecking) task;
								AdaptiveBehaviorConformanceCheckingHandler handler =
										new AdaptiveBehaviorConformanceCheckingHandler(file);
								handler.execute(conformanceChecking);
								logger.log(Level.INFO, "The adaptive behavior conformance checking has been finished");
							}
							else if (task instanceof StatechartContractTestGeneration) {
								StatechartContractTestGeneration testGeneration = (StatechartContractTestGeneration) task; 
								StatechartContractTestGenerationHandler handler = new StatechartContractTestGenerationHandler(file);
								handler.execute(testGeneration);
								logger.log(Level.INFO, "The contract-based test generation has been finished");
							}
							else if (task instanceof StatechartContractGeneration) {
								StatechartContractGeneration statechartGeneration = (StatechartContractGeneration) task; 
								StatechartContractGenerationHandler handler = new StatechartContractGenerationHandler(file);
								handler.execute(statechartGeneration);
								logger.log(Level.INFO, "The contract statechart generation has been finished");
							}
							else if (task instanceof EventPriorityTransformation) {
								logger.log(Level.INFO, "The event priority transformation has been started");
								EventPriorityTransformation eventPriorityTransformation = (EventPriorityTransformation) task;
								EventPriorityTransformationHandler handler = new EventPriorityTransformationHandler(file);
								handler.execute(eventPriorityTransformation);
								logger.log(Level.INFO, "The event priority transformation has been finished");
							}
							else if (task instanceof PhaseStatechartGeneration) {
								logger.log(Level.INFO, "The phase statechart transformation has been started");
								PhaseStatechartGeneration phaseStatechartGeneration = (PhaseStatechartGeneration) task;
								PhaseGenerationHandler handler = new PhaseGenerationHandler(file);
								handler.execute(phaseStatechartGeneration);
								logger.log(Level.INFO, "The phase statechart transformation has been finished");
							}
						}
						// Iteration end
						hook.endIteration();
						//
					}
					// All iteration ended
					hook.endTaskProcess();
					//
					// Refreshing the project
					logger.log(Level.INFO, "Refreshing project");
					project.refreshLocal(IResource.DEPTH_INFINITE, new NullProgressMonitor());
					logger.log(Level.INFO, "Refreshing project has been finished");
				}
			}
			else {
				logger.log(Level.WARNING, "The given resource does not contain a GenModel: " + resource);
			}
		}
	}

	/** 
	 * Compilation order: interfaces <- statecharts <- event priority <- analysis model, code <- test.
	 * As everything depends on statecharts and statecharts depend on interfaces.
	 * This way the user does not have to compile two or three times.
	 */
	private List<Task> orderTasks(GenModel genmodel, int iteration) {
		List<Task> allTasks = GenmodelDerivedFeatures.getAllTasks(genmodel);
		switch (iteration) {
			case 0: 
				return allTasks.stream()
						.filter(it -> it instanceof InterfaceCompilation)
						.collect(Collectors.toList());
			case 1: 
				return allTasks.stream()
						.filter(it -> it instanceof StatechartCompilation)
						.collect(Collectors.toList());
			case 2: 
				return allTasks.stream()
						.filter(it -> it instanceof EventPriorityTransformation ||
								it instanceof PhaseStatechartGeneration)
						.collect(Collectors.toList());
			case 3: 
				return allTasks.stream()
						.filter(it -> it instanceof AnalysisModelTransformation ||
								it instanceof CodeGeneration)
						.collect(Collectors.toList());
			case 4: 
				return allTasks.stream()
						.filter(it -> it instanceof Slicing)
						.collect(Collectors.toList());
			case 5: 
				return allTasks.stream()
						.filter(it -> it instanceof TestGeneration || it instanceof Verification ||
								it instanceof AdaptiveContractTestGeneration ||
								it instanceof AdaptiveBehaviorConformanceChecking ||
								it instanceof TraceReplayModelGeneration ||
								it instanceof StatechartContractTestGeneration || it instanceof StatechartContractGeneration)
						.collect(Collectors.toList());
			default: 
				throw new IllegalArgumentException("Not known iteration variable: " + iteration);
		}
	}
	
}