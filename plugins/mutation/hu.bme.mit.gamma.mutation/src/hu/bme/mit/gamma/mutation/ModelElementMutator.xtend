/********************************************************************************
 * Copyright (c) 2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.mutation

import hu.bme.mit.gamma.expression.model.AddExpression
import hu.bme.mit.gamma.expression.model.AndExpression
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.EqualityExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.FalseExpression
import hu.bme.mit.gamma.expression.model.GreaterEqualExpression
import hu.bme.mit.gamma.expression.model.GreaterExpression
import hu.bme.mit.gamma.expression.model.InequalityExpression
import hu.bme.mit.gamma.expression.model.IntegerLiteralExpression
import hu.bme.mit.gamma.expression.model.LessEqualExpression
import hu.bme.mit.gamma.expression.model.LessExpression
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.NotExpression
import hu.bme.mit.gamma.expression.model.OrExpression
import hu.bme.mit.gamma.expression.model.SubtractExpression
import hu.bme.mit.gamma.expression.model.TrueExpression
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.math.BigInteger
import java.util.List
import java.util.Random
import java.util.logging.Logger
import org.eclipse.emf.ecore.EObject

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ModelElementMutator {
	
	//
	protected final Random random = new Random()
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	protected final extension StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE
	
	protected final extension Logger logger = Logger.getLogger("GammaLogger")
	//

	// Statechart structural elements
	
	def changeTransitionSource(Transition transition) {
		val source = transition.sourceState
		val region = source.parentRegion
		val states = region.states
		
		val newSource = states.selectDifferentElement(source)
		transition.sourceState = newSource
		
		info('''Changed transition's source from «source.name» to «newSource.name»''')
	}
	
	def changeTransitionTarget(Transition transition) {
		val target = transition.targetState
		val region = target.parentRegion
		val states = region.states
		
		val newTarget = states.selectDifferentElement(target)
		transition.targetState = newTarget
		
		info('''Changed transition's target from «target.name» to «newTarget.name»''')
	}
	
	def removeTransition(Transition transition) {
		transition.remove
		
		info('''Removed transition from «transition.sourceState.name» to «transition.targetState.name»''')
	}
	
	def removeTransitionGuard(Transition transition) {
		val guard = transition.guard
		guard.remove

		info('''Removed guard of transition from «transition.sourceState.name» to «transition.targetState.name»''')
	}
	
	def removeTransitionTrigger(Transition transition) {
		val trigger = transition.trigger
		val onCycleTrigger = createOnCycleTrigger
		
		onCycleTrigger.replace(trigger)

		info('''Removed trigger of transition from «transition.sourceState.name» to «transition.targetState.name»''')
	}
	
	//
	
	def changePortReference(AnyPortEventReference reference) {
		val oldPort = reference.port
		val newPort = oldPort.newInPort
		
		reference.port = newPort
	}
	
	def changePortReference(PortEventReference reference) {
		val oldPort = reference.port
		val newPort = oldPort.newInPort
		
		reference.port = newPort
	}
	
	def changeEventReference(PortEventReference reference) {
		val port = reference.port
		val oldEvent = reference.event
		val newEvent = port.getNewInEvent(oldEvent)
		
		reference.event = newEvent
	}
	
	// Should be overridable
	protected def getNewInPort(Port port) {
		val component = port.containingComponent
		val ports = component.allPortsWithInput
		
		return ports.selectDifferentElement(port)
	}
	
	// Should be overridable
	protected def getNewOutPort(Port port) {
		val component = port.containingComponent
		val ports = component.allPortsWithOutput
		
		return ports.selectDifferentElement(port)
	}
	
	// Should be overridable
	protected def getNewInEvent(Port port, Event event) {
		val events = port.inputEvents
		
		return events.selectDifferentElement(event)
	}
	
	// Should be overridable
	protected def getNewOutEvent(Port port, Event event) {
		val events = port.outputEvents
		
		return events.selectDifferentElement(event)
	}
	
	def changePortReference(RaiseEventAction action) {
		val oldPort = action.port
		val newPort = oldPort.newOutPort
		
		action.port = newPort
	}
	
	def changeEventReference(RaiseEventAction action) {
		val port = action.port
		val oldEvent = action.event
		
		val newEvent = port.getNewOutEvent(oldEvent)
		
		action.event = newEvent
	}
	
	def removeEntryAction(State state) {
		val entryActions = state.entryActions
		
		if (entryActions.empty) {
			return
		}
		
		val entryAction = entryActions.selectElement
		entryAction.remove
	}
	
	def removeExitAction(State state) {
		val exitActions = state.exitActions
		
		if (exitActions.empty) {
			return
		}
		
		val exitAction = exitActions.selectElement
		exitAction.remove
	}
	
	def removeEffect(Transition transition) {
		val effects = transition.effects
		
		if (effects.empty) {
			return
		}
		
		val effect = effects.selectElement
		effect.remove
	}
	
	// Expression and action elements
	
	def invertExpression(TrueExpression expression) {
		val _false = createFalseExpression
		
		_false.replace(expression)
	}
	
	def invertExpression(FalseExpression expression) {
		val _true = createTrueExpression
		
		_true.replace(expression)
	}
	
	def invertExpression(IntegerLiteralExpression expression) {
		val value = expression.value
		expression.value = value.negate
	}
	
	def invertExpression(AddExpression expression) {
		val subtract = createSubtractExpression.addInto(expression.operands)
		
		subtract.replace(expression)
	}
	
	def invertExpression(SubtractExpression expression) {
		val add = createAddExpression.addInto(
			expression.leftOperand, expression.rightOperand)
		
		add.replace(expression)
	}
	
	def invertExpression(NotExpression expression) {
		val operand = expression.operand
		
		operand.replace(expression)
	}
	
	def invertExpression(LessExpression expression) {
		val greaterEqual = createGreaterEqualExpression.addInto(
			expression.leftOperand, expression.rightOperand)
		
		greaterEqual.replace(expression)
	}
	
	def invertExpression(LessEqualExpression expression) {
		val greater = createGreaterExpression.addInto(
			expression.leftOperand, expression.rightOperand)
		
		greater.replace(expression)
	}
	
	def invertExpression(GreaterExpression expression) {
		val lessEqual = createLessEqualExpression.addInto(
			expression.leftOperand, expression.rightOperand)
		
		lessEqual.replace(expression)
	}
	
	def invertExpression(GreaterEqualExpression expression) {
		val less = createLessExpression.addInto(
			expression.leftOperand, expression.rightOperand)
		
		less.replace(expression)
	}
	
	def invertExpression(EqualityExpression expression) {
		val inequal = createInequalityExpression.addInto(
			expression.leftOperand, expression.rightOperand)
		
		inequal.replace(expression)
	}
	
	def invertExpression(InequalityExpression expression) {
		val equal = createEqualityExpression.addInto(
			expression.leftOperand, expression.rightOperand)
		
		equal.replace(expression)
	}
	
	def changeExpression(IntegerLiteralExpression expression) {
		val value = expression.value
		if (random.nextBoolean) {
			expression.value = value.add(BigInteger.ONE)
		}
		else {
			expression.value = value.subtract(BigInteger.ONE)
		}
	}
	
	def changeExpression(AndExpression expression) {
		val or = createOrExpression.addInto(expression.operands)
		
		or.replace(expression)
	}
	
	def changeExpression(OrExpression expression) {
		val and = createAndExpression.addInto(expression.operands)
		
		and.replace(expression)
	}
	
	def changeExpression(LessExpression expression) {
		val lessEqual = createLessEqualExpression.addInto(
			expression.leftOperand, expression.rightOperand)
		
		lessEqual.replace(expression)
	}
	
	def changeExpression(LessEqualExpression expression) {
		val less = createLessExpression.addInto(
			expression.leftOperand, expression.rightOperand)
		
		less.replace(expression)
	}
	
	def changeExpression(GreaterExpression expression) {
		val greaterEqual = createGreaterEqualExpression.addInto(
			expression.leftOperand, expression.rightOperand)
		
		greaterEqual.replace(expression)
	}
	
	def changeExpression(GreaterEqualExpression expression) {
		val greater = createGreaterExpression.addInto(
			expression.leftOperand, expression.rightOperand)
		
		greater.replace(expression)
	}
	
	//
	
	protected def addInto(MultiaryExpression pivot, Expression lhs, Expression rhs) {
		return pivot.addInto(
			#[lhs, rhs])
	}
	
	protected def addInto(MultiaryExpression pivot, List<? extends Expression> expressions) {
		pivot.operands += expressions
		
		return pivot
	}
	
	protected def addInto(BinaryExpression pivot, List<? extends Expression> expressions) {
		checkState(expressions.size == 2)
		pivot.leftOperand = expressions.head
		pivot.rightOperand = expressions.get(1)
		
		return pivot
	}
	
	protected def addInto(BinaryExpression pivot, Expression lhs, Expression rhs) {
		return pivot.addInto(
			#[lhs, rhs])
	}
	
	//
	
	protected def <T extends EObject> selectDifferentElement(
				List<? extends T> objects, T object) {
		checkState(objects.contains(object), objects + " " + object)
		
		if (objects.size <= 1) {
			throw new IllegalArgumentException("The list contains only this element: " + object)
		}
		
		val index = objects.indexOf(object)
		
		var int i = -1
		do {
			i = random.nextInt(objects.size)
		} while (i == index)
		
		val newObject = objects.get(i)
		
		return newObject
	}
	
	protected def <T extends EObject> selectElement(List<? extends T> objects) {
		if (objects.empty) {
			return null
		}
		
		val i = random.nextInt(objects.size)
		val newObject = objects.get(i)
		
		return newObject
	}
	
	//
	
}