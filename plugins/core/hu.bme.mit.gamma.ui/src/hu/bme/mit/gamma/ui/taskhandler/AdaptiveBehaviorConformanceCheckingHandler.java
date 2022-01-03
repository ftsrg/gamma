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

import java.io.File;
import java.io.IOException;
import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.stream.Collectors;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.AdaptiveBehaviorConformanceChecking;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.property.model.ComponentInstanceStateConfigurationReference;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.property.util.PropertyUtil;
import hu.bme.mit.gamma.scenario.statechart.util.ScenarioStatechartUtil;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.Channel;
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.contract.StateContractAnnotation;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateAnnotation;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateDefinition;
import hu.bme.mit.gamma.statechart.phase.transformation.PhaseStatechartTransformer;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StateAnnotation;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;

public class AdaptiveBehaviorConformanceCheckingHandler extends TaskHandler {
	
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	protected final ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE;
	protected final PropertyUtil propertyUtil = PropertyUtil.INSTANCE;
	
	protected final CompositeModelFactory factory = CompositeModelFactory.eINSTANCE;
	
	public AdaptiveBehaviorConformanceCheckingHandler(IFile file) {
		super(file);
	}
	
	public void execute(AdaptiveBehaviorConformanceChecking conformanceChecker) throws IOException {
		// Setting target folder
		setTargetFolder(conformanceChecker);
		//
		setAdaptiveBehaviorConformanceChecker(conformanceChecker);
		
		AnalysisModelTransformation modelTransformation = conformanceChecker.getModelTransformation();
		
		ComponentReference modelReference = (ComponentReference) modelTransformation.getModel();
		Component adaptiveComponent = modelReference.getComponent();
		// restart-on-cold-violation
		// back-transitions are on
		// permissive or strict
		StatechartDefinition adaptiveStatechart = (StatechartDefinition) adaptiveComponent;
		
		// Collecting contract-behavior mappings
		// History-based and no-history mappings have to be distinguished
		boolean hasHistory = false;
		
		Map<StatechartDefinition, List<MissionPhaseStateDefinition>> contractBehaviors = 
				new HashMap<StatechartDefinition, List<MissionPhaseStateDefinition>>(); 
		Collection<State> adaptiveStates = StatechartModelDerivedFeatures.getAllStates(adaptiveStatechart);
		for (State adaptiveState : adaptiveStates) {
			List<StateAnnotation> annotations = adaptiveState.getAnnotations();
			List<StateContractAnnotation> stateContractAnnotations =
					javaUtil.filterIntoList(annotations, StateContractAnnotation.class);
			List<MissionPhaseStateAnnotation> missionPhaseStateAnnotations =
					javaUtil.filterIntoList(annotations, MissionPhaseStateAnnotation.class);
			
			for (StateContractAnnotation stateContractAnnotation : stateContractAnnotations) {
				// Statechart contract - cold violation must lead to initial state
				for (StatechartDefinition contract : stateContractAnnotation.getContractStatecharts()) {
					// Java util - add contract - list
					List<MissionPhaseStateDefinition> behaviors = javaUtil.getOrCreateList(
							contractBehaviors, contract);
					for (MissionPhaseStateAnnotation phaseAnnotation : missionPhaseStateAnnotations) {
						for (MissionPhaseStateDefinition stateDefinition :
								List.copyOf(phaseAnnotation.getStateDefinitions())) {
							if (!StatechartModelDerivedFeatures.hasHistory(stateDefinition)) {
														
								behaviors.add(stateDefinition); // Maybe this should be cloned to prevent overwriting
								
								// No history: contract - behavior equivalence can be analyzed
								// independently of the context -> removing from adaptive statechart
								ecoreUtil.remove(stateDefinition);
							}
							else {
								hasHistory = true;
								checkArgument(StatechartModelDerivedFeatures.isMissionPhase(
										stateDefinition.getComponent().getType()));
							}
						}
					}
				}
			}
			
			// If there is no MissionPhaseStateDefinition, the state contracts can be removed
			for (MissionPhaseStateAnnotation phaseAnnotation :
						List.copyOf(missionPhaseStateAnnotations)) {
				if (phaseAnnotation.getStateDefinitions().isEmpty()) {
					missionPhaseStateAnnotations.remove(phaseAnnotation);
					ecoreUtil.remove(phaseAnnotation);
				}
			}
			if (missionPhaseStateAnnotations.isEmpty()) {
				for (StateContractAnnotation stateContractAnnotation : stateContractAnnotations) {
					ecoreUtil.remove(stateContractAnnotation);
				}
			}
			
		}
		
		// Processing historyless associations
		List<Entry<String, PropertyPackage>> historylessModelFileUris =
				new ArrayList<Entry<String, PropertyPackage>>();
		
		for (StatechartDefinition contract : contractBehaviors.keySet()) {
			List<MissionPhaseStateDefinition> behaviors = contractBehaviors.get(contract);
			if (!behaviors.isEmpty()) {
				String name = contract.getName() + "_" + behaviors.stream()
					.map(it -> it.getComponent().getName()).reduce("", (a,  b) -> a + "_" + b);
				
				CascadeCompositeComponent cascade = factory.createCascadeCompositeComponent();
				cascade.setName(name);
				
				Package statelessAssocationPackage = statechartUtil.wrapIntoPackage(cascade);
				
				List<PortBinding> portBindings = javaUtil.flattenIntoList(
						behaviors.stream().map(it -> it.getPortBindings())
						.collect(Collectors.toList()));
				Collection<Port> systemPorts = adaptiveStatechart.getPorts();
				for (Port systemPort : systemPorts) {
					Port clonedSystemPort = ecoreUtil.clone(systemPort);
					cascade.getPorts().add(clonedSystemPort);
					ecoreUtil.change(clonedSystemPort, systemPort, behaviors);
				}
				
				cascade.getPortBindings().addAll(portBindings); // Could be cloned
				
				for (MissionPhaseStateDefinition behavior : behaviors) {
					SynchronousComponentInstance componentInstance = behavior.getComponent();
					cascade.getComponents().add(componentInstance);
					SynchronousComponent behaviorType = componentInstance.getType();
					// Supporting hierarchical mission phase statecharts
					if (StatechartModelDerivedFeatures.isMissionPhase(behaviorType)) {
						StatechartDefinition phaseStatechart = (StatechartDefinition) behaviorType;
						PhaseStatechartTransformer phaseStatechartTransformer =
								new PhaseStatechartTransformer(phaseStatechart);
						phaseStatechartTransformer.execute();
						// Same reference but reworked content: has to be saved and serialized
						statelessAssocationPackage.getComponents().add(phaseStatechart);
					}
				}
				
				// Inserting the monitor into the composition
				Entry<String, PropertyPackage> modelFileUri = insertMonitor(cascade, contract, name);
				historylessModelFileUris.add(modelFileUri);
			}
		}
		
		List<Entry<String, PropertyPackage>> historyModelFileUris =
				new ArrayList<Entry<String, PropertyPackage>>();
		
		// Processing original adaptive statechart if necessary
		if (hasHistory) {
			// Transforming (inlining) phases
			PhaseStatechartTransformer phaseStatechartTransformer =
					new PhaseStatechartTransformer(adaptiveStatechart);
			phaseStatechartTransformer.execute();
			Package missionPhasePackage = statechartUtil.wrapIntoPackage(adaptiveStatechart);
			String packageName = missionPhasePackage.getName();
			
			String targetFolderUri = this.getTargetFolderUri();
			String packageFileName = fileUtil.toHiddenFileName(fileNamer.getPackageFileName(packageName));
			this.serializer.saveModel(missionPhasePackage, targetFolderUri, packageFileName);
			
			for (StateContractAnnotation annotation :
					ecoreUtil.getAllContentsOfType(adaptiveStatechart, StateContractAnnotation.class)) {
				for (StatechartDefinition contract : annotation.getContractStatecharts()) {
					// Creating a composition
					CascadeCompositeComponent cascade = statechartUtil.wrapSynchronousComponent(adaptiveStatechart);
					statechartUtil.wrapIntoPackage(cascade);
					
					Entry<String, PropertyPackage> modelFileUri = insertMonitor(
							cascade, contract, adaptiveStatechart.getName());
					historyModelFileUris.add(modelFileUri);
				}
			}
		}
		
		// Executing the analysis model transformation on the created models
		
		AnalysisLanguage analysisLanguage = modelTransformation.getLanguages().get(0);
		
		List<Entry<String, PropertyPackage>> modelFileUris =
				new ArrayList<Entry<String, PropertyPackage>>();
		modelFileUris.addAll(historylessModelFileUris);
		modelFileUris.addAll(historyModelFileUris);
		
		List<Entry<String, PropertyPackage>> analyisModelFileUris =
				new ArrayList<Entry<String, PropertyPackage>>();
		
		for (Entry<String, PropertyPackage> modelFileUri : modelFileUris) {
			// Transformation
			AnalysisModelTransformationHandler handler = new AnalysisModelTransformationHandler(file);
			
			AnalysisModelTransformation conformanceModelTransformation =
					ecoreUtil.clone(modelTransformation);
			ComponentReference conformanceModelReference =
					(ComponentReference) conformanceModelTransformation.getModel();
			
			PropertyPackage propertyPackage = modelFileUri.getValue();
			Component component = propertyPackage.getComponent();
			conformanceModelReference.setComponent(component); // modelReference is contained by modelTransformation
			conformanceModelTransformation.setPropertyPackage(propertyPackage);
			
			handler.execute(conformanceModelTransformation);
			
			String plainFileName = conformanceModelTransformation.getFileName().get(0);
			String analysisModelFileName = handler.getFileName(plainFileName, analysisLanguage);
			String analyisModelFileUri = handler.getTargetFolderUri() + File.separator + analysisModelFileName;
			analyisModelFileUris.add(
					new SimpleEntry<String, PropertyPackage>(analyisModelFileUri, propertyPackage));
		}
		
		// Executing verification
		
		for (Entry<String, PropertyPackage> analyisModelFileUri : analyisModelFileUris) {
			String analyisModelFile = analyisModelFileUri.getKey();
			PropertyPackage propertyPackage = analyisModelFileUri.getValue();
			
			Verification verification = super.factory.createVerification();
			verification.getAnalysisLanguages().add(analysisLanguage);
			// No programming languages, we do not need temporary test classes
			verification.getFileName().add(analyisModelFile);
			verification.getPropertyPackages().add(propertyPackage);

			VerificationHandler verificationHandler = new VerificationHandler(file);
			verificationHandler.execute(verification);
		}
	}
	
	// Extraction

	private Entry<String, PropertyPackage> insertMonitor(CascadeCompositeComponent cascade,
			StatechartDefinition contract, String name) throws IOException {
		// Contract statechart
		
		SynchronousComponentInstance contractInstance =
				statechartUtil.instantiateSynchronousComponent(contract);
		String monitorName = contractInstance.getName() + "Monitor";
		contractInstance.setName(monitorName);
		cascade.getComponents().add(0, contractInstance); // Contract is executed first
		
		// Binding system ports
		for (Port systemPort : StatechartModelDerivedFeatures.getAllPorts(cascade)) {
			Port contractPort = matchPort(systemPort, contract);
			// Only for all input ports
			if (StatechartModelDerivedFeatures.isBroadcastMatcher(contractPort)) {
				PortBinding inputPortBinding = factory.createPortBinding();
				inputPortBinding.setCompositeSystemPort(systemPort);
				
				InstancePortReference instancePortReference = statechartUtil
						.createInstancePortReference(contractInstance, contractPort);
				inputPortBinding.setInstancePortReference(instancePortReference);
				
				cascade.getPortBindings().add(inputPortBinding);
			}
			// Only for output ports
			else if (StatechartModelDerivedFeatures.isBroadcast(contractPort)) {
				Collection<PortBinding> outputPortBindings =
						StatechartModelDerivedFeatures.getPortBindings(systemPort);
				
				Port reservedContractPort = matchReversedPort(contractPort, contract);
				
				// Channeling ports to definitions
				for (PortBinding outputPortBinding : outputPortBindings) {
					InstancePortReference contractPortReference = statechartUtil
							.createInstancePortReference(contractInstance, reservedContractPort);
					InstancePortReference behaviorPortReference = ecoreUtil
							.clone(outputPortBinding.getInstancePortReference());
					Channel channel = statechartUtil.createChannel(
							behaviorPortReference, contractPortReference);
					
					cascade.getChannels().add(channel);
				}
			}
			else {
				throw new IllegalArgumentException("Not broadcast port: " + contractPort);
			}
		}
		
		// TODO Setting environment model if necessary
		
		// Setting imports
		Package statelessAssocationPackage = StatechartModelDerivedFeatures.getContainingPackage(cascade);
		statelessAssocationPackage.getImports().addAll(
				StatechartModelDerivedFeatures.getImportablePackages(cascade));
		
		// Serialization
		String targetFolderUri = this.getTargetFolderUri();
		String packageFileName = fileUtil.toHiddenFileName(fileNamer.getPackageFileName(name));
		
		this.serializer.saveModel(statelessAssocationPackage, targetFolderUri, packageFileName);
		
		String modelFileUri = targetFolderUri + File.separator + packageFileName;
		
		// Saving the property
		State violationState = getViolationState(contract);
		ComponentInstanceStateConfigurationReference violationStateReference =
				propertyUtil.createStateReference(
						propertyUtil.createInstanceReference(contractInstance), violationState);
		StateFormula eFViolation = propertyUtil.createEF(
					propertyUtil.createAtomicFormula(violationStateReference));
		PropertyPackage violationPropertyPackage = propertyUtil.wrapFormula(cascade, eFViolation);
		String propertyFileName = fileNamer.getHiddenPropertyFileName(name);

		this.serializer.saveModel(violationPropertyPackage, targetFolderUri, propertyFileName);
		
		// Returning the artifacts to set the analysis model transformer
		return new SimpleEntry<String, PropertyPackage>(modelFileUri, violationPropertyPackage);
	}
	
	// Traceability
	
	private Port matchPort(Port matchablePort, Component component) {
		for (Port port : StatechartModelDerivedFeatures.getAllPorts(component)) {
			if (ecoreUtil.helperEquals(matchablePort, port)) {
				return port;
			}
		}
		throw new IllegalArgumentException("Not found bound port: " + matchablePort);
	}
	
	private Port matchReversedPort(Port matchablePort, Component component) {
		String name = scenarioStatechartUtil.getTurnedOutPortName(matchablePort);
		for (Port port : StatechartModelDerivedFeatures.getAllPorts(component)) {
			if (port.getName().equals(name)) {
				return port;
			}
		}
		throw new IllegalArgumentException("Not found reversed port: " + matchablePort);
	}
	
	private State getViolationState(StatechartDefinition contractStatechart) {
		String name = scenarioStatechartUtil.getHotViolation(); // TODO Change to contract violation
		for (State state : StatechartModelDerivedFeatures.getAllStates(contractStatechart)) {
			if (state.getName().equals(name)) {
				return state;
			}
		}
		throw new IllegalArgumentException("Not found violation state: " + contractStatechart);
	}
	
	// Settings

	private void setAdaptiveBehaviorConformanceChecker(AdaptiveBehaviorConformanceChecking conformanceChecker) {
		
	}

}
