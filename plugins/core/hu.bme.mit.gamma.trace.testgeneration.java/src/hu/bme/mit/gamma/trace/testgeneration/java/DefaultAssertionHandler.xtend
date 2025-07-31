/********************************************************************************
 * Copyright (c) 2018-2025 Contributors to the Gamma project
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
import hu.bme.mit.gamma.expression.model.OpaqueExpression

class DefaultAssertionHandler extends AbstractAssertionHandler {

	new(ExecutionTrace trace, ActAndAssertSerializer serializer) {
		super(trace, serializer)
	}

	override generateAssertBlock(List<Expression> asserts) '''
		«FOR _assert : asserts»
			«val string = serializer.serializeAssert(_assert)»
			«IF _assert instanceof OpaqueExpression»
				«string»
			«ELSE»
				assertTrue(«string»);
			«ENDIF»
		«ENDFOR»
	'''

}
