/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer

import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.model.XTransition
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

class XstsOptimizer {
	// Singleton
	public static final XstsOptimizer INSTANCE =  new XstsOptimizer
	protected new() {}
	//
	
	protected final extension ActionOptimizer actionOptimizer = ActionOptimizer.INSTANCE
	protected final extension TransientVariableRemover transientVariableRemover = TransientVariableRemover.INSTANCE
	protected final extension VariableInliner variableInliner = VariableInliner.INSTANCE
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil actionFactory = XstsActionUtil.INSTANCE
	protected final extension XSTSModelFactory xStsModelFactory = XSTSModelFactory.eINSTANCE
	
	def optimizeXSts(XSTS xSts) {
		// Initial optimize iteration
		xSts.variableInitializingTransition = xSts.variableInitializingTransition.optimize
		xSts.configurationInitializingTransition = xSts.configurationInitializingTransition.optimize
		xSts.entryEventTransition = xSts.entryEventTransition.optimize
		xSts.changeTransitions(xSts.transitions.optimize)
		xSts.inEventTransition = xSts.inEventTransition.optimize
		xSts.outEventTransition = xSts.outEventTransition.optimize
		
		// Multiple inline-optimize iterations until fixpoint is reached
		xSts.entryEventTransition = xSts.entryEventTransition.optimizeTransition
		xSts.changeTransitions(xSts.transitions.optimizeTransitions)
		
		// Finally, removing unreferenced transient variables
		xSts.removeTransientVariables
	}
	
	def optimizeTransitions(Iterable<? extends XTransition> transitions) {
		val optimizedTransitions = newArrayList
		for (transition : transitions) {
			optimizedTransitions += transition.optimizeTransition
		}
		return optimizedTransitions
	}
	
	def optimizeTransition(XTransition transition) {
		if (transition === null) {
			return null
		}
		val action = transition.action
		return createXTransition => [
			it.action = action?.optimizeAction
		]
	}
	
	def optimizeAction(Action action) {
		var Action oldAction = null
		var newAction = action
		while (!oldAction.helperEquals(newAction)) {
			oldAction = newAction
			newAction = newAction.clone
			newAction.inline
			newAction = newAction.optimize
		}
		return newAction
	}
	
}