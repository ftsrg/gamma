/********************************************************************************
 * Copyright (c) 2021-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui.taskhandler;

import java.io.IOException;
import java.util.List;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.StatechartContractTestGeneration;
import hu.bme.mit.gamma.scenario.trace.generator.ScenarioStatechartTraceGenerator;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.ui.taskhandler.AnalysisModelTransformationHandler.Gamma2XstsTransformer;

public class StatechartContractTestGenerationHandler extends TaskHandler {

	public StatechartContractTestGenerationHandler(IFile file) {
		super(file);
	}

	public void execute(StatechartContractTestGeneration testGeneration) {
		setTargetFolder(testGeneration);
		int constraintValue = 0;
		if (testGeneration.getConstraint() != null) {
			AnalysisModelTransformationHandler analysisModelTransformationHandler =
					new AnalysisModelTransformationHandler(file);
			Gamma2XstsTransformer transformer = analysisModelTransformationHandler
					.new Gamma2XstsTransformer();
			constraintValue = transformer.evaluateConstraint(testGeneration.getConstraint());
		}

		ComponentReference componentReference = testGeneration.getComponentReference();
		StatechartDefinition stateChart = (StatechartDefinition) componentReference.getComponent();
		ScenarioStatechartTraceGenerator traceGenerator = new ScenarioStatechartTraceGenerator(
				stateChart, componentReference.getArguments(), constraintValue);
		List<ExecutionTrace> testTraces = traceGenerator.execute();
		for (ExecutionTrace testTrace : testTraces) {
			try {
				serializer.saveModel(testTrace, targetFolderUri, testTrace.getName() + ".get");
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}

}