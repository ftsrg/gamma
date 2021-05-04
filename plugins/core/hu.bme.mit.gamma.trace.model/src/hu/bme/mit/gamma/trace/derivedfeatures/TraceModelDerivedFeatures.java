package hu.bme.mit.gamma.trace.derivedfeatures;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures;
import hu.bme.mit.gamma.expression.model.ArgumentedElement;
import hu.bme.mit.gamma.expression.model.ParameterDeclaration;
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance;
import hu.bme.mit.gamma.statechart.interface_.Event;
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction;
import hu.bme.mit.gamma.statechart.statechart.State;
import hu.bme.mit.gamma.trace.model.Assert;
import hu.bme.mit.gamma.trace.model.ExecutionTrace;
import hu.bme.mit.gamma.trace.model.InstanceStateConfiguration;
import hu.bme.mit.gamma.trace.model.InstanceVariableState;
import hu.bme.mit.gamma.trace.model.NegatedAssert;
import hu.bme.mit.gamma.trace.model.RaiseEventAct;
import hu.bme.mit.gamma.trace.model.Step;

public class TraceModelDerivedFeatures extends ExpressionModelDerivedFeatures {
	
	public static List<ParameterDeclaration> getParameterDeclarations(ArgumentedElement element) {
		if (element instanceof RaiseEventAction) {
			RaiseEventAction raiseEventAction = (RaiseEventAction) element;
			Event event = raiseEventAction.getEvent();
			return event.getParameterDeclarations();
		}
		if (element instanceof ExecutionTrace) {
			ExecutionTrace trace = (ExecutionTrace) element;
			return trace.getComponent().getParameterDeclarations();
		}
		throw new IllegalArgumentException("Not supported element: " + element);
	}
	
	//
	
	public static Assert getLowermostAssert(Assert assertion) {
		if (assertion instanceof NegatedAssert) {
			NegatedAssert negatedAssert = (NegatedAssert) assertion;
			return getLowermostAssert(negatedAssert.getNegatedAssert());
		}
		return assertion;
	}

	
	// Views
	
	public static Step getLastStep(ExecutionTrace trace) {
		List<Step> steps = trace.getSteps();
		int size = steps.size();
		return steps.get(size - 1); 
	}

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
	
	public static Map<SynchronousComponentInstance, Set<State>> groupInstanceStateConfigurations(Step step) {
		Map<SynchronousComponentInstance, Set<State>> instanceStates =
				new HashMap<SynchronousComponentInstance, Set<State>>();
		List<InstanceStateConfiguration> stateConfigurations = getInstanceStateConfigurations(step);
		for (InstanceStateConfiguration stateConfiguration : stateConfigurations) {
			SynchronousComponentInstance instance = stateConfiguration.getInstance();
			State state = stateConfiguration.getState();
			if (!instanceStates.containsKey(instance)) {
				instanceStates.put(instance, new HashSet<State>());
			}
			Set<State> states = instanceStates.get(instance);
			states.add(state);
		}
		return instanceStates;
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
