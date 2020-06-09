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

import hu.bme.mit.gamma.statechart.statechart.BinaryTrigger
import hu.bme.mit.gamma.statechart.interface_.EventReference
import hu.bme.mit.gamma.statechart.interface_.EventTrigger
import hu.bme.mit.gamma.statechart.statechart.PortEventReference
import hu.bme.mit.gamma.statechart.statechart.Transition
import hu.bme.mit.gamma.statechart.interface_.Trigger
import hu.bme.mit.gamma.statechart.statechart.UnaryTrigger

class EventPriorityDeterminer {
	
	def isTransitionTriggerPrioritized(Transition transition) {
		if (transition.trigger === null) {
			return false
		}
		return transition.trigger.isTriggerPrioritized
	}
	
	def dispatch boolean isTriggerPrioritized(Trigger trigger) {
		throw new IllegalArgumentException("Not known trigger: " + trigger)
	}
	
	def dispatch boolean isTriggerPrioritized(UnaryTrigger trigger) {
		return trigger.operand.isTriggerPrioritized
	}
	
	def dispatch boolean isTriggerPrioritized(BinaryTrigger trigger) {
		return trigger.leftOperand.isTriggerPrioritized || trigger.rightOperand.isTriggerPrioritized
	}
	
	def dispatch boolean isTriggerPrioritized(EventTrigger trigger) {
		return trigger.eventReference.isEventPrioritized
	}
	
	def dispatch boolean isEventPrioritized(EventReference eventReference) {
		return false
	}
	
	def dispatch boolean isEventPrioritized(PortEventReference eventReference) {
		return eventReference.event.priority !== null
	}
	
}