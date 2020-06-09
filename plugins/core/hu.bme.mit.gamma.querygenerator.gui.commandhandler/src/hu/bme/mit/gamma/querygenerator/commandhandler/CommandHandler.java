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
package hu.bme.mit.gamma.querygenerator.commandhandler;

import java.io.File;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.viewers.ISelection;
import org.eclipse.jface.viewers.IStructuredSelection;
import org.eclipse.ui.handlers.HandlerUtil;

import hu.bme.mit.gamma.querygenerator.application.AppMain;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.uppaal.composition.transformation.api.util.DefaultCompositionToUppaalTransformer;
import hu.bme.mit.gamma.xsts.transformation.GammaToXSTSTransformer;

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
						ResourceSet resourceSet = new ResourceSetImpl();
						logger.log(Level.INFO, "Resource set created for displaying model elements on GUI: " + resourceSet);
						String fullPath = file.getFullPath().toString();
						// Decoding so spaces do not stir trouble
						fullPath = URI.decode(fullPath);
						String relativeParentFolder = fullPath.substring(0, fullPath.lastIndexOf("/"));
						String absoluteParentFolder = file.getParent().getLocation().toString();
						// No file extension
						String fileName = fullPath.substring(fullPath.lastIndexOf("/") + 1, fullPath.lastIndexOf("."));
						URI flattenedFileUri = null;
						// Placing it on a .gsm if it is placed on a .gcd
						// (This command can be placed on either of them)
						if (fullPath.endsWith(".gcd")) {
							// .gsm are hidden
							String newPath = relativeParentFolder + File.separator + "." + fileName + ".gsm";
							flattenedFileUri = URI.createPlatformResourceURI(newPath, true);
						}
						Resource resource = null;
						try {
							resource = resourceSet.getResource(flattenedFileUri, true);
						} catch (Exception e) {
							// .gsm file is not found
							logger.log(Level.INFO, "The transformed UPPAAL model cannot be found. Starting UPPAAL transformation.");
							URI originalFileUri = URI.createPlatformResourceURI(fullPath, true);
							resource = resourceSet.getResource(originalFileUri, true);
							Package gammaPackage = (Package) resource.getContents().get(0);
							DefaultCompositionToUppaalTransformer transformer = new DefaultCompositionToUppaalTransformer();
							final File containingFile = new File(file.getLocation().toString());
							transformer.transformComponent(gammaPackage, containingFile);
							logger.log(Level.INFO, "UPPAAL transformation has been finished.");
							resourceSet.getResources().clear(); // Has to be done, otherwise the resource content is null
							resource = resourceSet.getResource(flattenedFileUri, true);
							logger.log(Level.INFO, "Starting XSTS transformation.");
							Package _package = (Package) resource.getContents().get(0);
							GammaToXSTSTransformer gammaToXSTSTransformer = new GammaToXSTSTransformer();
							File xStsFile = new File(absoluteParentFolder + File.separator + fileName + ".xsts");
							gammaToXSTSTransformer.executeAndSerializeAndSave(_package, xStsFile);
							logger.log(Level.INFO, "XSTS transformation has been finished.");
						}
						if (resource != null) {
							if (resource.getContents().get(0) instanceof Package) {
								AppMain app = new AppMain();
								// E.g.: F:/eclipse_ws/sc_analysis_comp_oxy/runtime-New_configuration/
								// hu.bme.mit.inf.gamma.tests/model/TestOneComponent.statechartmodel
								app.start(file);
							}
						}
						return null;
					}
				}
			}
		} catch (Exception exception) {
			exception.printStackTrace();
		}
		return null;
	}

}