package hu.bme.mit.gamma.transformation.util.reducer

import hu.bme.mit.gamma.property.model.StateFormula
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import java.util.Collection

class CoveredPropertyReducer implements Reducer {
	
	protected final Collection<StateFormula> formulas
	protected final ExecutionTrace trace
	
	new(Collection<StateFormula> formulas, ExecutionTrace trace) {
		this.formulas = formulas
		this.trace = trace
	}
	
	override execute() {
	
	}	
}