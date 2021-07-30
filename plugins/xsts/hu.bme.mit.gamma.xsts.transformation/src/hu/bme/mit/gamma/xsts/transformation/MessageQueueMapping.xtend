package hu.bme.mit.gamma.xsts.transformation

import hu.bme.mit.gamma.expression.model.VariableDeclaration
import java.util.List
import java.util.Map
import java.util.Set
import org.eclipse.xtend.lib.annotations.Data

@Data
class MessageQueueMapping {
	
	Set<Integer> eventIds
	VariableDeclaration masterQueue // Integer array
	VariableDeclaration sizeVariable // Integer
	Map<Integer, List<VariableDeclaration>> slaveQueues // Event id - list is in accordance with the order of event parameters
	
}