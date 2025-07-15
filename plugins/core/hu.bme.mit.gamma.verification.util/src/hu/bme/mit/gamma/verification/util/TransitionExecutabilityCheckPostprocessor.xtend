/********************************************************************************
 * Copyright (c) 2025 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.statechart.composite.ComponentInstanceReferenceExpression
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import java.util.Collection
import java.util.List
import java.util.Map.Entry

class TransitionExecutabilityCheckPostprocessor extends VerificationPostprocessor {
	//
	protected final List<Collection<? extends Entry<
			ComponentInstanceReferenceExpression, Transition>>> executedTransitions = newArrayList
	//
	
	override execute(ExecutionTrace trace) {
		trace.saveTrace
		
		return executedTransitions
	}
	
		
	//
	
	def getExecutedTransitions() {
		return executedTransitions
	}
	
	//
	
}