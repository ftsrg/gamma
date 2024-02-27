/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
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
import java.util.List;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint;
import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.genmodel.model.TraceReplayModelGeneration;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory;
import hu.bme.mit.gamma.statechart.interface_.TimeSpecification;
import hu.bme.mit.gamma.statechart.interface_.TimeUnit;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures;
import hu.bme.mit.gamma.trace.environment.transformation.EnvironmentModel;
import hu.bme.mit.gamma.trace.environment.transformation.TraceReplayModelGenerator;
import hu.bme.mit.gamma.trace.environment.transformation.TraceReplayModelGenerator.Result;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;

public class TraceReplayModelGenerationHandler extends TaskHandler {
	//
	protected final InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE;
	//
	
	public TraceReplayModelGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(TraceReplayModelGeneration modelGeneration) throws IOException, InterruptedException {
		// Setting target folder
		setTargetFolder(modelGeneration);
		//
		setTraceReplayModelGeneration(modelGeneration);
		// TODO multiple traces
		ExecutionTrace executionTrace = modelGeneration.getExecutionTrace();
		List<String> fileName = modelGeneration.getFileName();
		List<String> environmentModelFileName = modelGeneration.getEnvironmentModelFileName();
		checkArgument(fileName.size() == 1 && environmentModelFileName.size() == 1 && executionTrace != null);
		String systemName = fileName.get(0);
		String environmentModelName = environmentModelFileName.get(0); // Set in setTraceReplayModelGeneration
		EnvironmentModel environmentModelSetting = transformEnvironmentModel(modelGeneration.getEnvironmentModel());
		
		boolean considerOutEvents = modelGeneration.isConsiderOutEvents();
		TraceReplayModelGenerator modelGenerator = new TraceReplayModelGenerator(executionTrace,
				systemName, environmentModelName, environmentModelSetting, considerOutEvents);
		Result result = modelGenerator.execute();
		ComponentInstance environmentInstance = result.getEnvironmentModelIntance();
		Component environmentModel = StatechartModelDerivedFeatures.getDerivedType(environmentInstance);
		State lastState = result.getLastState();
		Component systemModel = result.getSystemModel();
		
		PropertyPackage propertyPackage = propertyUtil.createAtomicInstanceStateReachabilityProperty(
				systemModel, environmentInstance, lastState);
		
		// Serialization
		serializer.saveModel(ecoreUtil.getRoot(environmentModel), targetFolderUri, environmentModelName + ".gcd");
		serializer.saveModel(ecoreUtil.getRoot(systemModel), targetFolderUri, systemName + ".gcd");
		serializer.saveModel(ecoreUtil.getRoot(propertyPackage), targetFolderUri, systemName + ".gpd");
		
		// If we want to execute it right away...
		// Make sure that the ExecutionTrace is back-annotated to original!
		Expression schedulingTime = TraceModelDerivedFeatures.getSchedulingTime(executionTrace);
		
		List<AnalysisLanguage> analysisLanguages = modelGeneration.getAnalysisLanguages();
		for (AnalysisLanguage language : analysisLanguages) {
			String analysisFileName = fileName.get(0) + "-" + language.toString();
			
			AnalysisModelTransformation transformation = factory.createAnalysisModelTransformation();
			ComponentReference componentReference = factory.createComponentReference();
			componentReference.setComponent(systemModel);
			
			transformation.setModel(componentReference);
			transformation.setPropertyPackage(propertyPackage);
			
			transformation.getLanguages().add(language);
			
			transformation.getFileName().add(analysisFileName);
			transformation.getTargetFolder().addAll(modelGeneration.getTargetFolder());
			
			if (schedulingTime != null) {
				OrchestratingConstraint constraint = factory.createOrchestratingConstraint();
				transformation.setConstraint(constraint);
				
				TimeSpecification min = interfaceFactory.createTimeSpecification();
				min.setValue(
						ecoreUtil.clone(schedulingTime));
				min.setUnit(TimeUnit.MILLISECOND);
				TimeSpecification max = ecoreUtil.clone(min);
				constraint.setMinimumPeriod(min);
				constraint.setMaximumPeriod(max);
			}
			
			AnalysisModelTransformationAndVerificationHandler handler = new
					AnalysisModelTransformationAndVerificationHandler(file, true, false, true, ProgrammingLanguage.JAVA);
			handler.execute(transformation);
			
			// TODO Check trace-conformance right here?
		}
	}

	private void setTraceReplayModelGeneration(TraceReplayModelGeneration modelGeneration) {
		List<String> environmentModelFileName = modelGeneration.getEnvironmentModelFileName();
		if (environmentModelFileName.isEmpty()) {
			ExecutionTrace executionTrace = modelGeneration.getExecutionTrace();
			environmentModelFileName.add(
					executionTrace.getName());
		}
	}
	
	private EnvironmentModel transformEnvironmentModel(hu.bme.mit.gamma.genmodel.model.EnvironmentModel environmentModel) {
		switch (environmentModel) {
			case OFF:
				return EnvironmentModel.OFF;
			case SYNCHRONOUS:
				return EnvironmentModel.SYNCHRONOUS;
			case ASYNCHRONOUS:
				return EnvironmentModel.ASYNCHRONOUS;
			default:
				throw new IllegalArgumentException("Not known literal: " + environmentModel);
		}
	}
	
}
