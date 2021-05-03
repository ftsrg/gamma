/********************************************************************************
 * Copyright (c) 2019-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui.taskhandler;

import static com.google.common.base.Preconditions.checkArgument;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.util.logging.Level;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.genmodel.model.TestGeneration;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.testgeneration.java.TestGenerator;

public class TestGenerationHandler extends TaskHandler {

	public TestGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(TestGeneration testGeneration, String packageName) throws IOException {
		// Setting target folder
		setTargetFolder(testGeneration);
		//
		checkArgument(testGeneration.getProgrammingLanguages().size() == 1, 
				"A single programming language must be specified: " + testGeneration.getProgrammingLanguages());
		checkArgument(testGeneration.getProgrammingLanguages().get(0) == ProgrammingLanguage.JAVA, 
				"Currently only Java is supported.");
		setTestGeneration(testGeneration, packageName);
		ExecutionTrace executionTrace = testGeneration.getExecutionTrace();
		logger.log(Level.INFO, "Resource set content for test generation: " + executionTrace.eResource().getResourceSet());
		TestGenerator testGenerator = new TestGenerator(executionTrace,
				testGeneration.getPackageName().get(0), testGeneration.getFileName().get(0));
		String testClass = testGenerator.execute();
		saveCode(targetFolderUri + File.separator + testGenerator.getPackageName().replaceAll("\\.", "/"),
				testGeneration.getFileName().get(0) + ".java", testClass);
	}
	
	private void setTestGeneration(TestGeneration testGeneration, String packageName) {
		checkArgument(testGeneration.getFileName().size() <= 1);
		checkArgument(testGeneration.getPackageName().size() <= 1);
		if (testGeneration.getPackageName().isEmpty()) {
			testGeneration.getPackageName().add(packageName);
		}
		if (testGeneration.getFileName().isEmpty()) {
			testGeneration.getFileName().add("ExecutionTraceSimulation");
		}
		// TargetFolder set in setTargetFolder
	}
	
	/**
	 * Creates a Java class from the the given code at the location specified by the given URI.
	 */
	private void saveCode(String parentFolder, String fileName, String code) throws IOException {
		String path = parentFolder + File.separator + fileName;
		new File(path).getParentFile().mkdirs();
		try (FileWriter fileWriter = new FileWriter(path)) {
			fileWriter.write(code);
		}
	}
	
}
