package hu.bme.mit.gamma.scenario.statechart.traversal;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import hu.bme.mit.gamma.expression.model.VariableDeclaration;
import hu.bme.mit.gamma.statechart.statechart.StateNode;
import hu.bme.mit.gamma.statechart.statechart.Transition;

public class Path {

	public Path(Map<VariableDeclaration, Integer> vV, StateNode ls) {
		lastState = ls;
		transitions = new ArrayList<Transition>();
		variableValues = vV;
	}

	private Set<StateNode> visitedStates = new HashSet<StateNode>();

	private StateNode lastState;

	private List<Transition> transitions;

	private List<Boolean> scheduleIsNeeded;

	private Map<VariableDeclaration, Integer> variableValues;

	public StateNode getLastState() {
		return lastState;
	}

	public List<Boolean> getScheduleIsNeeded() {
		return scheduleIsNeeded;
	}

	public void setLastState(StateNode lastState) {
		this.lastState = lastState;
	}

	public void setScheduleIsNeeded(List<Boolean> scheduleIsNeeded) {
		this.scheduleIsNeeded = scheduleIsNeeded;
	}

	public List<Transition> getTransitions() {
		return transitions;
	}

	public void setTransitions(List<Transition> transitions) {
		this.transitions = transitions;
	}

	public Map<VariableDeclaration, Integer> getVariableValues() {
		return variableValues;
	}

	public void setVariableValues(Map<VariableDeclaration, Integer> variableValues) {
		this.variableValues = variableValues;
	}

	public Set<StateNode> getVisitedStates() {
		return visitedStates;
	}

	public void setVisitedStates(Set<StateNode> visitedStates) {
		this.visitedStates = visitedStates;
	}

}
