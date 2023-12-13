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

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.ModelMutation;
import hu.bme.mit.gamma.genmodel.model.ModelReference;
import hu.bme.mit.gamma.genmodel.model.MutationBasedTestGeneration;
import hu.bme.mit.gamma.statechart.composite.ComponentInstance;
import hu.bme.mit.gamma.statechart.composite.SchedulableCompositeComponent;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.statechart.interface_.Port;
import hu.bme.mit.gamma.statechart.util.StatechartUtil;

public class MutationBasedTestGenerationHandler extends TaskHandler {
	
	//
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE;
	//
	
	public MutationBasedTestGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(MutationBasedTestGeneration mutationBasedTestGeneration) throws IOException {
		// Setting target folder
		setTargetFolder(mutationBasedTestGeneration);
		//
		setModelBasedMutationTestGeneration(mutationBasedTestGeneration);
		
		String fileName = javaUtil.getOnlyElement(
				mutationBasedTestGeneration.getFileName());
		
		AnalysisModelTransformation analysisModelTransformation = mutationBasedTestGeneration.getAnalysisModelTransformation();
		ModelReference model = analysisModelTransformation.getModel();
		Component component = (Component) GenmodelDerivedFeatures.getModel(model);
		
		ModelMutation modelMutation = factory.createModelMutation();
		modelMutation.setModel(model);
		
		ModelMutationHandler modelMutationHandler =  new ModelMutationHandler(file);
		modelMutationHandler.execute(modelMutation);
		// TODO set number
		List<Package> mutatedModels = modelMutationHandler.getMutatedModels();
		
		int i = 0;
		for (Package mutatedModel : mutatedModels) {
			Component mutatedTopComponent = StatechartModelDerivedFeatures.getFirstComponent(mutatedModel);
			
			//
			SchedulableCompositeComponent compositeOriginal = statechartUtil.wrapComponent(component);
			List<ComponentInstance> originalComponents = (List<ComponentInstance>)
					StatechartModelDerivedFeatures.getDerivedComponents(compositeOriginal);
			for (ComponentInstance originalComponent : originalComponents) {
				originalComponent.setName("original");
			}
			List<Port> originalInputPorts = StatechartModelDerivedFeatures.getAllPortsWithInput(compositeOriginal);
			//
			
			//
			SchedulableCompositeComponent compositeMutant = statechartUtil.wrapComponent(mutatedTopComponent);
			List<Port> mutantInputPorts = StatechartModelDerivedFeatures.getAllPortsWithInput(compositeMutant);
			List<Port> mutantInternalPorts = StatechartModelDerivedFeatures.getAllInternalPorts(compositeMutant);
			List<Port> mutantOutputPorts = StatechartModelDerivedFeatures.getAllPortsWithOutput(compositeMutant);
			checkState(javaUtil.containsNone(mutantInputPorts, mutantOutputPorts), "A port contains both input and output events");
			
			List<Port> mergableMutantPorts = new ArrayList<Port>(mutantInternalPorts);
			mergableMutantPorts.addAll(mutantOutputPorts);
			for (Port port : mergableMutantPorts) {
				String name = port.getName();
				port.setName(name + "Mutant");
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
			
			Package newMergedPackage = statechartUtil.wrapIntoPackageAndAddImports(compositeOriginal);
			String newFileName = fileUtil.toHiddenFileName(
					fileNamer.getPackageFileName(fileName + "_Mutant_" + (i++)));
			
			serializer.saveModel(newMergedPackage, targetFolderUri, newFileName);
			
			// Analysis model transformation
			
			// Verification
			
		}
		
	}
	
	private void setModelBasedMutationTestGeneration(MutationBasedTestGeneration mutationBasedTestGeneration) {
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
	}

}
