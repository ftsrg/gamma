package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.trace.model.Assert
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.testgeneration.java.util.TestGeneratorUtil
import java.util.List

class WaitingAllowedInFunction extends AbstractAssertionHandler {
	
	val TestGeneratorUtil testGeneratorutil
	
	new(ExecutionTrace trace, ActAndAssertSerializer serializer) {
		super(trace, serializer)
		testGeneratorutil = new TestGeneratorUtil(trace.component)
	}
	
	override String generateAssertBlock(List<Assert> asserts) '''
		checkGeneralAsserts(new String[] {«FOR _assert : asserts SEPARATOR ", "»«testGeneratorutil.getPortOfAssert(_assert as RaiseEventAct)»«ENDFOR»},
				new String[] {«FOR _assert : asserts SEPARATOR ", "»«testGeneratorutil.getEventOfAssert(_assert as RaiseEventAct)»«ENDFOR»},
				new Object[][] {«FOR _assert : asserts SEPARATOR ", "»«testGeneratorutil.getParamsOfAssert(_assert as RaiseEventAct)»«ENDFOR»});
	'''
	
	def generateWaitingHandlerFunction(String testInstanceName) '''
		private void checkGeneralAsserts(String[] ports, String[] events, Object[][] objects) {
			boolean done = false;
			boolean wasPresent = true;
			int idx = 0;
			 
			while (!done) {
				wasPresent = true;
				try {
					for(int i = 0; i < ports.length; i++) {
						assertTrue(«testInstanceName».isRaisedEvent(ports[i], events[i], objects[i]));
					}
				} catch (AssertionError error) {
					wasPresent= false;
					if (idx > 1) {
						throw error;
					}
				}
				if (wasPresent && idx >= 0) {
					done = true;
				} 
				else {
					«testInstanceName».schedule();
				}
				idx++;
			}
		}
	'''
	
}