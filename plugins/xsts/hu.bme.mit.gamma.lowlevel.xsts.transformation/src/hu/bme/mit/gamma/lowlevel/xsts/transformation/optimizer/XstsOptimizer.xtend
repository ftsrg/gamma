/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
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
import hu.bme.mit.gamma.xsts.model.SequentialAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.model.XTransition
import hu.bme.mit.gamma.xsts.util.XstsActionUtil
import java.util.Collection

class XstsOptimizer {
	// Singleton
	public static final XstsOptimizer INSTANCE =  new XstsOptimizer
	protected new() {}
	//
	
	protected final extension ActionOptimizer actionOptimizer = ActionOptimizer.INSTANCE
	protected final extension RemovableVariableRemover variableRemover = RemovableVariableRemover.INSTANCE
	protected final extension VariableInliner variableInliner = VariableInliner.INSTANCE
	
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil actionUtil = XstsActionUtil.INSTANCE
	protected final extension XSTSModelFactory xStsModelFactory = XSTSModelFactory.eINSTANCE
	
	def optimizeXSts(XSTS xSts) {
		// Initial optimize iteration
		xSts.variableInitializingTransition = xSts.variableInitializingTransition.optimize
		xSts.configurationInitializingTransition = xSts.configurationInitializingTransition.optimize
		xSts.entryEventTransition = xSts.entryEventTransition.optimize
		xSts.changeTransitions(xSts.transitions.optimize)
		xSts.inEventTransition = xSts.inEventTransition.optimize
		xSts.outEventTransition = xSts.outEventTransition.optimize
		
//		// Inlining and removing variables that are only read - not good here, as the generated code may miss some parameters and input variables
//		xSts.removeReadOnlyVariables
		
		// Multiple inline-optimize iterations until fixpoint is reached
		xSts.configurationInitializingTransition = xSts.configurationInitializingTransition.optimizeTransition(
				#[xSts.variableInitializingTransition])
		xSts.entryEventTransition = xSts.entryEventTransition.optimizeTransition(
				#[xSts.variableInitializingTransition, xSts.configurationInitializingTransition])
		xSts.changeTransitions(xSts.transitions.optimizeTransitions)
		
		//
		val optimizeInitVariableTransition = true
		if (optimizeInitVariableTransition) {
			var initVariableAction = xSts.variableInitializingTransition.action as SequentialAction // Original
			val initVariableSubactions = initVariableAction.actions
			val originalInitActions = newArrayList
			originalInitActions += initVariableSubactions
			
			initVariableSubactions += xSts.configurationInitializingTransition.action.clone // Clone
			initVariableSubactions += xSts.entryEventTransition.action.clone // Clone
			
			initVariableAction = initVariableAction.simplifySequentialActions as SequentialAction
			initVariableAction.optimizeAssignmentActions
			
			initVariableAction.actions.removeIf[!originalInitActions.contains(it)]
			xSts.variableInitializingTransition.action = initVariableAction
		}
		//
		
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
		transition.optimizeTransition(#[])
	}
	
	def optimizeTransition(XTransition transition, Collection<? extends XTransition> contextTransitions) {
		if (transition === null) {
			return null
		}
		val action = transition.action
		// Context for inlining if necessary
		val Action context =
		if (!contextTransitions.empty) {
			contextTransitions.map[it.action.clone].toList // Cloning!
					.createSequentialAction
		}
		//
		return createXTransition => [
			it.action = action?.optimizeAction(context)
		]
	}
	
	def optimizeAction(Action action) {
		return action.optimizeAction(null)
	}
	
	def optimizeAction(Action action, Action context) {
		var Action oldAction = null
		var newAction = action
		while (!oldAction.helperEquals(newAction)) {
			oldAction = newAction
			newAction = newAction.clone
			newAction.inline(context)
			newAction = newAction.optimize
		}
		return newAction
	}
	
}