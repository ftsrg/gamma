package hu.bme.mit.gamma.ui.taskhandler;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.ContractAutomatonType;
import hu.bme.mit.gamma.genmodel.model.StatechartContractGeneration;
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration;
import hu.bme.mit.gamma.scenario.model.ScenarioPackage;
import hu.bme.mit.gamma.scenario.model.reduction.SimpleScenarioGenerator;
import hu.bme.mit.gamma.scenario.model.sorter.ScenarioContentSorter;
import hu.bme.mit.gamma.scenario.statechart.generator.AbstractContractStatechartGeneration;
import hu.bme.mit.gamma.scenario.statechart.generator.MonitorStatechartGenerator;
import hu.bme.mit.gamma.scenario.statechart.generator.StatechartGenerationMode;
import hu.bme.mit.gamma.scenario.statechart.generator.TestGeneratorStatechartGenerator;
import hu.bme.mit.gamma.scenario.statechart.generator.serializer.StatechartSerializer;
import hu.bme.mit.gamma.scenario.statechart.util.transformation.AutomatonDeterminizator;
import hu.bme.mit.gamma.statechart.contract.ContractModelFactory;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;

public class StatechartContractGenerationHandler extends TaskHandler {
	
	protected ContractModelFactory contractFactory = ContractModelFactory.eINSTANCE;

	public StatechartContractGenerationHandler(IFile file) {
		super(file);
	}

	public void execute(StatechartContractGeneration statechartGeneration) {

		setTargetFolder(statechartGeneration);
		ScenarioDeclaration baseScenario = statechartGeneration.getScenario();
		ScenarioPackage containingScenarioPackage = ecoreUtil.getContainerOfType(baseScenario, ScenarioPackage.class);
		Component component = containingScenarioPackage.getComponent();
		StatechartGenerationMode generationMode = statechartGeneration.isUseIteratingVariable()
				? StatechartGenerationMode.GENERATE_ORIGINAL_STRUCTURE
				: StatechartGenerationMode.GENERATE_ONLY_FORWARD;
		AbstractContractStatechartGeneration statechartGenerator = null;
		SimpleScenarioGenerator simpleGenerator = null;
		ScenarioContentSorter sorter = new ScenarioContentSorter();
		sorter.sort(baseScenario);
		ContractAutomatonType type = statechartGeneration.getAutomatonType();
		if (type.equals(ContractAutomatonType.MONITOR)) {
			simpleGenerator = new SimpleScenarioGenerator(baseScenario, true, statechartGeneration.getArguments());
			ScenarioDeclaration simplifiedScenario = simpleGenerator.execute();
			statechartGenerator = new MonitorStatechartGenerator(simplifiedScenario, component,
					statechartGeneration.isStartAsColdViolation());
		} else {
			simpleGenerator = new SimpleScenarioGenerator(baseScenario, false, statechartGeneration.getArguments());
			ScenarioDeclaration simplifiedScenario = simpleGenerator.execute();
			statechartGenerator = new TestGeneratorStatechartGenerator(simplifiedScenario, component, generationMode,
					!statechartGeneration.isStartAsColdViolation());
		}
		StatechartDefinition statechart = statechartGenerator.execute();
		if (type.equals(ContractAutomatonType.MONITOR)) {
			AutomatonDeterminizator determinizator = new AutomatonDeterminizator(statechart);
			statechart = determinizator.execute();
		}
		if (GenmodelDerivedFeatures.isNegativeContractGeneration(statechartGeneration)) {
			statechart.getAnnotations().add(contractFactory.createNegativeContractStatechartAnnotation());
		}
		Package packageOfComponent = ecoreUtil.getContainerOfType(component, Package.class);
		StatechartSerializer statechartSerializer = new StatechartSerializer(file);
		statechartSerializer.saveStatechart(statechart, packageOfComponent.getImports(), targetFolderUri);
	}
}