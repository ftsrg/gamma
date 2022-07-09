/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.ui.taskhandler;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;

public class AnalysisModelTransformationAndVerificationHandler extends TaskHandler {
	
	public AnalysisModelTransformationAndVerificationHandler(IFile file) {
		super(file);
	}

	public void execute(AnalysisModelTransformation transformation) throws IOException {
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
			transformationHandler.execute(transformation);
			logger.log(Level.INFO, "Analysis transformation " + index + "/" + size + " finished");
			
			Verification verification = factory.createVerification();
			verification.getAnalysisLanguages().add(language);
			verification.getFileName().addAll(
					transformation.getFileName());
			verification.getTargetFolder().addAll(
					transformation.getTargetFolder());
			verification.getPropertyPackages().add(propertyPackage);
			verification.setOptimize(true);
			
			VerificationHandler verificationHandler = new VerificationHandler(file);
			verificationHandler.execute(verification);
			logger.log(Level.INFO, "Verification " + index + "/" + size + " finished");
		}
	}
	
}
