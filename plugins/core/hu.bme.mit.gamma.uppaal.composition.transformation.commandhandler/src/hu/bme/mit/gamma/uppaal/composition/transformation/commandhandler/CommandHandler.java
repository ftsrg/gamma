/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.composition.transformation.commandhandler;

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

import hu.bme.mit.gamma.dialog.DialogUtil;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.uppaal.composition.transformation.api.util.DefaultCompositionToUppaalTransformer;

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
						ResourceSet resourceSet = new ResourceSetImpl();
						IFile selectedFile = (IFile) selection.getFirstElement();
						String targetFolderUri = selectedFile.getParent().getLocation().toString();
						URI packageUri = URI.createPlatformResourceURI(selectedFile.getFullPath().toString(), true);
						// Loading the model
						Package gammaPackage = this.loadResource(resourceSet, packageUri);
						DefaultCompositionToUppaalTransformer transformer = new DefaultCompositionToUppaalTransformer();
						transformer.transformComponent(gammaPackage, targetFolderUri, selectedFile.getName());
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

	private Package loadResource(ResourceSet resSet, URI uri) throws IllegalArgumentException {
		Resource resource = resSet.getResource(uri, true);
		EObject elem = resource.getContents().get(0);
		if (!(elem instanceof Package)) {
			throw new IllegalArgumentException("There must be a single package in the selection: " + elem.getClass());
		}
		return (Package) elem;
	}
	
}
