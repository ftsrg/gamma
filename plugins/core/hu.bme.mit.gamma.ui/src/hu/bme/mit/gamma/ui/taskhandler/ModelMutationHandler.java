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
import java.util.List;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.expression.model.Expression;
import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.ComponentReference;
import hu.bme.mit.gamma.mutation.ModelMutator;
import hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures;
import hu.bme.mit.gamma.statechart.interface_.Component;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.transformation.util.preprocessor.AnalysisModelPreprocessor;

public class ModelMutationHandler extends TaskHandler {
	
	//
	protected final AnalysisModelPreprocessor preprocessor = AnalysisModelPreprocessor.INSTANCE;
	//
	
	public ModelMutationHandler(IFile file) {
		super(file);
	}
	
	public void execute(AnalysisModelTransformation transformation, String packageName) throws IOException {
		// Setting target folder
//		setProjectLocation(transformation); // Before the target folder
		setTargetFolder(transformation);
		//
		setModelMutation(transformation);
		
		String fileName = javaUtil.getOnlyElement(
				transformation.getFileName());
		
		ComponentReference reference = (ComponentReference) transformation.getModel();
		Component component = reference.getComponent();
		List<Expression> arguments = reference.getArguments();
		Package gammaPackage = StatechartModelDerivedFeatures.getContainingPackage(component);
				
		Component newTopComponent = preprocessor.preprocess(gammaPackage, arguments,
				targetFolderUri, fileName, true);
		
		ModelMutator mutator = new ModelMutator(); // TODO add heuristics parameters
		int MAX_MUTATION_ITERATION = 10;
		for (int i = 0; i < MAX_MUTATION_ITERATION; i++) {
			mutator.executeOnStatechart(newTopComponent);
			serializer.saveModel(newTopComponent, targetFolderUri, fileName + "_" + i);
		}
	}
	
	private void setModelMutation(AnalysisModelTransformation transformation) {
		List<String> fileNames = transformation.getFileName();
		checkArgument(fileNames.size() <= 1);
		if (fileNames.isEmpty()) {
			EObject sourceModel = GenmodelDerivedFeatures.getModel(
					transformation);
			String fileName = getNameWithoutExtension(
					getContainingFileName(sourceModel));
			fileNames.add(fileName);
		}
	}

}
