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
package hu.bme.mit.gamma.lowlevel.xsts.transformation.optimizer

import hu.bme.mit.gamma.expression.model.ArrayAccessExpression
import hu.bme.mit.gamma.expression.model.ArrayLiteralExpression
import hu.bme.mit.gamma.expression.model.ArrayTypeDefinition
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.util.GammaEcoreUtil
import hu.bme.mit.gamma.util.JavaUtil
import hu.bme.mit.gamma.xsts.model.AssignmentAction
import hu.bme.mit.gamma.xsts.model.XSTS
import hu.bme.mit.gamma.xsts.util.XstsActionUtil

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class ArrayOptimizer {
	// Singleton
	public static final ArrayOptimizer INSTANCE =  new ArrayOptimizer
	protected new() {}
	//
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension XstsActionUtil xStsActionUtil = XstsActionUtil.INSTANCE
	protected final extension JavaUtil javaUtil = JavaUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	// Model factories
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	
	def void optimizeOneCapacityArrays(XSTS xSts) {
		val oneCapacityArrays = newLinkedHashSet
		for (variableDeclaration : xSts.variableDeclarations) {
			val type = variableDeclaration.typeDefinition
			if (type instanceof ArrayTypeDefinition) {
				val size = type.size
				if (size.evaluateInteger == 1) {
					oneCapacityArrays += variableDeclaration
					// int[1] -> int
					val elementType = type.elementType
					elementType.replace(type)
				}
			}
		}
		
		if (oneCapacityArrays.empty) {
			return // Nothing to optimize
		}
		
		for (assignmentAction : xSts.getAllContentsOfType(AssignmentAction)) {
			val lhs = assignmentAction.lhs
			// array := #[1]
			if (lhs instanceof DirectReferenceExpression) {
				val declaration = lhs.declaration
				if (oneCapacityArrays.contains(declaration)) {
					val rhs = assignmentAction.rhs
					if (rhs instanceof ArrayLiteralExpression) {
						// #[1] -> 1
						val expression = rhs.operands.onlyElement
						expression.replace(rhs)
					}
					else {
						val arrayAccessExpression = createArrayAccessExpression
						arrayAccessExpression.replace(rhs)
						// #[1] -> #[1][0]
						arrayAccessExpression.operand = rhs
						arrayAccessExpression.index = 0.toIntegerLiteral
					}
				}
			}
		}
		// array[0] -> array
		for (arrayAccessExpression : xSts.getAllContentsOfType(ArrayAccessExpression)) {
			val operand = arrayAccessExpression.operand
			if (operand instanceof DirectReferenceExpression) {
				val declaration = operand.declaration
				if (oneCapacityArrays.contains(declaration)) {
					operand.replace(arrayAccessExpression)
				}
			}
		}
	}
	
}