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
import java.util.Map.Entry;
import java.util.logging.Level;

import org.eclipse.core.resources.IFile;
import org.eclipse.emf.ecore.resource.Resource;

import com.google.gson.Gson;
import com.google.gson.GsonBuilder;

import hu.bme.mit.gamma.genmodel.model.TraceGeneration;
import hu.bme.mit.gamma.property.util.PropertyUtil;
import hu.bme.mit.gamma.theta.verification.ThetaTraceGenerator;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.util.TraceUtil;
import hu.bme.mit.gamma.transformation.util.GammaFileNamer;
import hu.bme.mit.gamma.transformation.util.StatechartEcoreUtil;
import hu.bme.mit.gamma.util.FileUtil;
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean;

public class TraceGenerationHandler extends TaskHandler {

	protected boolean serializeTest; // Denotes whether test code is generated
	protected String testFolderUri;
	// targetFolderUri is traceFolderUri 
	protected String svgFileName; // Set in setVerification
	protected final String traceFileName = "ExecutionTrace";
	protected final String testFileName = traceFileName + "Simulation";
	
	//
	
	protected final List<ExecutionTrace> traces = new ArrayList<ExecutionTrace>();
	
	//
	
	protected final TraceUtil traceUtil = TraceUtil.INSTANCE;
	protected final PropertyUtil propertyUtil = PropertyUtil.INSTANCE;
	protected final StatechartEcoreUtil statechartEcoreUtil = StatechartEcoreUtil.INSTANCE;
	protected final ExecutionTraceSerializer serializer = ExecutionTraceSerializer.INSTANCE;
	
	public TraceGenerationHandler(IFile file) {
		super(file);
	}
		
	public void execute(TraceGeneration traceGeneration) throws IOException {
		setTargetFolder(traceGeneration);
		
		File targetFolder = new File(targetFolderUri + File.separator + file.getName().split("\\.")[0] + File.separator);
		if (targetFolder.exists()) {
			cleanFolder(targetFolder);			
		} else {
			targetFolder.mkdirs();
		}
		
		// Based on the method setVerification in VerificationHandler
		Resource resource = traceGeneration.eResource();
		File file = (resource != null) ?
				ecoreUtil.getFile(resource).getParentFile() : // If Verification is contained in a resource
					fileUtil.toFile(super.file).getParentFile(); // If Verification is created in Java
		// Setting the file paths
		traceGeneration.getFileName().replaceAll(it -> fileUtil.exploreRelativeFile(file, it).toString());

		List<String> variableList = traceGeneration.getVariables();
		boolean useAbstraction = traceGeneration.getVariableLists().size() != 0;
		
		boolean fullTraces = traceGeneration.isFullTraces();
		boolean noTransitionCoverage = traceGeneration.isNoTransitionCoverage();
		String filePath = traceGeneration.getFileName().get(0);
		File modelFile = new File(filePath);		
		List<ExecutionTrace> retrievedTraces = new ArrayList<ExecutionTrace>();
		ThetaTraceGenerator ttg = new ThetaTraceGenerator();
		retrievedTraces = ttg.execute(modelFile, fullTraces, variableList, noTransitionCoverage, useAbstraction);
		logger.log(Level.INFO, "Number of received traces: " + retrievedTraces.size());

		for (ExecutionTrace trace : retrievedTraces) {
			serializer.serialize(targetFolder.getAbsolutePath(), traceFileName, svgFileName,
					testFolderUri, testFileName, "", trace);
		}
		traces.addAll(retrievedTraces);
		System.err.println(traces.size());
	}

	public static void cleanFolder(File folder) {
		File[] files = folder.listFiles();
	    if (files != null) {
	        for (File file : files) {
	            if (file.isDirectory()) {
	                deleteFolder(file);
	            } else {
	                file.delete();
	            }
	        }
	    }
	}
	
	public static void deleteFolder(File folder) {
	    File[] files = folder.listFiles();
	    if (files!=null) {
	        for (File file : files) {
	            if (file.isDirectory()) {
	                deleteFolder(file);
	            } else {
	                file.delete();
	            }
	        }
	    }
	    folder.delete();
	}
	
	public List<ExecutionTrace> getTraces() {
		return traces;
	}
	
	public static class ExecutionTraceSerializer {
		//
		public static ExecutionTraceSerializer INSTANCE = new ExecutionTraceSerializer();
		protected ExecutionTraceSerializer() {}
		//
		protected final Gson gson = new GsonBuilder().disableHtmlEscaping().create();
		protected final FileUtil fileUtil = FileUtil.INSTANCE;
		protected final ModelSerializer serializer = ModelSerializer.INSTANCE;
		
		public void serialize(String traceFolderUri, String traceFileName, ExecutionTrace trace) throws IOException {
			this.serialize(traceFolderUri, traceFileName, null, null, null, trace);
		}
		
		public void serialize(String traceFolderUri, String traceFileName,
				String testFolderUri, String testFileName, String basePackage, ExecutionTrace trace) throws IOException {
			this.serialize(traceFolderUri, traceFileName, null, testFolderUri, testFileName, basePackage, trace);
		}
		
		public void serialize(String traceFolderUri, String traceFileName, String svgFileName,
				String testFolderUri, String testFileName, String basePackage, ExecutionTrace trace) throws IOException {
			
			// Model
			Entry<String, Integer> fileNamePair = fileUtil.getFileName(new File(traceFolderUri),
					traceFileName, GammaFileNamer.EXECUTION_XTEXT_EXTENSION);
			String fileName = fileNamePair.getKey();
			Integer id = fileNamePair.getValue();
			serializer.saveModel(trace, traceFolderUri, fileName);
		}
		
		@SuppressWarnings("unused")
		public static class VerificationResult {
			
			private String query;
			private ThreeStateBoolean result;
			private String[] parameters;
			private String executionTime;
			
			public VerificationResult(String query, ThreeStateBoolean result) {
				this(query, result, null, null);
			}
			
			public VerificationResult(String query, ThreeStateBoolean result,
					String[] parameters, String executionTime) {
				this.query = query;
				this.result = result;
				this.parameters = parameters;
				this.executionTime = executionTime;
			}
			
		}
		
	}
	
}