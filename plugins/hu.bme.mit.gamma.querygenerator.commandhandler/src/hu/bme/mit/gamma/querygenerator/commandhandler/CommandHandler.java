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
import hu.bme.mit.gamma.statechart.model.Package;

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
						logger.log(Level.INFO, "Resource set created for displaying model elements on GUI: " + resSet);
						String fullPath = file.getFullPath().toString();
						// Decoding so spaces do not stir trouble
						fullPath = URI.decode(fullPath);
						String parentFolder = fullPath.substring(0, fullPath.lastIndexOf("/"));
						// No file extension
						String fileName = fullPath.substring(fullPath.lastIndexOf("/") + 1, fullPath.lastIndexOf("."));
						URI fileURI = null;
						// Placing it on a .gsm if it is placed on a .gcd
						// (This command can be placed on either of them)
						if (fullPath.endsWith(".gcd")) {
							// .gsm are hidden
							String newPath = parentFolder + File.separator + "." + fileName + ".gsm";
							fileURI = URI.createPlatformResourceURI(newPath, true);
						}
						Resource resource = null;
						try {
							resource = resSet.getResource(fileURI, true);
						} catch (Exception e) {
							// . gsm file is not found
							logger.log(Level.SEVERE, "The transformed UPPAAL model cannot be found. Transform the Gamma model to UPPAAL first.");
						}
						if (resource != null && resource.getContents() != null) {
							if (resource.getContents().get(0) instanceof Package) {
								AppMain app = new AppMain();
								// E.g.: F:/eclipse_ws/sc_analysis_comp_oxy/runtime-New_configuration/
								// hu.bme.mit.inf.gamma.tests/model/TestOneComponent.statechartmodel
								app.start(resSet, file);
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