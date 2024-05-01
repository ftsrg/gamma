/********************************************************************************
 * Copyright (c) 2018-2024 Contributors to the Gamma project
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
import hu.bme.mit.gamma.expression.model.EqualityExpression
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
import hu.bme.mit.gamma.statechart.composite.ComponentInstanceVariableReferenceExpression
import hu.bme.mit.gamma.statechart.composite.CompositeModelFactory
import hu.bme.mit.gamma.statechart.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.util.ExpressionTypeDeterminator
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.trace.model.ExecutionTrace
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceModelFactory
import hu.bme.mit.gamma.trace.util.TraceUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.expression.derivedfeatures.ExpressionModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*
import static extension hu.bme.mit.gamma.trace.derivedfeatures.TraceModelDerivedFeatures.*

class TraceBuilder {
	// Singleton
	public static final TraceBuilder INSTANCE = new TraceBuilder
	protected new() {}
	//
	protected final extension CompositeModelFactory compositeModelFactory = CompositeModelFactory.eINSTANCE
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension TraceModelFactory traceFactory = TraceModelFactory.eINSTANCE
	
	protected final extension ComplexTypeUtil complexTypeUtil = ComplexTypeUtil.INSTANCE
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	protected final extension ExpressionEvaluator expressionEvaluator = ExpressionEvaluator.INSTANCE
	protected final extension ExpressionTypeDeterminator typeDeterminator = ExpressionTypeDeterminator.INSTANCE
	protected final extension TraceUtil traceUtil = TraceUtil.INSTANCE
	protected final StatechartUtil statechartUtil = StatechartUtil.INSTANCE // For component instance reference
	
	// Add annotation
	
	def void addTimeUnitAnnotation(ExecutionTrace trace) {
		val component = trace.component
		val _package = component.containingPackage
		val smallestTimeUnit = _package.smallestTimeUnit
		
		val timeUnitAnnotation = createTimeUnitAnnotation => [
			it.timeUnit = smallestTimeUnit
		]
		trace.annotations += timeUnitAnnotation
	}
	
	// Add unraised event negations
	
	def addUnraisedEventNegations(ExecutionTrace trace) {
		val steps = trace.allSteps
		
		val component = trace.component
		val outputPorts = component.allPortsWithOutput
		
		for (step : steps) {
			val asserts = step.asserts
			val outputAsserts = step.outEvents
			
			for (outputPort : outputPorts) {
				for (outputEvent : outputPort.outputEvents.reject[it.internal]) { // Not for internal events
					val isRaised = outputAsserts.exists[it.port == outputPort && it.event == outputEvent]
					if (!isRaised) {
						val raiseEventAct = outputPort.createRaiseEventAct(outputEvent)
						raiseEventAct.arguments.clear // !
						val unraisedExpression = raiseEventAct.createNotExpression
						asserts.add(0, unraisedExpression)
					}
				}
			}
		}
	}
	
	// Remove elements
	
	def removeInternalEventRaiseActs(ExecutionTrace trace) {
		val raiseEventActs = trace.getAllContentsOfType(RaiseEventAct)
		for (raiseEventAct : raiseEventActs) {
			val event = raiseEventAct.event
			if (event.internal) {
				raiseEventAct.removeContainmentChainUntilType(Step)
			}
		}
	}
	
	def removeTransientVariableReferences(ExecutionTrace trace) {
		val instanceVariableStates = trace.getAllContentsOfType(ComponentInstanceVariableReferenceExpression)
		for (instanceVariableState : instanceVariableStates) {
			val variable = instanceVariableState.variableDeclaration
			if (variable.transient) {
				val expressionContainer = instanceVariableState.getSelfOrLastContainerOfType(Expression)
				expressionContainer.remove
			}
		}
	}
	
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
		step.addTimeElapse(elapsedTime.evaluateInteger)
	}
	
	def addTimeElapse(Step step, int elapsedTime) {
		if (elapsedTime <= 0) {
			return
		}
		
		val timeElapseActions = step.actions.filter(TimeElapse)
		if (!timeElapseActions.empty) {
			// A single time elapse action in all steps
			val action = timeElapseActions.head
			val newTime = action.elapsedTime.add(elapsedTime)
			action.elapsedTime = newTime
		}
		else {
			// No time elapses in this step so far
			step.actions.add(0, // Always in front
				createTimeElapse => [
					it.elapsedTime = elapsedTime.toIntegerLiteral
				]
			)
		}
	}
	
	// Schedule
	
	def addReset(Step step) {
		step.actions += createReset
	}
	
	def addScheduling(Step step) {
		addScheduling(step, null)
	}
	
	def addScheduling(Step step, AsynchronousComponentInstance instance) {
		if (instance !== null) {
			step.addInstanceScheduling(instance)
		}
		else {
			step.addComponentScheduling
		}
	}
	
	def scheduleIfSynchronousComponent(Step step, Component component) {
		if (component instanceof SynchronousComponent) {
			step.addComponentScheduling
		}
	}
	
	private def void addComponentScheduling(Step step) {
		step.actions += createComponentSchedule
	}
	
	private def void addInstanceScheduling(Step step, AsynchronousComponentInstance instance) {
		step.actions += createInstanceSchedule => [
			it.instanceReference = statechartUtil.createInstanceReference(instance)
			// Not reference chain - that is used for back-annotation to original component
		]
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
		step.asserts += statechartUtil.createVariableReference(
				statechartUtil.createInstanceReference(instance), variable)
					.createEqualityExpression(value)
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
		val equalityExpressions = step.asserts.filter(EqualityExpression)
		// Finding the instance, if it has been already been created
		var ComponentInstanceVariableReferenceExpression variableState = null
		var Expression value = null
		for (equalityExpression : equalityExpressions) {
			val leftOperand = equalityExpression.leftOperand
			if (leftOperand instanceof ComponentInstanceVariableReferenceExpression) {
				if (leftOperand.instance.lastInstance === instance &&
						leftOperand.variableDeclaration === variable) {
					variableState = leftOperand
					value = leftOperand.otherOperandIfContainedByEquality
				}
			}
			// We do not put ComponentInstanceVariableReferenceExpression as a right operand
		}
		if (variableState === null) {
			// Creating the literal, similar to "getInstance" in singletons
			val type = variable.typeDefinition
			val initialValue = type.initialValueOfType
			step.asserts += statechartUtil.createVariableReference(
					statechartUtil.createInstanceReference(instance), variable)
						.createEqualityExpression(initialValue)
			
			return initialValue
		}
		else {
			return value
		}
	}
	
	// Instance states
	
	def addInstanceState(Step step, SynchronousComponentInstance instance, State state) {
		step.asserts += createComponentInstanceStateReferenceExpression => [
			it.instance = statechartUtil.createInstanceReference(instance)
			it.region = state.parentRegion
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
			case "false", case "FALSE":
				return 0
			case "true", case "TRUE":
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
		val valueToBeChanged = literal.getValue(fieldHierarchy, indexes)
		val innerType = valueToBeChanged.typeDefinition // Works even if fieldHierarchy is empty
		val newValue = innerType.createLiteral(value)
		newValue.replace(valueToBeChanged)
	}
	
}