package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.statechart.composite.MessageQueue
import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import java.util.Map
import java.util.Map.Entry
import java.util.SortedMap

class MessageQueueTraceability {
	
	protected int eventId = 1 // 0 is the "empty cell"
	
	protected final Map<Entry<Port, Event>, Integer> eventIds = newHashMap
	protected final SortedMap<MessageQueue, MessageQueueMapping> messageQueues = newTreeMap(
		lhs, rhs | lhs.priority.compareTo(rhs.priority))
	
	//
	
	def put(Entry<Port, Event> event) {
		eventIds += event -> eventId++
	}
	
	def get(Entry<Port, Event> event) {
		return eventIds.get(event)
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
	
}