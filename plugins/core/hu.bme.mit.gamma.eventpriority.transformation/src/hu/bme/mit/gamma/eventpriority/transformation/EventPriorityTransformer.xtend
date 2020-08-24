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
package hu.bme.mit.gamma.eventpriority.transformation

import hu.bme.mit.gamma.statechart.interface_.Component
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.EventReference
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.interface_.InterfaceModelFactory
import hu.bme.mit.gamma.statechart.interface_.Trigger
import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.statechart.BinaryType
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.StatechartModelFactory
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.statechart.UnaryType
import hu.bme.mit.gamma.statechart.util.StatechartUtil
import hu.bme.mit.gamma.util.GammaEcoreUtil
import java.util.Collection
import java.util.logging.Logger

import static extension hu.bme.mit.gamma.statechart.derivedfeatures.StatechartModelDerivedFeatures.*

class EventPriorityTransformer {
	
	protected final StatechartDefinition statechart
	
	protected final extension StatechartUtil statechartUtil = StatechartUtil.INSTANCE
	protected final extension GammaEcoreUtil gammaEcoreUtil = GammaEcoreUtil.INSTANCE
	
	protected final extension InterfaceModelFactory interfaceFactory = InterfaceModelFactory.eINSTANCE;
	protected final extension StatechartModelFactory statechartFactory = StatechartModelFactory.eINSTANCE;
	
	protected Logger logger = Logger.getLogger("Gamma")
	
	new(StatechartDefinition statechart) {
		// No cloning to save resources, we process the original model
		this.statechart = statechart
	}
	
	def execute() {
		for (transition : statechart.transitions) {
			transition.extendTransition
		}
		return statechart
	}
	
	protected def extendTransition(Transition transition) {
		val trigger = transition.trigger
		if (trigger !== null) {
			val eventTriggers = trigger.getSelfAndAllContentsOfType(EventTrigger)
			for (eventTrigger : eventTriggers) {
				eventTrigger.extendTrigger
			}
		}
	}
	
	///
	
	protected def dispatch void extendTrigger(Trigger trigger) {
		throw new IllegalArgumentException("Not supported trigger type: " + trigger)
	}
	
	// Note that not-triggers and other any triggers are not supported
	
	protected def dispatch void extendTrigger(BinaryTrigger trigger) {
		// Not needed as trigger.getSelfAndAllContentsOfType(EventTrigger) is called above
	}
	
	protected def dispatch void extendTrigger(EventTrigger trigger) {
		val eventReference = trigger.eventReference
		if (eventReference instanceof PortEventReference) {
			val component = trigger.containingComponent
			val higherPriorityEvents = eventReference.higherPriorityEvents
			var Trigger actualTrigger = trigger
			for (higherPriorityEvent : higherPriorityEvents) {
				for (port : component.ports.filter[it.inputEvents.contains(higherPriorityEvent)]) {
					val notTrigger = createUnaryTrigger => [
						it.type = UnaryType.NOT
						it.operand = createEventTrigger => [
							it.eventReference = createPortEventReference => [
								it.port = port
								it.event = higherPriorityEvent
							]
						]
					]
					val andTrigger = createBinaryTrigger(
						actualTrigger.clone /*Important due to replace*/, notTrigger, BinaryType.AND)
					andTrigger.change(actualTrigger, component)
					andTrigger.replace(actualTrigger)
					actualTrigger = andTrigger
				}
			}
		}
	}
	
	///
		
	protected def dispatch Collection<Event> getHigherPriorityEvents(EventReference eventReference) {
		throw new IllegalArgumentException("Not supported reference type: " + eventReference)
	}
	
	// Note that any port event references and timeout references are not supported
	
	protected def dispatch Collection<Event> getHigherPriorityEvents(PortEventReference eventReference) {
		val component = eventReference.getContainerOfType(Component)
		return eventReference.event.getHigherPriorityEvents(component)
	}
	
	///
	
	protected def Collection<Event> getHigherPriorityEvents(Event event, Component component) {
		val priority = event.priorityValue
		val events = component.allPorts.map[it.inputEvents].flatten
		return events.filter[it.priorityValue > priority].toSet
	}
	
}