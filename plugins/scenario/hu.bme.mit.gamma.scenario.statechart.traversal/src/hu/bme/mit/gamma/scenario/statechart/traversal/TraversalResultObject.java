package hu.bme.mit.gamma.scenario.statechart.traversal;

import java.util.List;

public class TraversalResultObject {

	List<Path> accepting;
	List<Path> error;

	public List<Path> getAccepting() {
		return accepting;
	}

	public void setAccepting(List<Path> accepting) {
		this.accepting = accepting;
	}

	public List<Path> getError() {
		return error;
	}

	public void setError(List<Path> error) {
		this.error = error;
	}

}
