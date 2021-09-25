package hu.bme.mit.gamma.ui.taskhandler;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.StatechartContractGeneration;
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration;
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition;
import hu.bme.mit.gamma.scenario.reduction.SimpleScenarioGenerator;
import hu.bme.mit.gamma.scenario.statechart.generator.StatechartGenerationMode;
import hu.bme.mit.gamma.scenario.statechart.generator.StatechartGenerator;
import hu.bme.mit.gamma.scenario.statechart.generator.serializer.StatechartSerializer;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;

public class StatechartContractGenerationHandler extends TaskHandler {
	
	private static boolean transformLoopFragments = false;
	
	public StatechartContractGenerationHandler(IFile file) {
		super(file);
	}

	public void execute(StatechartContractGeneration statechartGeneration) {

		setTargetFolder(statechartGeneration);
		ScenarioDefinition baseScenario = statechartGeneration.getScenario();
		SimpleScenarioGenerator simpleGenerator = new SimpleScenarioGenerator(
				baseScenario, transformLoopFragments);
		ScenarioDefinition simplifiedScenario= simpleGenerator.execute();
		Component component = ecoreUtil.getContainerOfType(baseScenario, ScenarioDeclaration.class)
				.getComponent();
		StatechartGenerator statechartGenerator = new StatechartGenerator(
				true, simplifiedScenario, component, StatechartGenerationMode.GENERATE_ONLY_FORWARD);
		StatechartDefinition statechart = statechartGenerator.execute();
		Package packageOfComponent = ecoreUtil.getContainerOfType(component, Package.class);
		StatechartSerializer statechartSerializer = new StatechartSerializer(file);
		statechartSerializer.saveStatechart(statechart, packageOfComponent.getImports(), targetFolderUri);
	}
}