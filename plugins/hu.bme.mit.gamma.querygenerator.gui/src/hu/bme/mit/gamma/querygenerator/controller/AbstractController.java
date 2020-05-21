package hu.bme.mit.gamma.querygenerator.controller;

import java.util.Collections;
import java.util.List;
import java.util.logging.Logger;

import javax.swing.JComboBox;

import hu.bme.mit.gamma.querygenerator.AbstractQueryGenerator;
import hu.bme.mit.gamma.querygenerator.operators.TemporalOperator;

public abstract class AbstractController {
	
	protected Logger logger = Logger.getLogger("GammaLogger");
	// Has to be set by subclass
	protected AbstractQueryGenerator queryGenerator;
	
	/**
	 * Starts the verification process with the given query.
	 */
	public abstract void verify(String query);
	
	/**
	 * Cancels the actual verification process. Returns true if a process has been cancelled.
	 */
	public abstract boolean cancelVerification();
	
	/**
	 * Executes the generated queries.
	 */
	public abstract void executeGeneratedQueries();
	
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
	
}
