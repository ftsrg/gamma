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
package hu.bme.mit.gamma.trace.testgeneration.commandhandler;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
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

import hu.bme.mit.gamma.dialog.DialogUtil;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.testgeneration.java.TestGenerator;

public class CommandHandler extends AbstractHandler {

	protected final Logger logger = Logger.getLogger("GammaLogger");
	
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
						String fullPath = file.getFullPath().toString();
						// Decoding so spaces do not stir trouble
						fullPath = URI.decode(fullPath);
						String[] splittedPath = fullPath.split("/");
						// No file extension
						URI fileURI = null;
						if (fullPath.endsWith(".get")) {
							fileURI = URI.createPlatformResourceURI(fullPath, true);
						}
						Resource resource;
						try {
							resource = resSet.getResource(fileURI, true);
						} catch (Exception e) {
							fileURI = URI.createPlatformResourceURI(fullPath, true);
							resource = resSet.getResource(fileURI, true);
						}
						if (resource.getContents() != null) {
							if (resource.getContents().get(0) instanceof ExecutionTrace) {
								ExecutionTrace executionTrace = (ExecutionTrace) resource.getContents().get(0);
								// From import "statechartView" we need the statechart part
								Package importedPackage = executionTrace.getImport();
								String importedPackageName = importedPackage.getName();
								if (importedPackageName.endsWith("View")) {
									importedPackageName = importedPackageName.substring(0, importedPackageName.length() - "View".length());
								} 
								else {
									logger.log(Level.WARNING, "The package name does not contain View at the end: " + importedPackageName);
								}
								importedPackageName = importedPackageName.toLowerCase(); // Otherwise, capital letters may remain in the name
								String className = splittedPath[splittedPath.length - 1].split(".get")[0];
								String packageName = file.getProject().getName().toLowerCase();
								TestGenerator testGenerator = new TestGenerator(executionTrace,	packageName, className);
								String testClass = testGenerator.execute();
								// Generate in the test-gen folder the right package
								String basePackage = packageName.replaceAll("\\.", "/") + "/" + importedPackageName;
								String testClassPath = file.getProject().getLocation() + "/test-gen/" +
										basePackage + "/" + className + ".java";
								saveCode(testClass, testClassPath);
								logger.log(Level.INFO, "The test class generation based on a trace model has been finished.");
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
	
	/**
	 * Creates a Java class from the the given code at the location specified by the given URI.
	 */
	private void saveCode(String code, String uri) throws IOException {
		new File(uri).getParentFile().mkdirs();
		try (FileWriter fileWriter = new FileWriter(uri)) {
			fileWriter.write(code);
		}
	}

}
