package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.statechart.interface_.Event
import hu.bme.mit.gamma.statechart.interface_.Port
import java.util.List
import java.util.Map
import java.util.Map.Entry
import java.util.Set
import org.eclipse.xtend.lib.annotations.Data

@Data
class MessageQueueMapping {
	
	Set<Entry<Port, Event>> portEvents
	MessageQueueStruct masterQueue
	Map<Entry<Port, Event>, List<MessageQueueStruct>> slaveQueues // Event id - list is in accordance with the order of event parameters
	
}