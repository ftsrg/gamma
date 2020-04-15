package hu.bme.mit.gamma.trace.model;

import java.util.List;

import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.util.EcoreUtil.EqualityHelper;

public class TraceUtil {

	public boolean isOverWritten(RaiseEventAct lhs, RaiseEventAct rhs) {
		return lhs.getPort() == rhs.getPort() && lhs.getEvent() == rhs.getEvent();
	}
	
	public void removeCoveredExecutionTraces(List<ExecutionTrace> traces) {
		for (int i = 0; i < traces.size() - 1; ++i) {
			ExecutionTrace lhs = traces.get(i);
			for (int j = i + 1; j < traces.size(); ++j) {
				ExecutionTrace rhs = traces.get(j);
			}
		}
	}
	
	public boolean isCovered(ExecutionTrace covered, ExecutionTrace covering) {
		return isCovered(covered.getSteps(), covering.getSteps());
	}
	
	public boolean isCovered(List<Step> covered, List<Step> covering) {
		for (int i = 0; i < covered.size(); i++) {
			if (!isCovered(covered.get(i), covering.get(i))) {
				return false;
			}
		}
		return true;
	}
	
	public boolean isCovered(Step covered, Step covering) {
		// Only input actions are covered
		for (Act act : covered.getActions()) {
			boolean isEqual = covering.getActions().stream().anyMatch(it -> equalsTo(act, it));
			if (!isEqual) {
				return false;
			}
		}
		return true;
	}
	
	public boolean equalsTo(EObject lhs, EObject rhs) {
		EqualityHelper helper = new EqualityHelper();
		return helper.equals(lhs, rhs);
	}
	
}
