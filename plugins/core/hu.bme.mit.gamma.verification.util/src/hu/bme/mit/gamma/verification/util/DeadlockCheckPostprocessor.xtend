/********************************************************************************
 * Copyright (c) 2026 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.verification.result.ThreeStateBoolean
import hu.bme.mit.gamma.verification.util.AbstractVerifier.Result

class DeadlockCheckPostprocessor extends VerificationPostprocessor {
	
	protected boolean deadlock
	
	override execute(Result result) {
		val res = result.result
		deadlock = res == ThreeStateBoolean.FALSE
		return deadlock
	}
	
	override execute(ExecutionTrace trace) {
		deadlock = trace !== null
		return deadlock
	}
	
	def isDeadlock() {
		return deadlock
	}
	
}