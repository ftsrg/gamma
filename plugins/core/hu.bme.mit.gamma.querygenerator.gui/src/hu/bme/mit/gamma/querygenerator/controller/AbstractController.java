/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.querygenerator.controller;

import java.io.File;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

import javax.swing.JComboBox;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IResource;
import org.eclipse.emf.common.util.URI;

import hu.bme.mit.gamma.querygenerator.AbstractQueryGenerator;
import hu.bme.mit.gamma.querygenerator.application.View;
import hu.bme.mit.gamma.querygenerator.gui.util.GeneratedTestVerifier;
import hu.bme.mit.gamma.querygenerator.gui.util.GuiVerifier;
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator;
import hu.bme.mit.gamma.util.FileUtil;
import hu.bme.mit.gamma.util.GammaEcoreUtil;
import hu.bme.mit.gamma.verification.util.AbstractVerifier;

public abstract class AbstractController {
	// Has to be set by subclass
	protected AbstractQueryGenerator queryGenerator;
	// View
	protected View view;
	// Indicates the actual verification process
	private volatile GuiVerifier verifier;
	// Indicates the actual test generation process
	private volatile GeneratedTestVerifier generatedTestVerifier;
	
	// The location of the model on which this query generator is opened
	// E.g.: F:/eclipse_ws/sc_analysis_comp_oxy/runtime-New_configuration/hu.bme.mit.inf.gamma.tests/model/TestOneComponent.gsm
	protected IFile file;
	
	// Util
	protected final GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE;
	protected final FileUtil fileUtil = FileUtil.INSTANCE;
	protected final Logger logger = Logger.getLogger("GammaLogger");

	protected final String TEST_GEN_FOLDER_NAME = "test-gen";
	protected final String TRACE_FOLDER_NAME = "trace";
	
	/**
	 * Starts the verification process with the given query.
	 */
	public void verify(String query) {
		verifier = new GuiVerifier(query, true, view);
		// Starting the worker
		verifier.execute();
	}
	
	/**
	 * Executes the generated queries.
	 */
    public void executeGeneratedQueries() {
    	generatedTestVerifier = new GeneratedTestVerifier(this.view, this);
		Thread thread = new Thread(generatedTestVerifier);
    	thread.start();
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
	
	// View setting
	
	public void initSelectorWithStates(JComboBox<String> selector) {
		fillComboBox(selector, queryGenerator.getStateNames());
	}
	
	public void initSelectorWithVariables(JComboBox<String> selector) {
		fillComboBox(selector, queryGenerator.getVariableNames());
	}
	
	public void initSelectorWithEvents(JComboBox<String> selector) {
		List<String> systemOutEventNames = queryGenerator.getSynchronousSystemOutEventNames();
		systemOutEventNames.addAll(queryGenerator.getSynchronousSystemOutEventParameterNames());
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
	
	// Parameter and file manipulation
	
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
	
    /**
     * Returns the next valid name for the file containing the back-annotation.
     */
    public Map.Entry<String, Integer> getFileName(String fileExtension) {
    	File traceFolder = new File(getTraceFolder());
    	return fileUtil.getFileName(traceFolder, "ExecutionTrace", fileExtension);
    }
    
	protected String getCompositeSystemName() {
		return getLocation(file).substring(getLocation(file).lastIndexOf("/") + 1, getLocation(file).lastIndexOf("."));
	}
    
    protected String getLocation(IResource file) {
    	return URI.decode(file.getLocation().toString());
    }
    
    protected String getParentFolder() {
		return getLocation(file.getParent());
	}
    
    public String getBasePackage() {
		return file.getProject().getName().toLowerCase();
	}
    
    protected String getUnwrappedFile() {
		return getParentFolder() + File.separator + "." + getCompositeSystemName() + ".gsm";
	}
    
    public String getTestGenFolder() {
		return getLocation(file.getProject()) + File.separator + TEST_GEN_FOLDER_NAME;
	}
    
    public String getTraceFolder() {
		return getLocation(file.getProject()) + File.separator + TRACE_FOLDER_NAME;
	}
    
	public abstract AbstractVerifier createVerifier();
	
	public abstract String getParameters();
	public abstract String getModelFile();
	public abstract String getGeneratedQueryFile();
	public abstract Object getTraceability();
	
}
