package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.trace.testgeneration.java.AbstractAllowedWaitingHandler
import hu.bme.mit.gamma.trace.model.ExecutionTrace

class WaitingAllowedHandler extends AbstractAllowedWaitingHandler {
	
	new(ExecutionTrace trace, String schedule, String asserts){
		super(trace, schedule, asserts)
	}
	
	
	override generateAssertBlock() {
		'''
		boolean done = false;
		boolean notPresent = false;
		int idx=0;
		
		while(!done) {
			notPresent = false;
			try {
				«asserts»
				} catch (AssertionError error) {
				notPresent= true;
				if(idx>«max») {
					throw(error);
				}
			}
			if(!notPresent && idx>=«min») {
				done=true;
			}
			else
			{
				«schedule»
			}
			idx++;
		}
		'''
	}
	
}