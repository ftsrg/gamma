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
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.VariableContainer
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.AssignmentOperator
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LiteralExpression
import uppaal.expressions.LogicalExpression
import uppaal.expressions.LogicalOperator
import uppaal.expressions.NegationExpression
import uppaal.templates.Edge
import uppaal.templates.Location
import uppaal.templates.TemplatesPackage
import uppaal.declarations.VariableDeclaration
import uppaal.core.NamedElement

class AssignmentExpressionCreator {
	// NTA builder
	protected final extension NtaBuilder ntaBuilder
	// Model manipulator
	protected final extension IModelManipulations manipulation
	// UPPAAL packages
	protected final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
	protected final extension TemplatesPackage temPackage = TemplatesPackage.eINSTANCE
	// UPPAAL factories
	protected final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
	// Auxiliary objects
	protected final extension ExpressionTransformer expressionTransformer
	
	new(NtaBuilder ntaBuilder, IModelManipulations manipulation, ExpressionTransformer expressionTransformer) {
		this.ntaBuilder = ntaBuilder
		this.manipulation = manipulation
		this.expressionTransformer = expressionTransformer
	}
	
	/**
	 * Puts an assignment expression onto the given container. The left side is the given variable, the right side is either true or false". E.g.: myVariable = true.
	 */
	def createAssignmentExpression(EObject container, EReference reference, DataVariableDeclaration variable, boolean isTrue) {
		return container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
				it.text = isTrue.toString
			]
		]
	}
	
	/**
	 * Puts an assignment expression onto the given container. The left side is the given variable, the right side is an integer value". E.g.: myVariable = 0.
	 */
	def void createAssignmentExpression(EObject container, EReference reference, VariableDeclaration variable, String value) {
		container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
				it.text = value
			]
		]
	}
	
	/**
	 * Puts an assignment expression onto the given container. The left side is the first given variable, the right side is the second given variable". E.g.: myFirstVariable = mySecondVariable.
	 */
	def void createAssignmentExpression(EObject container, EReference reference, DataVariableDeclaration lhs, DataVariableDeclaration rhs) {
   		container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = lhs.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = rhs.variable.head // Only one variable is expected
			]
		]
	}
	
	/**
	 * Responsible for creating an assignment expression with the given variable reference and the given expression.
	 */
	def AssignmentExpression createAssignmentExpression(EObject container, EReference reference, VariableContainer variable, Expression rhs, ComponentInstance owner) {
		val assignmentExpression = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.transform(binaryExpression_SecondExpr, rhs)
		]
		return assignmentExpression
	}
	
	def AssignmentExpression createAssignmentExpression(EObject container, EReference reference, VariableContainer variable, uppaal.expressions.Expression rhs) {
		val assignmentExpression = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.secondExpr = rhs
		]
		return assignmentExpression
	}
	
	def AssignmentExpression createIfThenElseAssignment(EObject container, EReference reference, VariableContainer variable,
			NamedElement _if, NamedElement _then, NamedElement _else) {
		return container.createIfThenElseAssignment(reference, variable, 
			createIdentifierExpression => [it.identifier = _if],
			createIdentifierExpression => [it.identifier = _then],
			createIdentifierExpression => [it.identifier = _else]
		)
	}
	
	def AssignmentExpression createIfThenElseAssignment(EObject container, EReference reference, VariableContainer variable,
			NamedElement _if, String _then, NamedElement _else) {
		return container.createIfThenElseAssignment(reference, variable, 
			createIdentifierExpression => [it.identifier = _if],
			createLiteralExpression => [it.text = _then],
			createIdentifierExpression => [it.identifier = _else]
		)
	}
	
	def AssignmentExpression createIfThenElseAssignment(EObject container, EReference reference, VariableContainer variable,
			NamedElement _if, NamedElement _then, String _else) {
		return container.createIfThenElseAssignment(reference, variable, 
			createIdentifierExpression => [it.identifier = _if],
			createIdentifierExpression => [it.identifier = _then],
			createLiteralExpression => [it.text = _else]
		)
	}
	
	def AssignmentExpression createIfThenElseAssignment(EObject container, EReference reference, VariableContainer variable,
			uppaal.expressions.Expression _if, uppaal.expressions.Expression _then, uppaal.expressions.Expression _else) {
		val assignmentExpression = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.secondExpr = createConditionExpression => [
				it.ifExpression = _if
				it.thenExpression = _then
				it.elseExpression = _else
			]
		]
		return assignmentExpression
	}
	
	/**
	 * Puts an assignment expression onto the given container. The left side is the first given variable, the right side is the second given variable in disjunction with the third variable. E.g.: myFirstVariable = mySecondVariable || myThirdVariable.
	 */
	def void createAssignmentLogicalExpression(EObject container, EReference reference, DataVariableDeclaration lhs, DataVariableDeclaration rhsl, DataVariableDeclaration rhsr) {
   		container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
				it.identifier = lhs.variable.head // Only one variable is expected
			]
			it.operator = AssignmentOperator.EQUAL
			it.createChild(binaryExpression_SecondExpr, logicalExpression) as LogicalExpression => [
				it.operator = LogicalOperator.OR
				it.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
					it.identifier = rhsl.variable.head // Only one variable is expected
				]
				it.createChild(binaryExpression_SecondExpr, identifierExpression) as IdentifierExpression => [
					it.identifier = rhsr.variable.head // Only one variable is expected
				]
			]
		]
	}
	
	/**
	 * Creates a loop edge onto the given location that sets the toRaise flag of the give signal to isTrue.
	 */
	def createLoopEdgeWithBoolAssignment(Location location, DataVariableDeclaration variable, boolean isTrue) {
		val loopEdge = location.createEdge(location)
		// variable = isTrue
		loopEdge.createAssignmentExpression(edge_Update, variable, isTrue)
		return loopEdge
	}
	
	/**
	 * Creates a loop edge onto the given location that sets the toRaise flag of the give signal to true and puts a guard on it too,
	 * so the edge is only fireable if the variable-to-be-set is false.
	 */
	def createLoopEdgeWithGuardedBoolAssignment(Location location, DataVariableDeclaration variable) {
		val loopEdge = location.createLoopEdgeWithBoolAssignment(variable, true)
		val negationExpression = createNegationExpression as NegationExpression => [
			it.createChild(negationExpression_NegatedExpression, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head
			]
		]
		// Only fireable if the bool variable is not already set
		loopEdge.addGuard(negationExpression, LogicalOperator.AND)
		return loopEdge
	}
	
	def extendLoopEdgeWithGuardedBoolAssignment(Edge loopEdge, DataVariableDeclaration variable) {
		loopEdge.createAssignmentExpression(edge_Update, variable, true)
		val negationExpression = createNegationExpression as NegationExpression => [
			it.createChild(negationExpression_NegatedExpression, identifierExpression) as IdentifierExpression => [
				it.identifier = variable.variable.head
			]
		]
		// Only fireable if the bool variable is not already set
		loopEdge.addGuard(negationExpression, LogicalOperator.AND)
		return loopEdge
	}
	
}