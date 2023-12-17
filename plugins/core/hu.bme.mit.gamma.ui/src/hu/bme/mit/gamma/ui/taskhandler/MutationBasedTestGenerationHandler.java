/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
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
import static com.google.common.base.Preconditions.checkState;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.List;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.expression.model.InequalityExpression;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.ModelMutation;
import hu.bme.mit.gamma.genmodel.model.ModelReference;
import hu.bme.mit.gamma.genmodel.model.MutationBasedTestGeneration;
import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.property.model.StateFormula;
import hu.bme.mit.gamma.property.util.PropertyUtil;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventParameterReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceEventReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression;
import hu.bme.mit.gamma.statechart.composite.InstancePortReference;
import hu.bme.mit.gamma.statechart.composite.PortBinding;
import hu.bme.mit.gamma.statechart.composite.SchedulableCompositeComponent;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.interface_.Interface;
import hu.bme.mit.gamma.statechart.interface_.InterfaceRealization;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.interface_.UnfoldedPackageAnnotation;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;
import hu.bme.mit.gamma.trace.model.Step;
import hu.bme.mit.gamma.transformation.util.GammaFileNamer;
import hu.bme.mit.gamma.ui.taskhandler.VerificationHandler.ExecutionTraceSerializer;

public class MutationBasedTestGenerationHandler extends TaskHandler {
	//
	protected String packageName;
	protected String traceFolderUri;
	protected String testFolderUri;
	protected String traceFileName;
	protected String testFileName;
	protected ProgrammingLanguage programmingLanguage;
	//
	protected final PropertyUtil propertyUtil = PropertyUtil.INSTANCE;
	protected final ExecutionTraceSerializer traceSerializer = ExecutionTraceSerializer.INSTANCE;
	//
	
	public MutationBasedTestGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(MutationBasedTestGeneration mutationBasedTestGeneration)
			throws IOException, InterruptedException {
		// Setting target folder
		setProjectLocation(mutationBasedTestGeneration); // Before the target folder
		setTargetFolder(mutationBasedTestGeneration);
		//
		setModelBasedMutationTestGeneration(mutationBasedTestGeneration);
		//
		
		String fileName = javaUtil.getOnlyElement(
				mutationBasedTestGeneration.getFileName());
		
		AnalysisModelTransformation analysisModelTransformation = mutationBasedTestGeneration.getAnalysisModelTransformation();
		ComponentReference model = (ComponentReference) analysisModelTransformation.getModel();
		Component component = (Component) GenmodelDerivedFeatures.getModel(model);
		
		Expression mutationCount = mutationBasedTestGeneration.getIterationCount();
		ModelMutation modelMutation = factory.createModelMutation();
		modelMutation.setModel(
				ecoreUtil.clone(model));
		modelMutation.setIterationCount(
				ecoreUtil.clone(mutationCount));
		
		ModelMutationHandler modelMutationHandler =  new ModelMutationHandler(file);
		modelMutationHandler.execute(modelMutation);
		
		List<Package> mutatedModels = modelMutationHandler.getMutatedModels();
		
		int i = 0;
		for (Package mutatedModel : mutatedModels) {
			// Handling these packages as if they were not unfolded (as the original component is not) 
			mutatedModel.getAnnotations().removeIf(it -> it instanceof UnfoldedPackageAnnotation);
			ecoreUtil.save(mutatedModel);
			//
			
			Component mutatedTopComponent = StatechartModelDerivedFeatures.getFirstComponent(mutatedModel);
			
			//
			SchedulableCompositeComponent compositeOriginal = propertyUtil.wrapComponent(component);
			@SuppressWarnings("unchecked")
			List<ComponentInstance> originalComponents = (List<ComponentInstance>)
					StatechartModelDerivedFeatures.getDerivedComponents(compositeOriginal);
			String originalComponentInstanceName = "original";
			for (ComponentInstance originalComponent : originalComponents) {
				originalComponent.setName(originalComponentInstanceName);
			}
			List<Port> originalInputPorts = StatechartModelDerivedFeatures.getAllPortsWithInput(compositeOriginal);
			List<Port> originalOutputPorts = StatechartModelDerivedFeatures.getAllPortsWithOutput(compositeOriginal);
			//
			
			//
			SchedulableCompositeComponent compositeMutant = propertyUtil.wrapComponent(mutatedTopComponent);
			List<Port> mutantInputPorts = StatechartModelDerivedFeatures.getAllPortsWithInput(compositeMutant);
			List<Port> mutantInternalPorts = StatechartModelDerivedFeatures.getAllInternalPorts(compositeMutant);
			List<Port> mutantOutputPorts = StatechartModelDerivedFeatures.getAllPortsWithOutput(compositeMutant);
			checkState(javaUtil.containsNone(mutantInputPorts, mutantOutputPorts), "A port contains both input and output events");
			
			List<Port> mergableMutantPorts = new ArrayList<Port>(mutantInternalPorts);
			mergableMutantPorts.addAll(mutantOutputPorts);
			for (Port port : mergableMutantPorts) {
				String name = port.getName();
				port.setName(
						javaUtil.matchFirstCharacterCapitalization(
								"mutant" + javaUtil.toFirstCharUpper(name),  name));
			}
			
			List<? extends ComponentInstance> mutantComponents = StatechartModelDerivedFeatures.getDerivedComponents(compositeMutant);
			for (ComponentInstance mutantComponent : mutantComponents) {
				mutantComponent.setName("mutant");
			}
			//
			
			// Merging the two models
			compositeOriginal.getPorts().addAll(mergableMutantPorts);
			
			originalComponents.addAll(mutantComponents);
			
			compositeOriginal.getPortBindings().addAll(
					compositeMutant.getPortBindings());
			compositeOriginal.getChannels().addAll(
					compositeMutant.getChannels());
			
			ecoreUtil.change(originalInputPorts, mutantInputPorts, compositeOriginal);
			
			Package newMergedPackage = propertyUtil.wrapIntoPackageAndAddImports(compositeOriginal);
			String newFileName = fileName + "_Mutant_" + (i++);
			String newPackageFileName = fileUtil.toHiddenFileName(
					fileNamer.getPackageFileName(newFileName));
			
			serializer.saveModel(newMergedPackage, targetFolderUri, newPackageFileName);
			
			// Create EF property
			List<Expression> orOperends = new ArrayList<Expression>();
			for (int j = 0; j < originalOutputPorts.size(); j++) {
				Port originalOutputPort = originalOutputPorts.get(j);
				Port mutantOutputPort = mutantOutputPorts.get(j);
				
				Interface _interface = StatechartModelDerivedFeatures.getInterface(originalOutputPort);
				checkState(ecoreUtil.helperEquals(_interface,
						StatechartModelDerivedFeatures.getInterface(mutantOutputPort)),
						"Interfaces are not the same");
				InterfaceRealization mutantInterfaceRealization = mutantOutputPort.getInterfaceRealization();
				mutantInterfaceRealization.setInterface(_interface);;
				
				List<Event> outputEvents = StatechartModelDerivedFeatures.getOutputEvents(originalOutputPort);
				for (Event outputEvent : outputEvents) {
					ComponentInstanceEventReferenceExpression originalReference =
							propertyUtil.createSystemEventReference(originalOutputPort, outputEvent);
					ComponentInstanceEventReferenceExpression mutantReference =
							propertyUtil.createSystemEventReference(mutantOutputPort, outputEvent);
					if (originalReference != null && mutantReference != null) {
						InequalityExpression inequality = propertyUtil
								.createInequalityExpression(originalReference, mutantReference);
						orOperends.add(inequality);
					}
					
					for (ParameterDeclaration eventParameter : outputEvent.getParameterDeclarations()) {
						ComponentInstanceEventParameterReferenceExpression originalParameterReference =
								propertyUtil.createSystemParameterReference(originalOutputPort, outputEvent, eventParameter);
						ComponentInstanceEventParameterReferenceExpression mutantParameterReference =
								propertyUtil.createSystemParameterReference(mutantOutputPort, outputEvent, eventParameter);
						if (originalParameterReference != null && mutantParameterReference != null) {
							InequalityExpression parameterInequality = propertyUtil
									.createInequalityExpression(originalParameterReference, mutantParameterReference);
							orOperends.add(parameterInequality);
						}
					}
				}
			}
			Expression or = propertyUtil.wrapIntoOrExpression(orOperends);
			StateFormula mutantKillingProperty = propertyUtil.createEF(
					propertyUtil.createAtomicFormula(or));
			
			PropertyPackage propertyPackage = propertyUtil.wrapFormula(compositeOriginal, mutantKillingProperty);
			ecoreUtil.normalSave(propertyPackage, targetFolderUri, "." + newFileName + ".gpd");
			
			analysisModelTransformation.setPropertyPackage(propertyPackage);
			
			// Analysis model transformation & verification
			model.setComponent(compositeOriginal);
			
			AnalysisModelTransformationAndVerificationHandler transformationHandler =
					new AnalysisModelTransformationAndVerificationHandler(file,
							true, true, false, null);
			transformationHandler.execute(analysisModelTransformation);
			
			analysisModelTransformation.setPropertyPackage(null);
			
			// Post-processing traces: projection to original component
			List<ExecutionTrace> traces = transformationHandler.getTraces();
			for (ExecutionTrace trace : traces) {
				List<RaiseEventAct> eventRaises = ecoreUtil.getAllContentsOfType(trace, RaiseEventAct.class);
				for (RaiseEventAct act : eventRaises) {
					Port systemPort = act.getPort();
					Collection<PortBinding> portBindings = StatechartModelDerivedFeatures.getPortBindings(systemPort);
					boolean foundOriginal = false;
					for (PortBinding portBinding : portBindings) {
						InstancePortReference instancePortReference = portBinding.getInstancePortReference();
						ComponentInstance instance = instancePortReference.getInstance();
						String instanceName = instance.getName();
						Port port = instancePortReference.getPort();
						if (instanceName.equals(originalComponentInstanceName)) {
							// Original port
							act.setPort(port);
							foundOriginal = true;
						}
					}
					if (!foundOriginal) {
						// Mutant port
						ecoreUtil.removeContainmentChainUntilType(act, Step.class);
					}
				}
				
				List<ComponentInstanceReferenceExpression> instanceReferences = ecoreUtil
						.getAllContentsOfType(trace, ComponentInstanceReferenceExpression.class)
						.stream()
						.filter(it -> !(it.eContainer() instanceof ComponentInstanceReferenceExpression))
						.toList();
				for (ComponentInstanceReferenceExpression instanceReference : instanceReferences) {
					ComponentInstance componentInstance = instanceReference.getComponentInstance();
					String instanceName = componentInstance.getName();
					if (instanceName.equals(originalComponentInstanceName)) {
						// Original instance
						ComponentInstanceReferenceExpression child = instanceReference.getChild();
						ecoreUtil.replace(child, instanceReference);
					}
					else {
						// Mutant instance
						ecoreUtil.removeContainmentChainUntilType(instanceReference, Step.class);
					}
				}

				trace.setComponent(component);
				trace.setImport(
						StatechartModelDerivedFeatures.getContainingPackage(trace.getComponent()));
				
				// Traces and tests are not serialized
				traceSerializer.serialize(traceFolderUri, traceFileName, null, testFolderUri,
						testFileName, packageName, programmingLanguage, trace);
			}
		}
		
	}
	
	private void setModelBasedMutationTestGeneration(
			MutationBasedTestGeneration mutationBasedTestGeneration) {
		List<String> fileNames = mutationBasedTestGeneration.getFileName();
		checkArgument(fileNames.size() <= 1);
		if (fileNames.isEmpty()) {
			AnalysisModelTransformation analysisModelTransformation =
					mutationBasedTestGeneration.getAnalysisModelTransformation();
			ModelReference model = analysisModelTransformation.getModel();
			EObject sourceModel = GenmodelDerivedFeatures.getModel(model);
			String containingFileName = getContainingFileName(sourceModel);
			String fileName = getNameWithoutExtension(containingFileName);
			fileNames.add(fileName);
		}
		List<String> packageNames = mutationBasedTestGeneration.getPackageName();
		List<String> testFolders = mutationBasedTestGeneration.getTestFolder();
		checkArgument(packageNames.size() <= 1);
		checkArgument(testFolders.size() <= 1);
		if (packageNames.isEmpty()) {
			packageNames.add(
					file.getProject().getName().toLowerCase());
		}
		if (testFolders.isEmpty()) {
			testFolders.add("test-gen");
		}
		
		List<ProgrammingLanguage> programmingLanguages = mutationBasedTestGeneration.getProgrammingLanguages();
		this.programmingLanguage = programmingLanguages.isEmpty() ? null : programmingLanguages.get(0);
		
		this.packageName = packageNames.get(0);
		this.traceFileName = GammaFileNamer.EXECUTION_TRACE_FILE_NAME;
		this.traceFolderUri = URI.decode(projectLocation + File.separator + "trace");
		// Setting the attribute, the test folder is a RELATIVE path now from the project
		String testFolder = testFolders.get(0);
		this.testFolderUri = URI.decode(projectLocation + File.separator + testFolder);
		this.testFileName = traceFileName + "Simulation";
	}

}
