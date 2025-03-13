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
package hu.bme.mit.gamma.yakindu.transformation.batch

import hu.bme.mit.gamma.action.model.ActionModelPackage
import hu.bme.mit.gamma.action.model.AssignmentStatement
import hu.bme.mit.gamma.expression.model.AddExpression
import hu.bme.mit.gamma.expression.model.ArithmeticExpression
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.BooleanExpression
import hu.bme.mit.gamma.expression.model.DecimalLiteralExpression
import hu.bme.mit.gamma.expression.model.DirectReferenceExpression
import hu.bme.mit.gamma.expression.model.DivideExpression
import hu.bme.mit.gamma.expression.model.ExpressionModelPackage
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.MultiplyExpression
import hu.bme.mit.gamma.expression.model.SubtractExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.expression.model.UnaryExpression
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.genmodel.model.StatechartCompilation
import hu.bme.mit.gamma.statechart.interface_.EventParameterReferenceExpression
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelPackage
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.StatechartModelPackage
import hu.bme.mit.gamma.yakindu.transformation.queries.EventToEvent
import hu.bme.mit.gamma.yakindu.transformation.queries.ExpressionTraces
import hu.bme.mit.gamma.yakindu.transformation.queries.Traces
import hu.bme.mit.gamma.yakindu.transformation.traceability.AbstractTrace
import hu.bme.mit.gamma.yakindu.transformation.traceability.TraceabilityPackage
import hu.bme.mit.gamma.yakindu.transformation.traceability.Y2GTrace
import java.math.BigDecimal
import java.math.BigInteger
import java.util.NoSuchElementException
import java.util.Set
import org.eclipse.emf.ecore.EClass
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.viatra.query.runtime.api.ViatraQueryEngine
import org.eclipse.viatra.transformation.runtime.emf.modelmanipulation.IModelManipulations
import org.yakindu.base.expressions.expressions.AssignmentExpression
import org.yakindu.base.expressions.expressions.BoolLiteral
import org.yakindu.base.expressions.expressions.DoubleLiteral
import org.yakindu.base.expressions.expressions.ElementReferenceExpression
import org.yakindu.base.expressions.expressions.FeatureCall
import org.yakindu.base.expressions.expressions.IntLiteral
import org.yakindu.base.expressions.expressions.LogicalAndExpression
import org.yakindu.base.expressions.expressions.LogicalNotExpression
import org.yakindu.base.expressions.expressions.LogicalOrExpression
import org.yakindu.base.expressions.expressions.LogicalRelationExpression
import org.yakindu.base.expressions.expressions.NumericalAddSubtractExpression
import org.yakindu.base.expressions.expressions.NumericalMultiplyDivideExpression
import org.yakindu.base.expressions.expressions.NumericalUnaryExpression
import org.yakindu.base.expressions.expressions.ParenthesizedExpression
import org.yakindu.base.expressions.expressions.PostFixUnaryExpression
import org.yakindu.base.expressions.expressions.PrimitiveValueExpression
import org.yakindu.base.expressions.expressions.StringLiteral
import org.yakindu.base.types.Event
import org.yakindu.base.types.Expression
import org.yakindu.sct.model.stext.stext.EventDefinition
import org.yakindu.sct.model.stext.stext.EventRaisingExpression
import org.yakindu.sct.model.stext.stext.EventValueReferenceExpression
import org.yakindu.sct.model.stext.stext.InterfaceScope
import org.yakindu.sct.model.stext.stext.VariableDefinition

/** 
 * Only initializations, guards and effects (actions) should be transformed by this, not triggers.
 */
class ExpressionTransformer {
	
    protected final ViatraQueryEngine traceEngine
    protected final ViatraQueryEngine genmodelEngine
    protected final StatechartCompilation statechartCompilation
    protected final Y2GTrace traceRoot
    
	protected final extension IModelManipulations manipulation
    
    protected final extension StatechartModelPackage stmPackage = StatechartModelPackage.eINSTANCE
    protected final extension InterfaceModelPackage ifPackage = InterfaceModelPackage.eINSTANCE
    protected final extension ActionModelPackage acPackage = ActionModelPackage.eINSTANCE
	protected final extension ExpressionModelPackage cmPackage = ExpressionModelPackage.eINSTANCE
    protected final extension TraceabilityPackage trPackage = TraceabilityPackage.eINSTANCE
	
	new(IModelManipulations manipulation, StatechartCompilation statechartCompilation, 
			Y2GTrace traceRoot, ViatraQueryEngine traceEngine, ViatraQueryEngine genmodelEngine) {
		this.manipulation = manipulation
		this.statechartCompilation = statechartCompilation
		this.traceRoot = traceRoot
		this.traceEngine = traceEngine
		this.genmodelEngine = genmodelEngine
	}
	
	def getGammaEvent(Event event) {		
		val events = EventToEvent.Matcher.on(genmodelEngine).getAllValuesOfgammaEvent(null, event)
		if (events.size > 1) {
			throw new IllegalArgumentException("This Yakindu event is mapped to more
				than one Gamma event: " + event + " " + events)
		}
		// The event is not mapped explicitly, have to find it through name equality
		if (events.empty) {
			val gammaEvent = event.findGammaEvent
			return gammaEvent
		}
		return events.head
	}
	
	/**
	 * Explores Yakindu event - Gamma event mappings through name equality.
	 */
	private def findGammaEvent(Event event) {
		val eventName = event.name
		val interfaceMappings = statechartCompilation.interfaceMappings
				.filter[it.yakinduInterface.events.contains(event)]
		if (interfaceMappings.size != 1) {
			throw new IllegalArgumentException("This Yakindu event is not contained by a
				single Yakindu interface: " + event + " " + interfaceMappings)
		}
		val gammaInterface = interfaceMappings.head.gammaInterface
		val gammaEvents = gammaInterface.events.map[it.event].filter[it.name == eventName]
		if (gammaEvents.size != 1) {
			throw new IllegalArgumentException("Not one Gamma event with the name " + eventName +
				" is present: " + gammaEvents)
		}
		return gammaEvents.head
	}
	
	def getGammaPort(Event event) {
		val yInterface = (event.eContainer as InterfaceScope)
    	val gPorts = yInterface.allValuesOfTo.filter(Port)
    	if (gPorts.size != 1) {
    		throw new IllegalArgumentException("Not one Gamma port connected to Yakindu interface: " + gPorts)
    	}
    	return gPorts.head
	}
	
	/**
     * Returns a Set of EObjects that are created of the given "from" object.
     */
    def getAllValuesOfTo(EObject from) {
    	return traceEngine.getMatcher(Traces.instance).getAllValuesOfto(null, from)
    }
    
    /**
     * Returns a Set of EObjects that are created of the given "to" object.
     */
    def getAllValuesOfFrom(EObject to) {
    	return traceEngine.getMatcher(Traces.instance).getAllValuesOffrom(null, to)
    }
	
	/**
	 * Responsible for putting the "from" -> "to" mapping into a trace. If the "from" object is already in
	 * another trace object, it is fetched and it will contain the "from" object.
	 */
	def addToTrace(EObject from, Set<EObject> to, EClass traceClass) {
		// So from values will not be duplicated if they are already present in the trace model
		var AbstractTrace aTrace 
		switch (traceClass) {
			case expressionTrace: 
				aTrace = traceEngine.getMatcher(ExpressionTraces.instance)
							.getAllValuesOftrace(from, null).head
			case trace: 
				aTrace = traceEngine.getMatcher(Traces.instance)
							.getAllValuesOftrace(from, null).head 
		}
		// Otherwise a new trace object is created
		if (aTrace === null) {
			aTrace = traceRoot.createChild(y2GTrace_Traces, traceClass) as AbstractTrace
			switch (traceClass) {
				case expressionTrace: 			
					aTrace.addTo(expressionTrace_From, from)
				case trace: 
					aTrace.addTo(trace_From, from)
			}
		}
		val AbstractTrace finalExpTrace = aTrace
		switch (traceClass) {
			case expressionTrace: 			
				to.forEach[finalExpTrace.addTo(expressionTrace_To, it)]
			case trace: 
				to.forEach[finalExpTrace.addTo(trace_To, it)]
		}
		return finalExpTrace
	}
	
	def dispatch EObject transform(EObject container, EReference reference, PrimitiveValueExpression expression) {
		container.transform(reference, expression.value)
	}
	
	def dispatch EObject transform(EObject container, EReference reference, StringLiteral expression) {
		var BigInteger newIntValue
		var StringLiteral stringLiteral = traceEngine.getMatcher(ExpressionTraces.instance)
											.allValuesOffrom.filter(StringLiteral)
											.filter[it.value.equals(expression.value)].head
		if (stringLiteral === null) {
			try {
				newIntValue = BigInteger.valueOf(traceEngine.getMatcher(ExpressionTraces.instance)
								.allMatches.filter[it.from instanceof StringLiteral]
								.map[(it.to as IntegerLiteralExpression).value].max.intValue + 1)
			} catch (NoSuchElementException e) {
				newIntValue = BigInteger.valueOf(0)
			}
		}
		else {
			newIntValue = (traceEngine.getMatcher(ExpressionTraces.instance)
							.getAllValuesOfto(null, stringLiteral).head as IntegerLiteralExpression).value
		}
		val intValue = newIntValue
		val newStringValue = container.createChild(reference, integerLiteralExpression) as IntegerLiteralExpression => [
			it.value = intValue 
		]
		// Creating the trace
    	addToTrace(expression, #{newStringValue}, expressionTrace)
    	return newStringValue
	}
	
	def dispatch EObject transform(EObject container, EReference reference, IntLiteral expression) {
		val intLiteral = container.createChild(reference, integerLiteralExpression) as IntegerLiteralExpression => [
			it.value = BigInteger.valueOf(expression.value)
		]
		// Creating the trace
    	addToTrace(expression, #{intLiteral}, expressionTrace)
    	return intLiteral
	}	
	
	def dispatch EObject transform(EObject container, EReference reference, DoubleLiteral expression) {
		val doubleLiteral = container.createChild(reference, decimalLiteralExpression) as DecimalLiteralExpression => [
			it.value = BigDecimal.valueOf(expression.value)
		]		
		// Creating the trace
    	addToTrace(expression, #{doubleLiteral}, expressionTrace)
    	return doubleLiteral 
	}
	
	def dispatch EObject transform(EObject container, EReference reference, BoolLiteral expression) {
		var BooleanExpression boolLiteral 
		if (expression.value) {
			boolLiteral = container.createChild(reference, trueExpression) as TrueExpression
		}
		else {
			boolLiteral = container.createChild(reference, falseExpression) as FalseExpression
		}
		// Creating the trace
    	addToTrace(expression, #{boolLiteral}, expressionTrace)
    	return boolLiteral 
	}
	
	def dispatch EObject transform(EObject container, EReference reference, NumericalAddSubtractExpression expression) {
		var ArithmeticExpression aritmExp
		if (expression.operator.literal.equals("+")) {
			aritmExp = container.createChild(reference, addExpression) as AddExpression => [
				it.transformBinaryExpression(multiaryExpression_Operands, multiaryExpression_Operands,
					expression.leftOperand, expression.rightOperand)
			]  
		}
		else {
			aritmExp = container.createChild(reference, subtractExpression) as SubtractExpression => [
				it.transformBinaryExpression(binaryExpression_LeftOperand, binaryExpression_RightOperand,
					expression.leftOperand, expression.rightOperand) as ArithmeticExpression	 		
			] 
		}
		// Creating the trace
    	addToTrace(expression, #{aritmExp}, expressionTrace)
    	return aritmExp 
	}
	
	def dispatch EObject transform(EObject container, EReference reference, NumericalMultiplyDivideExpression expression) {
		var ArithmeticExpression aritmExp
		if (expression.operator.literal.equals("*")) {
			aritmExp = container.createChild(reference, multiplyExpression) as MultiplyExpression => [
				it.transformBinaryExpression(multiaryExpression_Operands, multiaryExpression_Operands, expression.leftOperand, expression.rightOperand)	
			]
		}
		else {
			aritmExp = container.createChild(reference, divideExpression) as DivideExpression => [
				it.transformBinaryExpression(binaryExpression_LeftOperand, binaryExpression_RightOperand, expression.leftOperand, expression.rightOperand)			
			]
		}
		// Creating the trace
    	addToTrace(expression, #{aritmExp}, expressionTrace)
    	return aritmExp 
	}
	
	def dispatch EObject transform(EObject container, EReference reference, NumericalUnaryExpression expression) {
		var UnaryExpression unaryExp
		if (expression.operator.literal.equals("+")) {
			unaryExp = container.createChild(reference, unaryPlusExpression) as UnaryExpression => [
				it.transform(unaryExpression_Operand, expression.operand)
			] 
		}
		else {
			unaryExp = container.createChild(reference, unaryMinusExpression) as UnaryExpression => [
				it.transform(unaryExpression_Operand, expression.operand)
			]
		}
		// Creating the trace
    	addToTrace(expression, #{unaryExp}, expressionTrace)
    	return unaryExp 
	}
	
	def dispatch EObject transform(EObject container, EReference reference, PostFixUnaryExpression expression) {		
		// Transformed only if it has a single side effect and not contained by another assignment expression, e.g., (Var.a = Var.b++) or (a * b++)
		if (expression.eContainer instanceof Expression) {
			throw new IllegalArgumentException(expression + " is contained by another expression, thus, it is not transformable to Gamma.")
		}
		val operand = expression.operand
		val yakinduVariable = if (operand instanceof FeatureCall) {
				operand.feature
			}
			else if (operand instanceof ElementReferenceExpression) {
				operand.reference
			}
			else {
				throw new IllegalArgumentException(expression + " refers to a non-variable, thus, it is not transformable to Gamma.")
			}
		val gammaVariables = yakinduVariable.allValuesOfTo
		if (gammaVariables.size != 1) {
			throw new IllegalArgumentException("Not one Gamma variable of a Yakindu variable: " + gammaVariables)
		}
		val gammaVariable = gammaVariables.head as VariableDeclaration
		val assignmentExpression = switch (expression.operator) {
			case DECREMENT: {
				container.createChild(reference, assignmentStatement) as AssignmentStatement => [
					it.transform(abstractAssignmentStatement_Lhs, expression.operand)
					it.createChild(assignmentStatement_Rhs, subtractExpression) as SubtractExpression => [
						it.createChild(binaryExpression_LeftOperand, directReferenceExpression) as DirectReferenceExpression => [
							it.declaration = gammaVariable
						]
						it.createChild(binaryExpression_RightOperand, integerLiteralExpression) as IntegerLiteralExpression => [
							it.value = BigInteger.ONE
						]
					]
				]
			}
			case INCREMENT: {
				container.createChild(reference, assignmentStatement) as AssignmentStatement => [
					it.transform(abstractAssignmentStatement_Lhs, expression.operand)
					it.createChild(assignmentStatement_Rhs, addExpression) as AddExpression => [
						it.createChild(multiaryExpression_Operands, directReferenceExpression) as DirectReferenceExpression => [
							it.declaration = gammaVariable
						]
						it.createChild(multiaryExpression_Operands, integerLiteralExpression) as IntegerLiteralExpression => [
							it.value = BigInteger.ONE
						]
					]
				]
			}
		}
		// Creating the trace
		addToTrace(expression, #{assignmentExpression}, expressionTrace)
    	return assignmentExpression 
	}
	
	def dispatch EObject transform(EObject container, EReference reference, LogicalAndExpression expression) {		
		val logAndExp = container.createChild(reference, andExpression) => [
			it.transformBinaryExpression(multiaryExpression_Operands, multiaryExpression_Operands, expression.leftOperand, expression.rightOperand)				
		]
		// Creating the trace
    	addToTrace(expression, #{logAndExp}, expressionTrace)
    	return logAndExp 
	}
	
	def dispatch EObject transform(EObject container, EReference reference, LogicalOrExpression expression) {		
		val logOrExp = container.createChild(reference, orExpression) => [
			it.transformBinaryExpression(multiaryExpression_Operands, multiaryExpression_Operands,  expression.leftOperand, expression.rightOperand)				
		]
		// Creating the trace
    	addToTrace(expression, #{logOrExp}, expressionTrace)
    	return logOrExp 
	}
	
	def dispatch EObject transform(EObject container, EReference reference, LogicalNotExpression expression) {		
		val logNotExp = container.createChild(reference, notExpression) => [
			it.transform(unaryExpression_Operand, expression.operand)
		]
		// Creating the trace
    	addToTrace(expression, #{logNotExp}, expressionTrace)
    	return logNotExp 
	}
	
	def dispatch EObject transform(EObject container, EReference reference, ParenthesizedExpression expression) {		
		val parExp = container.transform(reference, expression.expression)
		// Creating the trace
    	addToTrace(expression, #{parExp}, expressionTrace)
    	return parExp 		
	}
	
	def dispatch EObject transform(EObject container, EReference reference, EventValueReferenceExpression expression) {		
		val yakinduEvent = expression.eventDefinition
		val gammaEvent = yakinduEvent.gammaEvent
		// Note: valueof expressions are in ExpressionTraces now
		if (gammaEvent.parameterDeclarations.size != 1) {
			throw new IllegalArgumentException("The event has too many parameters: " + gammaEvent.parameterDeclarations.size + " " + event)
		}
		val transitionParameter = gammaEvent.parameterDeclarations.head
    	val refExp = container.createChild(reference, eventParameterReferenceExpression) as EventParameterReferenceExpression => [
    		it.port = yakinduEvent.gammaPort
    		it.event = gammaEvent
    		it.parameter = transitionParameter
    	]
    	// Creating the trace
    	addToTrace(expression, #{refExp}, expressionTrace)
    	return refExp 
	}
	
	private def dispatch EventDefinition getEventDefinition(EventValueReferenceExpression expression) {
		return expression.value.getEventDefinition
	}
	private def dispatch EventDefinition getEventDefinition(ElementReferenceExpression expression) {
		return expression.reference as EventDefinition
	}
	private def dispatch EventDefinition getEventDefinition(FeatureCall expression) {
		return expression.feature as EventDefinition
	}
	
	def dispatch EObject transform(EObject container, EReference reference, ElementReferenceExpression expression) {		
		val elemRef = container.transform(reference, expression.reference)
		// Creating the trace
    	addToTrace(expression, #{elemRef}, expressionTrace)
    	return elemRef 	
	}
	
	def dispatch EObject transform(EObject container, EReference reference, FeatureCall expression) {		
		val elemRef = container.transform(reference, expression.feature)
		// Creating the trace
    	addToTrace(expression, #{elemRef}, expressionTrace)
    	return elemRef 		
	}
	
	def dispatch EObject transform(EObject container, EReference reference, LogicalRelationExpression expression) {		
		var BinaryExpression compExp 
		switch (expression.operator.literal) {
			case "<=":
				compExp = container.createChild(reference, lessEqualExpression) as BinaryExpression => [
					it.transformBinaryExpression(binaryExpression_LeftOperand, binaryExpression_RightOperand, expression.leftOperand, expression.rightOperand)
				]
			case "<":
				compExp = container.createChild(reference, lessExpression) as BinaryExpression => [
					it.transformBinaryExpression(binaryExpression_LeftOperand, binaryExpression_RightOperand, expression.leftOperand, expression.rightOperand)
				]
			case ">":
				compExp = container.createChild(reference, greaterExpression) as BinaryExpression => [
					it.transformBinaryExpression(binaryExpression_LeftOperand, binaryExpression_RightOperand, expression.leftOperand, expression.rightOperand)
				]
			case ">=":	
				compExp = container.createChild(reference, greaterEqualExpression) as BinaryExpression => [
					it.transformBinaryExpression(binaryExpression_LeftOperand, binaryExpression_RightOperand, expression.leftOperand, expression.rightOperand)
				]
			case "==":
				compExp = container.createChild(reference, equalityExpression) as BinaryExpression => [
					it.transformBinaryExpression(binaryExpression_LeftOperand, binaryExpression_RightOperand, expression.leftOperand, expression.rightOperand)
				]
			case "!=":
				compExp = container.createChild(reference, inequalityExpression) as BinaryExpression => [
					it.transformBinaryExpression(binaryExpression_LeftOperand, binaryExpression_RightOperand, expression.leftOperand, expression.rightOperand)
				]
			default:
				throw new IllegalArgumentException("The operator is not known: " + expression.operator.literal)
		}
		// Creating the trace
		addToTrace(expression, #{compExp}, expressionTrace)
    	return compExp 				
	}
	
	/**
	 * A helper method so expressions with two children can be transformed with the call of this method.
	 */
	def transformBinaryExpression(EObject container, EReference leftReference, EReference rightReference, Expression leftOperand, Expression rightOperand) {
		container.transform(leftReference, leftOperand)
		container.transform(rightReference, rightOperand)
	}
	
	/**
	 * For transforming variables appearing in variable initialization, guard and action expressions.
	 */
	def dispatch EObject transform(EObject container, EReference reference, VariableDefinition expression) {		
		container.createChild(reference, directReferenceExpression) as DirectReferenceExpression => [
			it.set(directReferenceExpression_Declaration, expression.getAllValuesOfTo.head)
		]
		// Trace is created by the method that called this one, and VariableDefintions are traced in Traces
	}
	
	def dispatch EObject transform(EObject container, EReference reference, EventRaisingExpression expression) {		
		val gammaSignal = container.transform(reference, expression.event)
		if (expression.value !== null) {
			gammaSignal.transform(argumentedElement_Arguments, expression.value)		
		}
		// Creating the trace
		addToTrace(expression, #{gammaSignal}, expressionTrace)
    	return gammaSignal 
	}
	
	/**
	 * For transforming raising events. (Triggers are not transformed by this.)
	 */
	def dispatch EObject transform(EObject container, EReference reference, EventDefinition eventDefinition) {		
		container.createChild(reference, raiseEventAction) as RaiseEventAction => [
			it.port = eventDefinition.gammaPort
			it.event = eventDefinition.gammaEvent		
		]	
		// Trace is created by the method that called this one, and EventDefinitions are traced in Traces
	}
	
	def dispatch EObject transform(EObject container, EReference reference, AssignmentExpression expression) {		
		var AssignmentStatement assExp
		switch (expression.operator.literal) {
			case "=":
				assExp = container.createChild(reference, assignmentStatement) as AssignmentStatement => [
					it.transform(abstractAssignmentStatement_Lhs, expression.varRef)
					it.transform(assignmentStatement_Rhs, expression.expression)
				]
			case "+=":
				assExp = container.createChild(reference, assignmentStatement) as AssignmentStatement => [
					it.transform(abstractAssignmentStatement_Lhs, expression.varRef)
					it.createChild(assignmentStatement_Rhs, addExpression) as ArithmeticExpression => [
						it.transformBinaryExpression(multiaryExpression_Operands, multiaryExpression_Operands,
							expression.varRef, expression.expression)
					]
				]
			case "*=":
				assExp = container.createChild(reference, assignmentStatement) as AssignmentStatement => [
					it.transform(abstractAssignmentStatement_Lhs, expression.varRef)
					it.createChild(assignmentStatement_Rhs, multiplyExpression) as ArithmeticExpression => [
						it.transformBinaryExpression(multiaryExpression_Operands, multiaryExpression_Operands,
							expression.varRef, expression.expression)
					]
				]
			case "-=":
				assExp = container.createChild(reference, assignmentStatement) as AssignmentStatement => [
					it.transform(abstractAssignmentStatement_Lhs, expression.varRef)
					it.createChild(assignmentStatement_Rhs, subtractExpression) as ArithmeticExpression => [
						it.transformBinaryExpression(binaryExpression_LeftOperand, binaryExpression_RightOperand,
							expression.varRef, expression.expression)
					]
				]
			case "/=":
				assExp = container.createChild(reference, assignmentStatement) as AssignmentStatement => [
					it.transform(abstractAssignmentStatement_Lhs, expression.varRef)
					it.createChild(assignmentStatement_Rhs, divideExpression) as ArithmeticExpression => [
						it.transformBinaryExpression(binaryExpression_LeftOperand, binaryExpression_RightOperand,
							expression.varRef, expression.expression)
					]
				]
			default:
				throw new IllegalArgumentException(expression.operator.literal + " operator is not supported.")
		}
		// Creating the trace
		addToTrace(expression, #{assExp}, expressionTrace)
    	return assExp 		
	}
	
	def dispatch EObject transform(EObject container, EReference reference, Expression expression) {
		throw new IllegalArgumentException("The expression is not supported: " + expression)
	}
	
}