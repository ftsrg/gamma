/********************************************************************************
 * Copyright (c) 2018-2026 Contributors to the Gamma project
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
import hu.bme.mit.gamma.expression.model.NamedElement;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.AnalysisTask;
import hu.bme.mit.gamma.genmodel.model.CompletenessCoverage;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.Coverage;
import hu.bme.mit.gamma.genmodel.model.DataflowCoverage;
import hu.bme.mit.gamma.genmodel.model.DeadlockCoverage;
import hu.bme.mit.gamma.genmodel.model.GenModel;
import hu.bme.mit.gamma.genmodel.model.InteractionCoverage;
import hu.bme.mit.gamma.genmodel.model.InteractionDataflowCoverage;
import hu.bme.mit.gamma.genmodel.model.ModelReference;
import hu.bme.mit.gamma.genmodel.model.StatechartContractGeneration;
import hu.bme.mit.gamma.genmodel.model.Task;
import hu.bme.mit.gamma.genmodel.model.TestAutomatonType;
import hu.bme.mit.gamma.genmodel.model.TransitionCoverage;
import hu.bme.mit.gamma.genmodel.model.TransitionPairCoverage;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.genmodel.model.XstsReference;
import hu.bme.mit.gamma.scenario.model.ScenarioDeclaration;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;

public class GenmodelDerivedFeatures extends ExpressionModelDerivedFeatures {

	public static List<ParameterDeclaration> getParameterDeclarations(ArgumentedElement element) {
		if (element instanceof ComponentReference componentReference) {
			Component component = componentReference.getComponent();
			return component.getParameterDeclarations();
		}
		if (element instanceof StatechartContractGeneration statechartContractGeneration) {
			ScenarioDeclaration scenarioDeclaration = statechartContractGeneration.getScenario();
			return scenarioDeclaration.getParameterDeclarations();
		}
		throw new IllegalArgumentException("Not supported element: " + element);
	}
	
	public static List<Task> getIncludedTasks(GenModel genmodel) {
		List<Task> tasks = getAllTasks(genmodel);
		tasks.removeAll(
				genmodel.getTasks());
		return tasks;
	}

	public static List<Task> getAllTasks(GenModel genmodel) {
		List<Task> tasks = new ArrayList<Task>(genmodel.getTasks());
		for (GenModel includedGenmodel : genmodel.getGenmodelImports()) {
			tasks.addAll(
					getAllTasks(includedGenmodel));
		}
		return tasks;
	}

	public static NamedElement getModel(AnalysisModelTransformation analysisModelTransformation) {
		ModelReference modelReference = analysisModelTransformation.getModel();
		return getModel(modelReference);
	}

	public static NamedElement getModel(ModelReference modelReference) {
		if (modelReference instanceof ComponentReference componentReference) {
			return componentReference.getComponent();
		}
		if (modelReference instanceof XstsReference xStsReference) {
			return xStsReference.getXSts();
		}
		throw new IllegalArgumentException("Not supported model reference: " + modelReference);
	}
	
	public static Component getComponent(AnalysisModelTransformation analysisModelTransformation) {
		EObject model = getModel(analysisModelTransformation);
		return (Component) model;
	}
	
	public static Package getPackage(AnalysisModelTransformation analysisModelTransformation) {
		Component component = getComponent(analysisModelTransformation);
		return StatechartModelDerivedFeatures.getContainingPackage(component);
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
	
	public static AnalysisLanguage getAnalysisLanguage(String name) {
		switch (name.toUpperCase()) {
			case "UPPAAL": {
				return AnalysisLanguage.UPPAAL;
			}
			case "XSTS_UPPAAL":
			case "XTA": {
				return AnalysisLanguage.XSTS_UPPAAL;
			}
			case "THETA":
			case "XSTS": {
				return AnalysisLanguage.THETA;
			}
			case "SPIN":
			case "PROMELA": {
				return AnalysisLanguage.PROMELA;
			}
			case "SMV":
			case "NUXMV": {
				return AnalysisLanguage.NUXMV;
			}
			case "OCRA":
			case "OSS":
			case "OTHELLO": {
				return AnalysisLanguage.OCRA;
			}
			case "IMANDRA":
			case "IML": {
				return AnalysisLanguage.IML;
			}
			default:
				throw new IllegalArgumentException("Not known language: " + name);
		}
	}
	
	public static AnalysisLanguage getXstsBasedAnalysisLanguage(String name) {
		AnalysisLanguage analysisLanguage = getAnalysisLanguage(name);
		if (analysisLanguage == AnalysisLanguage.UPPAAL) {
			return AnalysisLanguage.XSTS_UPPAAL;
		}
		return analysisLanguage;
	}
	
	public static boolean benefitsFromModelOptimization(Coverage coverage) {
		return coverage instanceof DataflowCoverage ||
				coverage instanceof TransitionCoverage ||
				coverage instanceof TransitionPairCoverage ||
				coverage instanceof InteractionCoverage ||
				coverage instanceof InteractionDataflowCoverage ||
				coverage instanceof DeadlockCoverage ||
				coverage instanceof CompletenessCoverage;
	}
	
}