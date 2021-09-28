package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.trace.model.Assert
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import java.util.List

class DefaultAssertionHandler extends AbstractAssertionHandler {

	new(ExecutionTrace trace, ActAndAssertSerializer serializer) {
		super(trace, serializer)
	}

	override generateAssertBlock(List<Assert> asserts) '''
		«FOR _assert : asserts»
			assertTrue(«serializer.serializeAssert(_assert)»);
		«ENDFOR»
	'''

}
