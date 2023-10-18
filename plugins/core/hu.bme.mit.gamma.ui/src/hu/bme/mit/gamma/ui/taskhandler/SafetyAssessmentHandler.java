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
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.AbstractMap.SimpleEntry;
import java.util.List;
import java.util.Map.Entry;
import java.util.Scanner;
import java.util.logging.Level;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;

import hu.bme.mit.gamma.fei.model.FaultExtensionInstructions;
import hu.bme.mit.gamma.fei.model.FaultSlice;
import hu.bme.mit.gamma.genmodel.derivedfeatures.GenmodelDerivedFeatures;
import hu.bme.mit.gamma.genmodel.model.AnalysisLanguage;
import hu.bme.mit.gamma.genmodel.model.AnalysisModelTransformation;
import hu.bme.mit.gamma.genmodel.model.SafetyAssessment;
import hu.bme.mit.gamma.property.model.CommentableStateFormula;
import hu.bme.mit.gamma.property.model.PropertyPackage;
import hu.bme.mit.gamma.querygenerator.serializer.NuxmvPropertySerializer;
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceElementReferenceExpression;
import hu.bme.mit.gamma.util.SystemChecker;
import hu.bme.mit.gamma.verification.util.AbstractVerifier.LtlQueryAdapter;

public abstract class SafetyAssessmentHandler extends TaskHandler {
	
	protected final String xSapCommand;
	//
	
	protected final hu.bme.mit.gamma.fei.xsap.transformation.serializer.ModelSerializer feiSerializer =
			hu.bme.mit.gamma.fei.xsap.transformation.serializer.ModelSerializer.INSTANCE;
	protected final NuxmvPropertySerializer nuXmvPropertySerializer = NuxmvPropertySerializer.INSTANCE;
	protected final SystemChecker systemChecker = SystemChecker.INSTANCE;
	
	//
	
	public SafetyAssessmentHandler(IFile file) {
		super(file);
		checkArgument(systemChecker.isWindows() || systemChecker.isUnix());
		String osSpecificParameter = systemChecker.isWindows() ? "win" : "linux";
		this.xSapCommand = "xSAP-" + osSpecificParameter + "64";
	}
	
	//
	
	public void execute(SafetyAssessment safetyAssessment) throws IOException {
		setTargetFolder(safetyAssessment);
		setSafetyAssessment(safetyAssessment);
		
		Entry<String, String> xSapFiles = generateXsapFiles(safetyAssessment);
		final String fmsXmlPath = xSapFiles.getKey();
		final String extendedSmvPath = xSapFiles.getValue();
		
		final String fileName = safetyAssessment.getFileName().get(0);
		final String extensionlessFileName = fileUtil.getUnhiddenExtensionlessName(fileName);
		final String outputPath = targetFolderUri + File.separator + extensionlessFileName + ".txt";
		final File targetFolder = new File(targetFolderUri);
		
		int propertyCount = 0;
		List<PropertyPackage> propertyPackages = safetyAssessment.getPropertyPackages();
		for (PropertyPackage propertyPackage : propertyPackages) {
			List<CommentableStateFormula> formulas = propertyPackage.getFormulas();
			for (CommentableStateFormula formula : formulas) {
				LtlQueryAdapter adapter = new LtlQueryAdapter();
				
				String serializedFormula = nuXmvPropertySerializer.serialize(formula);
				String plainTle = adapter.adaptLtlOrInvariantQueryToReachability(serializedFormula); // TLE - reachability property without operators
				String tle = javaUtil.simplifyExclamationMarkPairs(plainTle);
				
				String fileNamePrefix = extensionlessFileName + "_" + propertyCount++ + "_";
				String generateFaultTreeCommand = 
						"set on_failure_script_quits" + System.lineSeparator()
						+ "set input_file \"" + extendedSmvPath + "\"" + System.lineSeparator()
						+ "set sa_compass" + System.lineSeparator()
						+ "set sa_compass_task_file \"" + fmsXmlPath + "\"" + System.lineSeparator()
						+  getCommand() + " -x \"" + fileNamePrefix + "\" -o \"" + outputPath + "\" -t \"" + tle + "\"" + System.lineSeparator()
						+ "quit";
				
				File generateFaultTreeCommandFile = new File(targetFolderUri + File.separator +
						fileUtil.toHiddenFileName(getCommandFileNamePrefix() + "_" + extensionlessFileName + ".cmd"));
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
				
				// Visualize fault tree (a dependency to a certain version of Sirius is needed)
				boolean visualizeFaultTree = safetyAssessment.isVisualize();
				if (visualizeFaultTree) {
//					final String xmlPath = targetFolderUri + File.separator + fileNamePrefix + "ft.xml";
//					FaultTreeVisualizer faultTreeVisualizer = FaultTreeVisualizer.INSTANCE;
//					faultTreeVisualizer.visualizeFaultTree(xmlPath);
				}
			}
		}
	}
	
	abstract String getCommand();
	
	abstract String getCommandFileNamePrefix();
	
	//
	
	protected Entry<String, String> generateXsapFiles(SafetyAssessment safetyAssessment) throws IOException {
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
		
		List<String> faultExtensionInstructionsFile = safetyAssessment.getFaultExtensionInstructionsFile();
		List<String> faultModesFile = safetyAssessment.getFaultModesFile();
		FaultExtensionInstructions gFeiModel = safetyAssessment.getFaultExtensionInstructions();
		if (gFeiModel != null) {
			String serializedGfeiModel = feiSerializer.execute(gFeiModel);
			
			Resource safetyAssessmentResource = safetyAssessment.eResource();
			String parentUri = ecoreUtil.getFile(safetyAssessmentResource).getParent();
			String gFeiFileName = extensionlessFileName + ".fei";
			String fileUri = parentUri + File.separator + gFeiFileName;
			File gFeiFile = new File(fileUri);
			
			fileUtil.saveString(gFeiFile, serializedGfeiModel);
			faultExtensionInstructionsFile.add(gFeiFileName);
		}
		
		int feiSize = faultExtensionInstructionsFile.size();
		int fmSize = faultModesFile.size();
		
		checkArgument(feiSize * fmSize == 0 && feiSize + fmSize == 1);
		
		if (feiSize == 1) {
			String feiFile = faultExtensionInstructionsFile.get(0);
			File feiPath = super.exporeRelativeFile(safetyAssessment, feiFile);
			String feiFileNameExtensionless = fileUtil.getUnhiddenExtensionlessName(feiPath);
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
			final String expandedFmXmlPath = targetFolderUri + File.separator + prefix + feiFileNameExtensionless + ".xml";
			final String smvFilePath = smvTargetFolderUri + File.separator + extensionlessFileName + ".smv";
			
			final String dataSchema = "data" + File.separator + "schema";
			final String extendedSmvPath = targetFolderUri + File.separator + "extended_" + fileUtil.getUnhiddenFileName(smvFilePath);
			final String fmsXmlPath = targetFolderUri + File.separator + fileUtil.toHiddenFileName(
					"fms_" + fileUtil.getUnhiddenFileName(expandedFmXmlPath).substring(prefix.length()));
			
			String extendSmvCommand = 
					"set on_failure_script_quits" + System.lineSeparator()
					+ "read_model -i \"" + smvFilePath +"\"" + System.lineSeparator()
					+ "flatten_hierarchy" + System.lineSeparator()
					+ "fe_load_doc -p \"" + xSapHome + File.separator + dataSchema + "\" -i \"" + expandedFmXmlPath + "\"" + System.lineSeparator()
					+ "fe_extend_module -m \"" + fmsXmlPath + "\" -o \"" + extendedSmvPath + "\"" + System.lineSeparator()
					+ "quit";
			
			File extendSmvCommandFile = new File(targetFolderUri + File.separator + fileUtil.toHiddenFileName("extend_" + feiFileNameExtensionless + ".cmd"));
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
			
			// Ad hoc bugfix
			fixXsapBug(extendedSmvPath, gFeiModel);
			//
			
			return new SimpleEntry<String, String>(fmsXmlPath, extendedSmvPath); 
		}
		
		throw new UnsupportedOperationException("Plain fm xml files are not yet supported");
	}
	
	//

	private void fixXsapBug(String extendedSmvPath, FaultExtensionInstructions faultExtensionInstructions) throws FileNotFoundException {
		File extendedSmvFile = new File(extendedSmvPath);
		StringBuilder fixedExtendedSmvModel = new StringBuilder(8195);
		
		try (Scanner scanner = new Scanner(extendedSmvFile)) {
			while (scanner.hasNext()) {
				String line = scanner.nextLine();
				if (line.startsWith("MODULE main_#Extended")) { // Issue #n/a
					fixedExtendedSmvModel.append("MODULE main");
				}
				else if (line.contains("next(")) { // Issue #954
					String fixedLine = line;
					
					for (FaultSlice slice : faultExtensionInstructions.getFaultSlices()) {
						for (ComponentInstanceElementReferenceExpression element : slice.getAffectedElements()) {
							String serializeId = feiSerializer.serializeId(element);
							fixedLine = fixedLine.replace(
									"next(" + serializeId + ")", "next(" + serializeId + "_#nominal)");
						}
					}
					
					fixedExtendedSmvModel.append(fixedLine);
				}
				else {
					fixedExtendedSmvModel.append(line);
				}
				//
				fixedExtendedSmvModel.append(System.lineSeparator());
			}
		}
		
		fileUtil.saveString(extendedSmvFile, fixedExtendedSmvModel.toString());
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
