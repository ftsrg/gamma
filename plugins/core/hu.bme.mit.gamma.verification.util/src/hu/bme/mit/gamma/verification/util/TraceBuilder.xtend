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
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.expression.util.ComplexTypeUtil
import hu.bme.mit.gamma.expression.util.ExpressionEvaluator
import hu.bme.mit.gamma.expression.util.FieldHierarchy
import hu.bme.mit.gamma.expression.util.IndexHierarchy
import hu.bme.mit.gamma.statechart.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.InstanceVariableState
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.math.BigInteger

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*

class TraceBuilder {
	// Singleton
	public static final TraceBuilder INSTANCE = new TraceBuilder
	protected new() {}
	//
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE // For component instance reference
	
	// In event
	
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
	
	def addInEventWithParameter(Step step, Port port, Event event,
			ParameterDeclaration parameter, String value) {
		val type = parameter.typeDefinition
		val intValue = type.convertStringToInt(value)
		return addInEvent(step, port, event, parameter, intValue)
	}
	
	private def addInEvent(Step step, Port port, Event event,
			ParameterDeclaration parameter, Integer value) {
		val eventRaise = addInEvent(step, port, event)
		val index = parameter.index
		eventRaise.arguments.set(index, parameter.createParameter(value))
	}
	
	def addInEventWithParameter(Step step, Port port, Event event,
			ParameterDeclaration parameter, FieldHierarchy fieldHierarchy, IndexHierarchy indexes, String value) {
		addInEvent(step, port, event, parameter, fieldHierarchy, indexes, value)
	}
	
	private def addInEvent(Step step, Port port, Event event,
			ParameterDeclaration parameter, FieldHierarchy fieldHierarchy, IndexHierarchy indexes, String value) {
		val type = parameter.typeDefinition
		if (type.native) {
			addInEventWithParameter(step, port, event, parameter, value)
		}
		else {
			checkState(type.complex)
			val eventRaise = addInEvent(step, port, event)
			val arguments = eventRaise.arguments // Filled with dummy default literals
			val literal = arguments.get(parameter.index)
			literal.changeValue(fieldHierarchy, indexes, value)
		}
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
	
	def addOutEventWithStringParameter(Step step, Port port, Event event,
			ParameterDeclaration parameter, String value) {
		val type = parameter.typeDefinition
		val intValue = type.convertStringToInt(value)
		addOutEventWithParameter(step, port, event, parameter, intValue)
	}
	
	def addOutEventWithParameter(Step step, Port port, Event event,
			ParameterDeclaration parameter, Integer value) {
		val eventRaise = addOutEvent(step, port, event)
		val index = parameter.index
		eventRaise.arguments.set(index, parameter.createParameter(value))
	}
	
	def addOutEventWithStringParameter(Step step, Port port, Event event,
			ParameterDeclaration parameter, FieldHierarchy fieldHierarchy, IndexHierarchy indexes, String value) {
		val type = parameter.typeDefinition
		if (type.native) {
			addOutEventWithStringParameter(step, port, event, parameter, value)
		}
		else {
			checkState(type.complex)
			val eventRaise = addOutEvent(step, port, event)
			val arguments = eventRaise.arguments // Filled with dummy default literals
			val literal = arguments.get(parameter.index)
			literal.changeValue(fieldHierarchy, indexes, value)
		}
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
			it.instance = statechartUtil.createInstanceReference(instance)
			it.declaration = variable
			it.value = value
		]
	}
	
	def void addInstanceVariableState(Step step, SynchronousComponentInstance instance,
			VariableDeclaration variable, FieldHierarchy fieldHierarchy, IndexHierarchy indexes, String value) {
		val type = variable.typeDefinition
		if (type.native) {
			addInstanceVariableState(step, instance, variable, value)
		}
		else {
			checkState(type.complex)
			val literal = step.getOrCreateLiteral(instance, variable)
			literal.changeValue(fieldHierarchy, indexes, value)
		}
	}
	
	private def getOrCreateLiteral(Step step, SynchronousComponentInstance instance,
			VariableDeclaration variable) {
		val variableStates = step.asserts.filter(InstanceVariableState)
		val variableState = variableStates.filter[
			it.instance === instance &&	it.declaration === variable].head
		var Expression value
		if (variableState === null) {
			// Creating the literal, similar to "getInstance" in singletons
			val type = variable.typeDefinition
			val initialValue = type.initialValueOfType
			step.asserts += createInstanceVariableState => [
				it.instance = statechartUtil.createInstanceReference(instance)
				it.declaration = variable
				it.value = initialValue
			]
			value = initialValue
		}
		else {
			value = variableState.value
		}
		return value 
	}
	
	// Instance states
	
	def addInstanceState(Step step, SynchronousComponentInstance instance, State state) {
		step.asserts += createInstanceStateConfiguration => [
			it.instance = statechartUtil.createInstanceReference(instance)
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
			val type = dummyParameter.typeDefinition
			eventRaise.arguments += type.initialValueOfType // Filling with default values
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
			IntegerTypeDefinition: value.toIntegerLiteral
			BooleanTypeDefinition: (value == 0) ?
					createFalseExpression : createTrueExpression
			EnumerationTypeDefinition: {
				val literals = paramType.literals
				val enum = literals.get(value)
				enum.createEnumerationLiteralExpression
			}
			default: 
				throw new IllegalArgumentException("Not known type definition: " + paramType)
		}
		return literal
	}
	
	// Record handling
	
	private def changeValue(Expression literal,
			FieldHierarchy fieldHierarchy, IndexHierarchy indexes, String value) {
		val innerType = fieldHierarchy.last.typeDefinition
		val valueToBeChanged = literal.getValue(fieldHierarchy, indexes)
		val newValue = innerType.createLiteral(value)
		newValue.replace(valueToBeChanged)
	}
	
}