/********************************************************************************
 * Copyright (c) 2022 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation.util

import com.google.common.collect.Collections2
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.Action
import hu.bme.mit.gamma.xsts.model.UnorderedAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.model.XSTSModelFactory
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class UnorderedActionTransformer {
	// Singleton
	public static final UnorderedActionTransformer INSTANCE = new UnorderedActionTransformer
	protected new() {}
	//
	
	protected extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	protected extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected extension XSTSModelFactory xStsFactory = XSTSModelFactory.eINSTANCE
	
	def void transformUnorderedActions(XSTS xSts) {
		val unorderedActions = xSts.getAllContentsOfType(UnorderedAction)
		
		for (unorderedAction : unorderedActions) {
			if (!unorderedAction.areSubactionsOrthogonal) {
				val choiceAction = unorderedAction.transform
				choiceAction.replace(unorderedAction)
			}
			else {
				// Orthogonal subactions -> can be transformed into a sequential action
				val subactions = unorderedAction.actions
				val sequentialAction = subactions.createSequentialAction
				sequentialAction.replace(unorderedAction)
			}
		}
	}
	
	def transform(UnorderedAction unorderedAction) {
		val choiceAction = createNonDeterministicAction
		
		val actions = unorderedAction.actions
		
		val actionPermutations = Collections2.permutations(actions)
		for (actionPermutation : actionPermutations) {
			val clonedSubactions = <Action>newArrayList
			// Is adding an assume true necessary?
			clonedSubactions += createTrueExpression.createAssumeAction
			clonedSubactions += actionPermutation.map[it.clone] // Cloning is important

			choiceAction.actions += clonedSubactions.createSequentialAction
		}
		
		return choiceAction
	}
	
}