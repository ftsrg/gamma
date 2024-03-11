/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui.taskhandler;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.ProgrammingLanguage;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;

public class AnalysisModelTransformationAndVerificationHandler extends TaskHandler {
	
	//
	protected final boolean optimizeModel;
	protected final boolean backAnnotateToOriginal;
	protected boolean serializeTraces;
	protected final ProgrammingLanguage testLanguage;
	
	protected final List<ExecutionTrace> traces = new ArrayList<ExecutionTrace>();
	//
	
	public AnalysisModelTransformationAndVerificationHandler(IFile file) {
		this(file, false, false, true, null);
	}
	
	public AnalysisModelTransformationAndVerificationHandler(IFile file,
			boolean optimizeModel, boolean backAnnotateToOriginal,
			boolean serializeTraces, ProgrammingLanguage testLanguage) {
		super(file);
		this.optimizeModel = optimizeModel;
		this.backAnnotateToOriginal = backAnnotateToOriginal;
		this.serializeTraces = serializeTraces;
		this.testLanguage = testLanguage;
	}
	
	//

	public void execute(AnalysisModelTransformation transformation) throws IOException, InterruptedException {
		List<AnalysisLanguage> languages = transformation.getLanguages();
		AnalysisLanguage language = javaUtil.getOnlyElement(languages);
		
		PropertyPackage propertyPackage = transformation.getPropertyPackage();
		List<CommentableStateFormula> formulas = propertyPackage.getFormulas();
		List<CommentableStateFormula> savedFormulas = new ArrayList<CommentableStateFormula>(formulas);
		int size = savedFormulas.size();
		
		formulas.clear();
		for (CommentableStateFormula commentableStateFormula : savedFormulas) {
			int index = savedFormulas.indexOf(commentableStateFormula);
			formulas.add(commentableStateFormula); // One by one
			
			AnalysisModelTransformationHandler transformationHandler = new AnalysisModelTransformationHandler(file);
			transformation.setPropertyPackage(null); // No slicing - deprecated
			transformationHandler.execute(transformation);
			logger.info("Analysis transformation " + index + "/" + size + " finished");
			
			String folder = transformation.getTargetFolder().get(0);
			String plainFileName = fileUtil.getExtensionlessName(
					transformation.getFileName().get(0));
			String extension = fileNamer.getFileExtension(language);
			String fileName = folder + File.separator + plainFileName + "." + extension;
			
			Verification verification = factory.createVerification();
			verification.getAnalysisLanguages().add(language);
			verification.getFileName().add(fileName);
			verification.getTargetFolder().addAll(
					List.of("trace"));
			verification.getPropertyPackages().add(propertyPackage);
			verification.setOptimize(true);
			verification.setOptimizeModel(optimizeModel);
			verification.setBackAnnotateToOriginal(backAnnotateToOriginal);
			if (testLanguage != null) {
				verification.getProgrammingLanguages().add(testLanguage);
			}
			
			if (optimizeModel) {
				OptimizerAndVerificationHandler verificationHandler =
						new OptimizerAndVerificationHandler(file, serializeTraces);
				verificationHandler.execute(verification);
				
				traces.addAll(
						verificationHandler.getTraces());
			}
			else {
				VerificationHandler verificationHandler =
						new VerificationHandler(file, serializeTraces);
				verificationHandler.execute(verification);
				
				traces.addAll(
						verificationHandler.getTraces());
			}
			
			logger.info("Verification " + index + "/" + size + " finished");
		}
	}
	
	//
	
	public List<ExecutionTrace> getTraces() {
		return traces;
	}
	
}
