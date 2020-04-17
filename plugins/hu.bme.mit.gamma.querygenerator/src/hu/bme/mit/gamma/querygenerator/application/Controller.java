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
import java.util.AbstractMap;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.swing.JComboBox;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine;
import org.eclipse.viatra.query.runtime.emf.EMFScope;
import org.eclipse.viatra.query.runtime.exception.ViatraQueryException;

import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.querygenerator.patterns.InstanceStates;
import hu.bme.mit.gamma.querygenerator.patterns.InstanceVariables;
import hu.bme.mit.gamma.querygenerator.patterns.StatesToLocations;
import hu.bme.mit.gamma.querygenerator.patterns.Subregions;
import hu.bme.mit.gamma.querygenerator.util.GeneratedTestVerifier;
import hu.bme.mit.gamma.querygenerator.util.GuiVerifier;
import hu.bme.mit.gamma.statechart.model.Port;
import hu.bme.mit.gamma.statechart.model.Region;
import hu.bme.mit.gamma.statechart.model.State;
import hu.bme.mit.gamma.statechart.model.interface_.Event;
import hu.bme.mit.gamma.uppaal.verification.patterns.TopSyncSystemOutEvents;
import hu.bme.mit.gamma.uppaal.util.Namings;

public class Controller {

	protected Logger logger = Logger.getLogger("GammaLogger");
	
	private View view;
	
	private ResourceSet resourceSet;
	private ViatraQueryEngine engine;
	private ResourceSet traceabilitySet;
	private ViatraQueryEngine traceEngine;
	// Indicates the actual verification process
	private volatile GuiVerifier verifier;
	// Indicates the actual test generation process
	private volatile GeneratedTestVerifier generatedTestVerifier;
	
	// The location of the model on which this query generator is opened
	// E.g.: F:/eclipse_ws/sc_analysis_comp_oxy/runtime-New_configuration/hu.bme.mit.inf.gamma.tests/model/TestOneComponent.gsm
	private IFile file;

	private final String TEST_GEN_FOLDER_NAME = "test-gen";
	private final String TRACE_FOLDER_NAME = "trace";
	
	public Controller(View view, ResourceSet resourceSet, IFile file) throws ViatraQueryException {
		this.file = file;
		this.view = view;
		this.resourceSet = resourceSet;
		logger.log(Level.INFO, "Resource set content for displaying model elements on GUI: " + resourceSet);
		this.traceabilitySet = loadTraceability(); // For state-location
		logger.log(Level.INFO, "Traceability resource set content: " + traceabilitySet);
		this.engine = ViatraQueryEngine.on(new EMFScope(this.resourceSet));
		this.traceEngine = ViatraQueryEngine.on(new EMFScope(this.traceabilitySet));
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
	
	public void initSelectorWithStates(JComboBox<String> selector) throws ViatraQueryException {
		fillComboBox(selector, getStateNames());
	}
	
	public void initSelectorWithVariables(JComboBox<String> selector) throws ViatraQueryException {
		fillComboBox(selector, getVariableNames());
	}
	
	public void initSelectorWithEvents(JComboBox<String> selector) throws ViatraQueryException {
		List<String> systemOutEventNames = getSystemOutEventNames();
		systemOutEventNames.addAll(getSystemOutEventParameterNames());
		fillComboBox(selector, systemOutEventNames);
	}
	
	public List<String> getStateNames() throws ViatraQueryException {
		List<String> stateNames = new ArrayList<String>();
		for (InstanceStates.Match statesMatch : InstanceStates.Matcher.on(engine).getAllMatches()) {
			String entry = statesMatch.getInstanceName() + "." + getFullRegionPathName(statesMatch.getParentRegion()) + "." + statesMatch.getStateName();
			if (!statesMatch.getState().getName().startsWith("LocalReaction")) {
				stateNames.add(entry);				
			}
		}
		return stateNames;
	}
	
	public List<String> getVariableNames() throws ViatraQueryException {
		List<String> variableNames = new ArrayList<String>();
		for (InstanceVariables.Match variableMatch : InstanceVariables.Matcher.on(engine).getAllMatches()) {
			String entry = variableMatch.getInstance().getName() + "." + variableMatch.getVariable().getName();
			variableNames.add(entry);
		}
		return variableNames;
	}
	
	private String getSystemOutEventName(Port systemPort, Event event) {
		return systemPort.getName() + "." + event.getName();
	}
	
	public List<String> getSystemOutEventNames() throws ViatraQueryException {
		List<String> eventNames = new ArrayList<String>();
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches()) {
			String entry = getSystemOutEventName(eventsMatch.getSystemPort(), eventsMatch.getEvent());
			eventNames.add(entry);
		}
		return eventNames;
	}
	
	private String getSystemOutEventParameterName(Port systemPort, Event event, ParameterDeclaration parameter) {
		return getSystemOutEventName(systemPort, event) + "::" + parameter.getName();
	}
	
	public List<String> getSystemOutEventParameterNames() throws ViatraQueryException {
		List<String> parameterNames = new ArrayList<String>();
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches()) {
			Event event = eventsMatch.getEvent();
			for (ParameterDeclaration parameter : event.getParameterDeclarations()) {
				Port systemPort = eventsMatch.getSystemPort();
				String entry = getSystemOutEventParameterName(systemPort, event, parameter);
				parameterNames.add(entry);
			}
		}
		return parameterNames;
	}
	
	/** Returns the chain of regions from the given lowest region to the top region. 
	 */
	private String getFullRegionPathName(Region lowestRegion) {
		if (!(lowestRegion.eContainer() instanceof State)) {
			return lowestRegion.getName();
		}
		String fullParentRegionPathName = getFullRegionPathName((Region) lowestRegion.eContainer().eContainer());
		return fullParentRegionPathName + "." + lowestRegion.getName(); // Only regions are in path - states could be added too
	}
	
	public String parseRegular(String text, String operator) throws ViatraQueryException {
		String result = text;
		if (text.contains("deadlock")) {
			return text;
		}
		List<String> stateNames = this.getStateNames();
		List<String> variableNames = this.getVariableNames();
		List<String> systemOutEventNames = this.getSystemOutEventNames();
		List<String> systemOutEventParameterNames = this.getSystemOutEventParameterNames();
		for (String stateName : stateNames) {
			if (result.contains("(" + stateName + ")")) {
				String uppaalStateName = getUppaalStateName(stateName);
				// The parentheses need to be \-d
				result = result.replaceAll("\\(" + stateName + "\\)", "\\(" + uppaalStateName + "\\)");
			}
			// Checking the negations
			if (result.contains("(!" + stateName + ")")) {
				String uppaalStateName = getUppaalStateName(stateName);
				// The parentheses need to be \-d
				result = result.replaceAll("\\(!" + stateName + "\\)", "\\(!" + uppaalStateName + "\\)");
			}
		}
		for (String variableName : variableNames) {
			if (result.contains("(" + variableName + ")")) {
				String uppaalVariableName = getUppaalVariableName(variableName);
				result = result.replaceAll("\\(" + variableName + "\\)", "\\(" + uppaalVariableName + "\\)");
			}
			// Checking the negations
			if (result.contains("(!" + variableName + ")")) {
				String uppaalVariableName = getUppaalVariableName(variableName);
				result = result.replaceAll("\\(!" + variableName + "\\)", "\\(!" + uppaalVariableName + "\\)");
			}
		}
		for (String systemOutEventName : systemOutEventNames) {
			if (result.contains("(" + systemOutEventName + ")")) {
				String uppaalVariableName = getUppaalOutEventName(systemOutEventName);
				result = result.replaceAll("\\(" + systemOutEventName + "\\)", "\\(" + uppaalVariableName + "\\)");
			}
			// Checking the negations
			if (result.contains("(!" + systemOutEventName + ")")) {
				String uppaalVariableName = getUppaalOutEventName(systemOutEventName);
				result = result.replaceAll("\\(!" + systemOutEventName + "\\)", "\\(!" + uppaalVariableName + "\\)");
			}
		}
		for (String systemOutEventParameterName : systemOutEventParameterNames) {
			if (result.contains("(" + systemOutEventParameterName + ")")) {
				String uppaalVariableName = getUppaalOutEventParameterName(systemOutEventParameterName);
				result = result.replaceAll("\\(" + systemOutEventParameterName + "\\)", "\\(" + uppaalVariableName + "\\)");
			}
			// Checking the negations
			if (result.contains("(!" + systemOutEventParameterName + ")")) {
				String uppaalVariableName = getUppaalOutEventParameterName(systemOutEventParameterName);
				result = result.replaceAll("\\(!" + systemOutEventParameterName + "\\)", "\\(!" + uppaalVariableName + "\\)");
			}
		}
		result = "(" + result + ")";
		if (!operator.equals(View.MIGHT_ALWAYS) && !operator.equals(View.MUST_ALWAYS)) {
			// It is pointless to add isStable in the case of A[] and E[]
			result += " && isStable";
		}
		else {
			// Instead this is added
			result += " || !isStable";
		}
		return result;
	}
	
	private String getUppaalStateName(String stateName) throws ViatraQueryException {
		logger.log(Level.INFO, stateName);
		String[] splittedStateName = stateName.split("\\.");
		for (InstanceStates.Match match : InstanceStates.Matcher.on(engine).getAllMatches(null, splittedStateName[0],
				null, splittedStateName[splittedStateName.length - 2] /* parent region */,
				null, splittedStateName[splittedStateName.length - 1] /* state */)) {
			Region parentRegion = match.getParentRegion();
			String templateName = getRegionName(parentRegion) + "Of" + splittedStateName[0] /* instance name */;
			String processName = "P_" + templateName;
			StringBuilder locationNames = new StringBuilder("(");
			for (String locationName : StatesToLocations.Matcher.on(traceEngine).getAllValuesOflocationName(null,
					match.getState().getName(),
					templateName /*Must define templateName too as there are states with the same (same statechart types)*/)) {
				String templateLocationName = processName +  "." + locationName;
				if (locationNames.length() == 1) {
					// First append
					locationNames.append(templateLocationName);
				}
				else {
					locationNames.append(" || " + templateLocationName);
				}
			}
			locationNames.append(")");
			if (isSubregion(parentRegion)) {
				locationNames.append(" && " + processName + ".isActive"); 
			}
			return locationNames.toString();
		}
		throw new IllegalArgumentException("Not known state!");
	}
	
	private String getUppaalVariableName(String variableName) throws ViatraQueryException {		
		String[] splittedStateName = variableName.split("\\.");
		return splittedStateName[1] + "Of" + splittedStateName[0];
	}
	
	private String getUppaalOutEventName(String portEventName) throws ViatraQueryException {
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches()) {
			String name = getSystemOutEventName(eventsMatch.getSystemPort(), eventsMatch.getEvent());
			if (name.equals(portEventName)) {
				return Namings.getOutEventName(eventsMatch.getEvent(), eventsMatch.getPort(), eventsMatch.getInstance());
			}
		}
		throw new IllegalArgumentException("Not known system event: " + portEventName);
	}
	
	private String getUppaalOutEventParameterName(String portEventParameterName) throws ViatraQueryException {
		for (TopSyncSystemOutEvents.Match eventsMatch : TopSyncSystemOutEvents.Matcher.on(engine).getAllMatches()) {
			Port systemPort = eventsMatch.getSystemPort();
			Event event = eventsMatch.getEvent();
			for (ParameterDeclaration parameter : event.getParameterDeclarations()) {
				if (portEventParameterName.equals(getSystemOutEventParameterName(systemPort, event, parameter))) {
					return Namings.getValueOfName(event, eventsMatch.getPort(), eventsMatch.getInstance());
				}
			}
		}
		throw new IllegalArgumentException("Not known system event: " + portEventParameterName);
	}
	
	private boolean isSubregion(Region region) throws ViatraQueryException {
		return Subregions.Matcher.on(engine).countMatches(region, null) > 0;
	}
	
	/**
     * Returns the template name of a region.
     */
    private String getRegionName(Region region) throws ViatraQueryException {
    	String templateName;
    	if (isSubregion(region)) {
			templateName = (region.getName() + "Of" + ((State) region.eContainer()).getName());
		}
		else {			
			templateName = (region.getName()  + "OfStatechart");
		}
		return templateName.replaceAll(" ", "");
	}
    
    private void fillComboBox(JComboBox<String> selector, List<String> entryList) {
    	Collections.sort(entryList);
    	for (String item : entryList) {
    		selector.addItem(item);
    	}
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
	
	public ResourceSet loadTraceability() {
		ResourceSet resourceSet = new ResourceSetImpl();
		logger.log(Level.INFO, "Resource set created for traceability: " + resourceSet);
		URI fileURI = URI.createFileURI(getTraceabilityFile());
		try {
			resourceSet.getResource(fileURI, true);
		} catch (RuntimeException e) {
			e.printStackTrace();
			return null;
		}
		return resourceSet;
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