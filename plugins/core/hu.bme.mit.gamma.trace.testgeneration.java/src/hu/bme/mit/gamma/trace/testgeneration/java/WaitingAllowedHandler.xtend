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

class WaitingAllowedHandler extends AbstractAssertionHandler {

	new(ExecutionTrace trace, ActAndAssertSerializer serializer) {
		super(trace, serializer)
		if (min == -1 && max == -1) {
			throw (new IllegalArgumentException(
				'''ExecutionTrace «trace.name» is not equiped with an AllowedWaiting annotation'''))
		}
	}

	override generateAssertBlock(List<Expression> asserts) {
		if (asserts.nullOrEmpty) {
			return ''''''
		}
		return '''
			boolean done = false;
			boolean wasPresent = true;
			int idx = 0;
			
			while (!done) {
				wasPresent = true;
				try {
					«FOR _assert : asserts»
						assertTrue(«serializer.serializeAssert(_assert)»);
					«ENDFOR»
				} catch (AssertionError error) {
					wasPresent = false;
					if (idx > «max») {
						throw(error);
					}
				}
				if (wasPresent && idx >= «min») {
					done = true;
				}
				else {
					«schedule»
				}
				idx++;
			}
		'''
	}

}