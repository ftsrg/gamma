package hu.bme.mit.gamma.uppaal.verification

import hu.bme.mit.gamma.expression.model.BooleanTypeDefinition
import hu.bme.mit.gamma.expression.model.EnumerationTypeDefinition
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.IntegerTypeDefinition
import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.Type
import hu.bme.mit.gamma.expression.model.TypeReference
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.model.Port
import hu.bme.mit.gamma.statechart.model.State
import hu.bme.mit.gamma.statechart.model.composite.AsynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.composite.Component
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponent
import hu.bme.mit.gamma.statechart.model.composite.SynchronousComponentInstance
import hu.bme.mit.gamma.statechart.model.interface_.Event
import hu.bme.mit.gamma.trace.model.RaiseEventAct
import hu.bme.mit.gamma.trace.model.Step
import hu.bme.mit.gamma.trace.model.TimeElapse
import hu.bme.mit.gamma.trace.model.TraceFactory
import hu.bme.mit.gamma.trace.model.TraceUtil
import java.math.BigInteger

import static extension hu.bme.mit.gamma.expression.model.derivedfeatures.ExpressionModelDerivedFeatures.*

class TraceBuilder {
	
	protected final extension ExpressionModelFactory expressionModelFactory = ExpressionModelFactory.eINSTANCE
	protected final extension TraceFactory traceFactory = TraceFactory.eINSTANCE
	
	protected final extension TraceUtil traceUtil = new TraceUtil
		
	def scheduleIfSynchronousComponent(Step step, Component component) {
		if (component instanceof SynchronousComponent) {
			step.addComponentScheduling
		}
	}
	
	def addInEventWithParameter(Step step, Port port, Event event, ParameterDeclaration parameter, String string) {
		switch (string) {
			case "false":
				return addInEvent(step, port, event, parameter, 0)
			case "true":
				return addInEvent(step, port, event, parameter, 1)
			default:
				return addInEvent(step, port, event, parameter, Integer.parseInt(string))
		}
	}
	
	def addInEvent(Step step, Port port, Event event) {
		addInEvent(step, port, event, null, null)		
	}
	
	protected def addInEvent(Step step, Port port, Event event,
			ParameterDeclaration parameter, Integer value) {
		val eventRaise = createRaiseEventAct(port, event, parameter, value)
		val originalRaise = step.actions.filter(RaiseEventAct).findFirst[it.isOverWritten(eventRaise)]
		if (originalRaise === null) {
			// This is the first raise
			step.actions += eventRaise
		}
		else if (parameter !== null) {
			// Already a raise has been done, setting this parameter too
			val index = parameter.index
			originalRaise.arguments.set(index, parameter.createParameter(value))
		}
	}
	
	protected def createRaiseEventAct(Port port, Event event,
			ParameterDeclaration parameter,	Integer value) {
		val RaiseEventAct eventRaise = createRaiseEventAct => [
			it.port = port
			it.event = event
		]
		val parameters = event.parameterDeclarations
		for (dummyParameter : parameters) {
			eventRaise.arguments += createFalseExpression
		}
		if (parameter !== null) {
			val index = parameter.index
			eventRaise.arguments.set(index, parameter.createParameter(value))
		}		
		return eventRaise
	}
	
	protected def createParameter(ParameterDeclaration parameter, Integer value) {
		if (parameter === null) {
			return null
		}
		val paramType = parameter.type
		return paramType.createLiteral(value)
	}
	
	protected def createVariableLiteral(VariableDeclaration variable,
			Integer value) {
		val type = variable.type
		return type.createLiteral(value)
	}
	
	private def Expression createLiteral(Type paramType, Integer value) {
		val literal = switch (paramType) {
			IntegerTypeDefinition: createIntegerLiteralExpression => [it.value = BigInteger.valueOf(value)]
			BooleanTypeDefinition: {
				if (value == 0) {
					createFalseExpression
				}
				else {
					createTrueExpression
				}
			}
			TypeReference: {
				val typeDeclaration = paramType.reference
				val type = typeDeclaration.type
				if (type.isPrimitive) {
					return type.createLiteral(value)
				}
				switch (type) {
					EnumerationTypeDefinition:
						return createEnumerationLiteralExpression => [ it.reference = type.literals.get(value) ]				
					default: 
						throw new IllegalArgumentException("Not known type definition: " + type)
				}
			}
			default: 
				throw new IllegalArgumentException("Not known type: " + paramType)
		}
		return literal
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
	
	def addScheduling(Step step, AsynchronousComponentInstance instance) {
		step.actions += createInstanceSchedule => [
			it.scheduledInstance = instance
		]
	}
	
	def addComponentScheduling(Step step) {
		step.actions += createComponentSchedule
	}
	
	def addOutEvent(Step step, Port port, Event event) {
		addOutEventWithParameter(step, port, event, null, null)
	}
	
	protected def addOutEventWithParameter(Step step, Port port, Event event,
			ParameterDeclaration parameter, Integer value) {
		val eventRaise = createRaiseEventAct(port, event, parameter, value)
		val originalRaise = step.outEvents.findFirst[it.isOverWritten(eventRaise)]
		if (originalRaise === null) {
			// This is the first raise
			step.outEvents += eventRaise
		}
		else if (parameter !== null) {
			// Already a raise has been done, setting this parameter too
			val index = parameter.index
			originalRaise.arguments.set(index, parameter.createParameter(value))
		}
	}
	
	protected def addInstanceVariableState(Step step, SynchronousComponentInstance instance,
			VariableDeclaration variable,	Expression value) {
		step.instanceStates += createInstanceVariableState => [
			it.instance = instance
			it.declaration = variable
			it.value = value
		]
	}
	
	protected def addInstanceState(Step step, SynchronousComponentInstance instance, State state) {
		step.instanceStates += createInstanceStateConfiguration => [
			it.instance = instance
			it.state = state
		]
	}
	
}