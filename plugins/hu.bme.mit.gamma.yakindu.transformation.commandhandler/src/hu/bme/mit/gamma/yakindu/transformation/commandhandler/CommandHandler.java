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

import java.io.File;
import java.io.IOException;
import java.util.AbstractMap.SimpleEntry;
import java.util.Collections;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import com.google.inject.Injector;

import hu.bme.mit.gamma.dialog.DialogUtil;
import hu.bme.mit.gamma.statechart.language.ui.internal.LanguageActivator;
import hu.bme.mit.gamma.statechart.language.ui.serializer.StatechartLanguageSerializer;
import hu.bme.mit.gamma.statechart.model.Package;
import hu.bme.mit.gamma.yakindu.genmodel.GenModel;
import hu.bme.mit.gamma.yakindu.genmodel.InterfaceCompilation;
import hu.bme.mit.gamma.yakindu.genmodel.StatechartCompilation;
import hu.bme.mit.gamma.yakindu.genmodel.Task;
import hu.bme.mit.gamma.yakindu.genmodel.YakinduCompilation;
import hu.bme.mit.gamma.yakindu.transformation.batch.InterfaceTransformer;
import hu.bme.mit.gamma.yakindu.transformation.batch.ModelValidator;
import hu.bme.mit.gamma.yakindu.transformation.batch.YakinduToGammaTransformer;
import hu.bme.mit.gamma.yakindu.transformation.traceability.Y2GTrace;

/**
 * This class receives the transformation command, acquires the Yakindu model as a resource,
 *  then creates a transformer with the resource file and executes the transformation. 
 */
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
						ResourceSet resSet = new ResourceSetImpl();
						logger.log(Level.INFO, "Resource set for Yakindu to Gamma statechart generation: " + resSet);
						URI fileURI = URI.createPlatformResourceURI(file.getFullPath().toString(), true);
						Resource resource;
						try {
							resource = resSet.getResource(fileURI, true);
						} catch (RuntimeException e) {
							return null;
						}
						if (resource.getContents() != null) {
							if (resource.getContents().get(0) instanceof GenModel) {
								String fileUriSubstring = URI.decode(file.getLocation().toString());
								// Decoding so spaces do not stir trouble
								String parentFolderUri = fileUriSubstring.substring(0, fileUriSubstring.lastIndexOf("/"));	
								// No file extension
								String fileName = file.getName().substring(0, file.getName().length() - file.getFileExtension().length() - 1);
								GenModel genmodel = (GenModel) resource.getContents().get(0);
								String workspaceLocation = file.getWorkspace().getRoot().getLocation().toString();
								for (Task task : genmodel.getTasks()) {
									setTask(task, file, parentFolderUri);
									String targetFolderUri = workspaceLocation + File.separator +
											task.getTargetProject() + File.separator + task.getTargetFolder();
									if (task instanceof YakinduCompilation) {
										YakinduCompilation yakinduCompilation = (YakinduCompilation) task;
										setYakinduCompilation(yakinduCompilation, fileName);
										if (task instanceof InterfaceCompilation) {
											logger.log(Level.INFO, "Resource set content for Yakindu to Gamma interface generation: " + resSet);
											InterfaceCompilation interfaceCompilation = (InterfaceCompilation) task;
											InterfaceTransformer transformer = new InterfaceTransformer(
													interfaceCompilation.getStatechart(), interfaceCompilation.getPackageName());
											SimpleEntry<Package, Y2GTrace> resultModels = transformer.execute();
											saveModel(resultModels.getKey(), targetFolderUri, interfaceCompilation.getFileName() + ".gcd");
											saveModel(resultModels.getValue(), targetFolderUri, "." + interfaceCompilation.getFileName()  + ".y2g");
											logger.log(Level.INFO, "The Yakindu-Gamma interface transformation has been finished.");
										}
										else if (task instanceof StatechartCompilation) {
											logger.log(Level.INFO, "Resource set content Yakindu to Gamma statechart generation: " + resSet);
											StatechartCompilation statechartCompilation = (StatechartCompilation) task;
											setStatechartCompilation(statechartCompilation, fileName + "Statechart");
											ModelValidator validator = new ModelValidator(statechartCompilation.getStatechart());
											validator.checkModel();
											YakinduToGammaTransformer transformer = new YakinduToGammaTransformer(statechartCompilation);
											SimpleEntry<Package, Y2GTrace> resultModels = transformer.execute();
											// Saving Xtext and EMF models
											saveModel(resultModels.getKey(), targetFolderUri, yakinduCompilation.getFileName() + ".gcd");
											saveModel(resultModels.getValue(), targetFolderUri, "." + yakinduCompilation.getFileName() + ".y2g");
											transformer.dispose();
											logger.log(Level.INFO, "The Yakindu-Gamma transformation has been finished.");
										}
									}
								}
							}
						}
						return null;
					}
				}
			}
		} catch (Exception exception) {
			exception.printStackTrace();
			logger.log(Level.SEVERE, exception.getMessage());
			DialogUtil.showErrorWithStackTrace(exception.getMessage(), exception);
		}
		return null;
	}
	
	private void setTask(Task task, IFile file, String parentFolderUri) {
		String projectName = file.getProject().getName();
		// No file extension
		String fileName = getNameWithoutExtension(file);
		// E.g., C:/Users/...
		String workspaceLocation = file.getWorkspace().getRoot().getLocation().toString();
		if (task.getFileName() == null) {
			task.setFileName(fileName);
		}
		if (task.getTargetProject() == null) {
			task.setTargetProject(projectName);
		}
		if (task.getTargetFolder() == null) {
			String targetFolder = parentFolderUri.substring((workspaceLocation + File.separator +
					projectName).length());
			task.setTargetFolder(targetFolder);
		}
	}

	private void setYakinduCompilation(YakinduCompilation yakinduCompilation, String packageName) {
		if (yakinduCompilation.getPackageName() == null) {
			yakinduCompilation.setPackageName(packageName);
		}
	}
	
	private void setStatechartCompilation(StatechartCompilation statechartCompilation, String statechartName) {
		if (statechartCompilation.getStatechartName() == null) {
			statechartCompilation.setStatechartName(statechartName);
		}
	}
	
	private String getNameWithoutExtension(IFile file) {
		return file.getName().substring(0, file.getName().length() - file.getFileExtension().length() - 1);
	}
	
	/**
	 * Responsible for saving the given element into a resource file.
	 */
	private void saveModel(EObject rootElem, String parentFolder, String fileName) throws IOException {
		if (rootElem instanceof Package) {
			try {
				// Trying to serialize the model
				serialize(rootElem, parentFolder, fileName);
			} catch (Exception e) {
				e.printStackTrace();
				logger.log(Level.WARNING, e.getMessage() + System.lineSeparator() +
						"Possibly you have two more model elements with the same name specified in the previous error message.");
				new File(parentFolder + File.separator + fileName).delete();
				// Saving like an EMF model
				String newFileName = fileName.substring(0, fileName.lastIndexOf(".")) + ".gsm";
				normalSave(rootElem, parentFolder, newFileName);
			}
		}
		else {
			// It is not a statechart model, regular saving
			normalSave(rootElem, parentFolder, fileName);
		}
	}

	private void normalSave(EObject rootElem, String parentFolder, String fileName) throws IOException {
		ResourceSet resourceSet = new ResourceSetImpl();
		Resource saveResource = resourceSet.createResource(URI.createFileURI(URI.decode(parentFolder + File.separator + fileName)));
		saveResource.getContents().add(rootElem);
		saveResource.save(Collections.EMPTY_MAP);
	}
	
	private void serialize(EObject rootElem, String parentFolder, String fileName) throws IOException {
		// This is how an injected object can be retrieved
		Injector injector = LanguageActivator.getInstance()
				.getInjector(LanguageActivator.HU_BME_MIT_GAMMA_STATECHART_LANGUAGE_STATECHARTLANGUAGE);
		StatechartLanguageSerializer serializer = injector.getInstance(StatechartLanguageSerializer.class);
		serializer.save(rootElem, URI.decode(parentFolder + File.separator + fileName));
	}
	
}