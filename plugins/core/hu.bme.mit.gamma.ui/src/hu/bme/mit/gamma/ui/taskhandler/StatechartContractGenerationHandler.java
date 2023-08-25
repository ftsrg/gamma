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

import static com.google.common.base.Preconditions.checkArgument;

import java.util.List;
import java.util.Set;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.expression.model.Expression;
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
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
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
		setFileName(statechartGeneration);
		
		ScenarioDeclaration baseScenario = statechartGeneration.getScenario();
		ScenarioPackage containingScenarioPackage = ecoreUtil.getContainerOfType(
				baseScenario, ScenarioPackage.class);
		Component component = containingScenarioPackage.getComponent();
		StatechartGenerationMode generationMode = statechartGeneration.isUseIteratingVariable() ?
				StatechartGenerationMode.GENERATE_ORIGINAL_STRUCTURE :
				StatechartGenerationMode.GENERATE_ONLY_FORWARD;
		AbstractContractStatechartGeneration statechartGenerator = null;
		SimpleScenarioGenerator simpleGenerator = null;
		ScenarioContentSorter sorter = new ScenarioContentSorter();
		sorter.sort(baseScenario);
		
		
		ContractAutomatonType type = statechartGeneration.getAutomatonType();
		List<Expression> arguments = statechartGeneration.getArguments();
		if (type.equals(ContractAutomatonType.MONITOR)) {
			simpleGenerator = new SimpleScenarioGenerator(baseScenario, true, arguments);
			ScenarioDeclaration simplifiedScenario = simpleGenerator.execute();
			statechartGenerator = new MonitorStatechartGenerator(simplifiedScenario, component,
					statechartGeneration.isStartAsColdViolation(), statechartGeneration.isRestartOnAccept());
		} else {
			simpleGenerator = new SimpleScenarioGenerator(baseScenario, false, arguments);
			ScenarioDeclaration simplifiedScenario = simpleGenerator.execute();
			statechartGenerator = new TestGeneratorStatechartGenerator(simplifiedScenario,
					component, generationMode, !statechartGeneration.isStartAsColdViolation(),
					GenmodelDerivedFeatures.isNegativeContractGeneration(statechartGeneration));
		}
		StatechartDefinition statechart = statechartGenerator.execute();
		String name = statechartGeneration.getFileName().get(0);
		statechart.setName(name);
		
		if (type.equals(ContractAutomatonType.MONITOR)) {
			AutomatonDeterminizator determinizator = new AutomatonDeterminizator(statechart);
			statechart = determinizator.execute();
		}
		if (GenmodelDerivedFeatures.isNegativeContractGeneration(statechartGeneration)) {
			statechart.getAnnotations().add(
					contractFactory.createNegativeContractStatechartAnnotation());
		}
		
		StatechartSerializer statechartSerializer = new StatechartSerializer(file);
		Set<Package> imports = StatechartModelDerivedFeatures.getImportablePackages(statechart);// packageOfComponent.getImports();
		statechartSerializer.saveStatechart(statechart, imports, targetFolderUri);
	}
	
	private void setFileName(StatechartContractGeneration task) {
		List<String> fileName = task.getFileName();
		checkArgument(fileName.size() <= 1);
		if (fileName.isEmpty()) {
			fileName.add(
					task.getScenario().getName());
		}
	}
	
}