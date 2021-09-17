package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.trace.testgeneration.java.AbstractAllowedWaitingHandler
import hu.bme.mit.gamma.trace.model.ExecutionTrace

class NoWaitingAllowedHandler extends AbstractAllowedWaitingHandler {
	
	new(ExecutionTrace trace, String schedule, String asserts) {
		super(trace, schedule,asserts)
	}
	
	override generateAssertBlock() {
		'''
		«asserts»
		'''
	}
	
}