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

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.genmodel.model.ModelMutation;
import hu.bme.mit.gamma.genmodel.model.ModelReference;
import hu.bme.mit.gamma.mutation.ModelMutator;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.transformation.util.preprocessor.AnalysisModelPreprocessor;

public class ModelMutationHandler extends TaskHandler {
	
	//
	protected final List<Package> mutatedModels = new ArrayList<Package>();
	
	protected final AnalysisModelPreprocessor preprocessor = AnalysisModelPreprocessor.INSTANCE;
	//
	
	public ModelMutationHandler(IFile file) {
		super(file);
	}
	
	public void execute(ModelMutation modelMutation) throws IOException {
		// Setting target folder
		setTargetFolder(modelMutation);
		//
		setModelMutation(modelMutation);
		
		String fileName = javaUtil.getOnlyElement(
				modelMutation.getFileName());
		
		ComponentReference reference = (ComponentReference) modelMutation.getModel();
		Component component = reference.getComponent();
		List<Expression> arguments = reference.getArguments();
		Package gammaPackage = StatechartModelDerivedFeatures.getContainingPackage(component);
				
		Component newTopComponent = preprocessor.preprocess(gammaPackage, arguments,
				targetFolderUri, fileName, true);
		Package newPackage = StatechartModelDerivedFeatures.getContainingPackage(newTopComponent);
		
		ModelMutator mutator = new ModelMutator(); // TODO add heuristics parameters
		int MAX_MUTATION_ITERATION = 5; // TODO make it customizable
		for (int i = 0; i < MAX_MUTATION_ITERATION; i++) {
			Package clonedNewPackage =  ecoreUtil.clone(newPackage);
			Component clonedNewTopComponent = StatechartModelDerivedFeatures
					.getFirstComponent(clonedNewPackage);
			String componentName = clonedNewTopComponent.getName();
			clonedNewTopComponent.setName(componentName + "Mutant");
			
			mutator.executeOnStatechart(clonedNewTopComponent);
			serializer.saveModel(clonedNewPackage, targetFolderUri,
					fileNamer.getUnfoldedPackageFileName(fileName + "_Mutant_" + i));
			mutatedModels.add(clonedNewPackage);
		}
	}
	
	//
	
	public List<Package> getMutatedModels() {
		return this.mutatedModels;
	}
	
	//
	
	private void setModelMutation(ModelMutation mutation) {
		List<String> fileNames = mutation.getFileName();
		checkArgument(fileNames.size() <= 1);
		if (fileNames.isEmpty()) {
			ModelReference model = mutation.getModel();
			EObject sourceModel = GenmodelDerivedFeatures.getModel(model);
			String containingFileName = getContainingFileName(sourceModel);
			String fileName = getNameWithoutExtension(containingFileName);
			fileNames.add(fileName);
		}
	}

}
