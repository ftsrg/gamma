package hu.bme.mit.gamma.xsts.transformation

import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.xtend.lib.annotations.Data

@Data
class MessageQueueMapping {
	
	Set<Integer> eventIds
	MessageQueueStruct masterQueue
	Map<Integer, List<MessageQueueStruct>> slaveQueues // Event id - list is in accordance with the order of event parameters
	
}