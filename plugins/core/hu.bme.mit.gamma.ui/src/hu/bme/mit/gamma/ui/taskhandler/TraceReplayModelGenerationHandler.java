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

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.OrchestratingConstraint;
import hu.bme.mit.gamma.genmodel.model.TraceReplayModelGeneration;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression;
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
import hu.bme.mit.gamma.trace.model.RaiseEventAct;
import hu.bme.mit.gamma.trace.model.Step;

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
		
		// Loading the traces
		List<ExecutionTrace> executionTraces = new ArrayList<>();
		for (String relativeTraceFolder : modelGeneration.getExecutionTraceFolder()) {
			File traceFolder = super.exporeRelativeFile(modelGeneration, relativeTraceFolder);
			List<File> allFiles = fileUtil.getAllContainedFiles(traceFolder);
			
			for (File traceFile : allFiles) {
				try {
					ExecutionTrace trace = (ExecutionTrace) ecoreUtil.normalLoad(traceFile);
					executionTraces.add(trace);
				} catch (RuntimeException e) {
					// Not actually an execution trace
				}
			}
		}
		ExecutionTrace trace = modelGeneration.getExecutionTrace();
		if (trace != null) {
			executionTraces.add(trace);
		}
		//
		
		int i = 0;
		for (ExecutionTrace executionTrace : executionTraces) {
			++i;
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
			EObject environmentModelPackage = ecoreUtil.getRoot(environmentModel);
			serializer.saveModel(environmentModelPackage, targetFolderUri, environmentModelName + ".gcd");
			EObject systemModelPackage = ecoreUtil.getRoot(systemModel);
			try {
				serializer.saveModel(systemModelPackage, targetFolderUri, systemName + ".gcd");
			} catch (RuntimeException e) { // Potentially models with the same ID
				serializer.saveModel(systemModelPackage, targetFolderUri, systemName + ".gsm");
			}
			serializer.saveModel(propertyPackage, targetFolderUri, systemName + ".gpd");
			
			//
			Collection<ExecutionTrace> generatedTraces = new ArrayList<ExecutionTrace>();
			
			// We execute the conformance checking right away...
			// Make sure that the ExecutionTrace is back-annotated to original!
			Expression schedulingTime = TraceModelDerivedFeatures.getSchedulingTime(executionTrace);
			
			List<Expression> arguments = executionTrace.getArguments();
			List<AnalysisLanguage> analysisLanguages = modelGeneration.getAnalysisLanguages();
			for (AnalysisLanguage language : analysisLanguages) {
				String analysisFileName = fileName.get(0) + "-" + language.toString() + "-" + i;
				
				AnalysisModelTransformation transformation = factory.createAnalysisModelTransformation();
				ComponentReference componentReference = factory.createComponentReference();
				componentReference.setComponent(systemModel);
				if (!arguments.isEmpty()) {
					componentReference.getArguments().addAll(
							ecoreUtil.clone(arguments));
				}
				
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
				
				boolean optimizeModel = false; // Due to the exact assert equivalence
				AnalysisModelTransformationAndVerificationHandler handler =
						new AnalysisModelTransformationAndVerificationHandler(file, optimizeModel,
								false, true, null);
				handler.execute(transformation);
				
				generatedTraces.addAll(
						handler.getTraces());
			}
			// Checking trace-conformance
			for (ExecutionTrace generatedTrace : generatedTraces) {
				// Removing environment instance
				for (var reference : TraceModelDerivedFeatures
						.getFirstComponentInstanceReferenceExpressions(generatedTrace)) {
					ComponentInstance componentInstance = reference.getComponentInstance();
					String instanceName = componentInstance.getName()+ "_"; // "_" to handle name extension for async statecharts
					String environmentName = environmentInstance.getName() + "_";
					if (instanceName.startsWith(environmentName)) {
						ecoreUtil.removeContainmentChainUntilType(reference, Step.class);
					}
				}
				//
				final boolean ignoreOutEvents = false;
				if (ignoreOutEvents) {
					removeAsserts(executionTrace, RaiseEventAct.class);
					removeAsserts(generatedTrace, RaiseEventAct.class);
				}
				//
				final boolean ignoreStateReferences = false;
				if (ignoreStateReferences) {
					removeAsserts(executionTrace, ComponentInstanceStateReferenceExpression.class);
					removeAsserts(generatedTrace, ComponentInstanceStateReferenceExpression.class);
				}
				//
				boolean areAssertsEquivalent = TraceModelDerivedFeatures.areAssertsEquivalent(
						executionTrace, generatedTrace, false /* Not back-annotated to original */, false /* To counter flattened vs. original deviances */);
				if (!areAssertsEquivalent) {
					logger.warning("A generated trace is not equivalent");
//					throw new IllegalStateException("A generated trace is not equivalent");
				}
			}
		}
	}
	
	//
	
	private void setTraceReplayModelGeneration(TraceReplayModelGeneration modelGeneration) {
		List<String> environmentModelFileName = modelGeneration.getEnvironmentModelFileName();
		if (environmentModelFileName.isEmpty()) {
			ExecutionTrace executionTrace = modelGeneration.getExecutionTrace();
			String name = (executionTrace != null) ? executionTrace.getName() : "Environment";
			environmentModelFileName.add(name);
		}
	}
	
	private void removeAsserts(ExecutionTrace trace, Class<? extends EObject> clazz) {
		List<Step> steps = trace.getSteps();
		for (Step step : steps) {
			List<Expression> asserts = step.getAsserts();
			asserts.removeIf(it -> ecoreUtil.isOrContainsTypesTransitively(it, clazz));
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
