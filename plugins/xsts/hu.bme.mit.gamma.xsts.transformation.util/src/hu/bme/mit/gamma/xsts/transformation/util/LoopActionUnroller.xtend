/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.LoopAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class LoopActionUnroller {
	//
	public static final LoopActionUnroller INSTANCE = new LoopActionUnroller
	//
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionEvaluator evaluator = ExpressionEvaluator.INSTANCE
	
	def unrollLoopActions(XSTS xSts) {
		val loopActions = xSts.getAllContentsOfType(LoopAction)
		for (loopAction : loopActions) {
			val parameter = loopAction.iterationParameterDeclaration
			val range = loopAction.range
			val actionInLoop = loopAction.action
			
			val left = range.left
			val right = range.right
			
			// Inlineable?
			if (range.evaluable) {
				val leftInt = left.evaluateInteger
				val rightInt = right.evaluateInteger
				
				val body = newArrayList
				for (var i = leftInt; i <= rightInt /* Right is inclusive */; i++) {
					val index = i.toIntegerLiteral
					val clonedBody = actionInLoop.clone
					
					parameter.inlineReferences(index, clonedBody)
					
					body += clonedBody
				}
				val sequentialAction = body.createSequentialAction
				
				sequentialAction.replace(loopAction)
			}
		}
	}
	
}