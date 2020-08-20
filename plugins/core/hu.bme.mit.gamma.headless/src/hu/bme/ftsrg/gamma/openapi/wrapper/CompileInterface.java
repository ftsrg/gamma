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
package hu.bme.ftsrg.gamma.openapi.wrapper;


import java.io.File;
import java.io.IOException;
import java.util.AbstractMap.SimpleEntry;
import java.util.Collections;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IWorkspaceRoot;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.Path;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.yakindu.sct.model.sgraph.Statechart;

import com.google.inject.Injector;

import hu.bme.mit.gamma.language.util.serialization.GammaLanguageSerializer;
import hu.bme.mit.gamma.statechart.language.ui.internal.LanguageActivator;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.yakindu.transformation.batch.InterfaceTransformer;
import hu.bme.mit.gamma.yakindu.transformation.traceability.Y2GTrace;


public class CompileInterface {

	protected Logger logger = Logger.getLogger("GammaLogger");
	
	
	public void execute() throws ExecutionException {
						IPath path = new Path("D:/BME/Projects/Workspaces/runtime-hu.bme.mit.gamma.headless.product/hu.bme.mit.gamma.tutorial.start/model/Interfaces/Interfaces.sct");
				
						IWorkspaceRoot root = ResourcesPlugin.getWorkspace().getRoot();
						logger.log(Level.INFO, "Workspace root: " + root.getRawLocationURI());
						IFile file = (IFile) root.getFileForLocation(path);
						ResourceSet resSet = new ResourceSetImpl();
						logger.log(Level.INFO, "Resource set for Yakindu to Gamma interface generation: " + resSet);
						URI fileURI = URI.createPlatformResourceURI(file.getFullPath().toString(), true);
						logger.log(Level.INFO, "File URI for interface: " + fileURI);
						
						Resource resource;
						try {
							resource = resSet.getResource(fileURI, true);
							System.out.print(fileURI.toString());
						} catch (RuntimeException e) {
							logger.log(Level.SEVERE, "Could not open test file.");
							throw e;
						}
//						String filePath = "/hu.bme.mit.gamma.tutorial.start/model/Interfaces/Interfaces.sct"; 
//						URI fileURI = URI.createPlatformResourceURI(filePath, true);
//						Resource resource;
//						ResourceSet resSet = new ResourceSetImpl();
//						try {
//							resource = resSet.getResource(fileURI, true);
//							System.out.print(fileURI.toString());
//						} catch (RuntimeException e) {
//							logger.log(Level.SEVERE, "Could not open test file.");
//							throw e;
//						}
						if (resource.getContents() != null) {
							if (resource.getContents().get(0) instanceof Statechart) {
								Statechart statechart = (Statechart) resource.getContents().get(0);
								if (!statechart.getRegions().isEmpty()) {
									logger.log(Level.INFO, "This statechart contains regions, and not just a single interface!");
								}
								String fileURISubstring = file.getLocationURI().toString().substring(5);
								String parentFolder = fileURISubstring.substring(0, fileURISubstring.lastIndexOf("/"));
								// No file extension
								String fileName = fileURISubstring.substring(fileURISubstring.lastIndexOf("/") + 1, fileURISubstring.lastIndexOf("."));
								logger.log(Level.INFO, "Resource set content for Yakindu to Gamma interface generation: " + resSet);
								SimpleEntry<Package, Y2GTrace> resultModels = (SimpleEntry<Package, Y2GTrace>) new InterfaceTransformer(statechart, statechart.getName()).execute();
								try {
									saveModel(resultModels.getKey(), parentFolder, fileName + ".gcd");
									saveModel(resultModels.getValue(), parentFolder, "." + fileName + ".y2g");

								} catch (IOException e) {
									//dummy handle
									e.printStackTrace();
								}
								logger.log(Level.INFO, "The Yakindu-Gamma interface transformation has been finished.");
							}
						}
						return;
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
		Injector injector = LanguageActivator.getInstance()
				.getInjector(LanguageActivator.HU_BME_MIT_GAMMA_STATECHART_LANGUAGE_STATECHARTLANGUAGE);
		GammaLanguageSerializer serializer = injector.getInstance(GammaLanguageSerializer.class);
		serializer.save(rootElem, URI.decode(parentFolder + File.separator + fileName));
   }
	
}