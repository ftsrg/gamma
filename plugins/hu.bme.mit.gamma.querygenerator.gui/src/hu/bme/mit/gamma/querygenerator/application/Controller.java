/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.application;

import java.io.File;
import java.io.IOException;
import java.util.AbstractMap;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

import javax.swing.JComboBox;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.emf.common.util.URI;

import hu.bme.mit.gamma.expression.util.ExpressionUtil;
import hu.bme.mit.gamma.querygenerator.QueryGenerator;
import hu.bme.mit.gamma.querygenerator.gui.util.GeneratedTestVerifier;
import hu.bme.mit.gamma.querygenerator.gui.util.GuiVerifier;
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator;
import hu.bme.mit.gamma.uppaal.transformation.traceability.G2UTrace;

public class Controller {

	protected Logger logger = Logger.getLogger("GammaLogger");
	
	private View view;
	
	private final QueryGenerator queryGenerator;
	// Indicates the actual verification process
	private volatile GuiVerifier verifier;
	// Indicates the actual test generation process
	private volatile GeneratedTestVerifier generatedTestVerifier;
	
	// The location of the model on which this query generator is opened
	// E.g.: F:/eclipse_ws/sc_analysis_comp_oxy/runtime-New_configuration/hu.bme.mit.inf.gamma.tests/model/TestOneComponent.gsm
	private IFile file;
	
	// Util
	private ExpressionUtil expressionUtil = new ExpressionUtil();

	private final String TEST_GEN_FOLDER_NAME = "test-gen";
	private final String TRACE_FOLDER_NAME = "trace";
	
	public Controller(View view, IFile file) throws IOException {
		this.file = file;
		this.view = view;
		this.queryGenerator = new QueryGenerator(loadTraceability()); // For state-location
	}
	
	public GuiVerifier getVerifier() {
		return verifier;
	}

	public void setVerifier(GuiVerifier verifier) {
		this.verifier = verifier;
	}

	public GeneratedTestVerifier getGeneratedTestVerifier() {
		return generatedTestVerifier;
	}

	public void setGeneratedTestVerifier(GeneratedTestVerifier generatedTestVerifier) {
		this.generatedTestVerifier = generatedTestVerifier;
	}
	
	public void initSelectorWithStates(JComboBox<String> selector) {
		fillComboBox(selector, queryGenerator.getStateNames());
	}
	
	public void initSelectorWithVariables(JComboBox<String> selector) {
		fillComboBox(selector, queryGenerator.getVariableNames());
	}
	
	public void initSelectorWithEvents(JComboBox<String> selector) {
		List<String> systemOutEventNames = queryGenerator.getSystemOutEventNames();
		systemOutEventNames.addAll(queryGenerator.getSystemOutEventParameterNames());
		fillComboBox(selector, systemOutEventNames);
	}
	
    private void fillComboBox(JComboBox<String> selector, List<String> entryList) {
    	Collections.sort(entryList);
    	for (String item : entryList) {
    		selector.addItem(queryGenerator.unwrap(item));
    	}
    }
    
	public String parseRegularQuery(String text, String temporalOperator) {
		TemporalOperator operator = TemporalOperator.valueOf(
				temporalOperator.replaceAll(" ", "_").replace("\"", "").toUpperCase());
		return queryGenerator.parseRegularQuery(text, operator);
	}
	
	public String parseLeadsToQuery(String first, String second) {
		return queryGenerator.parseLeadsToQuery(first, second);
	}

    /**
     * Returns the next valid name for the file containing the back-annotation.
     */
    public Map.Entry<String, Integer> getFileName(String fileExtension) throws CoreException {
    	final String TRACE_FILE_NAME = "ExecutionTrace";
    	List<Integer> usedIds = new ArrayList<Integer>();
    	File traceFile = new File(getTraceFolder());
    	traceFile.mkdirs();
    	// Searching the trace folder for highest id
    	for (File file: new File(getTraceFolder()).listFiles()) {
    		if (file.getName().matches(TRACE_FILE_NAME + "[0-9]+\\..*")) {
    			String id = file.getName().substring(TRACE_FILE_NAME.length(), file.getName().length() - ("." + fileExtension).length());
    			usedIds.add(Integer.parseInt(id));
    		}
    	}
    	if (usedIds.isEmpty()) {
    		return new AbstractMap.SimpleEntry<String, Integer>(TRACE_FILE_NAME + "0." + fileExtension, 0);
    	}
    	Collections.sort(usedIds);
    	Integer biggestId = usedIds.get(usedIds.size() - 1);
    	return new AbstractMap.SimpleEntry<String, Integer>(
    			TRACE_FILE_NAME + (biggestId + 1) + "." + fileExtension, (biggestId + 1));
    }
    
    public IProject getProject() {
		return file.getProject();
	}
    
    public String getTestGenFolder() {
		return file.getProject().getLocation() + File.separator + TEST_GEN_FOLDER_NAME;
	}
    
    public String getTraceFolder() {
		return URI.decode(file.getProject().getLocation() + File.separator + TRACE_FOLDER_NAME);
	}
    
	public String getParentFolder() {
		return getLocation(file).substring(0, getLocation(file).lastIndexOf("/"));
	}
	
	private String getCompositeSystemName() {
		return getLocation(file).substring(getLocation(file).lastIndexOf("/") + 1, getLocation(file).lastIndexOf("."));
	}
	
	private String getTraceabilityFile() {
		return getParentFolder() + File.separator + "." + getCompositeSystemName() + ".g2u"; 
	}
	
	public String getGeneratedQueryFile() {
		return getParentFolder() + File.separator + getCompositeSystemName() + ".q"; 
	}
	
	public String getUppaalXmlFile() {
		return getLocation(file).substring(0, getLocation(file).lastIndexOf(".")) + ".xml";
	}
	
	private String getLocation(IFile file) {
		return URI.decode(file.getLocation().toString());
	}
	
	public G2UTrace loadTraceability() throws IOException {
		URI fileURI = URI.createFileURI(getTraceabilityFile());
		return (G2UTrace) expressionUtil.normalLoad(fileURI);
	}
	
	/**
	 * Cancels the actual verification process. Returns true if a process has been cancelled.
	 */
	public boolean cancelVerification() {
		if (verifier != null) {
			verifier.cancelProcess(true);
			return true;
		}
		if (generatedTestVerifier != null) {
			generatedTestVerifier.cancelProcess();
			return true;
		}
		return false;
	}
	
	/**
	 * Verifies the given Uppaal query.
	 */
	public void verify(String uppaalQuery) {
		verifier = new GuiVerifier(uppaalQuery, true, view, this);
		// Starting the worker
		verifier.execute();
	}
    
    /**
     * Verifies the generated Uppaal queries.
     */
    public void executeGeneratedQueries() {
    	generatedTestVerifier = new GeneratedTestVerifier(this.view, this);
		Thread thread = new Thread(generatedTestVerifier);
    	thread.start();
    }
	
	public String getParameters() {
		return getStateSpaceRepresentation() + " " + getSearchOrder() + " " + getDiagnosticTrace() + " " +
				getResuseStateSpace() + " " +	" " + getHashtableSize() + " " + getStateSpaceReduction();
	}
	
	private String getSearchOrder() {
		final String paremterName = "-o ";
		switch (view.getSelectedSearchOrder()) {
		case "Breadth First":
			return paremterName + "0";
		case "Depth First":
			return paremterName + "1";
		case "Random Depth First":
			return paremterName + "2";
		case "Optimal First":
			if (view.getSelectedTrace().equals("Shortest") || view.getSelectedTrace().equals("Fastest")) {
				return paremterName + "3";	
			}
			// BFS
			return paremterName + "0"; 
		case "Random Optimal Depth First":
			if (view.getSelectedTrace().equals("Shortest") || view.getSelectedTrace().equals("Fastest")) {
				return paremterName + "4";
			}
			// BFS
			return paremterName + "0"; 
		default:
			throw new IllegalArgumentException("Not known option: " + view.getSelectedSearchOrder());
		}
	}
	
	private String getStateSpaceRepresentation() {
		switch (view.getStateSpaceRepresentation()) {
		case "DBM":
			return "-C";
		case "Over Approximation":
			return "-A";
		case "Under Approximation":
			return "-Z";
		default:
			throw new IllegalArgumentException("Not known option: " + view.getStateSpaceRepresentation());
		}
	}
	
	private String getHashtableSize() {
		/* -H n
	      Set hash table size for bit state hashing to 2**n
	      (default = 27)
		 */
		final String paremterName = "-H ";
		final int value = view.getHashTableSize();
		final int exponent = 20 + (int) Math.floor(Math.log10(value) / Math.log10(2)); // log2(value)
		return paremterName + exponent;
	}
	
	private String getStateSpaceReduction() {
		final String paremterName = "-S ";
		switch (view.getStateSpaceReduction()) {
		case "None":
			// BFS
			return paremterName + "0";
		case "Conservative":
			// DFS
			return paremterName + "1";
		case "Aggressive":
			// Random DFS
			return paremterName + "2";			
		default:
			throw new IllegalArgumentException("Not known option: " + view.getStateSpaceReduction());
		}
	}
	
	private String getResuseStateSpace() {
		if (view.isReuseStateSpace()) {
			return "-T";
		}
		return "";
	}
	
	private String getDiagnosticTrace() {
		switch (view.getSelectedTrace()) {
		case "Some":
			// Some trace
			return "-t0";
		case "Shortest":
			// Shortest trace
			return "-t1";
		case "Fastest":
			// Fastest trace
			return "-t2";			
		default:
			throw new IllegalArgumentException("Not known option: " + view.getSelectedTrace());
		}
	}
    
}