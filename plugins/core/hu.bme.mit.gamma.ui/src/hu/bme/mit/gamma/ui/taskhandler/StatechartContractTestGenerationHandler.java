package hu.bme.mit.gamma.ui.taskhandler;

import java.io.IOException;
import java.util.List;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.StatechartContractTestGeneration;
import hu.bme.mit.gamma.scenario.trace.generator.ScenarioStatechartTraceGenerator;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
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
			Gamma2XstsTransformer transformer = analysisModelTransformationHandler.new Gamma2XstsTransformer();
			constraintValue = transformer.evaluateConstraint(testGeneration.getConstraint());
		}

		StatechartDefinition stateChart = (StatechartDefinition) testGeneration.getComponentReference().getComponent();
		ScenarioStatechartTraceGenerator traceGenerator = new ScenarioStatechartTraceGenerator(
				stateChart,	constraintValue, StatechartModelDerivedFeatures.getScenarioAllowedWaitAnnotation(stateChart));
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