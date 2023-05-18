/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.serializer.commandhandler;

import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import hu.bme.mit.gamma.property.language.ui.serializer.PropertyLanguageSerializer;
import hu.bme.mit.gamma.statechart.language.ui.serializer.StatechartLanguageSerializer;
import hu.bme.mit.gamma.trace.language.ui.serializer.TraceLanguageSerializer;
import hu.bme.mit.gamma.transformation.util.GammaFileNamer;
import hu.bme.mit.gamma.util.GammaEcoreUtil;

public class CommandHandler extends AbstractHandler {

	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final GammaFileNamer fileNamer = GammaFileNamer.INSTANCE;
	protected final Logger logger = Logger.getLogger("GammaLogger");

	@Override
	public Object execute(ExecutionEvent event) {
		try {
			ISelection sel = HandlerUtil.getActiveMenuSelection(event);
			if (sel instanceof IStructuredSelection) {
				IStructuredSelection selection = (IStructuredSelection) sel;
				Object firstElement = selection.getFirstElement();
				if (firstElement != null) {
					if (firstElement instanceof IFile) {
						IFile file = (IFile) firstElement;
						String path = file.getFullPath().toString();
						
						String parentFolder = file.getParent().getFullPath().toString();
						String name = file.getName();
						String fileExtension = file.getFileExtension();
						String extensionlessName = name.substring(0, name.length() - ("." + fileExtension).length());
						
						ResourceSet resourceSet = new ResourceSetImpl();
						URI fileUri = URI.createPlatformResourceURI(path, true);
						Resource resource = resourceSet.getResource(fileUri, true);
						
						List<EObject> contents = resource.getContents();
						int size = contents.size();
						EObject rootElem = contents.get(0);
						
						switch (fileExtension) {
							case GammaFileNamer.PACKAGE_EMF_EXTENSION: {
								// Multiple Packages in a single file - sorting them according to references
								// to support referencing already serialized Packages
								List<EObject> sortedContents = ecoreUtil.sortAccordingToReferences(contents);
								for (EObject rootElement : sortedContents) {
									String extensionlessFileName = (size <= 1) ? extensionlessName :
										extensionlessName + "_" + contents.indexOf(rootElement);
									
									String fileName = fileNamer.getPackageFileName(extensionlessFileName);
									
									StatechartLanguageSerializer serializer = new StatechartLanguageSerializer();
									// The contents list changes here (rootElement is removed)
									serializer.serialize(rootElement, parentFolder, fileName);
									logger.log(Level.INFO, "Package serialization has been finished");
								}
								break;
							}
							case GammaFileNamer.EXECUTION_EMF_EXTENSION: {
								String fileName = fileNamer.getExecutionTraceFileName(name);
								
								TraceLanguageSerializer serializer = new TraceLanguageSerializer();
								serializer.serialize(rootElem, parentFolder, fileName);
								logger.log(Level.INFO, "Execution trace serialization has been finished");
								break;
							}
							case GammaFileNamer.PROPERTY_EMF_EXTENSION: {
								String fileName = fileNamer.getPropertyFileName(name);
								
								PropertyLanguageSerializer serializer = new PropertyLanguageSerializer();
								serializer.serialize(rootElem, parentFolder, fileName);
								logger.log(Level.INFO, "Property serialization has been finished");
								break;
							}
						}
					}
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}
	
}