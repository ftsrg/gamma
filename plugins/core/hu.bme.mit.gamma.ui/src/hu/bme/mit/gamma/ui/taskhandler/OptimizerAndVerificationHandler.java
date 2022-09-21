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

import static com.google.common.base.Preconditions.checkArgument;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.stream.Collectors;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.Verification;
import hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer.XstsOptimizer;
import hu.bme.mit.gamma.property.derivedfeatures.PropertyModelDerivedFeatures;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression;
import hu.bme.mit.gamma.uppaal.serializer.UppaalModelSerializer;
import hu.bme.mit.gamma.xsts.model.XSTS;
import hu.bme.mit.gamma.xsts.transformation.SystemReducer;
import hu.bme.mit.gamma.xsts.transformation.serializer.ActionSerializer;
import hu.bme.mit.gamma.xsts.uppaal.transformation.XstsToUppaalTransformer;
import uppaal.NTA;

public class OptimizerAndVerificationHandler extends TaskHandler {
	
	protected final SystemReducer xStsReducer = SystemReducer.INSTANCE;
	protected final ActionSerializer xStsSerializer = ActionSerializer.INSTANCE;

	public OptimizerAndVerificationHandler(IFile file) {
		super(file);
	}
	
	public void execute(Verification verification) throws IOException {
		List<AnalysisLanguage> analysisLanguages = verification.getAnalysisLanguages();
		checkArgument(analysisLanguages.contains(AnalysisLanguage.THETA) ||
				analysisLanguages.contains(AnalysisLanguage.XSTS_UPPAAL));
		
		String analysisFilePath = verification.getFileName().get(0);
		File analysisFile = super.exporeRelativeFile(verification, analysisFilePath);
		String gStsFilePath = fileNamer.getEmfXStsFileName(analysisFilePath);
		File gStsFile = super.exporeRelativeFile(verification, gStsFilePath);
		
		List<CommentableStateFormula> formulas = new ArrayList<CommentableStateFormula>();
		List<PropertyPackage> propertyPackages = verification.getPropertyPackages();
		
		PropertyPackage mainPropertyPackage = null;
		
		checkArgument(propertyPackages.stream()
							.allMatch(it ->  PropertyModelDerivedFeatures.isUnfolded(it)),
					"Not all property packages are unfolded: " + propertyPackages);
		for (PropertyPackage propertyPackage : propertyPackages) {
			if (mainPropertyPackage == null) {
				mainPropertyPackage = ecoreUtil.clone(propertyPackage);
			}
			formulas.addAll(
					propertyPackage.getFormulas());
		}
		propertyPackages.clear();
		List<CommentableStateFormula> checkableFormulas = mainPropertyPackage.getFormulas();
		int size = checkableFormulas.size();
		
		// Only one property package - we will add the formulas one by one
		propertyPackages.add(mainPropertyPackage);
		// As such, it is unnecessary to optimize the generated trace(s)
		boolean isOptimize = verification.isOptimize();
		verification.setOptimize(false);
		
		// A single one to store the traces and support later optimization - false: no trace serialization
		VerificationHandler verificationHandler = new VerificationHandler(file, false);
		//
		for (CommentableStateFormula formula : formulas) {
			checkableFormulas.clear();
			int index = formulas.indexOf(formula) + 1; // Only for logging
			checkableFormulas.add(formula);
			
			// Reload XSTS to retrieve all variables
			XSTS xSts = (XSTS) ecoreUtil.normalLoad(gStsFile);
			
			// Optimize XSTS based on formula
			List<ComponentInstanceVariableReferenceExpression> keepableVariableReferences =
					ecoreUtil.getAllContentsOfType(formula,
							ComponentInstanceVariableReferenceExpression.class); // Has to reference the unwrapped 
			List<VariableDeclaration> keepableVariables = keepableVariableReferences.stream()
					.map(it -> it.getVariableDeclaration())
					.collect(Collectors.toList());
			// Maybe other optimizations could be added?
			xStsReducer.deleteUnusedWrittenOnlyVariables(xSts, keepableVariables);
			XstsOptimizer xStsOptimizer = XstsOptimizer.INSTANCE;
			xStsOptimizer.optimizeXSts(xSts); // To remove null/empty actions
			// Serialize XSTS
			if (analysisLanguages.contains(AnalysisLanguage.THETA)) {
				String xStsString = xStsSerializer.serializeXsts(xSts);
				fileUtil.saveString(analysisFile, xStsString);
			}
			if (analysisLanguages.contains(AnalysisLanguage.XSTS_UPPAAL)) {
				XstsToUppaalTransformer transformer = new XstsToUppaalTransformer(xSts);
				NTA nta = transformer.execute();
				UppaalModelSerializer.saveToXML(nta, analysisFile);
			}
			//
			
			verificationHandler.execute(verification);
			logger.log(Level.INFO, "Verification property " + index + "/" + size + " finished");
		}
		
		if (isOptimize) {
			// Traces have not been serialized yet, doing it now
			verificationHandler.optimizeTraces();
		}
		verificationHandler.serializeTraces(); // Serialization in one pass
		
	}

}