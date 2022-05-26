/********************************************************************************
 * Copyright (c) 2020-2022 Contributors to the Gamma project
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
import static hu.bme.mit.gamma.ui.taskhandler.Namings.getActivityPortName;
import static hu.bme.mit.gamma.ui.taskhandler.Namings.getCompositeComponentName;
import static hu.bme.mit.gamma.ui.taskhandler.Namings.getExtendedContractName;
import static hu.bme.mit.gamma.ui.taskhandler.Namings.getMonitorName;
import static hu.bme.mit.gamma.ui.taskhandler.Namings.getPhaseComponentName;

import java.io.File;
import java.io.IOException;
import java.util.AbstractMap.SimpleEntry;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;
import java.util.logging.Level;
import java.util.stream.Collectors;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory;
import hu.bme.mit.gamma.genmodel.model.AdaptiveBehaviorConformanceChecking;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.property.util.PropertyUtil;
import hu.bme.mit.gamma.scenario.statechart.util.ScenarioStatechartUtil;
import hu.bme.mit.gamma.statechart.composite.Channel;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceStateReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
import hu.bme.mit.gamma.statechart.composite.SchedulableCompositeComponent;
import hu.bme.mit.gamma.statechart.contract.StateContractAnnotation;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.RealizationMode;
import hu.bme.mit.gamma.statechart.phase.MissionPhaseStateAnnotation;
import hu.bme.mit.gamma.statechart.phase.transformation.PhaseStatechartTransformer;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.Region;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.statechart.statechart.StateAnnotation;
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition;
import hu.bme.mit.gamma.statechart.statechart.Transition;
import hu.bme.mit.gamma.statechart.util.ExpressionSerializer;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;
import hu.bme.mit.gamma.transformation.util.ComponentDeactivator;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.util.JavaUtil;
import hu.bme.mit.gamma.util.Triple;

public class AdaptiveBehaviorConformanceCheckingHandler extends TaskHandler {
	
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	protected final ElementTracer elementTracer = ElementTracer.INSTANCE;
	protected final PropertyUtil propertyUtil = PropertyUtil.INSTANCE;
	
	protected final CompositeModelFactory factory = CompositeModelFactory.eINSTANCE;
	protected final InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE;
	protected final ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE;
	
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
		// initial-blocks, restart-on-cold-violation, back-transitions are on, permissive or strict
		StatechartDefinition adaptiveStatechart = (StatechartDefinition) adaptiveComponent;
		
		// Collecting contract-behavior mappings
		// History-based and no-history mappings have to be distinguished
		boolean hasContextDependency = false;
		
		Map<StateContractAnnotation, List<MissionPhaseStateAnnotation>> contractBehaviors = 
				new HashMap<StateContractAnnotation, List<MissionPhaseStateAnnotation>>(); 
		Collection<State> adaptiveStates = StatechartModelDerivedFeatures
				.getAllStates(adaptiveStatechart);
		for (State adaptiveState : adaptiveStates) {
			List<State> ancestorsAndSelfAdaptiveStates =
					StatechartModelDerivedFeatures.getAncestorsAndSelf(adaptiveState);
			// Super state handling
			boolean hasOrthogonalRegions = false;
			List<StateAnnotation> annotations = new ArrayList<StateAnnotation>();
			for (State state : ancestorsAndSelfAdaptiveStates) {
				annotations.addAll(state.getAnnotations());
				//
				Region parentRegion = StatechartModelDerivedFeatures.getParentRegion(state);
				if (StatechartModelDerivedFeatures.isOrthogonal(parentRegion)) {
					hasOrthogonalRegions = true;
				}
			}
			
			List<StateContractAnnotation> stateContractAnnotations =
					javaUtil.filterIntoList(annotations, StateContractAnnotation.class);
			List<MissionPhaseStateAnnotation> missionPhaseStateAnnotations =
					javaUtil.filterIntoList(annotations, MissionPhaseStateAnnotation.class);
			
			for (StateContractAnnotation stateContractAnnotation : stateContractAnnotations) {
				// Java util - add contract - list
				List<MissionPhaseStateAnnotation> behaviors = javaUtil.getOrCreateList(
						contractBehaviors, stateContractAnnotation);
				for (MissionPhaseStateAnnotation phaseAnnotation :
							List.copyOf(missionPhaseStateAnnotations)) {
					if (!hasOrthogonalRegions && // Too strict check - simplifiable via port binding checks
							!StatechartModelDerivedFeatures.hasHistory(phaseAnnotation) &&
							!stateContractAnnotation.isSetToSelf()) {
						behaviors.add(phaseAnnotation); // Maybe cloning to prevent overwriting?
						
						// No history: contract - behavior equivalence can be analyzed
						// independently of the context -> removing from adaptive statechart
						ecoreUtil.remove(phaseAnnotation);
						missionPhaseStateAnnotations.remove(phaseAnnotation);
					}
					else {
						hasContextDependency = true;
						ComponentInstance component = phaseAnnotation.getComponent();
						Component type = StatechartModelDerivedFeatures.getDerivedType(component);
						checkArgument(StatechartModelDerivedFeatures.isStatechart(type) ||
								StatechartModelDerivedFeatures.isMissionPhase(type));
					}
				}
			}
			
			// If there is no MissionPhaseStateAnnotation, the "non-self" state contracts can be removed
			if (missionPhaseStateAnnotations.isEmpty()) {
				for (StateContractAnnotation stateContractAnnotation : stateContractAnnotations) {
					if (!stateContractAnnotation.isSetToSelf()) {
						ecoreUtil.remove(stateContractAnnotation);
					}
				}
			}
			
		}
		
		// Processing historyless associations
		List<Entry<String, PropertyPackage>> historylessModelFileUris =
				new ArrayList<Entry<String, PropertyPackage>>();
		
		for (StateContractAnnotation contractAnnotation : contractBehaviors.keySet()) {
			StatechartDefinition contract = contractAnnotation.getContractStatechart();
			List<Expression> contractArguments = contractAnnotation.getArguments();
			
			List<MissionPhaseStateAnnotation> clonedBehaviors = ecoreUtil.clone(
					contractBehaviors.get(contractAnnotation));
			if (!clonedBehaviors.isEmpty()) {
				SchedulableCompositeComponent composite =
					(StatechartModelDerivedFeatures.isSynchronous(contract)) ?
						factory.createCascadeCompositeComponent() :
							factory.createScheduledAsynchronousCompositeComponent();
				
				String name = getCompositeComponentName(contract, clonedBehaviors);
				composite.setName(name);
				
				Package statelessAssocationPackage = statechartUtil.wrapIntoPackage(composite);
				
				List<PortBinding> portBindings = javaUtil.flattenIntoList(
						clonedBehaviors.stream().map(it -> it.getPortBindings())
						.collect(Collectors.toList()));
				Collection<Port> systemPorts = adaptiveStatechart.getPorts();
				for (Port systemPort : systemPorts) {
					Port clonedSystemPort = ecoreUtil.clone(systemPort);
					composite.getPorts().add(clonedSystemPort);
					ecoreUtil.change(clonedSystemPort, systemPort, clonedBehaviors);
				}
				
				composite.getPortBindings().addAll(portBindings);
				
				for (MissionPhaseStateAnnotation behavior : clonedBehaviors) {
					ComponentInstance componentInstance = behavior.getComponent();
					statechartUtil.addComponentInstance(composite, componentInstance);
					Component behaviorType = StatechartModelDerivedFeatures.getDerivedType(componentInstance);
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
				
				// Scheduling the behaviors
				statechartUtil.scheduleInstances(composite,
						StatechartModelDerivedFeatures.getDerivedComponents(composite));
				// Inserting the monitor into the composition
				Triple<String, PropertyPackage, ComponentInstance> artifacts =
						insertMonitor(composite, contract, contractArguments, name);
				Entry<String, PropertyPackage> modelFileUri =
						new SimpleEntry<String, PropertyPackage>(
								artifacts.getFirst(), artifacts.getSecond());
				
				historylessModelFileUris.add(modelFileUri);
			}
		}
		
		List<Entry<String, PropertyPackage>> historyModelFileUris =
				new ArrayList<Entry<String, PropertyPackage>>();
		
		// Processing original adaptive statechart if necessary
		if (hasContextDependency) {
			String targetFolderUri = this.getTargetFolderUri();
			// Creating activity interface and event
			Interface activityInterface = ComponentDeactivator.getActivityInterface();
			Event event = ComponentDeactivator.getActivityEvent();
			
			// Serializing activity interface
			Package activityInterfacePackage = statechartUtil.wrapIntoPackage(activityInterface);
			String interfacePackageFileName = fileUtil.toHiddenFileName(
					fileNamer.getPackageFileName(activityInterface.getName()));
			this.serializer.saveModel(activityInterfacePackage, targetFolderUri, interfacePackageFileName);
			
			// Adding activity ports in adaptive statechart
			Map<State, Port> activityPorts = new HashMap<State, Port>();
			
			List<StateContractAnnotation> stateContractAnnotations =
					ecoreUtil.getAllContentsOfType(adaptiveStatechart, StateContractAnnotation.class);
			Set<State> annotationStates = stateContractAnnotations.stream()
					.map(it -> ecoreUtil.getContainerOfType(it, State.class))
					.collect(Collectors.toSet()); // Important that it is a set
			
			for (State annotationState : annotationStates) {
				Port adaptiveActivityPort = statechartUtil.createPort(
						activityInterface, RealizationMode.PROVIDED,
						getActivityPortName(adaptiveStatechart, annotationState));
				activityPorts.put(annotationState, adaptiveActivityPort);
				
				adaptiveStatechart.getPorts()
						.add(adaptiveActivityPort);
				// Raising activity events
				RaiseEventAction activateAction = statechartUtil.createRaiseEventAction(
						adaptiveActivityPort, event, expressionFactory.createTrueExpression());
				annotationState.getEntryActions()
						.add(activateAction);
				RaiseEventAction deactivateAction = statechartUtil.createRaiseEventAction(
						adaptiveActivityPort, event, expressionFactory.createFalseExpression());
				annotationState.getExitActions()
						.add(deactivateAction);
			}
			//
			
			// Adding activity ports in contract statecharts
			Map<StateContractAnnotation, StatechartDefinition> extendedContracts =
					new HashMap<StateContractAnnotation, StatechartDefinition>();
			Map<Port, List<Port>> connectedActivityPorts = new HashMap<Port, List<Port>>();
			
			for (StateContractAnnotation stateContractAnnotation : stateContractAnnotations) {
				StatechartDefinition contract = stateContractAnnotation.getContractStatechart();
				StatechartDefinition extendedContract = ecoreUtil.clone(contract);
				extendedContracts.put(stateContractAnnotation, extendedContract);
				
				State annotationState = ecoreUtil.getContainerOfType(
						stateContractAnnotation, State.class);
				Port adaptiveActivityPort = activityPorts.get(annotationState);
				
				ComponentDeactivator componentDeactivator = new ComponentDeactivator(
						extendedContract, stateContractAnnotation.isHasHistory());
				
				Port contractActivityPort = componentDeactivator.addActivityPort();
				List<Port> contractPorts = javaUtil.getOrCreateList(
						connectedActivityPorts, adaptiveActivityPort);
				contractPorts.add(contractActivityPort);
				
				componentDeactivator.addDeactivatingTransitions();
				
				// Handling loop transitions
				Set<State> resetableStates = new LinkedHashSet<State>();
				resetableStates.add(
						elementTracer.getViolationState(extendedContract));
				resetableStates.add(
						elementTracer.getAcceptState(extendedContract));
				for (State resetableState : resetableStates) {
					Region region = StatechartModelDerivedFeatures.getParentRegion(resetableState);
					State initialState = StatechartModelDerivedFeatures.getInitialState(region);
					for (Transition loopTransition :
							StatechartModelDerivedFeatures.getLoopTransitions(resetableState)) {
						loopTransition.setTargetState(initialState);
					}
				}
				//
				
				// TODO An error event could be introduced in the hot violation state 
				
				// Removing annotations as they should not be serialized
				ecoreUtil.remove(stateContractAnnotation);
				//
				Package extendedContractPackage = statechartUtil.wrapIntoPackage(extendedContract);
				extendedContractPackage.getImports().addAll(
						StatechartModelDerivedFeatures.getImportablePackages(extendedContractPackage));
				String extendedContractPackageFileName = fileUtil.toHiddenFileName(
						fileNamer.getPackageFileName(getExtendedContractName(stateContractAnnotation)));
				this.serializer.saveModel(
						extendedContractPackage, targetFolderUri, extendedContractPackageFileName);
			}
			//
			
			// Transforming (inlining) phases
			PhaseStatechartTransformer phaseStatechartTransformer =
					new PhaseStatechartTransformer(adaptiveStatechart);
			phaseStatechartTransformer.execute();
			Package missionPhasePackage = statechartUtil.wrapIntoPackage(adaptiveStatechart);
			missionPhasePackage.getImports().addAll(
					StatechartModelDerivedFeatures.getImportablePackages(adaptiveStatechart));
			
			String componentFileName = getPhaseComponentName(adaptiveComponent);
			String packageFileName = fileUtil.toHiddenFileName(
					fileNamer.getPackageFileName(componentFileName));
			this.serializer.saveModel(missionPhasePackage, targetFolderUri, packageFileName);
			
			Set<Port> adaptiveStatechartActivityPorts = connectedActivityPorts.keySet();
			for (StateContractAnnotation stateContractAnnotation : extendedContracts.keySet()) {
				StatechartDefinition statechartContract = extendedContracts.get(stateContractAnnotation);
				List<Expression> arguments = stateContractAnnotation.getArguments();
				// Creating the composition without the activity ports
				adaptiveStatechart.getPorts()
						.removeAll(adaptiveStatechartActivityPorts);
				SchedulableCompositeComponent composite = statechartUtil.wrapComponent(adaptiveStatechart);
				adaptiveStatechart.getPorts()
						.addAll(adaptiveStatechartActivityPorts);
				//
				Package compositePackage = statechartUtil.wrapIntoPackage(composite);
				List<? extends ComponentInstance> components =
						StatechartModelDerivedFeatures.getDerivedComponents(composite);
				ComponentInstance adaptiveStatechartInstance = javaUtil.getOnlyElement(components);
				adaptiveStatechartInstance.setName(
						javaUtil.toFirstCharLower(adaptiveStatechartInstance.getName()));
				
				String name = getCompositeComponentName(statechartContract, composite);
				// Scheduling the behaviors
				statechartUtil.scheduleInstances(composite, components);
				
				// Inserting the monitor
				Triple<String, PropertyPackage, ComponentInstance> artifacts =
						insertMonitor(composite, statechartContract, arguments, name);
				Entry<String, PropertyPackage> modelFileUri =
						new SimpleEntry<String, PropertyPackage>(
								artifacts.getFirst(), artifacts.getSecond());
				historyModelFileUris.add(modelFileUri);
				
				// Connecting the activity ports
				ComponentInstance contractInstance = artifacts.getThird();
				for (Port adaptiveStatechartPort : adaptiveStatechartActivityPorts) {
					List<Port> connectedPorts = connectedActivityPorts.get(adaptiveStatechartPort);
					List<Port> contractPorts = new ArrayList<Port>(
							StatechartModelDerivedFeatures.getAllPorts(statechartContract));
					contractPorts.retainAll(connectedPorts);
					if (!contractPorts.isEmpty()) {
						Port contractPort = javaUtil.getOnlyElement(contractPorts);
						
						Channel channel = statechartUtil.connectPortsViaChannels(
								adaptiveStatechartInstance, adaptiveStatechartPort,
								contractInstance, contractPort);
						composite.getChannels().add(channel);
					}
				}
				// Saving again due to the channels
				ecoreUtil.save(compositePackage.eResource());
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
			conformanceModelTransformation.setPropertyPackage(propertyPackage); // Optimization
			
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
			verification.setBackAnnotateToOriginal(true);

			VerificationHandler verificationHandler = new VerificationHandler(file);
			verificationHandler.execute(verification);
		}
	}
	
	private Triple<String, PropertyPackage, ComponentInstance> insertMonitor(
			SchedulableCompositeComponent composite, StatechartDefinition contract,
			List<? extends Expression> arguments, String name)
					throws IOException {
		// Contract statechart
		ComponentInstance contractInstance = statechartUtil.instantiateComponent(contract);
		contractInstance.getArguments().addAll(
				ecoreUtil.clone(arguments));
		String monitorName = getMonitorName();
		contractInstance.setName(monitorName);
		
		statechartUtil.addComponentInstance(composite, contractInstance);
		
		// Setting the component execution
		
		boolean hasInitialBlock = StatechartModelDerivedFeatures.hasInitialOutputsBlock(contract);
		if (hasInitialBlock) {
			composite.getInitialExecutionList().add(
					statechartUtil.createInstanceReference(contractInstance));
		}
		
		// Monitor (input) - behavior (already present) - monitor (output)
		List<ComponentInstanceReferenceExpression> executionList = composite.getExecutionList();
		executionList.add(0, statechartUtil.createInstanceReference(contractInstance));
		executionList.add(statechartUtil.createInstanceReference(contractInstance));
		
		// Binding system ports
		
		for (Port systemPort : StatechartModelDerivedFeatures.getAllPorts(composite)) {
			if (elementTracer.hasMatchedPort(systemPort, contract)) {
				Port contractPort = elementTracer.matchPort(systemPort, contract);
				// Only for all input ports
				if (StatechartModelDerivedFeatures.isBroadcastMatcher(contractPort)) {
					PortBinding inputPortBinding = factory.createPortBinding();
					inputPortBinding.setCompositeSystemPort(systemPort);
					
					InstancePortReference instancePortReference = statechartUtil
							.createInstancePortReference(contractInstance, contractPort);
					inputPortBinding.setInstancePortReference(instancePortReference);
					
					composite.getPortBindings().add(inputPortBinding);
				}
				// Only for output ports
				else if (StatechartModelDerivedFeatures.isBroadcast(contractPort)) {
					Collection<PortBinding> outputPortBindings =
							StatechartModelDerivedFeatures.getPortBindings(systemPort);
					
					Port reversedContractPort = elementTracer.matchReversedPort(contractPort, contract);
					
					// Channeling ports to definitions
					for (PortBinding outputPortBinding : outputPortBindings) {
						InstancePortReference contractPortReference = statechartUtil
								.createInstancePortReference(contractInstance, reversedContractPort);
						InstancePortReference behaviorPortReference = ecoreUtil
								.clone(outputPortBinding.getInstancePortReference());
						Channel channel = statechartUtil.createChannel(
								behaviorPortReference, contractPortReference);
						
						composite.getChannels().add(channel);
					}
				}
				else {
					throw new IllegalArgumentException("Not broadcast port: " + contractPort);
				}
			}
			else {
				logger.log(Level.INFO, "Not matchable port: " +
						contract.getName() + "." + systemPort.getName());
			}
		}
		
		// TODO Setting environment model if necessary
		
		// Setting imports
		Package compositePackage = StatechartModelDerivedFeatures.getContainingPackage(composite);
		compositePackage.getImports().addAll(
				StatechartModelDerivedFeatures.getImportablePackages(composite));
		
		// Serialization
		String targetFolderUri = this.getTargetFolderUri();
		String packageFileName = fileUtil.toHiddenFileName(fileNamer.getPackageFileName(name));
		
		this.serializer.saveModel(compositePackage, targetFolderUri, packageFileName);
		
		String modelFileUri = targetFolderUri + File.separator + packageFileName;
		
		// Saving the property
		State violationState = elementTracer.getViolationState(contract);
		ComponentInstanceStateReferenceExpression violationStateReference =
				propertyUtil.createStateReference(
						propertyUtil.createInstanceReference(contractInstance), violationState);
		StateFormula eFViolation = propertyUtil.createEF(
					propertyUtil.createAtomicFormula(violationStateReference));
		PropertyPackage violationPropertyPackage = propertyUtil.wrapFormula(composite, eFViolation);
		String propertyFileName = fileNamer.getHiddenPropertyFileName(name);

		this.serializer.saveModel(violationPropertyPackage, targetFolderUri, propertyFileName);
		
		// Returning the artifacts to set the analysis model transformer
		return new Triple<String, PropertyPackage, ComponentInstance>(
				modelFileUri, violationPropertyPackage, contractInstance);
	}
	
	// Settings
	
	private void setAdaptiveBehaviorConformanceChecker(AdaptiveBehaviorConformanceChecking conformanceChecker) {
		// Check if the contract automata are valid: initial blocks, restart-on-cold-violation,
		// back-transitions are on, receives-sends sequences, iteration variables are set
		// Theoretically, both permissive and strict can be used
		
	}
	
}

class Namings {
	//
	protected static final ExpressionSerializer expressionSerializer = ExpressionSerializer.INSTANCE;
	protected static final JavaUtil javaUtil = JavaUtil.INSTANCE;
	//
	public static String getCompositeComponentName(Component contract,
			List<MissionPhaseStateAnnotation> behaviors) {
		return contract.getName() + "_" + behaviors.stream()
			.map(it -> it.getComponent().getName()).reduce("", (a,  b) -> a + "_" + b);
	}
	
	public static String getCompositeComponentName(Component contract, Component composite) {
		return contract.getName() + "_" + composite.getName();
	}
	
	public static String getPhaseComponentName(Component component) {
		return component.getName() + "Stateful";
	}
	
	public static String getMonitorName() {
		return "monitor";
	}
	
	public static String getExtendedContractName(StateContractAnnotation annotation) {
		StatechartDefinition contract = annotation.getContractStatechart();
		StringBuilder builder = new StringBuilder();
		for (Expression argument : annotation.getArguments()) {
			builder.append("_" +
					expressionSerializer.serialize(argument));
		}
		Boolean hasHistory = annotation.isHasHistory();
		return contract.getName() + builder.toString() + "_" +
				javaUtil.toFirstCharUpper(hasHistory.toString());
	}
	
	//
	
	public static String getActivityPortName(Component component, State state) {
		return component.getName() + "_" + state.getName() + "_Activity";
	}
	
	public static String getActivityPortName(Component component) {
		return component.getName() + "_Activity";
	}
	
	public static String getActivityInterfaceName() {
		return "Activity";
	}
	
	public static String getActivityEventName() {
		return "activity";
	}
	
	public static String getActivityParameterName() {
		return "isActive";
	}
	
}

class ElementTracer {
	// Singleton
	public static final ElementTracer INSTANCE = new ElementTracer();
	protected ElementTracer() {}
	//
	protected final ScenarioStatechartUtil scenarioStatechartUtil = ScenarioStatechartUtil.INSTANCE;
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	//
	
	public boolean hasMatchedPort(Port matchablePort, Component component) {
		try {
			matchPort(matchablePort, component);
			return true;
		} catch (IllegalArgumentException e) {
			return false;
		}
	}
	
	public Port matchPort(Port matchablePort, Component component) {
		for (Port port : StatechartModelDerivedFeatures.getAllPorts(component)) {
			if (ecoreUtil.helperEquals(matchablePort, port)) {
				return port;
			}
		}
		throw new IllegalArgumentException("Not found bound port: " + matchablePort);
	}
	
	public Port matchReversedPort(Port matchablePort, Component component) {
		String name = scenarioStatechartUtil.getTurnedOutPortName(matchablePort);
		for (Port port : StatechartModelDerivedFeatures.getAllPorts(component)) {
			if (port.getName().equals(name)) {
				return port;
			}
		}
		throw new IllegalArgumentException("Not found reversed port: " + matchablePort);
	}
	
	public State getAcceptState(StatechartDefinition contractStatechart) {
		String name = scenarioStatechartUtil.getAccepting();
		return findState(contractStatechart, name);
	}
	
	public State getViolationState(StatechartDefinition contractStatechart) {
		String name = scenarioStatechartUtil.getHotComponentViolation();
		return findState(contractStatechart, name);
	}
	
	protected State findState(StatechartDefinition contractStatechart, String name) {
		for (State state : StatechartModelDerivedFeatures.getAllStates(contractStatechart)) {
			if (state.getName().equals(name)) {
				return state;
			}
		}
		throw new IllegalArgumentException("Not found state: " + contractStatechart);
	}
	
}