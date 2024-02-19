/********************************************************************************
 * Copyright (c) 2019-2024 Contributors to the Gamma project
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
import java.util.List;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;

import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.genmodel.model.TestGeneration;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.testgeneration.c.MakefileGenerator;
import hu.bme.mit.gamma.trace.testgeneration.java.TestGenerator;

public class TestGenerationHandler extends TaskHandler {

	public TestGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(TestGeneration testGeneration, String packageName) throws IOException {
		// Setting target folder
		setProjectLocation(testGeneration); // Before the target folder
		setTargetFolder(testGeneration);
		setTestGeneration(testGeneration, packageName);
		//
		checkArgument(testGeneration.getProgrammingLanguages().size() == 1, 
				"A single programming language must be specified: " + testGeneration.getProgrammingLanguages());
		
		ProgrammingLanguage programmingLanguage = testGeneration.getProgrammingLanguages().get(0);
		checkArgument(programmingLanguage == ProgrammingLanguage.JAVA || programmingLanguage == ProgrammingLanguage.C,
				"Currently only Java and C supported.");
		
		switch (programmingLanguage) {
			case JAVA:
				generateJavaTest(testGeneration, packageName);
				break;
			case C:
				generateCTest(testGeneration);
				break;
			default:
				throw new IllegalArgumentException("Not known programming language: " + programmingLanguage);
		}
		
	}
	
	private void generateCTest(TestGeneration testGeneration) {
		logger.info("Generating C unit tests");
		ExecutionTrace executionTrace = testGeneration.getExecutionTrace();
		String name = (testGeneration.getFileName().size() > 0) ? testGeneration.getFileName().get(0) :
			file.getName().replace(file.getFileExtension(), "");
		
		/* test code */
		URI path = URI.createURI(projectLocation);
		hu.bme.mit.gamma.trace.testgeneration.c.TestGenerator testGenerator =
				new hu.bme.mit.gamma.trace.testgeneration.c.TestGenerator(executionTrace, path, name);
		testGenerator.execute();
		MakefileGenerator makeFileGenerator = new MakefileGenerator(
				testGeneration.getExecutionTrace(), URI.createFileURI(targetFolderUri));
		makeFileGenerator.execute();
	}
	
	private void generateJavaTest(TestGeneration testGeneration, String packageName) throws IOException {
		ExecutionTrace executionTrace = testGeneration.getExecutionTrace();
		logger.info("Java test generation for: " + executionTrace.getName());
		String fileName = testGeneration.getFileName().get(0);
		TestGenerator testGenerator = new TestGenerator(executionTrace,
				testGeneration.getPackageName().get(0), fileName);
		String testClass = testGenerator.execute();
		saveCode(targetFolderUri + File.separator + testGenerator.getPackageName().replaceAll("\\.", "/"),
				fileName + ".java", testClass);
	}
	
	private void setTestGeneration(TestGeneration testGeneration, String packageName) {
		List<String> fileNames = testGeneration.getFileName();
		List<String> packageNames = testGeneration.getPackageName();
		checkArgument(fileNames.size() <= 1);
		checkArgument(packageNames.size() <= 1);
		if (packageNames.isEmpty()) {
			packageNames.add(packageName);
		}
		if (fileNames.isEmpty()) {
			fileNames.add("ExecutionTraceSimulation");
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