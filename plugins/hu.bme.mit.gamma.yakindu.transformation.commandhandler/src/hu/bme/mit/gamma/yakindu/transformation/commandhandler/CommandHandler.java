/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.yakindu.transformation.commandhandler;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IncrementalProjectBuilder;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import hu.bme.mit.gamma.dialog.DialogUtil;
import hu.bme.mit.gamma.yakindu.genmodel.AnalysisModelTransformation;
import hu.bme.mit.gamma.yakindu.genmodel.CodeGeneration;
import hu.bme.mit.gamma.yakindu.genmodel.GenModel;
import hu.bme.mit.gamma.yakindu.genmodel.InterfaceCompilation;
import hu.bme.mit.gamma.yakindu.genmodel.StatechartCompilation;
import hu.bme.mit.gamma.yakindu.genmodel.Task;
import hu.bme.mit.gamma.yakindu.genmodel.TestGeneration;
import hu.bme.mit.gamma.yakindu.genmodel.YakinduCompilation;
import hu.bme.mit.gamma.yakindu.transformation.commandhandler.taskhandler.AnalysisModelTransformationHandler;
import hu.bme.mit.gamma.yakindu.transformation.commandhandler.taskhandler.CodeGenerationHandler;
import hu.bme.mit.gamma.yakindu.transformation.commandhandler.taskhandler.InterfaceCompilationHandler;
import hu.bme.mit.gamma.yakindu.transformation.commandhandler.taskhandler.StatechartCompilationHandler;
import hu.bme.mit.gamma.yakindu.transformation.commandhandler.taskhandler.TestGenerationHandler;

public class CommandHandler extends AbstractHandler {

	protected Logger logger = Logger.getLogger("GammaLogger");
	
	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		ISelection sel = HandlerUtil.getActiveMenuSelection(event);
		try {
			if (sel instanceof IStructuredSelection) {
				IStructuredSelection selection = (IStructuredSelection) sel;
				if (selection.getFirstElement() != null) {
					if (selection.getFirstElement() instanceof IFile) {
						IFile file = (IFile) selection.getFirstElement();
						IProject project = file.getProject();
						// Multiple compilations due to the dependencies between models
						final int MAX_ITERATION_COUNT = 3;
						for (int i = 0; i < MAX_ITERATION_COUNT; ++i) {
							ResourceSet resourceSet = new ResourceSetImpl();
							URI fileURI = URI.createPlatformResourceURI(file.getFullPath().toString(), true);
							Resource resource = resourceSet.getResource(fileURI, true);
							if (resource.getContents() != null) {
								EObject content = resource.getContents().get(0);
								if (content instanceof GenModel) {
									String fileUriSubstring = URI.decode(file.getLocation().toString());
									// Decoding so spaces do not stir trouble
									String parentFolderUri = fileUriSubstring.substring(0, fileUriSubstring.lastIndexOf("/"));	
									// WARNING: workspace location and imported project locations are not to be confused
									GenModel genmodel = (GenModel) content;
									// Sorting: InterfaceCompilation < StatechartCompilation < else does not work as the generated models are not reloaded
									List<Task> tasks = orderTasks(genmodel, i);
									for (Task task : tasks) {
										if (task instanceof YakinduCompilation) {
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
										}
										else if (task instanceof CodeGeneration) {
											CodeGeneration codeGeneration = (CodeGeneration) task;
											logger.log(Level.INFO, "Resource set content for Java code generation: " + resourceSet);
											CodeGenerationHandler handler = new CodeGenerationHandler();
											handler.setTargetFolder(codeGeneration, file, parentFolderUri);
											handler.execute(codeGeneration, project.getName());
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
											TestGeneration testGeneration = (TestGeneration) task;
											TestGenerationHandler handler = new TestGenerationHandler();
											handler.setTargetFolder(testGeneration, file, parentFolderUri);
											handler.execte(testGeneration, project.getName());
											logger.log(Level.INFO, "The test generation has been finished.");
										}
									}
									if (tasks.stream().anyMatch(it -> 
											it instanceof YakinduCompilation ||
											it instanceof TestGeneration)) {
										logger.log(Level.INFO, "Cleaning project...");
										// This is due to the bad imports and error markers generated by Xtext
										// as it serializes references to other models as names instead of URLs
										project.build(IncrementalProjectBuilder.CLEAN_BUILD, null);
										logger.log(Level.INFO, "Cleaning project finished.");
									}
								}
							}
						}
					}
				}
			}
			return null;
		} catch (Exception exception) {
			exception.printStackTrace();
			logger.log(Level.SEVERE, exception.getMessage());
			DialogUtil.showErrorWithStackTrace(exception.getMessage(), exception);
		}
		return null;
	}
	
	/** 
	 * Compilation order: interfaces <- statecharts <- everything else.
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
			default: 
				return genmodel.getTasks().stream()
						.filter(it -> !(it instanceof YakinduCompilation))
						.collect(Collectors.toList());
		}
	}
	
}