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
import hu.bme.mit.gamma.expression.model.BinaryExpression
import hu.bme.mit.gamma.expression.model.Expression
import hu.bme.mit.gamma.expression.model.ExpressionModelFactory
import hu.bme.mit.gamma.expression.model.MultiaryExpression
import hu.bme.mit.gamma.expression.model.SubtractExpression
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import hu.bme.mit.gamma.statechart.statechart.AnyPortEventReference
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.RaiseEventAction
import hu.bme.mit.gamma.statechart.statechart.State
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.List
import java.util.Random
import org.eclipse.emf.ecore.EObject

import static com.google.common.base.Preconditions.checkState

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class ModelElementMutator {
	
	//
	protected final Random random = new Random()
	protected final extension GammaEcoreUtil ecoreUtil = GammaEcoreUtil.INSTANCE
	
	protected final extension ExpressionModelFactory expressionFactory = ExpressionModelFactory.eINSTANCE
	//

	// Statechart structural elements
	
	def changeTransitionSource(Transition transition) {
		val newSource = transition.newState
		transition.sourceState = newSource
	}
	
	def changeTransitionTarget(Transition transition) {
		val newTarget = transition.newState
		transition.targetState = newTarget
	}
	
	// Should be overridable
	protected def getNewState(Transition transition) {
		val source = transition.sourceState
		val region = source.parentRegion
		
		val states = region.states
		
		return states.selectDifferentElement(source)
	}
	
	def removeTransition(Transition transition) {
		transition.remove
	}
	
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
	
	def invertExpression(AddExpression expression) {
		val subtract = createSubtractExpression.addInto(expression.operands)
		
		subtract.replace(expression)
	}
	
	def invertExpression(SubtractExpression expression) {
		val add = createAddExpression.addInto(
			expression.leftOperand, expression.rightOperand)
		
		add.replace(expression)
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
		} while (i !== index)
		
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