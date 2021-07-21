package hu.bme.mit.gamma.ui.taskhandler;

import java.util.ArrayList;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.StatechartContractGeneration;
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration;
import hu.bme.mit.gamma.scenario.model.ScenarioDefinition;
import hu.bme.mit.gamma.scenario.reduction.SimpleScenarioGenerator;
import hu.bme.mit.gamma.scenario.statechart.generator.StatechartGenerator;
import hu.bme.mit.gamma.scenario.statechart.generator.serializer.StatechartSerializer;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.statechart.interface_.Package;

public class StatechartContractGenerationHandler extends TaskHandler {
	
	GammaEcoreUtil util = GammaEcoreUtil.INSTANCE;
	
	private static boolean transformLoopFragments=false;
	
	public StatechartContractGenerationHandler(IFile file) {
		super(file);
	}

	public void execute(StatechartContractGeneration statechartGeneration) {

		setTargetFolder(statechartGeneration);
		ScenarioDefinition baseScenario = statechartGeneration.getScenario();
		SimpleScenarioGenerator simpleGenerator = new SimpleScenarioGenerator(baseScenario,transformLoopFragments);
		ScenarioDefinition simplifiedScenario= simpleGenerator.execute();
		Component component = util.getContainerOfType(baseScenario, ScenarioDeclaration.class).getComponent();
		StatechartGenerator statechartGenerator = new StatechartGenerator(true,simplifiedScenario, component);
		StatechartDefinition statechart = statechartGenerator.execute();
		Package packageOfComponent = util.getContainerOfType(component, Package.class);
		StatechartSerializer statechartSerializer =new StatechartSerializer(file);
		statechartSerializer.saveStatechart(statechart, packageOfComponent.getImports(), targetFolderUri);
	}
}