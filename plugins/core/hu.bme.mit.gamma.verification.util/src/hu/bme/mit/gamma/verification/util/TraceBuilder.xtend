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
package hu.bme.mit.gamma.verification.util

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FieldAssignment
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.RecordLiteralExpression
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.FieldHierarchy
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import java.math.BigInteger
import java.util.List

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class TraceBuilder {
	// Singleton
	public static final TraceBuilder INSTANCE = new TraceBuilder
	protected new() {}
	//
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	
	// In event
	
	def addInEventWithParameter(Step step, Port port, Event event,
			ParameterDeclaration parameter, String value) {
		val type = parameter.typeDefinition
		val intValue = type.convertStringToInt(value)
		return addInEvent(step, port, event, parameter, intValue)
	}
	
	def addInEventWithParameter(Step step, Port port, Event event,
			ParameterDeclaration parameter, FieldHierarchy fieldHierarchy, String value) {
		val type = parameter.typeDefinition
		val intValue = type.convertStringToInt(value)
		addInEvent(step, port, event, parameter, fieldHierarchy, intValue)
	}
	
	def addInEvent(Step step, Port port, Event event) {
		val eventRaise = createRaiseEventAct(port, event)
		val originalRaise = step.actions.filter(RaiseEventAct).findFirst[it.isOverWritten(eventRaise)]
		if (originalRaise === null) {
			// This is the first raise
			step.actions += eventRaise
			return eventRaise
		}
		return originalRaise
	}
	
	private def addInEvent(Step step, Port port, Event event,
			ParameterDeclaration parameter, Integer value) {
		val eventRaise = addInEvent(step, port, event)
		val index = parameter.index
		eventRaise.arguments.set(index, parameter.createParameter(value))
	}
	
	private def addInEvent(Step step, Port port, Event event,
			ParameterDeclaration parameter, FieldHierarchy fieldHierarchy, Integer value) {
		val eventRaise = addInEvent(step, port, event)
		val arguments = eventRaise.arguments
		arguments.setRecordArgument(parameter, fieldHierarchy, value)
	}
	
	// Time elapse
	
	def addTimeElapse(Step step, Expression elapsedTime) {
		return step.addTimeElapse(elapsedTime.evaluateInteger)
	}
	
	def addTimeElapse(Step step, int elapsedTime) {
		val timeElapseActions = step.actions.filter(TimeElapse)
		if (!timeElapseActions.empty) {
			// A single time elapse action in all steps
			val action = timeElapseActions.head
			val newTime = action.elapsedTime + BigInteger.valueOf(elapsedTime)
			action.elapsedTime = newTime
		}
		else {
			// No time elapses in this step so far
			step.actions += createTimeElapse => [
				it.elapsedTime = BigInteger.valueOf(elapsedTime)
			]
		}
	}
	
	// Schedule
	
	def addScheduling(Step step, AsynchronousComponentInstance instance) {
		step.actions += createInstanceSchedule => [
			it.scheduledInstance = instance
		]
	}
	
	def addReset(Step step) {
		step.actions += createReset
	}
	
	def addComponentScheduling(Step step) {
		step.actions += createComponentSchedule
	}
	
	def scheduleIfSynchronousComponent(Step step, Component component) {
		if (component instanceof SynchronousComponent) {
			step.addComponentScheduling
		}
	}
	
	// Out event
	
	def addOutEventWithStringParameter(Step step, Port port, Event event,
			ParameterDeclaration parameter, String value) {
		val type = parameter.typeDefinition
		val intValue = type.convertStringToInt(value)
		addOutEventWithParameter(step, port, event, parameter, intValue)
	}
	
	def addOutEvent(Step step, Port port, Event event) {
		val eventRaise = createRaiseEventAct(port, event)
		val outEventRaises = step.asserts.filter(RaiseEventAct)
		val originalRaise = outEventRaises.findFirst[it.isOverWritten(eventRaise)]
		if (originalRaise === null) {
			// This is the first raise
			step.asserts += eventRaise
			return eventRaise
		}
		return originalRaise
	}
	
	def addOutEventWithParameter(Step step, Port port, Event event,
			ParameterDeclaration parameter, Integer value) {
		val eventRaise = addOutEvent(step, port, event)
		val index = parameter.index
		eventRaise.arguments.set(index, parameter.createParameter(value))
	}
	
	def addOutEventWithStringParameter(Step step, Port port, Event event,
			ParameterDeclaration parameter, FieldHierarchy fieldHierarchy, String value) {
		val type = parameter.typeDefinition
		val intValue = type.convertStringToInt(value)
		addOutEventWithParameter(step, port, event, parameter, fieldHierarchy, intValue)
	}
	
	def addOutEventWithParameter(Step step, Port port, Event event,
			ParameterDeclaration parameter, FieldHierarchy fieldHierarchy, Integer value) {
		val eventRaise = addOutEvent(step, port, event)
		val arguments = eventRaise.arguments
		arguments.setRecordArgument(parameter, fieldHierarchy, value)
	}
	
	// Instance variables
	
	def addInstanceVariableState(Step step, SynchronousComponentInstance instance,
			VariableDeclaration variable, String value) {
		val type = variable.typeDefinition
		val expression = type.createLiteral(value)
		step.addInstanceVariableState(instance, variable, expression)
	}
	
	def addInstanceVariableState(Step step, SynchronousComponentInstance instance,
			VariableDeclaration variable, Expression value) {
		step.asserts += createInstanceVariableState => [
			it.instance = instance
			it.declaration = variable
			it.value = value
		]
	}
	
	def addInstanceVariableState(Step step, SynchronousComponentInstance instance,
			VariableDeclaration variable, FieldHierarchy fieldHierarchy, String value) {
		val literal = step.getRecordLiteral(instance, variable)
		val fieldAssignment = literal.getFieldAssignment(fieldHierarchy)
		fieldAssignment.fieldAssignment = value
	}
	
	private def getRecordLiteral(Step step, SynchronousComponentInstance instance,
			VariableDeclaration variable) {
		val variableStates = step.asserts.filter(InstanceVariableState)
		val variableState = variableStates.filter[
			it.instance === instance &&	it.declaration === variable].head
		var RecordLiteralExpression value
		if (variableState === null) {
			// Creating the literal, similar to "getInstance" in singletons
			val recordLiteral = variable.initialValue as RecordLiteralExpression
			step.asserts += createInstanceVariableState => [
				it.instance = instance
				it.declaration = variable
				it.value = recordLiteral
			]
			value = recordLiteral
		}
		else {
			value = variableState.value as RecordLiteralExpression
		}
		return value 
	}
	
	// Instance states
	
	def addInstanceState(Step step, SynchronousComponentInstance instance, State state) {
		step.asserts += createInstanceStateConfiguration => [
			it.instance = instance
			it.state = state
		]
	}
	
	// Raise event act
	
	private def createRaiseEventAct(Port port, Event event) {
		val eventRaise = createRaiseEventAct => [
			it.port = port
			it.event = event
		]
		val parameters = event.parameterDeclarations
		for (dummyParameter : parameters) {
			eventRaise.arguments += createFalseExpression
		}
		return eventRaise
	}
	
	// String and int parsing
	
	def createVariableLiteral(VariableDeclaration variable, Integer value) {
		val type = variable.typeDefinition
		return type.createLiteral(value)
	}
	
	private def createParameter(ParameterDeclaration parameter, Integer value) {
		if (parameter === null) {
			return null
		}
		val paramType = parameter.typeDefinition
		return paramType.createLiteral(value)
	}
	
	private def convertStringToInt(Type type, String value) {
		switch (value) {
			case "false":
				return 0
			case "true":
				return 1
			default:
				try {
					return Integer.parseInt(value)
				} catch (NumberFormatException e) {
					if (type instanceof EnumerationTypeDefinition) {
						val literals = type.literals
						val literal = literals.findFirst[it.name.equals(value)]
						return literals.indexOf(literal)
					}
					throw new IllegalArgumentException("Not known value: " + value)
				}
		}
	}
	
	private def Expression createLiteral(Type paramType, String value) {
		return paramType.createLiteral(paramType.convertStringToInt(value))
	}
	
	/**
	 * Only primitive types and enums are accepted, type references are not.
	 */
	private def Expression createLiteral(Type paramType, Integer value) {
		val literal = switch (paramType) {
			IntegerTypeDefinition: createIntegerLiteralExpression => [
				it.value = BigInteger.valueOf(value)
			]
			BooleanTypeDefinition: {
				if (value == 0) {
					createFalseExpression
				}
				else {
					createTrueExpression
				}
			}
			EnumerationTypeDefinition:
				return createEnumerationLiteralExpression => [
					it.reference = paramType.literals.get(value)
				]
			default: 
				throw new IllegalArgumentException("Not known type definition: " + paramType)
		}
		return literal
	}
	
	// Record handling
		
	private def getRecordLiteral(List<Expression> arguments, ParameterDeclaration parameter) {
		val index = parameter.index
		val argument = arguments.get(index)
		if (argument instanceof RecordLiteralExpression) {
			// "Singleton"
			return argument as RecordLiteralExpression
		}
		val type = parameter.typeDefinition
		val recordLiteral = type.initialValueOfType as RecordLiteralExpression
		// Creating the singleton
		arguments.set(index, recordLiteral)
		return recordLiteral
	}
	
	private def setFieldAssignment(FieldAssignment fieldAssignment, String value) {
		val declaration = fieldAssignment.reference.declaration
		val type = declaration.typeDefinition
		val intValue = type.convertStringToInt(value)
		fieldAssignment.fieldAssignment = intValue
	}
	
	private def setFieldAssignment(FieldAssignment fieldAssignment, Integer value) {
		val declaration = fieldAssignment.reference.declaration
		val type = declaration.typeDefinition
		// Type must be primitive
		val expression = type.createLiteral(value)
		fieldAssignment.value = expression
	}
	
	private def setRecordArgument(List<Expression> arguments,
			ParameterDeclaration parameter, FieldHierarchy fieldHierarchy, Integer value) {
		val recordLiteral = arguments.getRecordLiteral(parameter)
		val fieldAssignment = recordLiteral.getFieldAssignment(fieldHierarchy)
		fieldAssignment.fieldAssignment = value
	}
	
}