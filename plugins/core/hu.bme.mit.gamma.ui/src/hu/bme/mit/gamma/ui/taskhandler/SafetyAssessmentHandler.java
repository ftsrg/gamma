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
import hu.bme.mit.gamma.genmodel.model.SafetyAssessment;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.querygenerator.serializer.NuxmvPropertySerializer;
import hu.bme.mit.gamma.util.SystemChecker;
import hu.bme.mit.gamma.verification.util.AbstractVerifier.LtlQueryAdapter;

public abstract class SafetyAssessmentHandler extends TaskHandler {
	
	protected final String xSapCommand;
	//
	
	protected final NuxmvPropertySerializer nuXmvPropertySerializer = NuxmvPropertySerializer.INSTANCE;
	protected final SystemChecker systemChecker = SystemChecker.INSTANCE;
	
	//
	
	public SafetyAssessmentHandler(IFile file) {
		super(file);
		checkArgument(systemChecker.isWindows() || systemChecker.isUnix());
		String commandDetail = systemChecker.isWindows() ? "win" : "linux";
		this.xSapCommand = "xSAP-" + commandDetail + "64";
	}
	
	//
	
	public void execute(SafetyAssessment safetyAssessment) throws IOException {
		setTargetFolder(safetyAssessment);
		setSafetyAssessment(safetyAssessment);
		
		Entry<String, String> xSapFiles = generateXsapFiles(safetyAssessment);
		String fmsXmlPath = xSapFiles.getKey();
		String extendedSmvPath = xSapFiles.getValue();
		
		String fileName = safetyAssessment.getFileName().get(0);
		String extensionlessFileName = fileUtil.getExtensionlessName(fileName);
		final String outputPath = targetFolderUri + File.separator + extensionlessFileName + ".txt";
		final File targetFolder = new File(targetFolderUri);
		
		List<PropertyPackage> propertyPackages = safetyAssessment.getPropertyPackages();
		for (PropertyPackage propertyPackage : propertyPackages) {
			List<CommentableStateFormula> formulas = propertyPackage.getFormulas();
			for (CommentableStateFormula formula : formulas) {
				LtlQueryAdapter adapter = new LtlQueryAdapter();
				
				String serializedFormula = nuXmvPropertySerializer.serialize(formula);
				String tle = adapter.adaptLtlOrInvariantQueryToReachability(serializedFormula); // TLE - reachability property without operators
				
				String generateFaultTreeCommand = 
						"set on_failure_script_quits" + System.lineSeparator()
						+ "set input_file \"" + extendedSmvPath + "\"" + System.lineSeparator()
						+ "set sa_compass" + System.lineSeparator()
						+ "set sa_compass_task_file \"" + fmsXmlPath + "\"" + System.lineSeparator()
						+  getCommand() + " -o \"" + outputPath + "\" -t \"" + tle + "\"" + System.lineSeparator()
						+ "quit";
				
						File generateFaultTreeCommandFile = new File(targetFolderUri + File.separator +
								getCommandFileNamePrefix() + "_" + extensionlessFileName + ".cmd");
						fileUtil.saveString(generateFaultTreeCommandFile, generateFaultTreeCommand);
						generateFaultTreeCommandFile.deleteOnExit();
						
						String[] generateFaultTreeCmdCommand = new String[] { xSapCommand, "-source", generateFaultTreeCommandFile.getAbsolutePath() };
						logger.log(Level.INFO, "Issuing command: " + List.of(generateFaultTreeCmdCommand).stream().reduce("", ( (a, b) -> a + " " + b)));
						Process generateFaultTreeProcess = Runtime.getRuntime().exec(generateFaultTreeCmdCommand, new String[0], targetFolder);
						
						Scanner generateFaultTreeScanner = new Scanner(generateFaultTreeProcess.errorReader()); // Nothing is published to  stdout
						while (generateFaultTreeScanner.hasNext()) {
							logger.log(Level.INFO, generateFaultTreeScanner.nextLine());
						}
						generateFaultTreeScanner.close();
			}
		}
	}
	
	abstract String getCommand();
	
	abstract String getCommandFileNamePrefix();
	
	//
	
	protected Entry<String, String> generateXsapFiles(SafetyAssessment safetyAssessment) throws IOException {
		List<String> faultExtensionInstructionsFile = safetyAssessment.getFaultExtensionInstructionsFile();
		int feiSize = faultExtensionInstructionsFile.size();
		List<String> faultModesFile = safetyAssessment.getFaultModesFile();
		int fmSize = faultModesFile.size();
		
		checkArgument(feiSize * fmSize == 0 && feiSize + fmSize == 1);
		
		String smvTargetFolderUri = null;
		String extensionlessFileName = null;
		
		// Transforming the Gamma model into SMV if analysis model transformation task is added
		AnalysisModelTransformation analysisModelTransformation = safetyAssessment.getAnalysisModelTransformation();
		if (analysisModelTransformation != null) {
			checkArgument(analysisModelTransformation.getLanguages().stream()
					.allMatch(it -> it == AnalysisLanguage.NUXMV));
			
			AnalysisModelTransformationHandler analysisModelTransformationHandler = new AnalysisModelTransformationHandler(file);
			analysisModelTransformationHandler.execute(analysisModelTransformation);
			
			smvTargetFolderUri = analysisModelTransformationHandler.getTargetFolderUri();
			extensionlessFileName = analysisModelTransformation.getFileName().get(0);
		}
		else {
			// We will try to read it from: targetFolderUri / extensionlessFileName + ".smv";
			smvTargetFolderUri = targetFolderUri;
			extensionlessFileName = safetyAssessment.getFileName().get(0);
		}
		File relativeFile = new File(extensionlessFileName); // To make sure there do not remain any file separators
		extensionlessFileName = fileUtil.getExtensionlessName(relativeFile);
		
		// Handling the fei and fm models
		if (feiSize == 1) {
			String feiFile = faultExtensionInstructionsFile.get(0);
			File feiPath = super.exporeRelativeFile(safetyAssessment, feiFile);
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
			final String smvFilePath = smvTargetFolderUri + File.separator + extensionlessFileName + ".smv";
			
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
			
			String[] extendSmvCmdCommand = new String[] { xSapCommand, "-source", extendSmvCommandFile.getAbsolutePath() };
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
	
	protected void setSafetyAssessment(SafetyAssessment safetyAssessment) {
		List<String> fileNames = safetyAssessment.getFileName();
		checkArgument(fileNames.size() <= 1);
		if (fileNames.isEmpty()) {
			EObject sourceModel = GenmodelDerivedFeatures.getModel(
					safetyAssessment.getAnalysisModelTransformation());
			String fileName = getNameWithoutExtension(
					getContainingFileName(sourceModel));
			fileNames.add(fileName);
		}
	}
	
}
