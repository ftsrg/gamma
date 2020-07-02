/********************************************************************************
 * Copyright (c) 2018 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.uppaal.composition.transformation

import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.AddExpression
import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.DivExpression
import hu.bme.mit.gamma.expression.model.DivideExpression
import hu.bme.mit.gamma.expression.model.ElseExpression
import hu.bme.mit.gamma.expression.model.EnumerationLiteralExpression
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression
import hu.bme.mit.gamma.expression.model.GreaterExpression
import hu.bme.mit.gamma.expression.model.IfThenElseExpression
import hu.bme.mit.gamma.expression.model.InequalityExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.LessEqualExpression
import hu.bme.mit.gamma.expression.model.LessExpression
import hu.bme.mit.gamma.expression.model.ModExpression
import hu.bme.mit.gamma.expression.model.MultiplyExpression
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.ReferenceExpression
import hu.bme.mit.gamma.expression.model.SubtractExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.UnaryMinusExpression
import hu.bme.mit.gamma.expression.model.UnaryPlusExpression
import hu.bme.mit.gamma.expression.model.XorExpression
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.statechart.SetTimeoutAction
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import uppaal.declarations.ClockVariableDeclaration
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.VariableDeclaration
import uppaal.expressions.ArithmeticExpression
import uppaal.expressions.ArithmeticOperator
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.AssignmentOperator
import uppaal.expressions.CompareExpression
import uppaal.expressions.CompareOperator
import uppaal.expressions.ConditionExpression
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LiteralExpression
import uppaal.expressions.LogicalExpression
import uppaal.expressions.LogicalOperator
import uppaal.expressions.MinusExpression
import uppaal.expressions.NegationExpression
import uppaal.expressions.PlusExpression

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ExpressionTransformer {
    // For model creation
	final extension IModelManipulations manipulation
	final extension NtaBuilder ntaBuilder
    // Packages
    final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
    final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
    final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
    // Trace
    final extension Trace traceModel
    
	new(IModelManipulations manipulation, NtaBuilder ntaBuilder, Trace traceModel) {
		this.manipulation = manipulation
		this.ntaBuilder = ntaBuilder
		this.traceModel = traceModel
	}
	
	def void transformAssignmentAction(EObject container, EReference reference, AssignmentStatement action) {
		val newExp = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.operator = AssignmentOperator.EQUAL
		]
		newExp.transformBinaryExpressions(action.lhs, action.rhs)
		addToTrace(action, #{newExp}, expressionTrace)
	}
	
	def void transformTimeoutAction(EObject container, EReference reference, SetTimeoutAction action) {
		val clockVariables = action.timeoutDeclaration.allValuesOfTo.filter(ClockVariableDeclaration)
		checkState(clockVariables.size == 1)
		val clockVariable = clockVariables.head
		val boolVariable = action.timeoutDeclaration.allValuesOfTo.filter(DataVariableDeclaration).head
		val clockExp = container.createAssignmentExpression(reference, clockVariable, "0")
		val boolExp = container.createAssignmentExpression(reference, boolVariable, "false")
		addToTrace(action, #{clockExp}, expressionTrace)
		addToTrace(action, #{boolExp}, expressionTrace)
	}
	
	private def createAssignmentExpression(EObject container, EReference reference,
			VariableDeclaration variable, String literal) {
		val newExp = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.operator = AssignmentOperator.EQUAL
		]
		newExp.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
			it.identifier = variable.variable.head
		]
		// Always setting the timer to 0 at entry
		newExp.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
			it.text = literal
		]
		return newExp
	}
	
	def dispatch void transform(EObject container, EReference reference, Expression expression) {
		throw new IllegalArgumentException("Not supported expression: " + expression)
	}
	
	def dispatch void transform(EObject container, EReference reference, ElseExpression expression) {
		// No op, as these expressions are transformed separately in another rule
	}
	
	def dispatch void transform(EObject container, EReference reference, IntegerLiteralExpression expression) {
		val newExp = container.createChild(reference, literalExpression) as LiteralExpression => [
			it.text = expression.value.toString
		]
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, TrueExpression expression) {
		val newExp = container.createChild(reference, literalExpression) as LiteralExpression => [
			it.text = "true"
		]
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, FalseExpression expression) {
		val newExp = container.createChild(reference, literalExpression) as LiteralExpression => [
			it.text = "false" 
		]
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, EnumerationLiteralExpression expression) {
		val enumLiteral = expression.reference
		val enumType = enumLiteral.eContainer as EnumerationTypeDefinition
		val index = enumType.literals.indexOf(enumLiteral)
		val newExp = container.createChild(reference, literalExpression) as LiteralExpression => [
			it.text = index.toString
		]
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, ReferenceExpression expression) {		
		val originalDeclaration = expression.declaration
		val dataDeclarations = originalDeclaration.allValuesOfTo.filter(DataVariableDeclaration)
		checkState(dataDeclarations.size == 1, "Probably you do not use event parameters correctly: " + dataDeclarations.size)
		val dataDeclaration = dataDeclarations.head
		val declaration = dataDeclaration.variable.head
		// Normal variables: no owner is needed as now every instance has its own statechart declaration
		val newExp = container.createChild(reference, identifierExpression) as IdentifierExpression 
		newExp.identifier = declaration
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, EventParameterReferenceExpression expression) {		
		val gammaPort = expression.port
		val gammaEvent = expression.event
		val gammaParameter = expression.parameter
		val parameterOwners = gammaPort.containingStatechart.referencingComponentInstances
		checkState(parameterOwners.size == 1)
		val uppaalParameterVariable = gammaEvent.getIsRaisedValueOfVariable(gammaPort, gammaParameter, parameterOwners.head) // Event parameter reference -> isRaised
		val newExp = container.createChild(reference, identifierExpression) as IdentifierExpression => [
			it.identifier = uppaalParameterVariable.variable.head
		]
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, NotExpression expression) {
		val newExp = container.createChild(reference, negationExpression) as NegationExpression => [
			it.transform(negationExpression_NegatedExpression, expression.operand)
		]
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, OrExpression expression) {
		if (expression.operands.size < 2) {
			throw new IllegalArgumentException("The following expression has less than two operands: " + expression)
		}
		var newExp = createLogicalExpression => [
			it.operator = LogicalOperator.OR
			it.transformBinaryExpressions(expression.operands.get(0), expression.operands.get(1))
		]	
		val remainingExpressions = newLinkedList
		remainingExpressions += expression.operands.subList(2, expression.operands.size)
		for (remainingExpression : remainingExpressions) {
			newExp = newExp.extendLogicalExpression(LogicalOperator.OR, remainingExpression)
		}
		container.set(reference, newExp)
		addToTrace(expression, #{newExp}, expressionTrace)		
	}
	
	def dispatch void transform(EObject container, EReference reference, XorExpression expression) {
		if (expression.operands.size < 2) {
			throw new IllegalArgumentException("The following expression has less than two operands: " + expression)
		}
		var newExp = createLogicalExpression => [
			it.operator = LogicalOperator.XOR
			it.transformBinaryExpressions(expression.operands.get(0), expression.operands.get(1))
		]	
		val remainingExpressions = newLinkedList
		remainingExpressions += expression.operands.subList(2, expression.operands.size)
		for (remainingExpression : remainingExpressions) {
			newExp = newExp.extendLogicalExpression(LogicalOperator.XOR, remainingExpression)
		}
		container.set(reference, newExp)
		addToTrace(expression, #{newExp}, expressionTrace)		
	}
	
	def dispatch void transform(EObject container, EReference reference, AndExpression expression) {
		if (expression.operands.size < 2) {
			throw new IllegalArgumentException("The following expression has less than two operands: " + expression)
		}
		var newExp = createLogicalExpression => [
			it.operator = LogicalOperator.AND
			it.transformBinaryExpressions(expression.operands.get(0), expression.operands.get(1))
		]
		val remainingExpressions = newLinkedList
		remainingExpressions += expression.operands.subList(2, expression.operands.size)
		for (remainingExpression : remainingExpressions) {
			newExp = newExp.extendLogicalExpression(LogicalOperator.AND, remainingExpression)
		}
		container.set(reference, newExp)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, EqualityExpression expression) {
		val newExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = CompareOperator.EQUAL
		]
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, InequalityExpression expression) {
		val newExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = CompareOperator.UNEQUAL
		]
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, GreaterExpression expression) {
		val newExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = CompareOperator.GREATER
		]		
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, GreaterEqualExpression expression) {
		val newExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = CompareOperator.GREATER_OR_EQUAL
		]
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, LessExpression expression) {
		val newExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = CompareOperator.LESS
		]
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, LessEqualExpression expression) {
		val newExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = CompareOperator.LESS_OR_EQUAL
		]		
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, AddExpression expression) {
		val temp = container.createChild(reference, arithmeticExpression) as ArithmeticExpression => [
			it.operator = ArithmeticOperator.ADD
		]
		val transformedExpressions = newArrayList
		for (subExpression : expression.operands) {
			temp.transform(binaryExpression_FirstExpr, subExpression)
			transformedExpressions += temp.firstExpr
		}
		val newExp = createArithmeticExpression(ArithmeticOperator.ADD, transformedExpressions)
		container.eSet(reference, newExp)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, SubtractExpression expression) {
		val newExp = container.createChild(reference, arithmeticExpression) as ArithmeticExpression => [
			it.operator = ArithmeticOperator.SUBTRACT
		]		
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, MultiplyExpression expression) {
		val temp = container.createChild(reference, arithmeticExpression) as ArithmeticExpression => [
			it.operator = ArithmeticOperator.MULTIPLICATE
		]
		val transformedExpressions = newArrayList
		for (subExpression : expression.operands) {
			temp.transform(binaryExpression_FirstExpr, subExpression)
			transformedExpressions += temp.firstExpr
		}
		val newExp = createArithmeticExpression(ArithmeticOperator.MULTIPLICATE, transformedExpressions)
		container.eSet(reference, newExp)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, DivideExpression expression) {
		val newExp = container.createChild(reference, arithmeticExpression) as ArithmeticExpression => [
			it.operator = ArithmeticOperator.DIVIDE			
		]		
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, DivExpression expression) {
		val newExp = container.createChild(reference, arithmeticExpression) as ArithmeticExpression => [
			it.operator = ArithmeticOperator.DIVIDE			
		]		
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, ModExpression expression) {
		val newExp = container.createChild(reference, arithmeticExpression) as ArithmeticExpression => [
			it.operator = ArithmeticOperator.MODULO			
		]		
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	private def void transformBinaryExpressions(EObject container, Expression lhs, Expression rhs) {
		container.transform(binaryExpression_FirstExpr, lhs)
		container.transform(binaryExpression_SecondExpr, rhs)
	}
	
	private def extendLogicalExpression(LogicalExpression container, LogicalOperator operator, Expression expression) {
		return createLogicalExpression => [
			it.firstExpr = container
			it.operator = operator
			it.transform(binaryExpression_SecondExpr, expression)
		]
	}
	
	def dispatch void transform(EObject container, EReference reference, UnaryPlusExpression expression) {
		val newExp = container.createChild(reference, plusExpression) as PlusExpression => [			
			it.transform(plusExpression_ConfirmedExpression, expression.operand)
		]		
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, UnaryMinusExpression expression) {
		val newExp = container.createChild(reference, minusExpression) as MinusExpression => [			
			it.transform(minusExpression_InvertedExpression, expression.operand)
		]		
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, IfThenElseExpression expression) {
		val newExp = container.createChild(reference, conditionExpression) as ConditionExpression => [			
			it.transform(conditionExpression_IfExpression, expression.condition)
			it.transform(conditionExpression_ThenExpression, expression.then)
			it.transform(conditionExpression_ElseExpression, expression.^else)
		]		
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
}
