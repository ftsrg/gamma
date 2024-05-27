/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.genmodel.derivedfeatures;

import java.util.ArrayList;
import java.util.List;

import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.AnalysisTask;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.GenModel;
import hu.bme.mit.gamma.genmodel.model.ModelReference;
import hu.bme.mit.gamma.genmodel.model.StatechartContractGeneration;
import hu.bme.mit.gamma.genmodel.model.Task;
import hu.bme.mit.gamma.genmodel.model.TestAutomatonType;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.genmodel.model.XstsReference;
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration;
import hu.bme.mit.gamma.statechart.interface_.Component;

public class GenmodelDerivedFeatures extends ExpressionModelDerivedFeatures {

	public static List<ParameterDeclaration> getParameterDeclarations(ArgumentedElement element) {
		if (element instanceof ComponentReference) {
			ComponentReference componentReference = (ComponentReference) element;
			Component component = componentReference.getComponent();
			return component.getParameterDeclarations();
		}
		if (element instanceof StatechartContractGeneration) {
			StatechartContractGeneration statechartContractGeneration = (StatechartContractGeneration) element;
			ScenarioDeclaration scenarioDeclaration = statechartContractGeneration.getScenario();
			return scenarioDeclaration.getParameterDeclarations();
		}
		throw new IllegalArgumentException("Not supported element: " + element);
	}
	
	public static List<Task> getIncludedTasks(GenModel genmodel) {
		List<Task> tasks = getAllTasks(genmodel);
		tasks.removeAll(genmodel.getTasks());
		return tasks;
	}

	public static List<Task> getAllTasks(GenModel genmodel) {
		List<Task> tasks = new ArrayList<Task>(genmodel.getTasks());
		for (GenModel includedGenmodel : genmodel.getGenmodelImports()) {
			tasks.addAll(getAllTasks(includedGenmodel));
		}
		return tasks;
	}

	public static EObject getModel(AnalysisModelTransformation analysisModelTransformation) {
		ModelReference modelReference = analysisModelTransformation.getModel();
		return getModel(modelReference);
	}

	public static EObject getModel(ModelReference modelReference) {
		if (modelReference instanceof ComponentReference) {
			ComponentReference componentReference = (ComponentReference) modelReference;
			return componentReference.getComponent();
		}
		if (modelReference instanceof XstsReference) {
			XstsReference xStsReference = (XstsReference) modelReference;
			return xStsReference.getXSts();
		}
		throw new IllegalArgumentException("Not supported model reference: " + modelReference);
	}

	public static boolean isVerifyAnalysisTask(AnalysisModelTransformation analysisModelTransformation) {
		return analysisModelTransformation.getTask() == AnalysisTask.TRANSFORMATION_AND_VERIFICATION;
	}
	
	public static boolean isOptimizableVerificationTask(Verification verification) {
		return verification.isOptimizeModel();
	}
	
	public static boolean isNegativeContractGeneration(StatechartContractGeneration statechartGeneration) {
		return statechartGeneration.getTestType() == TestAutomatonType.NEGATIVE;
	}
	
}
