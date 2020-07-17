/********************************************************************************
 * Copyright (c) 2018-2020 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.uppaal.util.NtaBuilder
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import uppaal.declarations.VariableContainer
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.AssignmentOperator
import uppaal.expressions.ExpressionsPackage

class AssignmentExpressionCreator extends hu.bme.mit.gamma.uppaal.util.AssignmentExpressionCreator {
	// UPPAAL packages
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	// Auxiliary objects
	protected final extension ExpressionTransformer expressionTransformer
	
	new(NtaBuilder ntaBuilder, ExpressionTransformer expressionTransformer) {
		super(ntaBuilder)
		this.expressionTransformer = expressionTransformer
	}
	
	/**
	 * Responsible for creating an assignment expression with the given variable reference and the given expression.
	 */
	def AssignmentExpression createAssignmentExpression(EObject container, EReference reference,
			VariableContainer variable, Expression rhs) {
		val assignmentExpression = createAssignmentExpression => [
			it.firstExpr = createIdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.transform(binaryExpression_SecondExpr, rhs)
		]
		container.add(reference, assignmentExpression)
		return assignmentExpression
	}
	
}