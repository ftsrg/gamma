/********************************************************************************
 * Copyright (c) 2020 Contributors to the Gamma project
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
import java.io.IOException;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.AdaptiveContractTestGeneration;
import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.statechart.contract.testgeneration.java.StatechartToTestTransformer;

public class AdaptiveContractTestGenerationHandler extends TaskHandler {
	
	public AdaptiveContractTestGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(AdaptiveContractTestGeneration testGeneration, String containingFile, String packageName) throws IOException {
		checkArgument(testGeneration.getLanguage().size() == 1, 
				"A single programming language must be specified: " + testGeneration.getLanguage());
		checkArgument(testGeneration.getLanguage().get(0) == ProgrammingLanguage.JAVA, 
				"Currently only Java is supported.");
		setAdaptiveContractTestGeneration(testGeneration, packageName);
		StatechartToTestTransformer transformer = new StatechartToTestTransformer();
		String fileName = testGeneration.getFileName().isEmpty() ? null : testGeneration.getFileName().get(0);
		transformer.execute(testGeneration.getStatechartContract(), testGeneration.getArguments(),
			new File(containingFile), new File(targetFolderUri), testGeneration.getPackageName().get(0), fileName);
	}
	
	private void setAdaptiveContractTestGeneration(AdaptiveContractTestGeneration testGeneration, String packageName) {
		checkArgument(testGeneration.getFileName().size() <= 1);
		checkArgument(testGeneration.getPackageName().size() <= 1);
		if (testGeneration.getPackageName().isEmpty()) {
			testGeneration.getPackageName().add(packageName);
		}
		// TargetFolder set in setTargetFolder
	}
	
}
