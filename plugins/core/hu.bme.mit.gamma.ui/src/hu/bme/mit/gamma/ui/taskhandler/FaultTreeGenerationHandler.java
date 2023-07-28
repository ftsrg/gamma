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

import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Scanner;
import java.util.logging.Level;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.FaultTreeGeneration;

public class FaultTreeGenerationHandler extends TaskHandler {

	public FaultTreeGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(FaultTreeGeneration faultTreeGeneration) throws IOException {
		setTargetFolder(faultTreeGeneration);
		
		AnalysisModelTransformation analysisModelTransformation = faultTreeGeneration.getAnalysisModelTransformation();
		
		checkArgument(analysisModelTransformation.getLanguages().stream().allMatch(it -> it == AnalysisLanguage.NUXMV));
		
		List<String> faultExtensionInstructionsFile = faultTreeGeneration.getFaultExtensionInstructionsFile();
		int feiSize = faultExtensionInstructionsFile.size();
		List<String> faultModesFile = faultTreeGeneration.getFaultModesFile();
		int fmSize = faultModesFile.size();
		
		checkArgument(feiSize * fmSize == 0 && feiSize + fmSize == 1);
		
		// Transforming the Gamma model into SMV
		
		AnalysisModelTransformationHandler analysisModelTransformationHandler = new AnalysisModelTransformationHandler(file);
		analysisModelTransformationHandler.execute(analysisModelTransformation);
		
		// Handling the fei and fm models
		if (feiSize == 1) {
			String feiFile = faultExtensionInstructionsFile.get(0);
			File feiPath = super.exporeRelativeFile(faultTreeGeneration, feiFile);
			// We have to transform the fei into an fm file with the 'extend_model' exe
			// extend_model [-h] [--xml-fei] [--verbose] [-p PATH] [-d PATH] FEI-FILE
			String xSapHome = System.getenv("XSAP_HOME");
			checkArgument(xSapHome != null, "XSAP_HOME environment variable is not set");
			
			String schemaFolder = xSapHome + File.separator + "data" + File.separator + "fm_library";
			
			String[] feiCommand = new String[] { "extend_model.exe", "-p", schemaFolder, "-d", targetFolderUri, feiPath.getAbsolutePath() };
			Process feiProcess = Runtime.getRuntime().exec(feiCommand);
			
			logger.log(Level.INFO, "Issuing command: " + List.of(feiCommand).stream().reduce("", ( (a, b) -> a + " " + b)));
			
			Scanner scanner = new Scanner(feiProcess.errorReader()); // Nothing is published to  stdout
			while (scanner.hasNext()) {
				logger.log(Level.INFO, scanner.nextLine());
			}
		}
		
	}

}
