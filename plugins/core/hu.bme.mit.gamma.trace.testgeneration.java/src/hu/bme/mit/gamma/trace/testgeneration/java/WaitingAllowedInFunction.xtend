/********************************************************************************
 * Copyright (c) 2018-2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.trace.testgeneration.java

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import java.util.List

class WaitingAllowedInFunction extends AbstractAssertionHandler {
	
	
	new(ExecutionTrace trace, ActAndAssertSerializer serializer) {
		super(trace, serializer)
	}
	
	override String generateAssertBlock(List<Expression> asserts) '''
		«IF asserts.size == 1» 
			checkGeneralAssert(() -> «serializer.serializeAssert(asserts.head)»);
		«ELSEIF asserts.size > 1» 
			checkGeneralAsserts(Arrays.asList(«FOR _assert : asserts SEPARATOR ", "»() -> «serializer.serializeAssert(_assert)»«ENDFOR»));
		«ENDIF»
	'''
	
	
	def generateWaitingHandlerFunction(String testInstanceName) '''
		private void checkGeneralAssert(BooleanSupplier predicate) {
			checkGeneralAsserts(Arrays.asList(predicate));
		}
	
		private void checkGeneralAsserts(List<BooleanSupplier> predicates) {
			boolean done = false;
			boolean wasPresent = true;
			int idx = 0;
			 
			while (!done) {
				wasPresent = true;
				try {
					for(int i = 0; i < predicates.size(); i++) {
						assertTrue(predicates.get(i).getAsBoolean());
					}
				} catch (AssertionError error) {
					wasPresent= false;
					if (idx > «max») {
						throw error;
					}
				}
				if (wasPresent && idx >= «min») {
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