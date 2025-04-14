/********************************************************************************
 * Copyright (c) 2024-2025 Contributors to the Gamma project
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

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.expression.model.NamedElement;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.SemanticDiff;
import hu.bme.mit.gamma.iml.verification.ImlComposerSemanticDiffer;
import hu.bme.mit.gamma.iml.verification.ImlSemanticDiffer;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;

public class SemanticDiffHandler extends TaskHandler {
	//
	protected ExecutionTrace semanticDiff = null;
	//
	
	public SemanticDiffHandler(IFile file) {
		super(file);
	}
	
	public void execute(SemanticDiff semanticDiff) throws IOException, InterruptedException {
		// Setting target folder
		setTargetFolder(semanticDiff);
		setFileRelativePaths(semanticDiff);
		//
		setSemanticDiffHandler(semanticDiff);
		
		checkArgument(semanticDiff.getAnalysisLanguages().size() == 1, 
				"A single analysis language must be specified: " + semanticDiff.getAnalysisLanguages());
		
		AnalysisLanguage programmingLanguage = semanticDiff.getAnalysisLanguages().get(0);
		checkArgument(programmingLanguage == AnalysisLanguage.IML, "Currently only IML is supported");
		
		List<String> fileNames = semanticDiff.getFileName();
		checkArgument(fileNames.size() == 2, "2 files are expected among which diff is computed");
		File modelFile1 = new File(fileNames.get(0));
		File modelFile2 = new File(fileNames.get(1));
		
		Package unfoldedPackage = getTraceabilityPackage(fileNames);
		
		ImlSemanticDiffer semanticDiffer = new ImlComposerSemanticDiffer();
		this.semanticDiff = semanticDiffer.execute(unfoldedPackage, modelFile1, modelFile2);
		
		if (this.semanticDiff != null) {
			String fileName = modelFile1.getName();
			
			String traceFileName = fileNamer.getExecutionTraceFileName(fileName);
			serializer.saveModel(this.semanticDiff, targetFolderUri, traceFileName);
			
			String json = semanticDiffer.printJson(this.semanticDiff);
			String jsonFileName = fileUtil.getExtensionlessName(fileName) + ".json";
			File jsonFile = new File(targetFolderUri, jsonFileName);
			fileUtil.saveString(jsonFile, json);
		}
		//
		List<Package> traceabilityPackages = getTraceabilityPackages(fileNames);
		Package package1 = traceabilityPackages.get(0);
		Package package2 = traceabilityPackages.get(1);
		
		Package mergedPackage = ecoreUtil.cloneAndMerge(package1, package2,
				((a, b) -> {
					if (a instanceof NamedElement an) {
						if (b instanceof NamedElement bn) {
							return an.getName().equals(bn.getName()) && a.eClass() == b.eClass();
						}
					}
					return ecoreUtil.helperEquals(a, b);
				}),
				(it) -> { return it instanceof NamedElement; });
		
		String fileName = fileUtil.getUnhiddenExtensionlessName(fileUtil.getFileName(fileNames.get(0))) +
				"_" + fileUtil.getUnhiddenExtensionlessName(fileUtil.getFileName(fileNames.get(1)));
		
		String mergedPackageFileName = fileNamer.getUnfoldedPackageFileName(fileName);
		serializer.saveModel(mergedPackage, targetFolderUri, mergedPackageFileName);
		//
	}

	private void setSemanticDiffHandler(SemanticDiff semanticDiff) {
		List<AnalysisLanguage> analysisLanguages = semanticDiff.getAnalysisLanguages();
		if (analysisLanguages.isEmpty()) {
			analysisLanguages.add(AnalysisLanguage.IML);
		}
	}
	
	protected Package getTraceabilityPackage(Iterable<String> fileNames) {
		for (String fileName : fileNames) {
			String unfoldedPackageFileName = fileNamer.getUnfoldedPackageUri(fileName);
			File unfoldedPackageFile = new File(unfoldedPackageFileName);
			if (unfoldedPackageFile.exists()) {
				return (Package) ecoreUtil.normalLoad(unfoldedPackageFile);
			}
		}
		return null;
	}
	
	protected List<Package> getTraceabilityPackages(Iterable<String> fileNames) {
		List<Package> packages = new ArrayList<Package>();
		
		for (String fileName : fileNames) {
			String unfoldedPackageFileName = fileNamer.getUnfoldedPackageUri(fileName);
			File unfoldedPackageFile = new File(unfoldedPackageFileName);
			if (unfoldedPackageFile.exists()) {
				packages.add((Package) ecoreUtil.normalLoad(unfoldedPackageFile));
			}
		}
		return packages;
	}
	
	public ExecutionTrace getSemanticDiff() {
		return semanticDiff;
	}

}