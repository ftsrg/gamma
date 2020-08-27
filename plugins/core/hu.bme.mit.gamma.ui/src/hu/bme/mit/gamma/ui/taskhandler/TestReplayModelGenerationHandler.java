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
package hu.bme.mit.gamma.ui.taskhandler;

import static com.google.common.base.Preconditions.checkArgument;

import java.io.IOException;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.TestReplayModelGeneration;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.trace.environment.transformation.TestReplayModelGenerator;
import hu.bme.mit.gamma.trace.environment.transformation.TestReplayModelGenerator.Result;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;

public class TestReplayModelGenerationHandler extends TaskHandler {

	public TestReplayModelGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(TestReplayModelGeneration modelGeneration) throws IOException {
		ExecutionTrace executionTrace = modelGeneration.getExecutionTrace();
		checkArgument(modelGeneration.getFileName().size() == 1 && executionTrace != null);
		TestReplayModelGenerator modelGenerator = new TestReplayModelGenerator(executionTrace);
		Result result = modelGenerator.execute();
		StatechartDefinition environmentModel = result.getEnvironmentModel();
		CascadeCompositeComponent systemModel = result.getSystemModel();
		// Serialization
		saveModel(environmentModel.eContainer(), targetFolderUri, executionTrace.getName() + ".gcd");
		saveModel(systemModel.eContainer(), targetFolderUri, modelGeneration.getFileName().get(0) + ".gcd");
	}
	
}
