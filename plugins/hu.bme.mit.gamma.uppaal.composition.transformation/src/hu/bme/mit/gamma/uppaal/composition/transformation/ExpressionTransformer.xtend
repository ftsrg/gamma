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
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.SetTimeoutAction
import hu.bme.mit.gamma.statechart.model.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.statechart.model.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.uppaal.transformation.traceability.TraceabilityPackage
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import uppaal.declarations.ClockVariableDeclaration
import uppaal.declarations.DataVariableDeclaration
import uppaal.declarations.DataVariablePrefix
import uppaal.declarations.Variable
import uppaal.declarations.VariableDeclaration
import uppaal.expressions.ArithmeticExpression
import uppaal.expressions.ArithmeticOperator
import uppaal.expressions.AssignmentExpression
import uppaal.expressions.AssignmentOperator
import uppaal.expressions.CompareExpression
import uppaal.expressions.CompareOperator
import uppaal.expressions.ExpressionsFactory
import uppaal.expressions.ExpressionsPackage
import uppaal.expressions.IdentifierExpression
import uppaal.expressions.LiteralExpression
import uppaal.expressions.LogicalExpression
import uppaal.expressions.LogicalOperator
import uppaal.expressions.MinusExpression
import uppaal.expressions.NegationExpression
import uppaal.expressions.PlusExpression

class ExpressionTransformer {
    // For model creation
	final extension IModelManipulations manipulation	
    // Packages
    final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
    final extension ExpressionsPackage expPackage = ExpressionsPackage.eINSTANCE
    final extension ExpressionsFactory expFact = ExpressionsFactory.eINSTANCE
    // Trace
    protected final extension Trace traceModel
    
	new(IModelManipulations manipulation, Trace traceModel) {
		this.manipulation = manipulation
		this.traceModel = traceModel
	}
	
	def void transformAssignmentAction(EObject container, EReference reference, AssignmentStatement action, ComponentInstance owner) {
		val newExp = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.operator = AssignmentOperator.EQUAL
		]
		newExp.transformBinaryExpressions(action.lhs, action.rhs, owner)
		addToTrace(action, #{newExp}, expressionTrace)
	}
	
	
	def void transformTimeoutAction(EObject container, EReference reference, SetTimeoutAction action, ComponentInstance owner) {
		val newExp = container.createChild(reference, assignmentExpression) as AssignmentExpression => [
			it.operator = AssignmentOperator.EQUAL
		]
		val timeVar = action.timeoutDeclaration.allValuesOfTo.filter(ClockVariableDeclaration).filter[it.owner == owner].head
		newExp.createChild(binaryExpression_FirstExpr, identifierExpression) as IdentifierExpression => [
			it.identifier = timeVar.variable.head
		]
		// Always setting the timer to 0 at entry
		newExp.createChild(binaryExpression_SecondExpr, literalExpression) as LiteralExpression => [
			it.text = "0"
		]
		addToTrace(action, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, Expression expression, ComponentInstance owner) {
		throw new IllegalArgumentException("Not supported expression: " + expression)
	}
	
	def dispatch void transform(EObject container, EReference reference, ElseExpression expression, ComponentInstance owner) {
		// No op, as these expressions are transformed separately in another rule
	}
	
	def dispatch void transform(EObject container, EReference reference, IntegerLiteralExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, literalExpression) as LiteralExpression => [
			it.text = expression.value.toString
		]
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, TrueExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, literalExpression) as LiteralExpression => [
			it.text = "true"
		]
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, FalseExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, literalExpression) as LiteralExpression => [
			it.text = "false" 
		]
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, EnumerationLiteralExpression expression, ComponentInstance owner) {
		val enumLiteral = expression.reference
		val enumType = enumLiteral.eContainer as EnumerationTypeDefinition
		val index = enumType.literals.indexOf(enumLiteral)
		val newExp = container.createChild(reference, literalExpression) as LiteralExpression => [
			it.text = index.toString
		]
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, ReferenceExpression expression, ComponentInstance owner) {		
		var Variable declaration
		val dataDeclaration = expression.declaration.allValuesOfTo.filter(DataVariableDeclaration).head
		// Checking the constants individually as they do not have an owner
		if (dataDeclaration.prefix == DataVariablePrefix.CONST) {
			declaration = dataDeclaration.variable.head
		}
		// Normal variables
		else {
			// TODO
			declaration = expression.declaration.allValuesOfTo.filter(VariableDeclaration).filter[it.owner == owner].head.variable.head
		}
		val newExp = container.createChild(reference, identifierExpression) as IdentifierExpression 
			newExp.identifier = declaration
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, EventParameterReferenceExpression expression, ComponentInstance owner) {		
		val gammaPort = expression.port
		val gammaEvent = expression.event
		val uppaalParameterVariable = gammaEvent.getValueOfVariable(gammaPort, owner)
		val newExp = container.createChild(reference, identifierExpression) as IdentifierExpression => [
			it.identifier = uppaalParameterVariable.variable.head
		]
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, NotExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, negationExpression) as NegationExpression => [
			it.transform(negationExpression_NegatedExpression, expression.operand, owner)
		]
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, OrExpression expression, ComponentInstance owner) {
		if (expression.operands.size < 2) {
			throw new IllegalArgumentException("The following expression has less than two operands: " + expression)
		}
		var newExp = createLogicalExpression => [
			it.operator = LogicalOperator.OR
			it.transformBinaryExpressions(expression.operands.get(0), expression.operands.get(1), owner)
		]	
		val remainingExpressions = newLinkedList
		remainingExpressions += expression.operands.subList(2, expression.operands.size)
		for (remainingExpression : remainingExpressions) {
			newExp = newExp.extendLogicalExpression(LogicalOperator.OR, remainingExpression, owner)
		}
		container.set(reference, newExp)
		addToTrace(expression, #{newExp}, expressionTrace)		
	}
	
	def dispatch void transform(EObject container, EReference reference, XorExpression expression, ComponentInstance owner) {
		if (expression.operands.size < 2) {
			throw new IllegalArgumentException("The following expression has less than two operands: " + expression)
		}
		var newExp = createLogicalExpression => [
			it.operator = LogicalOperator.XOR
			it.transformBinaryExpressions(expression.operands.get(0), expression.operands.get(1), owner)
		]	
		val remainingExpressions = newLinkedList
		remainingExpressions += expression.operands.subList(2, expression.operands.size)
		for (remainingExpression : remainingExpressions) {
			newExp = newExp.extendLogicalExpression(LogicalOperator.XOR, remainingExpression, owner)
		}
		container.set(reference, newExp)
		addToTrace(expression, #{newExp}, expressionTrace)		
	}
	
	def dispatch void transform(EObject container, EReference reference, AndExpression expression, ComponentInstance owner) {
		if (expression.operands.size < 2) {
			throw new IllegalArgumentException("The following expression has less than two operands: " + expression)
		}
		var newExp = createLogicalExpression => [
			it.operator = LogicalOperator.AND
			it.transformBinaryExpressions(expression.operands.get(0), expression.operands.get(1), owner)
		]
		val remainingExpressions = newLinkedList
		remainingExpressions += expression.operands.subList(2, expression.operands.size)
		for (remainingExpression : remainingExpressions) {
			newExp = newExp.extendLogicalExpression(LogicalOperator.AND, remainingExpression, owner)
		}
		container.set(reference, newExp)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, EqualityExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = CompareOperator.EQUAL
		]
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand, owner)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, InequalityExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = CompareOperator.UNEQUAL
		]
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand, owner)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, GreaterExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = CompareOperator.GREATER
		]		
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand, owner)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, GreaterEqualExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = CompareOperator.GREATER_OR_EQUAL
		]
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand, owner)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, LessExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = CompareOperator.LESS
		]
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand, owner)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, LessEqualExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, compareExpression) as CompareExpression => [
			it.operator = CompareOperator.LESS_OR_EQUAL
		]		
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand, owner)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, AddExpression expression, ComponentInstance owner) {
		if (expression.operands.size > 2) {
			throw new IllegalArgumentException("The following expression has more than two operands: " + expression)
		}
		val newExp = container.createChild(reference, arithmeticExpression) as ArithmeticExpression => [
			it.operator = ArithmeticOperator.ADD
		]		
		newExp.transformBinaryExpressions(expression.operands.get(0), expression.operands.get(1), owner)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, SubtractExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, arithmeticExpression) as ArithmeticExpression => [
			it.operator = ArithmeticOperator.SUBTRACT
		]		
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand, owner)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, MultiplyExpression expression, ComponentInstance owner) {
		if (expression.operands.size > 2) {
			throw new IllegalArgumentException("The following expression has more than two operands: " + expression)
		}
		val newExp = container.createChild(reference, arithmeticExpression) as ArithmeticExpression => [
			it.operator = ArithmeticOperator.MULTIPLICATE
		]		
		newExp.transformBinaryExpressions(expression.operands.get(0), expression.operands.get(1), owner)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, DivideExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, arithmeticExpression) as ArithmeticExpression => [
			it.operator = ArithmeticOperator.DIVIDE			
		]		
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand, owner)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, DivExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, arithmeticExpression) as ArithmeticExpression => [
			it.operator = ArithmeticOperator.DIVIDE			
		]		
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand, owner)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, ModExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, arithmeticExpression) as ArithmeticExpression => [
			it.operator = ArithmeticOperator.MODULO			
		]		
		newExp.transformBinaryExpressions(expression.leftOperand, expression.rightOperand, owner)
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	private def void transformBinaryExpressions(EObject container, Expression lhs, Expression rhs, ComponentInstance owner) {
		container.transform(binaryExpression_FirstExpr, lhs, owner)
		container.transform(binaryExpression_SecondExpr, rhs, owner)
	}
	
	private def extendLogicalExpression(LogicalExpression container, LogicalOperator operator, Expression expression, ComponentInstance owner) {
		return createLogicalExpression => [
			it.firstExpr = container
			it.operator = operator
			it.transform(binaryExpression_SecondExpr, expression, owner)
		]
	}
	
	def dispatch void transform(EObject container, EReference reference, UnaryPlusExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, plusExpression) as PlusExpression => [			
			it.transform(plusExpression_ConfirmedExpression, expression.operand, owner)
		]		
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	def dispatch void transform(EObject container, EReference reference, UnaryMinusExpression expression, ComponentInstance owner) {
		val newExp = container.createChild(reference, minusExpression) as MinusExpression => [			
			it.transform(minusExpression_InvertedExpression, expression.operand, owner)
		]		
		addToTrace(expression, #{newExp}, expressionTrace)
	}
	
	/**
	 * Returns the Uppaal valueof variable of a gamma parametered-event.
	 */
	protected def getValueOfVariable(Event event, Port port, ComponentInstance owner) {
		if (event.parameterDeclarations.size != 1) {
			throw new IllegalArgumentException("This event has not one parameter: " + event + " - " + event.parameterDeclarations)
		}
		val parameter = event.parameterDeclarations.head
		val variables = parameter.allValuesOfTo.filter(DataVariableDeclaration).filter[it.owner == owner]
							.filter[it.port == port]
		if (variables.size != 1) {
			throw new IllegalArgumentException("This event has more than one UPPAAL valueof variables: " + event)
		} 
		return variables.head
	}
	
}
