/********************************************************************************
 * Copyright (c) 2018-2023 Contributors to the Gamma project
 *
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * SPDX-License-Identifier: EPL-1.0
 ********************************************************************************/
package hu.bme.mit.gamma.xsts.transformation.util

import hu.bme.mit.gamma.expression.model.ParameterDeclaration
import hu.bme.mit.gamma.expression.model.VariableDeclaration
import hu.bme.mit.gamma.statechart.composite.ComponentInstance
import hu.bme.mit.gamma.statechart.composite.MessageQueue
import hu.bme.mit.gamma.statechart.interface_.Port

import static extension java.lang.Math.*

class QueueNamings {
	
	def static String getMasterQueueName(
		MessageQueue queue, ComponentInstance instance) '''master_«queue.name»Of«instance.name»'''
	def static String getMasterSizeVariableName(
		MessageQueue queue, ComponentInstance instance) '''sizeMaster«queue.name.toFirstUpper»Of«instance.name»'''
	
	def static String getSlaveQueueName(ParameterDeclaration parameterDeclaration,
			Port port, ComponentInstance instance) // For traceability reasons, parameterDeclaration is needed
		'''slave_«port.name»_«parameterDeclaration.name»Of«instance.name»'''
	def static String getSlaveSizeVariableName(
			ParameterDeclaration parameterDeclaration, Port port, ComponentInstance instance)
		'''sizeSlave«parameterDeclaration.name.toFirstUpper»«port.name.toFirstUpper»Of«instance.name»'''
	
	def static String getEventIdLocalVariableName(VariableDeclaration queue)
		'''eventId_«queue.name»_«queue.hashCode.abs»'''
	def static String getRandomValueLocalVariableName(VariableDeclaration queue)
		'''random_«queue.name»_«queue.hashCode.abs»'''
	
	def static String getLoopIterationVariableName() '''i'''
		
}