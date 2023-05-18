/********************************************************************************
 * Copyright (c) 2018-2021 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.statechart.composite.MessageQueue
import hu.bme.mit.gamma.statechart.interface_.Clock
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import java.util.Map
import java.util.Map.Entry
import java.util.SortedMap

class MessageQueueTraceability {
	
	protected final Map<Clock, Integer> clockIds = newHashMap
	protected final Map<Entry<Port, Event>, Integer> eventIds = newHashMap
	protected final SortedMap<MessageQueue, MessageQueueMapping> messageQueues = newTreeMap(
		lhs, rhs | {
			val result = rhs.priority.compareTo(lhs.priority) /* Highest value - greater priority */
			if (result == 0) {
				return lhs.hashCode.compareTo(rhs.hashCode) // Random
			}
			return result
		}
	)
	
	// All event reference types
	
	def get(Object eventReference) {
		if (eventReference instanceof Clock) {
			return eventReference.get
		}
		else if (eventReference instanceof Entry) {
			return eventReference.get
		}
		else {
			throw new IllegalArgumentException("Not known type: " + eventReference)
		}
	}
	
	//
	
	def put(Clock clock, Integer id) { // Starts from 1, 0 is the "empty cell"
		clockIds += clock -> id
	}
	
	def get(Clock clock) {
		return clockIds.get(clock)
	}
	
	def contains(Clock clock) {
		return clockIds.containsKey(clock)
	}
	
	//
	
	def put(Entry<Port, Event> event, Integer id) { // Starts from 1, 0 is the "empty cell"
		eventIds += event -> id
	}
	
	def get(Entry<Port, Event> event) {
		return eventIds.get(event)
	}
	
	def contains(Entry<Port, Event> event) {
		return eventIds.containsKey(event)
	}
	
	//
	
	def put(MessageQueue messageQueue, MessageQueueMapping mapping) {
		messageQueues += messageQueue -> mapping
	}
	
	def get(MessageQueue messageQueue) {
		return messageQueues.get(messageQueue)
	}
	
	def getMessageQueues() {
		return messageQueues.keySet
	}
	
	def getMessageQueues(Entry<Port, Event> portEvent) {
		for (entry : messageQueues.entrySet) {
			val mappings = entry.value
			val portEvents = mappings.portEvents
			if (portEvents.contains(portEvent)) {
				return entry // Sorted according to priority, greatest priority is returned
			}
		}
		throw new IllegalArgumentException("Not found queue for id: " + portEvent)
	}
	
	//
	
	def getMasterQueues() {
		val masterQueues = newHashSet
		for (messageQueue : messageQueues.values) {
			masterQueues += messageQueue.masterQueue
		}
		return masterQueues
	}
	
	def getAllSlaveQueues() {
		val slaveQueues = newHashSet
		for (messageQueue : messageQueues.values) {
			slaveQueues += messageQueue.slaveQueues.values.flatten
		}
		return slaveQueues
	}
	
	def getAllQueues() {
		val queues = newHashSet
		queues += masterQueues
		queues += allSlaveQueues
		return queues
	}
	
}