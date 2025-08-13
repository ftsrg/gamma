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
package hu.bme.mit.gamma.xsts.iml.transformation.serialization

import hu.bme.mit.gamma.expression.model.FunctionAccessExpression
import hu.bme.mit.gamma.expression.model.FunctionDeclaration
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.xsts.model.FunctionCallAction
import hu.bme.mit.gamma.xsts.model.NonDeterministicAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

import static com.google.common.base.Preconditions.checkArgument

import static extension hu.bme.mit.gamma.xsts.derivedfeatures.XstsDerivedFeatures.*

class XstsValidator {
	// Singleton
	public static XstsValidator INSTANCE = new XstsValidator
	protected new() {}
	//
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	
	
	def validate(XSTS xSts) {
		xSts.validateFunctionDeclarations
	}
	
	protected def validateFunctionDeclarations(XSTS xSts) {
		val functions = xSts.functionDeclarations
		for (function : functions) {
			checkArgument(function.getAllContentsOfType(NonDeterministicAction).empty,
				"Functions cannot contain non-deterministic actions")
		}
		
		val functionCalls = xSts.getAllContentsOfType(FunctionAccessExpression)
		for (functionCall : functionCalls) {
			if (!(functionCall.eContainer instanceof FunctionCallAction)) {
				val function = functionCall.operand.declaration as FunctionDeclaration
				checkArgument(function.pure, "Functions used in expression must be pure")
			}
		}
	}	
}