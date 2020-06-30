package hu.bme.mit.gamma.ui.taskhandler;

import java.io.IOException;
import java.util.AbstractMap.SimpleEntry;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.TestReplayModelGeneration;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.trace.environment.transformation.TestReplayModelGenerator;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;

import static com.google.common.base.Preconditions.checkArgument;

public class TestReplayModelGenerationHandler extends TaskHandler {

	public TestReplayModelGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(TestReplayModelGeneration modelGeneration) throws IOException {
		ExecutionTrace executionTrace = modelGeneration.getExecutionTrace();
		checkArgument(modelGeneration.getFileName().size() == 1 &&
			modelGeneration.getTargetFolder().size() == 1 && executionTrace != null);
		TestReplayModelGenerator modelGenerator = new TestReplayModelGenerator(executionTrace);
		SimpleEntry<StatechartDefinition, CascadeCompositeComponent> result = modelGenerator.execute();
		StatechartDefinition environmentModel = result.getKey();
		CascadeCompositeComponent systemModel = result.getValue();
		// Serialization
		saveModel(environmentModel.eContainer(), targetFolderUri, executionTrace.getName() + ".gcd");
		saveModel(systemModel.eContainer(), targetFolderUri, modelGeneration.getFileName().get(0) + ".gcd");
	}

}
