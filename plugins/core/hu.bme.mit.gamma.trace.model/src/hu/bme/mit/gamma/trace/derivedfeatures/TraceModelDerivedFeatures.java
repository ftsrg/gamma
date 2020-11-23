package hu.bme.mit.gamma.trace.derivedfeatures;

import java.util.ArrayList;
import java.util.List;

import hu.bme.mit.gamma.trace.model.Assert;
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration;
import hu.bme.mit.gamma.trace.model.InstanceVariableState;
import hu.bme.mit.gamma.trace.model.NegatedAssert;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;
import hu.bme.mit.gamma.trace.model.Step;

public class TraceModelDerivedFeatures {
	
	public static Assert getLowermostAssert(Assert assertion) {
		if (assertion instanceof NegatedAssert) {
			NegatedAssert negatedAssert = (NegatedAssert) assertion;
			return getLowermostAssert(negatedAssert.getNegatedAssert());
		}
		return assertion;
	}

	
	// Views

	public static List<RaiseEventAct> getOutEvents(Step step) {
		List<RaiseEventAct> outEvents = new ArrayList<RaiseEventAct>();
		for (Assert assertion : step.getAsserts()) {
			if (assertion instanceof RaiseEventAct) {
				outEvents.add((RaiseEventAct) assertion);
			}
		}
		return outEvents;
	}

	public static List<InstanceStateConfiguration> getInstanceStateConfigurations(Step step) {
		List<InstanceStateConfiguration> states = new ArrayList<InstanceStateConfiguration>();
		for (Assert assertion : step.getAsserts()) {
			if (assertion instanceof InstanceStateConfiguration) {
				states.add((InstanceStateConfiguration) assertion);
			}
		}
		return states;
	}
	
	public static List<InstanceVariableState> getInstanceVariableStates(Step step) {
		List<InstanceVariableState> states = new ArrayList<InstanceVariableState>();
		for (Assert assertion : step.getAsserts()) {
			if (assertion instanceof InstanceVariableState) {
				states.add((InstanceVariableState) assertion);
			}
		}
		return states;
	}
	
}
