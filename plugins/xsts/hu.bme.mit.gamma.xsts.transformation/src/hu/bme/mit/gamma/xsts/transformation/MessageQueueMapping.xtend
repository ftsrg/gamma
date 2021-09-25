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

import hu.bme.mit.gamma.expression.model.Type
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
	
	// Event id - list is in accordance with the order of event parameters
	// Some MessageQueueStructs are duplicated due to optimization
	Map<Entry<Port, Event>, List<MessageQueueStruct>> slaveQueues
	// Same MessageQueueStructs as in slaveQueues, just associated to Types
	Map<? extends Type, List<MessageQueueStruct>> typeSlaveQueues 
	
}