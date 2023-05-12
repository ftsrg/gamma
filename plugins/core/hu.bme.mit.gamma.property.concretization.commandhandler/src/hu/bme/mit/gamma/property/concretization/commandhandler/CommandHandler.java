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
package hu.bme.mit.gamma.property.concretization.commandhandler;

import java.util.List;
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

import hu.bme.mit.gamma.property.concretization.PropertyConcretizer;
import hu.bme.mit.gamma.property.model.PropertyPackage;
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
						EObject rootElem = contents.get(0);
						
						PropertyPackage propertyPackage = (PropertyPackage) rootElem;
						
						PropertyConcretizer propertyConcretizer = PropertyConcretizer.INSTANCE;
						PropertyPackage concretizedPropertyPackage = propertyConcretizer.execute(propertyPackage);
						
						ecoreUtil.normalSave(concretizedPropertyPackage, parentFolder, extensionlessName + "_.gpd");
					}
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
		}
		return null;
	}
	
}
