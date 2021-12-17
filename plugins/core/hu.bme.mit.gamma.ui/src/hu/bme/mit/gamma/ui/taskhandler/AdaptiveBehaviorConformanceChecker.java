/********************************************************************************
 * Copyright (c) 2020-2021 Contributors to the Gamma project
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
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.AdaptiveContractTestGeneration;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.contract.StateContractAnnotation;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateAnnotation;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateDefinition;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StateAnnotation;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.util.JavaUtil;

public class AdaptiveBehaviorConformanceChecker extends TaskHandler {
	
	protected JavaUtil javaUtil = JavaUtil.INSTANCE;

	public AdaptiveBehaviorConformanceChecker(IFile file) {
		super(file);
	}
	
	public void execute(AdaptiveContractTestGeneration conformanceChecker) throws IOException {
		// Setting target folder
		setTargetFolder(conformanceChecker);
		//
		checkArgument(conformanceChecker.getProgrammingLanguages().size() == 1,
				"A single programming language must be specified: " + conformanceChecker.getProgrammingLanguages());
		checkArgument(conformanceChecker.getProgrammingLanguages().get(0) == ProgrammingLanguage.JAVA,
				"Currently only Java is supported");
		setAdaptiveBehaviorConformanceChecker(conformanceChecker);
		
		AnalysisModelTransformation modelTransformation = conformanceChecker.getModelTransformation();
		AnalysisLanguage analysisLanguage = modelTransformation.getLanguages().get(0);
		
		ComponentReference modelReference = (ComponentReference) modelTransformation.getModel();
		Component adaptiveComponent = modelReference.getComponent();
		StatechartDefinition adaptiveStatechart = (StatechartDefinition) adaptiveComponent;
		
		// Collecting contract-behavior mappings
		// History-based and no-history mappings have to be distinguished
		
		Map<StatechartDefinition, List<Component>> contractBehaviors = 
				new HashMap<StatechartDefinition, List<Component>>(); 
		Collection<State> adaptiveStates = StatechartModelDerivedFeatures.getAllStates(adaptiveStatechart);
		for (State adaptiveState : adaptiveStates) {
			List<StateAnnotation> annotations = adaptiveState.getAnnotations();
			List<StateContractAnnotation> stateContractAnnotations =
					javaUtil.filterIntoList(annotations, StateContractAnnotation.class);
			List<MissionPhaseStateAnnotation> missionPhaseStateAnnotations =
					javaUtil.filterIntoList(annotations, MissionPhaseStateAnnotation.class);
			
			for (StateContractAnnotation stateContractAnnotation : stateContractAnnotations) {
				for (StatechartDefinition contractStatechart :
						stateContractAnnotation.getContractStatecharts()) {
					// Java util - add contract - list
					List<Component> behaviors = javaUtil.getOrCreateList(
							contractBehaviors, contractStatechart);
					for (MissionPhaseStateAnnotation missionPhaseStateAnnotation : 
							missionPhaseStateAnnotations) {
						for (MissionPhaseStateDefinition stateDefinition :
								missionPhaseStateAnnotation.getStateDefinitions()) {
							SynchronousComponentInstance componentInstance = stateDefinition.getComponent();
						}
					}
				}
			}
		}
		
		// TODO - check that there are no empty lists
		
		
		// Executing the analysis model transformation on the created models
		AnalysisModelTransformationHandler handler = new AnalysisModelTransformationHandler(file);
		handler.execute(modelTransformation);
	}
	
	// Settings

	private void setAdaptiveBehaviorConformanceChecker(AdaptiveContractTestGeneration conformanceChecker) {
		
	}

}
