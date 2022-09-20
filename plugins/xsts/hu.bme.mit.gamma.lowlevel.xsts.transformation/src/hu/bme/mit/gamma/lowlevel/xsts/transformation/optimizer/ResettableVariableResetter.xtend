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
package hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer

import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class ResettableVariableResetter {
	// Singleton
	public static final ResettableVariableResetter INSTANCE =  new ResettableVariableResetter
	protected new() {}
	//
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	def void resetResettableVariables(XSTS xSts) {
		val resettableVariables = xSts.variableDeclarations
				.filter[it.resettable].toList.reverseView
				
		val inEventTransition = xSts.inEventTransition
		val inEventAction = inEventTransition.action
		
		for (resettableVariable : resettableVariables) {
			val resettingAction = resettableVariable.createVariableResetAction
			resettingAction.prependToAction(inEventAction)
		}
	}
}