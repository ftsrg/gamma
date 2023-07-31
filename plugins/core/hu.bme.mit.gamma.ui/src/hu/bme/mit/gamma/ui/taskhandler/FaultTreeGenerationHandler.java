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

import java.io.File;
import java.io.IOException;
import java.util.AbstractMap.SimpleEntry;
import java.util.List;
import java.util.Map.Entry;
import java.util.Scanner;
import java.util.logging.Level;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.ecore.EObject;

import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.FaultTreeGeneration;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.querygenerator.serializer.NuxmvPropertySerializer;
import hu.bme.mit.gamma.verification.util.AbstractVerifier.LtlQueryAdapter;

public class FaultTreeGenerationHandler extends TaskHandler {
	
	protected final NuxmvPropertySerializer nuXmvPropertySerializer = NuxmvPropertySerializer.INSTANCE;
	
	//
	
	public FaultTreeGenerationHandler(IFile file) {
		super(file);
	}
	
	public void execute(FaultTreeGeneration faultTreeGeneration) throws IOException {
		setTargetFolder(faultTreeGeneration);
		setFaultTreeGeneration(faultTreeGeneration);
		
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

	protected Entry<String, String> generateXsapFiles(FaultTreeGeneration faultTreeGeneration) throws IOException {
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
		
		String extensionlessFileName = analysisModelTransformation.getFileName().get(0);
		
		// Handling the fei and fm models
		if (feiSize == 1) {
			String feiFile = faultExtensionInstructionsFile.get(0);
			File feiPath = super.exporeRelativeFile(faultTreeGeneration, feiFile);
			String feiFileNameExtensionless = fileUtil.getExtensionlessName(feiPath);
			// We have to transform the fei into an fm file with the 'extend_model' exe
			// extend_model [-h] [--xml-fei] [--verbose] [-p PATH] [-d PATH] FEI-FILE
			String xSapHome = System.getenv("XSAP_HOME");
			checkArgument(xSapHome != null, "XSAP_HOME environment variable is not set");
			
			String schemaFolder = xSapHome + File.separator + "data" + File.separator + "fm_library";
			
			String[] feiCommand = new String[] { "extend_model.exe", "-p", schemaFolder, "-d", targetFolderUri, feiPath.getAbsolutePath() };
			logger.log(Level.INFO, "Issuing command: " + List.of(feiCommand).stream().reduce("", ( (a, b) -> a + " " + b)));
			Process feiProcess = Runtime.getRuntime().exec(feiCommand);
			
			Scanner feiProcessScanner = new Scanner(feiProcess.errorReader()); // Nothing is published to  stdout
			while (feiProcessScanner.hasNext()) {
				logger.log(Level.INFO, feiProcessScanner.nextLine());
			}
			feiProcessScanner.close();
			
			final String prefix = "expanded_";
			String expandedFmXmlPath = targetFolderUri + File.separator + prefix + feiFileNameExtensionless + ".xml";
			final String smvFilePath = targetFolderUri + File.separator + extensionlessFileName + ".smv";
			
			final String dataSchema = "data" + File.separator + "schema";
			final String extendedSmvPath = targetFolderUri + File.separator + "extended_" + fileUtil.getFileName(smvFilePath);
			final String fmsXmlPath = targetFolderUri + File.separator + "fms_" + fileUtil.getFileName(expandedFmXmlPath).substring(prefix.length());
			
			String extendSmvCommand = 
					"set on_failure_script_quits" + System.lineSeparator()
					+ "read_model -i \"" + smvFilePath +"\"" + System.lineSeparator()
					+ "flatten_hierarchy" + System.lineSeparator()
					+ "fe_load_doc -p \"" + xSapHome + File.separator + dataSchema + "\" -i \"" + expandedFmXmlPath + "\"" + System.lineSeparator()
					+ "fe_extend_module -m \"" + fmsXmlPath + "\" -o \"" + extendedSmvPath + "\"" + System.lineSeparator()
					+ "quit";
			
			File extendSmvCommandFile = new File(targetFolderUri + File.separator + "extend_" + feiFileNameExtensionless + ".cmd");
			fileUtil.saveString(extendSmvCommandFile, extendSmvCommand);
			extendSmvCommandFile.deleteOnExit();
			
			String[] extendSmvCmdCommand = new String[] { "xSAP-win64", "-source", extendSmvCommandFile.getAbsolutePath() };
			logger.log(Level.INFO, "Issuing command: " + List.of(extendSmvCmdCommand).stream().reduce("", ( (a, b) -> a + " " + b)));
			Process extendFmProcess = Runtime.getRuntime().exec(extendSmvCmdCommand);
			
			Scanner extendSmvScanner = new Scanner(extendFmProcess.errorReader()); // Nothing is published to  stdout
			while (extendSmvScanner.hasNext()) {
				logger.log(Level.INFO, extendSmvScanner.nextLine());
			}
			extendSmvScanner.close();
			
			return new SimpleEntry<String, String>(fmsXmlPath, extendedSmvPath); 
		}
		
		throw new UnsupportedOperationException("Plain fm xml files are not yet supported");
	}

	//
	
	private void setFaultTreeGeneration(FaultTreeGeneration faultTreeGeneration) {
		List<String> fileNames = faultTreeGeneration.getFileName();
		checkArgument(fileNames.size() <= 1);
		if (fileNames.isEmpty()) {
			EObject sourceModel = GenmodelDerivedFeatures.getModel(faultTreeGeneration.getAnalysisModelTransformation());
			String fileName = getNameWithoutExtension(
					getContainingFileName(sourceModel));
			fileNames.add(fileName);
		}
	}
	
}
