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

import java.io.File;
import java.io.IOException;
import java.util.List;
import java.util.Map.Entry;
import java.util.Scanner;
import java.util.logging.Level;

import org.eclipse.core.resources.IFile;

import hu.bme.mit.gamma.genmodel.model.FaultTreeGeneration;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.querygenerator.serializer.NuxmvPropertySerializer;
import hu.bme.mit.gamma.verification.util.AbstractVerifier.LtlQueryAdapter;

public class FaultTreeGenerationHandler extends SafetyAssessmentHandler {
	
	protected final NuxmvPropertySerializer nuXmvPropertySerializer = NuxmvPropertySerializer.INSTANCE;
	
	//
	
	public FaultTreeGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(FaultTreeGeneration faultTreeGeneration) throws IOException {
		setTargetFolder(faultTreeGeneration);
		setSafetyAssessment(faultTreeGeneration);
		
		Entry<String, String> xSapFiles = generateXsapFiles(faultTreeGeneration);
		String fmsXmlPath = xSapFiles.getKey();
		String extendedSmvPath = xSapFiles.getValue();
		
		String extensionlessFileName = faultTreeGeneration.getFileName().get(0);
		final String outputPath = targetFolderUri + File.separator + extensionlessFileName + ".txt";
		
		List<PropertyPackage> propertyPackages = faultTreeGeneration.getPropertyPackages();
		
		for (PropertyPackage propertyPackage : propertyPackages) {
			List<CommentableStateFormula> formulas = propertyPackage.getFormulas();
			for (CommentableStateFormula formula : formulas) {
				LtlQueryAdapter adapter = new LtlQueryAdapter();
				
				String serializedFormula = nuXmvPropertySerializer.serialize(formula);
				String tle = adapter.adaptLtlOrInvariantQueryToReachability(serializedFormula); // LTL invariant property (G ..)
				
				String generateFaultTreeCommand = 
						"set on_failure_script_quits" + System.lineSeparator()
						+ "set input_file \"" + extendedSmvPath + "\"" + System.lineSeparator()
						+ "set sa_compass" + System.lineSeparator()
						+ "set sa_compass_task_file \"" + fmsXmlPath + "\"" + System.lineSeparator()
						+ "go_msat" + System.lineSeparator()
						+ "compute_fault_tree_msat_bmc -o \"" + outputPath + "\" -t \"" + tle + "\"" + System.lineSeparator()
						+ "quit";
				
						File generateFaultTreeCommandFile = new File(targetFolderUri + File.separator + "generate_ft_" + extensionlessFileName + ".cmd");
						fileUtil.saveString(generateFaultTreeCommandFile, generateFaultTreeCommand);
						generateFaultTreeCommandFile.deleteOnExit();
						
						String[] generateFaultTreeCmdCommand = new String[] { "xSAP-win64", "-source", generateFaultTreeCommandFile.getAbsolutePath() };
						logger.log(Level.INFO, "Issuing command: " + List.of(generateFaultTreeCmdCommand).stream().reduce("", ( (a, b) -> a + " " + b)));
						Process generateFaultTreeProcess = Runtime.getRuntime().exec(generateFaultTreeCmdCommand);
						
						Scanner generateFaultTreeScanner = new Scanner(generateFaultTreeProcess.errorReader()); // Nothing is published to  stdout
						while (generateFaultTreeScanner.hasNext()) {
							logger.log(Level.INFO, generateFaultTreeScanner.nextLine());
						}
						generateFaultTreeScanner.close();
			}
		}
	}
	
}
