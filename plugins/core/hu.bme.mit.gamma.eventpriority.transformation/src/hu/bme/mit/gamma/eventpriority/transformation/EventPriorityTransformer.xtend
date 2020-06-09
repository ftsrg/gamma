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

import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.interface_.Package
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.StatechartDefinition
import hu.bme.mit.gamma.statechart.statechart.TransitionPriority
import java.util.logging.Level
import java.util.logging.Logger

import static com.google.common.base.Preconditions.checkState

class EventPriorityTransformer {
	
	protected final Package gammaPackage
	protected final StatechartDefinition statechart
	
	protected final extension EventPriorityDeterminer eventPriorityDeterminer = new EventPriorityDeterminer

	protected Logger logger = Logger.getLogger("Gamma")
	
	new(StatechartDefinition statechart) {
		// No cloning to save resources, we process the original model
		this.gammaPackage = statechart.eContainer as Package
		this.statechart = statechart
	}
	
	def execute() {
		if (!(this.statechart.transitionPriority == TransitionPriority.OFF || 
				this.statechart.transitionPriority == TransitionPriority.VALUE_BASED)) {
			logger.log(Level.WARNING ,"Transition priority is neither off nor value-based: " + this.statechart.transitionPriority)
		}
		for (transition : statechart.transitions) {
			if (transition.isTransitionTriggerPrioritized) {
				val trigger = transition.trigger
				checkState(trigger instanceof EventTrigger,
					"The trigger of the transition is not an event trigger: " + trigger)
				if (trigger instanceof EventTrigger) {
					val eventReference = trigger.eventReference
					checkState(eventReference instanceof PortEventReference,
						"The event reference is not a port event reference: " + eventReference)
					if (eventReference instanceof PortEventReference) {
						val event = eventReference.event
						checkState(transition.priority === null || transition.priority.intValue == 0 ||
							transition.priority == event.priority,
							"The transition priority is not null or 0: " + transition.priority)
						transition.priority = event.priority
						this.statechart.transitionPriority = TransitionPriority.VALUE_BASED
					}
				}
			}
		}
		return gammaPackage
	}
	
}