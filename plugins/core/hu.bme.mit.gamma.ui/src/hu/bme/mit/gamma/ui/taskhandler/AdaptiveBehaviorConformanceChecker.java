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
import java.util.stream.Collectors;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.AdaptiveContractTestGeneration;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.statechart.composite.CascadeCompositeComponent;
import hu.bme.mit.gamma.statechart.composite.Channel;
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.contract.StateContractAnnotation;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateAnnotation;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateDefinition;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StateAnnotation;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;

public class AdaptiveBehaviorConformanceChecker extends TaskHandler {
	
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	protected final CompositeModelFactory factory = CompositeModelFactory.eINSTANCE;
	protected final InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE;
	
	public AdaptiveBehaviorConformanceChecker(IFile file) {
		super(file);
	}
	
	public void execute(AdaptiveContractTestGeneration conformanceChecker) throws IOException {
		// Setting target folder
		setTargetFolder(conformanceChecker);
		//
		checkArgument(conformanceChecker.getProgrammingLanguages().size() == 1,
				"A single programming language must be specified: " +
						conformanceChecker.getProgrammingLanguages());
		checkArgument(conformanceChecker.getProgrammingLanguages().get(0) == ProgrammingLanguage.JAVA,
				"Currently only Java is supported");
		setAdaptiveBehaviorConformanceChecker(conformanceChecker);
		
		AnalysisModelTransformation modelTransformation = conformanceChecker.getModelTransformation();
		
		ComponentReference modelReference = (ComponentReference) modelTransformation.getModel();
		Component adaptiveComponent = modelReference.getComponent();
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
								phaseAnnotation.getStateDefinitions()) {
							if (!StatechartModelDerivedFeatures.hasHistory(stateDefinition)) {
														
								behaviors.add(stateDefinition); // Maybe this should be cloned to prevent overwriting
								
								// No history: contract - behavior equivalence can be analyzed
								// independently of the context -> removing from adaptive statechart
								ecoreUtil.remove(stateDefinition);
							}
							else {
								hasHistory = true;
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
				for (StateContractAnnotation stateContractAnnotation :
						List.copyOf(stateContractAnnotations)) {
					ecoreUtil.remove(stateContractAnnotation);
				}
				stateContractAnnotations.clear();
			}
			
		}
		
		// Processing historyless associations
		
		for (StatechartDefinition contract : contractBehaviors.keySet()) {
			List<MissionPhaseStateDefinition> behaviors = contractBehaviors.get(contract);
			// We expect: a mission phase statechart cannot contain other mission phase statecharts
			if (!behaviors.isEmpty()) {
				CascadeCompositeComponent cascade = factory.createCascadeCompositeComponent();
				cascade.setName("_");
				
				// We expect: all component ports are bound:
				// mission phase components do not introduce new ones
				List<PortBinding> portBindings = javaUtil.flattenIntoList(
						behaviors.stream().map(it -> it.getPortBindings())
						.collect(Collectors.toList()));
				Collection<Port> systemPorts = portBindings.stream()
						.map(it -> it.getCompositeSystemPort()).collect(Collectors.toSet());
				for (Port systemPort : systemPorts) {
					Port clonedSystemPort = ecoreUtil.clone(systemPort);
					cascade.getPorts().add(clonedSystemPort);
					ecoreUtil.change(clonedSystemPort, systemPort, behaviors);
				}
				
				cascade.getPortBindings().addAll(portBindings);
				
				for (MissionPhaseStateDefinition behavior : behaviors) {
					SynchronousComponentInstance componentInstance = behavior.getComponent();
					cascade.getComponents().add(componentInstance);
				}
				
				// Contract statechart
				
				SynchronousComponentInstance contractInstance =
						statechartUtil.instantiateSynchronousComponent(contract);
				
				// Binding system input ports
				
				for (Port systemPort : StatechartModelDerivedFeatures.getAllPorts(cascade)) {
					Port contractPort = matchPort(systemPort, cascade);
					// Only for all input ports
					if (StatechartModelDerivedFeatures.isBroadcastMatcher(contractPort)) {
						PortBinding portBinding = factory.createPortBinding();
						portBinding.setCompositeSystemPort(systemPort);
						
						InstancePortReference instancePortReference = statechartUtil
								.createInstancePortReference(contractInstance, contractPort);
						
						portBinding.setInstancePortReference(instancePortReference);
					}
					// Only for output ports
					if (StatechartModelDerivedFeatures.isBroadcastMatcher(contractPort)) {
						Collection<PortBinding> outputPortBindings =
								StatechartModelDerivedFeatures.getPortBindings(systemPort);
						// Channeling ports to definitions
						for (PortBinding outputPortBinding : outputPortBindings) {
							InstancePortReference contractPortReference = statechartUtil
									.createInstancePortReference(contractInstance, contractPort);
							InstancePortReference behaviorPortReference = ecoreUtil
									.clone(outputPortBinding.getInstancePortReference());
							Channel channel = statechartUtil.createChannel(
									behaviorPortReference, List.of(contractPortReference));
							
							cascade.getChannels().add(channel);
						}
					}
					else {
						throw new IllegalArgumentException("Not broadcast port: " + contractPort);
					}
				}
				
				// Wrapping into a package
				Package statelessAssocationPackage = interfaceFactory.createPackage();
				statelessAssocationPackage.setName("__");
				
				statelessAssocationPackage.getImports().addAll(
						StatechartModelDerivedFeatures.getImportableInterfacePackages(cascade));
				statelessAssocationPackage.getImports().addAll(
						StatechartModelDerivedFeatures.getImportableComponentPackages(cascade));
				
				// Serialization
				
				// Saving the file to set he analysis model transformer
			}
		}
		
		// Processing original adaptive statechart if necessary
		if (hasHistory) {
			
		}
		
		// Executing the analysis model transformation on the created models
		AnalysisModelTransformationHandler handler = new AnalysisModelTransformationHandler(file);
		handler.execute(modelTransformation);
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
	
	// Settings

	private void setAdaptiveBehaviorConformanceChecker(AdaptiveContractTestGeneration conformanceChecker) {
		
	}

}
