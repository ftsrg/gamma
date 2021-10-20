package hu.bme.mit.gamma.trace.testgeneration.java

import java.util.List
import hu.bme.mit.gamma.trace.model.Assert
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.testgeneration.java.util.TestGeneratorUtil
import hu.bme.mit.gamma.trace.model.RaiseEventAct

class WaitingAllowedInFunction extends AbstractAllowedWaitingHandler {
	
	val TestGeneratorUtil testGeneratorutil ;
	
	new(ExecutionTrace trace, ActAndAssertSerializer serializer) {
		super(trace, serializer)
		testGeneratorutil = new TestGeneratorUtil(trace.component);
	}
	
	

	override String generateAssertBlock(List<Assert> asserts) '''
		String[] ports = new String[]{«FOR _assert : asserts SEPARATOR ","»«testGeneratorutil.getPortOfAssert(_assert as RaiseEventAct)»«ENDFOR»};
		String[] events = new String[]{«FOR _assert : asserts SEPARATOR ","»«testGeneratorutil.getEventOfAssert(_assert as RaiseEventAct)»«ENDFOR»};
		Object[][] objects = new Object[][]{«FOR _assert : asserts SEPARATOR ","»«testGeneratorutil.getParamsOfAssert(_assert as RaiseEventAct)»«ENDFOR»};
		checkGeneralAsserts(ports,events,objects);
	'''
}
