/********************************************************************************
 * Copyright (c) 2025 Contributors to the Gamma project
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
import java.util.List;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.RegionDecomposition;
import hu.bme.mit.gamma.iml.verification.ImlRegionDecomposer;
import hu.bme.mit.gamma.statechart.interface_.Package;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;

public class RegionDecompositionHandler extends TaskHandler {
	//
	protected ExecutionTrace regionDecomp = null;
	//
	
	public RegionDecompositionHandler(IFile file) {
		super(file);
	}
	
	public void execute(RegionDecomposition regionDecomp) throws IOException, InterruptedException {
		// Setting target folder
		setTargetFolder(regionDecomp);
		setFileRelativePaths(regionDecomp);
		//
		setRegionDecompositionHandler(regionDecomp);
		
		checkArgument(regionDecomp.getAnalysisLanguages().size() == 1, 
				"A single analysis language must be specified: " + regionDecomp.getAnalysisLanguages());
		
		AnalysisLanguage programmingLanguage = regionDecomp.getAnalysisLanguages().get(0);
		checkArgument(programmingLanguage == AnalysisLanguage.IML, "Currently only IML is supported");
		
		List<String> fileNames = regionDecomp.getFileName();
		checkArgument(fileNames.size() == 1, "One file is expected");
		File modelFile1 = new File(fileNames.get(0));
		
		String fileName = fileNamer.getUnfoldedPackageFileName(fileUtil.getFileName(fileNames.get(0)));
		//
		Package _package = (Package) ecoreUtil.normalLoad(
				new File(targetFolderUri, fileName));
		//
		ImlRegionDecomposer regionDecomper = new ImlRegionDecomposer();
		this.regionDecomp = regionDecomper.execute(_package, modelFile1);
		
		if (this.regionDecomp != null) {
			String traceFileName = fileNamer.getExecutionTraceFileName(fileName);
			serializer.saveModel(this.regionDecomp, targetFolderUri, traceFileName);
			
			String json = regionDecomper.printJson(this.regionDecomp);
			String jsonFileName = fileUtil.getExtensionlessName(fileName) + ".json";
			File jsonFile = new File(targetFolderUri, jsonFileName);
			fileUtil.saveString(jsonFile, json);
		}
	}

	private void setRegionDecompositionHandler(RegionDecomposition regionDecomp) {
		List<AnalysisLanguage> analysisLanguages = regionDecomp.getAnalysisLanguages();
		if (analysisLanguages.isEmpty()) {
			analysisLanguages.add(AnalysisLanguage.IML);
		}
	}
	
	//
	
	public ExecutionTrace getRegionDecomposition() {
		return regionDecomp;
	}
	
}