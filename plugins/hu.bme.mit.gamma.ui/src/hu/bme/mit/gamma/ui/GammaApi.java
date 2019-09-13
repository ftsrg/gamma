/********************************************************************************
 * Copyright (c) 2019 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui;

import java.io.IOException;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import org.eclipse.core.resources.IContainer;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IWorkspaceRoot;
import org.eclipse.core.resources.IncrementalProjectBuilder;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.Path;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;

import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.CodeGeneration;
import hu.bme.mit.gamma.genmodel.model.EventPriorityTransformation;
import hu.bme.mit.gamma.genmodel.model.GenModel;
import hu.bme.mit.gamma.genmodel.model.InterfaceCompilation;
import hu.bme.mit.gamma.genmodel.model.StatechartCompilation;
import hu.bme.mit.gamma.genmodel.model.Task;
import hu.bme.mit.gamma.genmodel.model.TestGeneration;
import hu.bme.mit.gamma.genmodel.model.YakinduCompilation;
import hu.bme.mit.gamma.ui.taskhandler.AnalysisModelTransformationHandler;
import hu.bme.mit.gamma.ui.taskhandler.CodeGenerationHandler;
import hu.bme.mit.gamma.ui.taskhandler.EventPriorityTransformationHandler;
import hu.bme.mit.gamma.ui.taskhandler.InterfaceCompilationHandler;
import hu.bme.mit.gamma.ui.taskhandler.StatechartCompilationHandler;
import hu.bme.mit.gamma.ui.taskhandler.TestGenerationHandler;

public class GammaApi {
	
	protected Logger logger = Logger.getLogger("GammaLogger");

	/**
	 * Executes the Gamma tasks based on the ggen model specified by the fullPath parameter,
	 *  e.g., /hu.bme.mit.gamma.tutorial.start/model/Controller/Controller.ggen.
	 * @param fileWorkspaceRelativePath IFile.fullPath method of the file containing the ggen model
	 * @throws CoreException 
	 * @throws IOException 
	 */
	public void run(String fileWorkspaceRelativePath) throws Exception {
		URI fileURI = URI.createPlatformResourceURI(fileWorkspaceRelativePath, true);
		// Eclipse magic: URI -> IFile
		IWorkspaceRoot workspaceRoot = ResourcesPlugin.getWorkspace().getRoot();
		IFile file = workspaceRoot.getFile(new Path(fileURI.toPlatformString(true)));
		IProject project = file.getProject();
		// Xtext errors can be removed by cleaning the project in case of YakinduCompilation and TestGeneration tasks
		boolean needsCleaning = false;
		// Multiple compilations due to the dependencies between models
		final int MAX_ITERATION_COUNT = 5;
		for (int i = 0; i < MAX_ITERATION_COUNT; ++i) {
			ResourceSet resourceSet = new ResourceSetImpl();
			Resource resource = resourceSet.getResource(fileURI, true);
			// Assume that the resource has a single object as content
			EObject content = resource.getContents().get(0);
			if (content instanceof GenModel) {
				GenModel genmodel = (GenModel) content;
				IContainer parent = file.getParent();
				// Decoding so spaces do not stir trouble
				String parentFolderUri = URI.decode(parent.getLocation().toString());
				// WARNING: workspace location and imported project locations are not to be confused
				// Sorting: InterfaceCompilation < StatechartCompilation < else does not work as the generated models are not reloaded
				List<Task> tasks = orderTasks(genmodel, i);
				for (Task task : tasks) {
					if (task instanceof YakinduCompilation) {
						needsCleaning = true;
						if (task instanceof InterfaceCompilation) {
							logger.log(Level.INFO, "Resource set content for Yakindu to Gamma interface generation: " + resourceSet);
							InterfaceCompilation interfaceCompilation = (InterfaceCompilation) task;
							InterfaceCompilationHandler handler = new InterfaceCompilationHandler();
							handler.setTargetFolder(interfaceCompilation, file, parentFolderUri);
							handler.execute(interfaceCompilation);
							logger.log(Level.INFO, "The Yakindu-Gamma interface transformation has been finished.");
						}
						else if (task instanceof StatechartCompilation) {
							logger.log(Level.INFO, "Resource set content Yakindu to Gamma statechart generation: " + resourceSet);
							StatechartCompilation statechartCompilation = (StatechartCompilation) task;
							StatechartCompilationHandler handler = new StatechartCompilationHandler();
							handler.setTargetFolder(statechartCompilation, file, parentFolderUri);
							handler.execute(statechartCompilation);
							logger.log(Level.INFO, "The Yakindu-Gamma transformation has been finished.");
						}
					} else {
						final String projectName = project.getName();
						if (task instanceof CodeGeneration) {
							CodeGeneration codeGeneration = (CodeGeneration) task;
							logger.log(Level.INFO, "Resource set content for Java code generation: " + resourceSet);
							CodeGenerationHandler handler = new CodeGenerationHandler();
							handler.setTargetFolder(codeGeneration, file, parentFolderUri);
							handler.execute(codeGeneration, projectName);
							logger.log(Level.INFO, "The Java code generation has been finished.");
						}
						else if (task instanceof AnalysisModelTransformation) {
							AnalysisModelTransformation analysisModelTransformation = (AnalysisModelTransformation) task;
							AnalysisModelTransformationHandler handler = new AnalysisModelTransformationHandler();
							handler.setTargetFolder(analysisModelTransformation, file, parentFolderUri);
							handler.execute(analysisModelTransformation);
							logger.log(Level.INFO, "The composite system transformation has been finished.");
						}
						else if (task instanceof TestGeneration) {
							needsCleaning = true;
							TestGeneration testGeneration = (TestGeneration) task;
							TestGenerationHandler handler = new TestGenerationHandler();
							handler.setTargetFolder(testGeneration, file, parentFolderUri);
							handler.execute(testGeneration, projectName);
							logger.log(Level.INFO, "The test generation has been finished.");
						}
						else if (task instanceof EventPriorityTransformation) {
							needsCleaning = true;
							EventPriorityTransformation eventPriorityTransformation = (EventPriorityTransformation) task;
							EventPriorityTransformationHandler handler = new EventPriorityTransformationHandler();
							handler.setTargetFolder(eventPriorityTransformation, file, parentFolderUri);
							handler.execute(eventPriorityTransformation);
							logger.log(Level.INFO, "The event priority transformation has been finished.");
						}
					}
				}
			}
			else {
				logger.log(Level.WARNING, "The given resource does not contain a GenModel: " + resource);
			}
		}
		if (needsCleaning) {
			logger.log(Level.INFO, "Cleaning project...");
			// This is due to the bad imports and error markers generated by Xtext
			// as it serializes references to other models as names instead of URLs
			project.build(IncrementalProjectBuilder.CLEAN_BUILD, null);
			logger.log(Level.INFO, "Cleaning project finished.");
		}
	}	
	
	/** 
	 * Compilation order: interfaces <- statecharts <- event priority <- analysis model, code <- test.
	 * As everything depends on statecharts and statecharts depend on interfaces.
	 * This way the user does not have to compile two or three times.
	 */
	private List<Task> orderTasks(GenModel genmodel, int iteration) {
		switch (iteration) {
			case 0: 
				return genmodel.getTasks().stream()
						.filter(it -> it instanceof InterfaceCompilation)
						.collect(Collectors.toList());
			case 1: 
				return genmodel.getTasks().stream()
						.filter(it -> it instanceof StatechartCompilation)
						.collect(Collectors.toList());
			case 2: 
				return genmodel.getTasks().stream()
						.filter(it -> it instanceof EventPriorityTransformation)
						.collect(Collectors.toList());
			case 3: 
				return genmodel.getTasks().stream()
						.filter(it -> it instanceof AnalysisModelTransformation ||
								it instanceof CodeGeneration)
						.collect(Collectors.toList());
			case 4: 
				return genmodel.getTasks().stream()
						.filter(it -> it instanceof TestGeneration)
						.collect(Collectors.toList());
			default: 
				throw new IllegalArgumentException("Not known iteration variable: " + iteration);
		}
	}
	
}